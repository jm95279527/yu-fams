package com.example.service;

import cn.hutool.core.date.DateUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.example.common.enums.ResultCodeEnum;
import com.example.common.enums.RoleEnum;
import com.example.entity.Account;
import com.example.entity.Assets;
import com.example.entity.AssetsReceive;
import com.example.entity.AssetsRepair;
import com.example.exception.CustomException;
import com.example.mapper.AssetsReceiveMapper;
import com.example.mapper.AssetsRepairMapper;
import com.example.utils.TokenUtils;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * 资产借用业务处理
 **/
@Service
public class AssetsReceiveService {

    /** 手机号：1 开头 11 位 */
    private static final Pattern PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$");

    @Resource
    private AssetsReceiveMapper assetsReceiveMapper;
    @Resource
    private AssetsService assetsService;
    @Resource
    private AssetsRepairMapper assetsRepairMapper;
    @Resource
    private NotifyService notifyService;
    /**
     * 新增
     */
    public void add(AssetsReceive assetsReceive) {
        Integer assetsId = assetsReceive.getAssetsId();
        if (assetsId == null) {
            throw new CustomException("500", "请选择借用资产");
        }
        // 借用人姓名、联系方式（手机号）手工填写且必填
        if (StrUtil.isBlank(assetsReceive.getBorrowerName())) {
            throw new CustomException("500", "请填写借用人");
        }
        if (StrUtil.isBlank(assetsReceive.getBorrowerPhone())) {
            throw new CustomException("500", "请填写联系方式");
        }
        String phone = assetsReceive.getBorrowerPhone().trim();
        if (!PHONE_PATTERN.matcher(phone).matches()) {
            throw new CustomException("500", "联系方式格式不正确，请填写 11 位手机号");
        }
        assetsReceive.setBorrowerName(assetsReceive.getBorrowerName().trim());
        assetsReceive.setBorrowerPhone(phone);

        Assets assets = assetsService.selectById(assetsId);
        if (assets == null) {
            throw new CustomException("500", "资产不存在");
        }
        if (assets.getNum() == null || assets.getNum() <= 0) {
            throw new CustomException(ResultCodeEnum.ASSETS_NUM_ERROR);
        }
        // 登录用户仍记录 staffId（个人资产/归还流程依赖），扫码匿名提交时为空
        if (assetsReceive.getStaffId() == null) {
            Account currentUser = TokenUtils.getCurrentUser();
            assetsReceive.setStaffId(currentUser.getId());
        }
        assetsReceive.setDate(DateUtil.now());
        assetsReceive.setStatus("待审核");
        assetsReceive.setReturnStatus("未归还");
        assetsReceiveMapper.insert(assetsReceive);

        // 提交申请即推送群通知，管理员看到通知再去审核
        Map<String, Object> vars = new HashMap<>();
        vars.put("assetsName", assets.getName());
        vars.put("assetsNo", assets.getNo());
        vars.put("applicant", assetsReceive.getBorrowerName());
        vars.put("borrowerPhone", assetsReceive.getBorrowerPhone());
        vars.put("returnDate", assetsReceive.getReturnDate());
        vars.put("comment", assetsReceive.getComment());
        notifyService.push("RECEIVE_SUBMIT", "借用", assetsReceive.getId(), vars);
    }
    /**
     * 删除
     * 若该单已审核通过且未归还（借出时已扣库存），删除时把库存还回去，
     * 否则资产会永远卡在「已借出 / 库存 0」
     */
    public void deleteById(Integer id) {
        restoreStockIfBorrowed(assetsReceiveMapper.selectById(id));
        assetsReceiveMapper.deleteById(id);
    }

    /**
     * 批量删除
     */
    public void deleteBatch(List<Integer> ids) {
        for (Integer id : ids) {
            deleteById(id);
        }
    }

    /**
     * 借用单被删除时恢复库存（仅针对「已借出未归还」的单据）
     */
    private void restoreStockIfBorrowed(AssetsReceive receive) {
        if (receive == null || receive.getAssetsId() == null) {
            return;
        }
        if (!"通过".equals(receive.getStatus()) || !"未归还".equals(receive.getReturnStatus())) {
            return;
        }
        Assets assets = assetsService.selectById(receive.getAssetsId());
        if (assets == null) {
            return;
        }
        assets.setNum((assets.getNum() == null ? 0 : assets.getNum()) + 1);
        if ("已借出".equals(assets.getStatus())) {
            assets.setStatus("正常");
        }
        assetsService.updateById(assets);
    }


