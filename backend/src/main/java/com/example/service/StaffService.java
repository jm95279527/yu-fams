package com.example.service;

import cn.hutool.core.util.ObjectUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.crypto.SecureUtil;
import com.example.common.Constants;
import com.example.common.enums.ResultCodeEnum;
import com.example.common.enums.RoleEnum;
import com.example.common.utils.LoginGuard;
import com.example.entity.Account;
import com.example.entity.Department;
import com.example.entity.Staff;
import com.example.exception.CustomException;
import com.example.mapper.DepartmentMapper;
import com.example.mapper.StaffMapper;
import com.example.utils.TokenUtils;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * 员工员业务处理
 **/
@Service
public class StaffService {

    /** MD5 密文特征：32 位十六进制 */
    private static final Pattern MD5_PATTERN = Pattern.compile("^[a-fA-F0-9]{32}$");

    /** 手机号：1 开头 11 位 */
    private static final Pattern PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$");

    /** 身份证号：15 位或 18 位（末位可为 X） */
    private static final Pattern IDCARD_PATTERN = Pattern.compile("^(\\d{15}|\\d{17}[\\dXx])$");

    /** 密码强度：6-20 位且同时包含字母和数字（默认密码 123 豁免） */
    private static final Pattern PASSWORD_PATTERN = Pattern.compile("^(?=.*[A-Za-z])(?=.*\\d)\\S{6,20}$");

    @Resource
    private StaffMapper staffMapper;

    @Resource
    private DepartmentMapper departmentMapper;

    @Resource
    private LoginGuard loginGuard;

    /**
     * 密码加密：已经是 MD5 的原样返回，否则做 MD5（兼容历史明文数据）
     */
    private String encodePassword(String raw) {
        if (StrUtil.isBlank(raw)) {
            return raw;
        }
        if (MD5_PATTERN.matcher(raw).matches()) {
            return raw;
        }
        return SecureUtil.md5(raw);
    }

    /**
     * 校验登录密码：兼容库内历史明文，校验通过后自动升级为 MD5
     * @return 是否匹配
     */
    private boolean checkPassword(Staff dbStaff, String input) {
        String stored = dbStaff.getPassword();
        if (stored != null && MD5_PATTERN.matcher(stored).matches()) {
            return stored.equalsIgnoreCase(SecureUtil.md5(input));
        }
        // 历史明文：匹配后自动升级
        if (stored != null && stored.equals(input)) {
            Staff upgrade = new Staff();
            upgrade.setId(dbStaff.getId());
            upgrade.setPassword(SecureUtil.md5(input));
            staffMapper.updateById(upgrade);
            dbStaff.setPassword(upgrade.getPassword());
            return true;
        }
        return false;
    }

    /**
     * 档案字段格式校验：手机号/紧急电话/身份证号（填写了才校验）
     */
    private void validateArchive(Staff staff) {
        if (StrUtil.isNotBlank(staff.getPhone()) && !PHONE_PATTERN.matcher(staff.getPhone().trim()).matches()) {
            throw new CustomException("400", "手机号格式不正确");
        }
        if (StrUtil.isNotBlank(staff.getEmergencyPhone()) && !PHONE_PATTERN.matcher(staff.getEmergencyPhone().trim()).matches()) {
            throw new CustomException("400", "紧急联系电话格式不正确");
        }
        if (StrUtil.isNotBlank(staff.getIdCard()) && !IDCARD_PATTERN.matcher(staff.getIdCard().trim()).matches()) {
            throw new CustomException("400", "身份证号格式不正确");
        }
    }

    /**
     * 用户自设密码强度校验；留空或系统默认密码 123 豁免
     */
    private void checkPasswordStrength(String raw) {
        if (StrUtil.isBlank(raw) || Constants.USER_DEFAULT_PASSWORD.equals(raw)) {
            return;
        }
        if (!PASSWORD_PATTERN.matcher(raw).matches()) {
            throw new CustomException("400", "密码强度不足：需6-20位且同时包含字母和数字");
        }
    }

    /**
     * 工号唯一性校验（excludeId 用于编辑时排除自身）
     */
    private void checkEmpNoUnique(String empNo, Integer excludeId) {
        if (StrUtil.isBlank(empNo)) {
            return;
        }
        Staff other = staffMapper.selectByEmpNo(empNo.trim());
        if (other != null && (excludeId == null || !other.getId().equals(excludeId))) {
            throw new CustomException("400", "工号已存在：" + empNo.trim());
        }
    }

