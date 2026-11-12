package com.example.service.impl;

import cn.hutool.core.date.DateUtil;
import com.example.common.enums.RoleEnum;
import com.example.entity.Account;
import com.example.entity.Assets;
import com.example.entity.AssetsDetail;
import com.example.entity.AssetsTransfer;
import com.example.entity.Company;
import com.example.entity.Department;
import com.example.entity.Staff;
import com.example.exception.CustomException;
import com.example.mapper.AssetsDetailMapper;
import com.example.mapper.AssetsMapper;
import com.example.mapper.AssetsTransferMapper;
import com.example.mapper.CompanyMapper;
import com.example.mapper.DepartmentMapper;
import com.example.mapper.StaffMapper;
import com.example.service.AssetsTransferService;
import com.example.service.NotifyService;
import com.example.utils.TokenUtils;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 资产调拨业务处理实现
 **/
@Service
public class AssetsTransferServiceImpl implements AssetsTransferService {

    @Resource
    private AssetsTransferMapper assetsTransferMapper;

    @Resource
    private AssetsMapper assetsMapper;

    @Resource
    private AssetsDetailMapper assetsDetailMapper;

    @Resource
    private NotifyService notifyService;

    @Resource
    private DepartmentMapper departmentMapper;

    @Resource
    private StaffMapper staffMapper;

    @Resource
    private CompanyMapper companyMapper;

    @Override
    public void add(AssetsTransfer t) {
        Account currentUser = TokenUtils.getCurrentUser();

        Assets assets = assetsMapper.selectById(t.getAssetsId());
        if (assets == null) {
            throw new CustomException("500", "资产不存在");
        }
        // 资产信息快照
        t.setAssetsName(assets.getName());
        t.setAssetsNo(assets.getNo());
        // 变更前信息自动从资产当前值快照
        t.setFromStaffId(assets.getStaffId());
        t.setFromStaffName(staffName(assets.getStaffId()));
        t.setFromDepartmentId(assets.getDepartmentId());
        t.setFromDepartmentName(departmentName(assets.getDepartmentId()));
        t.setFromLocation(assets.getLocation());
        // 新部门/责任人名称解析（前端只传ID）
        if (t.getToDepartmentId() != null) {
            t.setToDepartmentName(departmentName(t.getToDepartmentId()));
        }
        if (t.getToStaffId() != null) {
            t.setToStaffName(staffName(t.getToStaffId()));
        }

        // 变更校验：三项中至少变一项
        boolean sameDept = eq(t.getFromDepartmentId(), t.getToDepartmentId());
        boolean sameStaff = eq(t.getFromStaffId(), t.getToStaffId());
        boolean sameLoc = (t.getFromLocation() == null ? "" : t.getFromLocation())
                .equals(t.getToLocation() == null ? "" : t.getToLocation());
        if (sameDept && sameStaff && sameLoc) {
            throw new CustomException("500", "新部门、责任人、存放地点与当前一致，无需调拨");
        }

        t.setTransferStaffId(currentUser.getId());
        String operator = currentUser.getName();
        if (operator == null || operator.trim().isEmpty()) {
            operator = currentUser.getUsername();
        }
        t.setTransferStaffName(operator);
        if (t.getTransferTime() == null) {
            t.setTransferTime(DateUtil.now());
        }
        t.setStatus("待审批");
        assetsTransferMapper.insert(t);

        // 提交调拨申请即推送群通知，管理员看到通知再去审批
        Map<String, Object> vars = new HashMap<>();
        vars.put("assetsName", t.getAssetsName());
        vars.put("assetsNo", t.getAssetsNo());
        vars.put("fromText", nz(t.getFromDepartmentName(), "-") + "/" + nz(t.getFromStaffName(), "-"));
        vars.put("toText", nz(t.getToDepartmentName(), "-") + "/" + nz(t.getToStaffName(), "-"));
        vars.put("reason", t.getReason());
        vars.put("applicant", t.getTransferStaffName());
        notifyService.push("TRANSFER_SUBMIT", "调拨", t.getId(), vars);
    }

