package com.example.service.impl;

import cn.hutool.core.date.DateUtil;
import com.example.common.enums.RoleEnum;
import com.example.entity.Account;
import com.example.entity.Assets;
import com.example.entity.AssetsDetail;
import com.example.entity.AssetsScrap;
import com.example.exception.CustomException;
import com.example.mapper.AssetsDetailMapper;
import com.example.mapper.AssetsMapper;
import com.example.mapper.AssetsScrapMapper;
import com.example.service.AssetsScrapService;
import com.example.service.NotifyService;
import com.example.utils.TokenUtils;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 资产报废业务处理实现
 **/
@Service
public class AssetsScrapServiceImpl implements AssetsScrapService {

    @Resource
    private AssetsScrapMapper assetsScrapMapper;

    @Resource
    private AssetsMapper assetsMapper;

    @Resource
    private AssetsDetailMapper assetsDetailMapper;

    @Resource
    private NotifyService notifyService;

    @Override
    public void add(AssetsScrap t) {
        Account currentUser = TokenUtils.getCurrentUser();
        if (t.getAssetsId() == null) {
            throw new CustomException("500", "请选择要报废的资产");
        }
        // 取资产带部门/责任人名称
        Assets assets = assetsMapper.selectJoinedById(t.getAssetsId());
        if (assets == null) {
            throw new CustomException("500", "资产不存在");
        }
        if ("已报废".equals(assets.getStatus())) {
            throw new CustomException("500", "该资产已报废，不能重复申请");
        }
        // 资产信息快照
        t.setAssetsNo(assets.getNo());
        t.setAssetsName(assets.getName());
        t.setCategory(assets.getCategory());
        t.setModel(assets.getModel());
        t.setMoney(assets.getMoney());
        t.setDepreciate(assets.getDepreciate());
        t.setDepartmentId(assets.getDepartmentId());
        t.setDepartmentName(assets.getDepartmentName());
        t.setStaffId(assets.getStaffId());
        t.setStaffName(assets.getStaffName());
        t.setLocation(assets.getLocation());

        if (t.getScrapType() == null || t.getScrapType().trim().isEmpty()) {
            t.setScrapType("正常报废");
        }
        if (t.getResidualValue() == null) {
            t.setResidualValue(java.math.BigDecimal.ZERO);
        }

        t.setApplicantId(currentUser.getId());
        String applicant = currentUser.getName();
        if (applicant == null || applicant.trim().isEmpty()) {
            applicant = currentUser.getUsername();
        }
        t.setApplicantName(applicant);
        if (t.getApplyTime() == null) {
            t.setApplyTime(DateUtil.now());
        }
        t.setStatus("待审批");
        assetsScrapMapper.insert(t);

        // 提交报废申请即推送群通知，管理员看到通知再去审批
        Map<String, Object> vars = new HashMap<>();
        vars.put("assetsName", t.getAssetsName());
        vars.put("assetsNo", t.getAssetsNo());
        vars.put("scrapType", t.getScrapType());
        vars.put("reason", t.getReason());
        vars.put("applicant", t.getApplicantName());
        notifyService.push("SCRAP_SUBMIT", "报废", t.getId(), vars);
    }

    @Override
    public void deleteById(Integer id) {
        assetsScrapMapper.deleteById(id);
    }

    @Override
    public void deleteBatch(List<Integer> ids) {
        for (Integer id : ids) {
            assetsScrapMapper.deleteById(id);
        }
    }

    @Override
    public void updateById(AssetsScrap t) {
        AssetsScrap old = assetsScrapMapper.selectById(t.getId());
        if (old == null) {
            throw new CustomException("500", "报废单不存在");
        }
        if ("已报废".equals(old.getStatus())) {
            throw new CustomException("500", "已完成的报废记录不能修改");
        }
        if (t.getResidualValue() == null) {
            t.setResidualValue(java.math.BigDecimal.ZERO);
        }
        // 已拒绝单据修改后重新进入审批；待审批单据保持待审批
        t.setStatus("待审批");
        assetsScrapMapper.updateById(t);
        if ("已拒绝".equals(old.getStatus())) {
            // 动态update会跳过null，审核信息需显式清空
            assetsScrapMapper.resetAudit(t.getId());
        }
    }

