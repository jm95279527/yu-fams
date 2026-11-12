package com.example.service.impl;

import cn.hutool.core.date.DateUtil;
import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import com.example.common.enums.ResultCodeEnum;
import com.example.common.enums.RoleEnum;
import com.example.entity.Account;
import com.example.entity.AssetsRepair;
import com.example.exception.CustomException;
import com.example.mapper.AssetsRepairMapper;
import com.example.service.AssetsRepairService;
import com.example.service.NotifyService;
import com.example.utils.TokenUtils;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Date;
import java.util.regex.Pattern;

/**
 * 资产报修业务处理实现
 **/
@Service
public class AssetsRepairServiceImpl implements AssetsRepairService {

    /** 手机号：1 开头 11 位 */
    private static final Pattern PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$");

    @Resource
    private AssetsRepairMapper assetsRepairMapper;

    @Resource
    private NotifyService notifyService;

    @Override
    public void add(AssetsRepair assetsRepair) {
        Account currentUser = TokenUtils.getCurrentUser();
        
        // 如果是从员工端申请维修，需要根据receiveId获取资产信息
        if (assetsRepair.getReceiveId() != null) {
            // 根据receiveId查询资产信息
            AssetsRepair assetInfo = assetsRepairMapper.selectAssetByReceiveId(assetsRepair.getReceiveId());
            if (assetInfo != null) {
                assetsRepair.setAssetsId(assetInfo.getAssetsId());
                assetsRepair.setAssetsName(assetInfo.getAssetsName());
                assetsRepair.setAssetsCode(assetInfo.getAssetsCode());
            } else {
                // 如果查询不到，设置默认值
                assetsRepair.setAssetsId(1);
                assetsRepair.setAssetsName("待确认");
                assetsRepair.setAssetsCode("待确认");
            }
        }
        
        // 报修人、报修电话手工填写且必填
        if (assetsRepair.getAssetsId() == null && assetsRepair.getReceiveId() == null) {
            throw new CustomException("500", "请选择报修资产");
        }
        if (StrUtil.isBlank(assetsRepair.getReporterName())) {
            throw new CustomException("500", "请填写报修人");
        }
        if (StrUtil.isBlank(assetsRepair.getReporterPhone())) {
            throw new CustomException("500", "请填写报修电话");
        }
        String reporterPhone = assetsRepair.getReporterPhone().trim();
        if (!PHONE_PATTERN.matcher(reporterPhone).matches()) {
            throw new CustomException("500", "报修电话格式不正确，请填写 11 位手机号");
        }
        assetsRepair.setReporterName(assetsRepair.getReporterName().trim());
        assetsRepair.setReporterPhone(reporterPhone);

        // 报修理由与故障描述已合并为一个字段，统一落到 fault_desc
        String desc = repairDesc(assetsRepair);
        if (StrUtil.isBlank(desc)) {
            throw new CustomException("500", "请填写故障描述");
        }
        assetsRepair.setFaultDesc(desc.trim());

        // 校验当前是否有同样的报修单
        AssetsRepair dbRepair = assetsRepairMapper.selectInProcessRepair(assetsRepair.getReceiveId());
        if (ObjectUtil.isNotNull(dbRepair)) {
            throw new CustomException(ResultCodeEnum.REPAIR_ERROR);
        }
        assetsRepair.setStaffId(currentUser.getId());
        assetsRepair.setStatus("处理中");
        assetsRepair.setDate(DateUtil.now());
        assetsRepairMapper.insert(assetsRepair);

        // 提交报修即推送群通知，管理员看到通知再去处理
        Map<String, Object> vars = new HashMap<>();
        vars.put("assetsName", assetsRepair.getAssetsName());
        vars.put("assetsCode", assetsRepair.getAssetsCode());
        vars.put("applicant", assetsRepair.getReporterName());
        vars.put("reporterPhone", assetsRepair.getReporterPhone());
        vars.put("reason", repairDesc(assetsRepair));
        vars.put("faultDesc", repairDesc(assetsRepair));
        notifyService.push("REPAIR_SUBMIT", "维修", assetsRepair.getId(), vars);
    }

    /**
     * 报修理由与故障描述已合并为一个字段，取非空的那个（兼容历史数据）
     */
    private String repairDesc(AssetsRepair repair) {
        if (repair == null) {
            return null;
        }
        return StrUtil.isNotBlank(repair.getFaultDesc()) ? repair.getFaultDesc() : repair.getReason();
    }

    @Override
    public void deleteById(Integer id) {
        assetsRepairMapper.deleteById(id);
    }

    @Override
    public void deleteBatch(List<Integer> ids) {
        for (Integer id : ids) {
            assetsRepairMapper.deleteById(id);
        }
    }

    @Override
    public void updateById(AssetsRepair assetsRepair) {
        AssetsRepair before = assetsRepairMapper.selectById(assetsRepair.getId());
        // 如果状态变为已完成，设置完成时间
        if ("已完成".equals(assetsRepair.getStatus()) && assetsRepair.getCompleteTime() == null) {
            assetsRepair.setCompleteTime(new Date());
        }
        assetsRepairMapper.updateById(assetsRepair);

        // 状态发生变化时推送群通知：维修中/已完成走通过模板，拒绝走驳回模板
        String newStatus = assetsRepair.getStatus();
        String oldStatus = before == null ? null : before.getStatus();
        if (newStatus != null && !newStatus.equals(oldStatus)
                && ("维修中".equals(newStatus) || "已完成".equals(newStatus) || "拒绝".equals(newStatus))) {
            AssetsRepair db = assetsRepairMapper.selectById(assetsRepair.getId());
            AssetsRepair src = db != null ? db : assetsRepair;
            Account currentUser = TokenUtils.getCurrentUser();
            String operator = currentUser.getName();
            if (operator == null || operator.trim().isEmpty()) {
                operator = currentUser.getUsername();
            }
            Map<String, Object> vars = new HashMap<>();
            vars.put("assetsName", src.getAssetsName());
            vars.put("assetsCode", src.getAssetsCode());
            vars.put("status", src.getStatus());
            vars.put("reason", repairDesc(src));
            vars.put("faultDesc", repairDesc(src));
            vars.put("applicant", StrUtil.isNotBlank(src.getReporterName()) ? src.getReporterName() : src.getStaffName());
            vars.put("reporterPhone", src.getReporterPhone());
            vars.put("approver", operator);
            notifyService.push("拒绝".equals(newStatus) ? "REPAIR_REJECT" : "REPAIR_PASS",
                    "维修", assetsRepair.getId(), vars);
        }
    }

    @Override
    public AssetsRepair selectById(Integer id) {
        return assetsRepairMapper.selectById(id);
    }

    @Override
    public List<AssetsRepair> selectAll(AssetsRepair assetsRepair) {
        return assetsRepairMapper.selectAll(assetsRepair);
    }

    @Override
    public PageInfo<AssetsRepair> selectPage(AssetsRepair assetsRepair, Integer pageNum, Integer pageSize) {
        Account currentUser = TokenUtils.getCurrentUser();
        if (RoleEnum.STAFF.name().equals(currentUser.getRole())) {
            assetsRepair.setStaffId(currentUser.getId());
        }
        PageHelper.startPage(pageNum, pageSize);
        List<AssetsRepair> list = assetsRepairMapper.selectAll(assetsRepair);
        return PageInfo.of(list);
    }


    @Override
    public List<AssetsRepair> getRecentRepairs() {
        return assetsRepairMapper.selectRecent(10);
    }
}