    /**
     * 新增
     */
    public void add(Staff staff) {
        Staff dbStaff = staffMapper.selectByUsername(staff.getUsername());
        if (ObjectUtil.isNotNull(dbStaff)) {
            throw new CustomException(ResultCodeEnum.USER_EXIST_ERROR);
        }
        validateArchive(staff);
        if (ObjectUtil.isEmpty(staff.getPassword())) {
            staff.setPassword(Constants.USER_DEFAULT_PASSWORD);
        }
        checkPasswordStrength(staff.getPassword());
        staff.setPassword(encodePassword(staff.getPassword()));
        if (ObjectUtil.isEmpty(staff.getName())) {
            staff.setName(staff.getUsername());
        }
        // 员工账号固定为 STAFF，不允许通过员工管理接口提权
        staff.setRole(RoleEnum.STAFF.name());
        if (ObjectUtil.isEmpty(staff.getStatus())) {
            staff.setStatus("在职");
        }
        if (StrUtil.isNotBlank(staff.getEmpNo())) {
            staff.setEmpNo(staff.getEmpNo().trim());
        }
        checkEmpNoUnique(staff.getEmpNo(), null);
        staffMapper.insert(staff);
    }

    /**
     * 删除（存在资产业务关联记录时禁止物理删除，建议改为离职）
     */
    public void deleteById(Integer id) {
        checkCanDelete(id);
        staffMapper.deleteById(id);
    }

    private void checkCanDelete(Integer id) {
        if (staffMapper.countReferences(id) > 0) {
            throw new CustomException("400", "该员工存在资产或业务关联记录，不能删除，建议将状态改为“离职”");
        }
    }

    /**
     * 批量删除
     */
    public void deleteBatch(List<Integer> ids) {
        for (Integer id : ids) {
            checkCanDelete(id);
        }
        for (Integer id : ids) {
            staffMapper.deleteById(id);
        }
    }

    /**
     * 修改
     */
    public void updateById(Staff staff) {
        if (staff.getId() == null) {
            throw new CustomException("400", "缺少员工ID");
        }
        // 员工角色固定 STAFF，防止越权提权
        staff.setRole(RoleEnum.STAFF.name());
        validateArchive(staff);
        // 密码：空不更新；非空则校验强度后加密（已经是 MD5 的保持不变，兼容个人中心回传）
        if (StrUtil.isNotBlank(staff.getPassword()) && !MD5_PATTERN.matcher(staff.getPassword()).matches()) {
            checkPasswordStrength(staff.getPassword());
        }
        if (StrUtil.isNotBlank(staff.getPassword())) {
            staff.setPassword(encodePassword(staff.getPassword()));
        }
        if (StrUtil.isNotBlank(staff.getEmpNo())) {
            staff.setEmpNo(staff.getEmpNo().trim());
        }
        checkEmpNoUnique(staff.getEmpNo(), staff.getId());
        // 状态与离职日期联动
        if (StrUtil.isNotBlank(staff.getStatus())) {
            if ("离职".equals(staff.getStatus())) {
                if (StrUtil.isBlank(staff.getLeaveDate())) {
                    staff.setLeaveDate(LocalDate.now().toString());
                }
            } else if ("在职".equals(staff.getStatus())) {
                // 动态 SQL 无法把 leave_date 更新为 NULL，单独处理
                staffMapper.clearLeaveDate(staff.getId());
                staff.setLeaveDate(null);
            }
        }
        staffMapper.updateById(staff);
    }

    /**
     * 根据ID查询
     */
    public Staff selectById(Integer id) {
        return staffMapper.selectById(id);
    }

    /**
     * 查询所有
     */
    public List<Staff> selectAll(Staff staff) {
        return staffMapper.selectAll(staff);
    }

    /**
     * 分页查询
     */
    public PageInfo<Staff> selectPage(Staff staff, Integer pageNum, Integer pageSize) {
        PageHelper.startPage(pageNum, pageSize);
        List<Staff> list = staffMapper.selectAll(staff);
        return PageInfo.of(list);
    }

    /**
     * 重置密码为系统默认密码
     */
    public void resetPassword(Integer id) {
        Staff staff = staffMapper.selectById(id);
        if (staff == null) {
            throw new CustomException(ResultCodeEnum.USER_NOT_EXIST_ERROR);
        }
        Staff update = new Staff();
        update.setId(id);
        update.setPassword(SecureUtil.md5(Constants.USER_DEFAULT_PASSWORD));
        staffMapper.updateById(update);
    }