    /**
     * 修改
     */
    public void updateById(AssetsReceive assetsReceive) {
        Account currentUser = TokenUtils.getCurrentUser();
        AssetsReceive before = assetsReceive.getId() == null ? null : assetsReceiveMapper.selectById(assetsReceive.getId());
        String oldStatus = before == null ? null : before.getStatus();
        String oldReturnStatus = before == null ? null : before.getReturnStatus();

        // 审核通过：一物一码按台借出——数量 -1，数量归零时状态置为「已借出」
        boolean justApproved = "通过".equals(assetsReceive.getStatus()) && !"通过".equals(oldStatus);
        if (RoleEnum.ADMIN.name().equals(currentUser.getRole()) && justApproved) {
            Assets assets = assetsService.selectById(resolveAssetsId(assetsReceive, before));
            if (assets != null) {
                int left = (assets.getNum() == null ? 0 : assets.getNum()) - 1;
                assets.setNum(left);
                if (left <= 0) {
                    assets.setStatus("已借出");
                }
                assetsService.updateById(assets);
            }
        }

        // 归还：库存 +1。管理员在「资产借用」页归还、员工在「个人资产」页归还都走这里，
        // 同样用库中原状态判断，只在「未归还 → 已归还」时执行一次
        boolean returning = "已归还".equals(assetsReceive.getReturnStatus()) && !"已归还".equals(oldReturnStatus);
        if (returning) {
            // 检测是否存在维修中的工单
            AssetsRepair assetsRepair = assetsRepairMapper.selectInProcessRepair(assetsReceive.getId());
            if (ObjectUtil.isNotNull(assetsRepair)) {
                throw new CustomException(ResultCodeEnum.REPAIR_ERROR);
            }
            Assets assets = assetsService.selectById(resolveAssetsId(assetsReceive, before));
            if (assets != null) {
                assets.setNum((assets.getNum() == null ? 0 : assets.getNum()) + 1);
                // 一物一码：归还后状态由「已借出」恢复为「正常」
                if ("已借出".equals(assets.getStatus())) {
                    assets.setStatus("正常");
                }
                assetsService.updateById(assets);
            }
        }
        assetsReceiveMapper.updateById(assetsReceive);

        // 管理员审核（待审核 → 通过/拒绝）时推送群通知
        boolean isAuditResult = "通过".equals(assetsReceive.getStatus()) || "拒绝".equals(assetsReceive.getStatus());
        if (RoleEnum.ADMIN.name().equals(currentUser.getRole()) && isAuditResult
                && before != null && "待审核".equals(before.getStatus())) {
            String operator = currentUser.getName();
            if (operator == null || operator.trim().isEmpty()) {
                operator = currentUser.getUsername();
            }
            Map<String, Object> vars = new HashMap<>();
            // 资产信息以库为准，避免请求体未带 assetsName 时消息里资产为空
            Assets notifyAssets = assetsReceive.getAssetsId() == null ? null
                    : assetsService.selectById(assetsReceive.getAssetsId());
            vars.put("assetsName", notifyAssets != null ? notifyAssets.getName() : assetsReceive.getAssetsName());
            vars.put("assetsNo", notifyAssets != null ? notifyAssets.getNo() : assetsReceive.getAssetsNo());
            // 借用人/联系方式/归还日期同样以库中记录为准（审核请求体可能不带这些字段）
            String borrowerName = before != null && StrUtil.isNotBlank(before.getBorrowerName())
                    ? before.getBorrowerName() : assetsReceive.getBorrowerName();
            String borrowerPhone = before != null && StrUtil.isNotBlank(before.getBorrowerPhone())
                    ? before.getBorrowerPhone() : assetsReceive.getBorrowerPhone();
            String returnDate = before != null && StrUtil.isNotBlank(before.getReturnDate())
                    ? before.getReturnDate() : assetsReceive.getReturnDate();
            vars.put("applicant", StrUtil.isNotBlank(borrowerName) ? borrowerName : assetsReceive.getStaffName());
            vars.put("returnDate", returnDate);
            vars.put("borrowerPhone", borrowerPhone);
            vars.put("approver", operator);
            notifyService.push("通过".equals(assetsReceive.getStatus()) ? "RECEIVE_PASS" : "RECEIVE_REJECT",
                    "借用", assetsReceive.getId(), vars);
        }
    }

    /**
     * 取资产ID：优先请求体，其次库中原值
     */
    private Integer resolveAssetsId(AssetsReceive payload, AssetsReceive before) {
        if (payload.getAssetsId() != null) {
            return payload.getAssetsId();
        }
        return before == null ? null : before.getAssetsId();
    }

    /**
     * 根据ID查询
     */
    public AssetsReceive selectById(Integer id) {
        return assetsReceiveMapper.selectById(id);
    }

    /**
     * 查询所有
     */
    public List<AssetsReceive> selectAll(AssetsReceive assetsReceive) {
        return assetsReceiveMapper.selectAll(assetsReceive);
    }


    /**
     * 分页查询
     */
    public PageInfo<AssetsReceive> selectPage(AssetsReceive assetsReceive, Integer pageNum, Integer pageSize) {
        Account currentUser = TokenUtils.getCurrentUser();
        if (RoleEnum.STAFF.name().equals(currentUser.getRole())) {
            assetsReceive.setStaffId(currentUser.getId());
        }
        PageHelper.startPage(pageNum, pageSize);
        List<AssetsReceive> list = assetsReceiveMapper.selectAll(assetsReceive);
        return PageInfo.of(list);
    }

}