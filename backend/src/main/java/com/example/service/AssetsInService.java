package com.example.service;

import cn.hutool.core.date.DateUtil;
import com.example.common.enums.RoleEnum;
import com.example.entity.Account;
import com.example.entity.Assets;
import com.example.entity.AssetsIn;
import com.example.mapper.AssetsInMapper;
import com.example.utils.TokenUtils;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 资产入库业务处理
 **/
@Service
public class AssetsInService {

    @Resource
    private AssetsInMapper assetsInMapper;
    @Resource
    private AssetsService assetsService;
    @Resource
    private NotifyService notifyService;

    /**
     * 新增入库单（待审核）
     */
    public void add(AssetsIn assetsIn) {
        Account currentUser = TokenUtils.getCurrentUser();
        assetsIn.setStaffId(currentUser.getId());
        assetsIn.setStatus("待审核");
        if (assetsIn.getDate() == null || assetsIn.getDate().isEmpty()) {
            assetsIn.setDate(DateUtil.today());
        }
        assetsInMapper.insert(assetsIn);

        // 提交入库单即推送群通知，管理员看到通知再去审核
        String applicant = currentUser.getName();
        if (applicant == null || applicant.trim().isEmpty()) {
            applicant = currentUser.getUsername();
        }
        Map<String, Object> vars = new HashMap<>();
        vars.put("assetsName", assetsIn.getName());
        vars.put("category", assetsIn.getCategory());
        vars.put("purchaseNo", assetsIn.getPurchaseNo());
        vars.put("num", assetsIn.getNum());
        vars.put("money", assetsIn.getMoney());
        vars.put("applicant", applicant);
        notifyService.push("ASSETS_IN_SUBMIT", "入库", assetsIn.getId(), vars);
    }

    /**
     * 批量新增（Excel 导入），全部为待审核
     */
    public int addBatch(List<AssetsIn> list) {
        Account currentUser = TokenUtils.getCurrentUser();
        int count = 0;
        int shown = 0;
        StringBuilder names = new StringBuilder();
        for (AssetsIn assetsIn : list) {
            if (assetsIn.getName() == null || assetsIn.getName().trim().isEmpty()) {
                continue;
            }
            assetsIn.setId(null);
            assetsIn.setStaffId(currentUser.getId());
            assetsIn.setStatus("待审核");
            if (assetsIn.getNum() == null) {
                assetsIn.setNum(1);
            }
            if (assetsIn.getDate() == null || assetsIn.getDate().isEmpty()) {
                assetsIn.setDate(DateUtil.today());
            }
            assetsInMapper.insert(assetsIn);
            count++;
            // 汇总消息里最多列出前 5 个资产名称
            if (shown < 5) {
                if (shown > 0) {
                    names.append("、");
                }
                names.append(assetsIn.getName());
                shown++;
            }
        }

        // 批量导入只在最后汇总推送一条，避免逐行刷屏
        if (count > 0) {
            String applicant = currentUser.getName();
            if (applicant == null || applicant.trim().isEmpty()) {
                applicant = currentUser.getUsername();
            }
            Map<String, Object> vars = new HashMap<>();
            vars.put("count", count);
            vars.put("detail", shown < count ? names + " 等 " + count + " 项" : names.toString());
            vars.put("applicant", applicant);
            notifyService.push("ASSETS_IN_BATCH", "入库", null, vars);
        }
        return count;
    }

    /**
     * 删除
     */
    public void deleteById(Integer id) {
        assetsInMapper.deleteById(id);
    }

    /**
     * 批量删除
     */
    public void deleteBatch(List<Integer> ids) {
        for (Integer id : ids) {
            assetsInMapper.deleteById(id);
        }
    }

    /**
     * 修改（提交人编辑待审核单据 / 通用修改）
     */
    public void updateById(AssetsIn assetsIn) {
        // 已审核单据不允许通过该接口改动审核状态
        assetsIn.setAuditUser(null);
        assetsIn.setAuditDate(null);
        assetsIn.setAssetsId(null);
        assetsInMapper.updateById(assetsIn);
    }