    /**
     * 一键离职：状态置为离职并写入离职日期
     */
    public void leave(Integer id) {
        Staff staff = staffMapper.selectById(id);
        if (staff == null) {
            throw new CustomException(ResultCodeEnum.USER_NOT_EXIST_ERROR);
        }
        if ("离职".equals(staff.getStatus())) {
            throw new CustomException("400", "「" + staff.getName() + "」已是离职状态");
        }
        Staff update = new Staff();
        update.setId(id);
        update.setStatus("离职");
        update.setLeaveDate(LocalDate.now().toString());
        staffMapper.updateById(update);
    }

    /**
     * 批量一键离职：已是离职或不存在的人自动跳过
     */
    public String leaveBatch(List<Integer> ids) {
        int done = 0;
        int skipped = 0;
        for (Integer id : ids) {
            Staff staff = staffMapper.selectById(id);
            if (staff == null || "离职".equals(staff.getStatus())) {
                skipped++;
                continue;
            }
            Staff update = new Staff();
            update.setId(id);
            update.setStatus("离职");
            update.setLeaveDate(LocalDate.now().toString());
            staffMapper.updateById(update);
            done++;
        }
        return "已办理离职 " + done + " 人" + (skipped > 0 ? "，跳过 " + skipped + " 人（已离职或不存在）" : "");
    }

    /**
     * Excel 批量导入员工。
     * 列：工号、姓名、账号、性别、电话、邮箱、身份证号、公司、部门、职位、学历、入职日期、状态、籍贯、家庭住址、紧急联系人、紧急联系电话、备注
     * 规则：
     * 1) 姓名必填；账号留空时用工号（工号也留空则该行失败）
     * 2) 账号或工号已存在 → 跳过（可重复导入）
     * 3) 部门匹配：填了「公司」则在该公司下按部门名匹配；未填「公司」则按「公司-部门」整体、再按部门名匹配；找不到则该行失败
     * 4) 密码统一使用系统默认密码；状态留空默认在职
     */
    @Transactional(rollbackFor = Exception.class)
    public String importStaff(List<Map<String, Object>> rows) {
        if (rows == null || rows.isEmpty()) {
            throw new CustomException("500", "文件中没有数据");
        }
        List<Department> departments = departmentMapper.selectAll(null);
        int success = 0;
        int skip = 0;
        List<String> fails = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            String name = cell(row, "姓名");
            String empNo = cell(row, "工号");
            String username = cell(row, "账号");
            if (StrUtil.isBlank(name)) {
                fails.add("存在未填写「姓名」的行");
                continue;
            }
            if (StrUtil.isBlank(username)) {
                username = empNo;
            }
            if (StrUtil.isBlank(username)) {
                fails.add(name + "：缺少「账号」或「工号」");
                continue;
            }
            username = username.trim();
            if (staffMapper.selectByUsername(username) != null) {
                skip++;
                continue;
            }
            if (StrUtil.isNotBlank(empNo) && staffMapper.selectByEmpNo(empNo.trim()) != null) {
                skip++;
                continue;
            }

            Staff staff = new Staff();
            staff.setName(name);
            staff.setUsername(username);
            if (StrUtil.isNotBlank(empNo)) {
                staff.setEmpNo(empNo.trim());
            }
            staff.setGender(cell(row, "性别"));
            staff.setPhone(cell(row, "电话"));
            staff.setEmail(cell(row, "邮箱"));
            staff.setIdCard(cell(row, "身份证号"));
            staff.setBirthDate(cell(row, "出生日期"));
            staff.setPosition(cell(row, "职位"));
            staff.setEducation(cell(row, "学历"));
            staff.setEntryDate(cell(row, "入职日期"));
            staff.setNativePlace(cell(row, "籍贯"));
            staff.setAddress(cell(row, "家庭住址"));
            staff.setEmergencyContact(cell(row, "紧急联系人"));
            staff.setEmergencyPhone(cell(row, "紧急联系电话"));
            staff.setRemark(cell(row, "备注"));

            String companyName = cell(row, "公司");
            String deptName = cell(row, "部门");
            if (StrUtil.isNotBlank(companyName) && StrUtil.isBlank(deptName)) {
                fails.add(name + "：填写了「公司」但未填「部门」");
                continue;
            }
            if (StrUtil.isNotBlank(deptName)) {
                Department dept = findDepartment(departments, companyName, deptName);
                if (dept == null) {
                    fails.add(name + "：" + (StrUtil.isBlank(companyName) ? "" : "公司「" + companyName + "」下")
                            + "部门「" + deptName + "」不存在");
                    continue;
                }
                staff.setDepartmentId(dept.getId());
            }
            String status = cell(row, "状态");
            staff.setStatus(StrUtil.isBlank(status) ? "在职" : status);
            if ("离职".equals(staff.getStatus())) {
                staff.setLeaveDate(LocalDate.now().toString());
            }

            try {
                this.add(staff);
                success++;
            } catch (Exception e) {
                fails.add(name + "：" + e.getMessage());
            }
        }