    @Override
    public void deleteById(Integer id) {
        assetsTransferMapper.deleteById(id);
    }

    @Override
    public void deleteBatch(List<Integer> ids) {
        for (Integer id : ids) {
            assetsTransferMapper.deleteById(id);
        }
    }

    @Override
    public void updateById(AssetsTransfer t) {
        AssetsTransfer old = assetsTransferMapper.selectById(t.getId());
        if (old == null) {
            throw new CustomException("500", "调拨记录不存在");
        }
        if ("已调拨".equals(old.getStatus())) {
            throw new CustomException("500", "已完成的调拨记录不能修改");
        }
        // 重新解析新值名称
        if (t.getToDepartmentId() != null) {
            t.setToDepartmentName(departmentName(t.getToDepartmentId()));
        }
        if (t.getToStaffId() != null) {
            t.setToStaffName(staffName(t.getToStaffId()));
        }
        // 已拒绝单据修改后重新进入审批；待审批单据保持待审批
        t.setStatus("待审批");
        assetsTransferMapper.updateById(t);
        if ("已拒绝".equals(old.getStatus())) {
            // 动态update会跳过null，审核信息需显式清空
            assetsTransferMapper.resetAudit(t.getId());
        }
    }

    @Override
    public AssetsTransfer selectById(Integer id) {
        return assetsTransferMapper.selectById(id);
    }

    @Override
    public List<AssetsTransfer> selectAll(AssetsTransfer assetsTransfer) {
        return assetsTransferMapper.selectAll(assetsTransfer);
    }

    @Override
    public PageInfo<AssetsTransfer> selectPage(AssetsTransfer assetsTransfer, Integer pageNum, Integer pageSize) {
        Account currentUser = TokenUtils.getCurrentUser();
        if (RoleEnum.STAFF.name().equals(currentUser.getRole())) {
            assetsTransfer.setTransferStaffId(currentUser.getId());
        }
        PageHelper.startPage(pageNum, pageSize);
        List<AssetsTransfer> list = assetsTransferMapper.selectAll(assetsTransfer);
        return PageInfo.of(list);
    }

    @Override
    public List<AssetsTransfer> selectByAssetsId(Integer assetsId) {
        return assetsTransferMapper.selectByAssetsId(assetsId);
    }