    /**
     * 管理员审核
     * 通过：根据入库单生成正式资产（编号按编码规则自动生成）
     * 拒绝：记录驳回原因
     */
    public void audit(Integer id, Boolean pass, String rejectReason) {
        AssetsIn assetsIn = assetsInMapper.selectById(id);
        if (assetsIn == null) {
            throw new IllegalArgumentException("入库单不存在");
        }
        if (!"待审核".equals(assetsIn.getStatus())) {
            throw new IllegalStateException("该入库单已审核，请勿重复操作");
        }
        Account currentUser = TokenUtils.getCurrentUser();
        AssetsIn update = new AssetsIn();
        update.setId(id);
        String auditor = currentUser.getName();
        if (auditor == null || auditor.trim().isEmpty()) {
            auditor = currentUser.getUsername();
        }
        update.setAuditUser(auditor);
        update.setAuditDate(DateUtil.now());
        if (Boolean.TRUE.equals(pass)) {
            // 一物一码：入库数量 N 审核通过后生成 N 条资产记录，每条数量 1、各自独立编号与二维码
            int num = (assetsIn.getNum() == null || assetsIn.getNum() < 1) ? 1 : assetsIn.getNum();
            String comment = assetsIn.getComment();
            if (assetsIn.getPurchaseNo() != null && !assetsIn.getPurchaseNo().isEmpty()) {
                comment = (comment == null ? "" : comment + " | ") + "采购单号:" + assetsIn.getPurchaseNo();
            }
            if (assetsIn.getSupplier() != null && !assetsIn.getSupplier().isEmpty()) {
                comment = (comment == null ? "" : comment + " | ") + "供应商:" + assetsIn.getSupplier();
            }
            Integer firstAssetsId = null;
            for (int i = 0; i < num; i++) {
                Assets assets = new Assets();
                assets.setName(assetsIn.getName());
                assets.setCategory(assetsIn.getCategory());
                assets.setModel(assetsIn.getModel());
                assets.setNum(1);
                assets.setDate(assetsIn.getDate());
                assets.setMoney(assetsIn.getMoney());
                assets.setDepreciate(assetsIn.getDepreciate());
                assets.setDepartmentId(assetsIn.getDepartmentId());
                assets.setStaffId(assetsIn.getManagerId());
                assets.setLocation(assetsIn.getLocation());
                assets.setImg(assetsIn.getImg());
                assets.setStatus("正常");
                assets.setComment(comment);
                assetsService.add(assets); // 编号留空，每次自动生成一个新编号
                if (firstAssetsId == null) {
                    firstAssetsId = assets.getId();
                }
            }

            update.setAssetsId(firstAssetsId);
            update.setStatus("通过");
        } else {
            update.setStatus("拒绝");
            update.setRejectReason(rejectReason);
        }
        assetsInMapper.updateById(update);

        // 推送群机器人通知（失败不影响审核）
        Map<String, Object> vars = new HashMap<>();
        vars.put("assetsName", assetsIn.getName());
        vars.put("category", assetsIn.getCategory());
        vars.put("purchaseNo", assetsIn.getPurchaseNo());
        vars.put("num", assetsIn.getNum());
        vars.put("money", assetsIn.getMoney());
        vars.put("applicant", assetsIn.getStaffName());
        vars.put("approver", auditor);
        vars.put("approveComment", rejectReason);
        notifyService.push(Boolean.TRUE.equals(pass) ? "ASSETS_IN_PASS" : "ASSETS_IN_REJECT", "入库", id, vars);
    }

    /**
     * 根据ID查询
     */
    public AssetsIn selectById(Integer id) {
        return assetsInMapper.selectById(id);
    }

    /**
     * 查询所有
     */
    public List<AssetsIn> selectAll(AssetsIn assetsIn) {
        return assetsInMapper.selectAll(assetsIn);
    }

    /**
     * 分页查询（员工只能看自己提交的）
     */
    public PageInfo<AssetsIn> selectPage(AssetsIn assetsIn, Integer pageNum, Integer pageSize) {
        Account currentUser = TokenUtils.getCurrentUser();
        if (RoleEnum.STAFF.name().equals(currentUser.getRole())) {
            assetsIn.setStaffId(currentUser.getId());
        }
        PageHelper.startPage(pageNum, pageSize);
        List<AssetsIn> list = assetsInMapper.selectAll(assetsIn);
        return PageInfo.of(list);
    }

}