        StringBuilder msg = new StringBuilder("成功导入 " + success + " 个员工");
        if (skip > 0) {
            msg.append("，跳过已存在 ").append(skip).append(" 个");
        }
        if (!fails.isEmpty()) {
            List<String> shown = fails.size() > 5 ? fails.subList(0, 5) : fails;
            msg.append("，失败 ").append(fails.size()).append(" 个（").append(String.join("；", shown));
            if (fails.size() > 5) {
                msg.append(" 等");
            }
            msg.append("）");
        }
        return msg.toString();
    }

    /**
     * 部门匹配：
     * 1) 填了「公司」→ 在「该公司下」按部门名称精确匹配
     * 2) 没填「公司」→ 先按「公司-部门」整体匹配，再按部门名称匹配（同名部门取第一个）
     */
    private Department findDepartment(List<Department> departments, String companyName, String deptName) {
        if (StrUtil.isBlank(deptName)) {
            return null;
        }
        if (StrUtil.isNotBlank(companyName)) {
            for (Department d : departments) {
                if (companyName.equals(d.getCompanyName()) && deptName.equals(d.getName())) {
                    return d;
                }
            }
            return null;
        }
        for (Department d : departments) {
            if (deptName.equals(d.getLabel())) {
                return d;
            }
        }
        for (Department d : departments) {
            if (deptName.equals(d.getName())) {
                return d;
            }
        }
        return null;
    }

    private String cell(Map<String, Object> row, String key) {
        Object value = row.get(key);
        return value == null ? null : String.valueOf(value).trim();
    }

    /**
     * 登录
     */
    public Account login(Account account) {
        String guardKey = RoleEnum.STAFF.name() + ":" + account.getUsername();
        loginGuard.checkLocked(guardKey);
        Account dbStaff = staffMapper.selectByUsername(account.getUsername());
        if (ObjectUtil.isNull(dbStaff)) {
            loginGuard.onFailure(guardKey);
            throw new CustomException(ResultCodeEnum.USER_NOT_EXIST_ERROR);
        }
        Staff staff = (Staff) dbStaff;
        if ("离职".equals(staff.getStatus())) {
            throw new CustomException("400", "该账号已离职停用，请联系管理员");
        }
        if (!checkPassword(staff, account.getPassword())) {
            loginGuard.onFailure(guardKey);
            throw new CustomException(ResultCodeEnum.USER_ACCOUNT_ERROR);
        }
        loginGuard.onSuccess(guardKey);
        // 生成token
        String tokenData = dbStaff.getId() + "-" + RoleEnum.STAFF.name();
        String token = TokenUtils.createToken(tokenData, dbStaff.getPassword());
        dbStaff.setToken(token);
        return dbStaff;
    }


    /**
     * 修改密码
     */
    public void updatePassword(Account account) {
        Staff dbStaff = staffMapper.selectByUsername(account.getUsername());
        if (ObjectUtil.isNull(dbStaff)) {
            throw new CustomException(ResultCodeEnum.USER_NOT_EXIST_ERROR);
        }
        if ("离职".equals(dbStaff.getStatus())) {
            throw new CustomException("400", "该账号已离职停用，请联系管理员");
        }
        if (!checkPassword(dbStaff, account.getPassword())) {
            throw new CustomException(ResultCodeEnum.PARAM_PASSWORD_ERROR);
        }
        if (StrUtil.isBlank(account.getNewPassword())) {
            throw new CustomException("400", "新密码不能为空");
        }
        checkPasswordStrength(account.getNewPassword());
        dbStaff.setPassword(SecureUtil.md5(account.getNewPassword()));
        staffMapper.updateById(dbStaff);
    }




}