    @Override
    @Transactional
    public void audit(Integer id, Boolean pass, String approveComment) {
        Account currentUser = TokenUtils.getCurrentUser();
        AssetsTransfer t = assetsTransferMapper.selectById(id);
        if (t == null) {
            throw new CustomException("500", "调拨记录不存在");
        }
        if (!"待审批".equals(t.getStatus())) {
            throw new CustomException("500", "该调拨申请已审核，请勿重复操作");
        }
        String approver = currentUser.getName();
        if (approver == null || approver.trim().isEmpty()) {
            approver = currentUser.getUsername();
        }

        AssetsTransfer update = new AssetsTransfer();
        update.setId(id);
        update.setApproverId(currentUser.getId());
        update.setApproverName(approver);
        update.setApproveTime(DateUtil.now());
        update.setApproveComment(approveComment);

        if (Boolean.TRUE.equals(pass)) {
            Assets assets = assetsMapper.selectById(t.getAssetsId());
            if (assets == null) {
                throw new CustomException("500", "资产不存在，无法调拨");
            }
            // 写变更明细（历史追溯）
            AssetsDetail detail = new AssetsDetail();
            detail.setAssetsId(assets.getId());
            detail.setAssetsName(assets.getName());
            detail.setAssetsNo(assets.getNo());
            detail.setOperationType("调拨");
            detail.setOperationTime(DateUtil.now());
            detail.setOperatorId(currentUser.getId());
            detail.setOperatorName(approver);
            detail.setBeforeStatus(assets.getStatus());
            detail.setAfterStatus(assets.getStatus());
            detail.setBeforeStaffId(assets.getStaffId());
            detail.setBeforeStaffName(t.getFromStaffName());
            detail.setAfterStaffId(t.getToStaffId());
            detail.setAfterStaffName(t.getToStaffName());
            detail.setBeforeDepartmentId(assets.getDepartmentId());
            detail.setBeforeDepartmentName(t.getFromDepartmentName());
            detail.setAfterDepartmentId(t.getToDepartmentId());
            detail.setAfterDepartmentName(t.getToDepartmentName());
            detail.setBeforeLocation(t.getFromLocation());
            detail.setAfterLocation(t.getToLocation());
            detail.setDescription("资产调拨：" + nz(t.getFromDepartmentName(), "-") + "/" + nz(t.getFromStaffName(), "-")
                    + " → " + nz(t.getToDepartmentName(), "-") + "/" + nz(t.getToStaffName(), "-"));
            detail.setComment(t.getReason());
            assetsDetailMapper.insert(detail);

            // 更新资产归属（只更新非空目标值；目标传0视为清空，这里用null表示不变）
            Assets patch = new Assets();
            patch.setId(assets.getId());
            if (t.getToDepartmentId() != null) {
                patch.setDepartmentId(t.getToDepartmentId());
            }
            if (t.getToStaffId() != null) {
                patch.setStaffId(t.getToStaffId());
            }
            patch.setLocation(t.getToLocation() == null ? assets.getLocation() : t.getToLocation());
            assetsMapper.updateById(patch);

            update.setStatus("已调拨");
        } else {
            update.setStatus("已拒绝");
        }
        assetsTransferMapper.updateById(update);

        // 推送群机器人通知（失败不影响审批）
        Map<String, Object> vars = new HashMap<>();
        vars.put("assetsName", t.getAssetsName());
        vars.put("assetsNo", t.getAssetsNo());
        vars.put("fromText", nz(t.getFromDepartmentName(), "-") + "/" + nz(t.getFromStaffName(), "-"));
        vars.put("toText", nz(t.getToDepartmentName(), "-") + "/" + nz(t.getToStaffName(), "-"));
        vars.put("reason", t.getReason());
        vars.put("applicant", t.getTransferStaffName());
        vars.put("approver", approver);
        vars.put("approveComment", approveComment);
        notifyService.push(Boolean.TRUE.equals(pass) ? "TRANSFER_PASS" : "TRANSFER_REJECT", "调拨", id, vars);
    }