    @Override
    public AssetsScrap selectById(Integer id) {
        return assetsScrapMapper.selectById(id);
    }

    @Override
    public List<AssetsScrap> selectAll(AssetsScrap assetsScrap) {
        return assetsScrapMapper.selectAll(assetsScrap);
    }

    @Override
    public PageInfo<AssetsScrap> selectPage(AssetsScrap assetsScrap, Integer pageNum, Integer pageSize) {
        Account currentUser = TokenUtils.getCurrentUser();
        if (RoleEnum.STAFF.name().equals(currentUser.getRole())) {
            assetsScrap.setApplicantId(currentUser.getId());
        }
        PageHelper.startPage(pageNum, pageSize);
        List<AssetsScrap> list = assetsScrapMapper.selectAll(assetsScrap);
        return PageInfo.of(list);
    }

    @Override
    public List<AssetsScrap> selectByAssetsId(Integer assetsId) {
        return assetsScrapMapper.selectByAssetsId(assetsId);
    }

    @Override
    @Transactional
    public void audit(Integer id, Boolean pass, String approveComment) {
        Account currentUser = TokenUtils.getCurrentUser();
        AssetsScrap t = assetsScrapMapper.selectById(id);
        if (t == null) {
            throw new CustomException("500", "报废单不存在");
        }
        if (!"待审批".equals(t.getStatus())) {
            throw new CustomException("500", "该报废申请已审核，请勿重复操作");
        }
        String approver = currentUser.getName();
        if (approver == null || approver.trim().isEmpty()) {
            approver = currentUser.getUsername();
        }

        AssetsScrap update = new AssetsScrap();
        update.setId(id);
        update.setApproverId(currentUser.getId());
        update.setApproverName(approver);
        update.setApproveTime(DateUtil.now());
        update.setApproveComment(approveComment);

        if (Boolean.TRUE.equals(pass)) {
            Assets assets = assetsMapper.selectById(t.getAssetsId());
            if (assets == null) {
                throw new CustomException("500", "资产不存在，无法报废");
            }
            // 写变更明细（历史追溯）
            AssetsDetail detail = new AssetsDetail();
            detail.setAssetsId(assets.getId());
            detail.setAssetsName(assets.getName());
            detail.setAssetsNo(assets.getNo());
            detail.setOperationType("报废");
            detail.setOperationTime(DateUtil.now());
            detail.setOperatorId(currentUser.getId());
            detail.setOperatorName(approver);
            detail.setBeforeStatus(assets.getStatus());
            detail.setAfterStatus("已报废");
            detail.setBeforeStaffId(assets.getStaffId());
            detail.setBeforeStaffName(t.getStaffName());
            detail.setBeforeDepartmentId(assets.getDepartmentId());
            detail.setBeforeDepartmentName(t.getDepartmentName());
            detail.setBeforeLocation(t.getLocation());
            detail.setDescription("资产报废：" + nz(t.getScrapType(), "报废")
                    + "，残值￥" + nz(String.valueOf(t.getResidualValue()), "0"));
            detail.setComment(t.getReason());
            assetsDetailMapper.insert(detail);

            // 更新资产状态为已报废
            Assets patch = new Assets();
            patch.setId(assets.getId());
            patch.setStatus("已报废");
            assetsMapper.updateById(patch);

            update.setStatus("已报废");
        } else {
            update.setStatus("已拒绝");
        }
        assetsScrapMapper.updateById(update);

        // 推送群机器人通知（失败不影响审批）
        Map<String, Object> vars = new HashMap<>();
        vars.put("assetsName", t.getAssetsName());
        vars.put("assetsNo", t.getAssetsNo());
        vars.put("scrapType", t.getScrapType());
        vars.put("reason", t.getReason());
        vars.put("applicant", t.getApplicantName());
        vars.put("approver", approver);
        vars.put("approveComment", approveComment);
        notifyService.push(Boolean.TRUE.equals(pass) ? "SCRAP_PASS" : "SCRAP_REJECT", "报废", id, vars);
    }

    private String nz(String s, String fallback) {
        return (s == null || s.isEmpty()) ? fallback : s;
    }
}