    @Override
    public Map<String, Object> importBatch(List<Map<String, String>> rows) {
        Account user = TokenUtils.getCurrentUser();
        if (user == null) {
            throw new CustomException("4001", "未登录");
        }
        String operator = user.getName();
        if (operator == null || operator.trim().isEmpty()) {
            operator = user.getUsername();
        }
        List<Department> departments = departmentMapper.selectAll(new Department());
        Map<Integer, Department> deptById = new HashMap<>();
        for (Department d : departments) {
            deptById.put(d.getId(), d);
        }
        List<Staff> staffs = staffMapper.selectAll(new Staff());

        List<Map<String, Object>> errors = new ArrayList<>();
        Set<String> seenNos = new HashSet<>();
        int success = 0;
        for (Map<String, String> row : rows) {
            int rowNo = parseInt(row.get("__row"), 0);
            try {
                AssetsTransfer t = buildImportTransfer(row, departments, deptById, staffs, seenNos);
                t.setTransferStaffId(user.getId());
                t.setTransferStaffName(operator);
                t.setTransferTime(DateUtil.now());
                t.setStatus("待审批");
                assetsTransferMapper.insert(t);
                success++;
            } catch (CustomException e) {
                errors.add(rowError(rowNo, e.getMsg()));
            } catch (Exception e) {
                errors.add(rowError(rowNo, "导入失败：" + e.getMessage()));
            }
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("total", rows.size());
        result.put("success", success);
        result.put("failed", errors.size());
        result.put("errors", errors);
        return result;
    }

    /**
     * 校验并组装一行调拨申请（导入后为待审批，审核通过才变更资产）
     */
    private AssetsTransfer buildImportTransfer(Map<String, String> row, List<Department> departments,
                                               Map<Integer, Department> deptById, List<Staff> staffs,
                                               Set<String> seenNos) {
        String no = text(row.get("资产编号"));
        if (no.isEmpty()) {
            throw new CustomException("500", "资产编号不能为空");
        }
        if (seenNos.contains(no)) {
            throw new CustomException("500", "文件内资产编号重复：" + no);
        }
        Assets assets = assetsMapper.selectJoinedByNo(no);
        if (assets == null && no.matches("\\d+")) {
            assets = assetsMapper.selectById(Integer.valueOf(no));
        }
        if (assets == null) {
            throw new CustomException("500", "资产不存在：" + no);
        }
        if ("报废".equals(assets.getStatus())) {
            throw new CustomException("500", "资产已报废，不能调拨：" + no);
        }
        for (AssetsTransfer old : assetsTransferMapper.selectByAssetsId(assets.getId())) {
            if ("待审批".equals(old.getStatus())) {
                throw new CustomException("500", "该资产已有待审批的调拨申请：" + no);
            }
        }

        String companyName = text(row.get("新所属公司"));
        String deptName = text(row.get("新使用部门"));
        String staffName = text(row.get("新使用人"));
        String location = text(row.get("新存放地点"));
        String reason = text(row.get("调拨原因"));
        String comment = text(row.get("备注"));
        if (reason.isEmpty()) {
            throw new CustomException("500", "调拨原因不能为空");
        }
        if (companyName.isEmpty() && deptName.isEmpty() && staffName.isEmpty() && location.isEmpty()) {
            throw new CustomException("500", "请至少填写一项调拨目标（新公司/新部门/新使用人/新存放地点）");
        }

        Company company = null;
        if (!companyName.isEmpty()) {
            company = companyMapper.selectByName(companyName);
            if (company == null) {
                throw new CustomException("500", "新所属公司不存在：" + companyName);
            }
        }
        Department targetDept = null;
        if (!deptName.isEmpty()) {
            targetDept = findDepartment(departments, deptName, company == null ? null : company.getId());
            if (targetDept == null) {
                throw new CustomException("500", company == null
                        ? "新使用部门不存在：" + deptName
                        : "公司「" + companyName + "」下不存在部门：" + deptName);
            }
        }
        Staff targetStaff = null;
        if (!staffName.isEmpty()) {
            targetStaff = findStaff(staffs, staffName, targetDept,
                    company == null ? null : company.getId(), deptById);
            if (targetStaff == null) {
                if (targetDept != null) {
                    throw new CustomException("500", "使用人「" + staffName + "」不存在、已离职或不属于部门「" + targetDept.getName() + "」");
                }
                if (company != null) {
                    throw new CustomException("500", "使用人「" + staffName + "」不存在、已离职或不属于公司「" + companyName + "」");
                }
                throw new CustomException("500", "使用人不存在或已离职：" + staffName);
            }
            if (targetDept == null) {
                targetDept = deptById.get(targetStaff.getDepartmentId());
                if (targetDept == null) {
                    throw new CustomException("500", "使用人「" + staffName + "」未分配部门，请同时填写新使用部门");
                }
                if (company != null && !company.getId().equals(targetDept.getCompanyId())) {
                    throw new CustomException("500", "使用人「" + staffName + "」不属于公司「" + companyName + "」");
                }
            }
        }
        if (targetDept == null && company != null) {
            throw new CustomException("500", "填写了新所属公司，请同时填写新使用部门（公司随部门变更）");
        }

        String toLocation = location.isEmpty() ? assets.getLocation() : location;
        boolean sameDept = eq(assets.getDepartmentId(), targetDept == null ? null : targetDept.getId());
        boolean sameStaff = eq(assets.getStaffId(), targetStaff == null ? null : targetStaff.getId());
        boolean sameLoc = (assets.getLocation() == null ? "" : assets.getLocation().trim())
                .equals(toLocation == null ? "" : toLocation.trim());
        if (sameDept && sameStaff && sameLoc) {
            throw new CustomException("500", "新部门、新使用人、新存放地点与当前一致，无需调拨");
        }

        // 校验通过才记为已出现，避免前面失败的行影响后续同编号的有效行
        seenNos.add(no);

        AssetsTransfer t = new AssetsTransfer();
        t.setAssetsId(assets.getId());
        t.setAssetsName(assets.getName());
        t.setAssetsNo(assets.getNo());
        t.setFromStaffId(assets.getStaffId());
        t.setFromStaffName(staffName(assets.getStaffId()));
        t.setFromDepartmentId(assets.getDepartmentId());
        t.setFromDepartmentName(departmentName(assets.getDepartmentId()));
        t.setFromLocation(assets.getLocation());
        t.setToStaffId(targetStaff == null ? null : targetStaff.getId());
        t.setToStaffName(targetStaff == null ? null : targetStaff.getName());
        t.setToDepartmentId(targetDept == null ? null : targetDept.getId());
        t.setToDepartmentName(targetDept == null ? null : targetDept.getName());
        t.setToLocation(toLocation);
        t.setReason(reason);
        t.setComment(comment.isEmpty() ? null : comment);
        return t;
    }

    private Department findDepartment(List<Department> departments, String input, Integer companyId) {
        List<Department> matches = new ArrayList<>();
        for (Department d : departments) {
            if (companyId != null && !companyId.equals(d.getCompanyId())) {
                continue;
            }
            if (input.equals(d.getName()) || (d.getLabel() != null && input.equals(d.getLabel()))) {
                matches.add(d);
            }
        }
        if (matches.size() > 1) {
            throw new CustomException("500", "部门「" + input + "」匹配到多个，请填写「公司-部门」格式或同时填写新所属公司");
        }
        return matches.isEmpty() ? null : matches.get(0);
    }

    private Staff findStaff(List<Staff> staffs, String name, Department dept, Integer companyId,
                            Map<Integer, Department> deptById) {
        List<Staff> matches = new ArrayList<>();
        for (Staff s : staffs) {
            if (!"在职".equals(s.getStatus()) || !name.equals(s.getName())) {
                continue;
            }
            if (dept != null && !dept.getId().equals(s.getDepartmentId())) {
                continue;
            }
            if (dept == null && companyId != null) {
                Department sd = deptById.get(s.getDepartmentId());
                if (sd == null || !companyId.equals(sd.getCompanyId())) {
                    continue;
                }
            }
            matches.add(s);
        }
        if (matches.size() > 1) {
            throw new CustomException("500", "使用人「" + name + "」存在重名，请同时填写新使用部门或新所属公司区分");
        }
        return matches.isEmpty() ? null : matches.get(0);
    }

    private String text(String value) {
        return value == null ? "" : value.trim();
    }

    private int parseInt(String value, int fallback) {
        try {
            return Integer.parseInt(value == null ? "" : value.trim());
        } catch (Exception e) {
            return fallback;
        }
    }

    private Map<String, Object> rowError(int row, String msg) {
        Map<String, Object> error = new LinkedHashMap<>();
        error.put("row", row);
        error.put("msg", msg);
        return error;
    }

    private boolean eq(Integer a, Integer b) {
        return a == null ? b == null : a.equals(b);
    }

    private String nz(String s, String fallback) {
        return (s == null || s.isEmpty()) ? fallback : s;
    }

    private String staffName(Integer id) {
        if (id == null) {
            return null;
        }
        Staff staff = staffMapper.selectById(id);
        return staff == null ? null : staff.getName();
    }

    private String departmentName(Integer id) {
        if (id == null) {
            return null;
        }
        Department dept = departmentMapper.selectById(id);
        return dept == null ? null : dept.getName();
    }
}
