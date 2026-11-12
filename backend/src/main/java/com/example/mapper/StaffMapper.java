package com.example.mapper;

import com.example.entity.Staff;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.List;

/**
 * 操作staff相关数据接口
*/
public interface StaffMapper {

    /**
      * 新增
    */
    int insert(Staff staff);

    /**
      * 删除
    */
    int deleteById(Integer id);

    /**
      * 修改
    */
    int updateById(Staff staff);

    /**
      * 根据ID查询
    */
    Staff selectById(Integer id);

    /**
      * 查询所有
    */
    List<Staff> selectAll(Staff staff);

    @Select("select s.*, d.name as departmentName from staff s left join department d on s.department_id = d.id where s.username = #{username}")
    Staff selectByUsername(String username);

    @Select("select s.*, d.name as departmentName from staff s left join department d on s.department_id = d.id where s.emp_no = #{empNo}")
    Staff selectByEmpNo(String empNo);

    /**
     * 统计员工在资产业务表中的关联记录数（用于删除前校验）
     */
    @Select("select " +
            "(select count(*) from assets where staff_id = #{id}) + " +
            "(select count(*) from assets_in where staff_id = #{id}) + " +
            "(select count(*) from assets_receive where staff_id = #{id}) + " +
            "(select count(*) from assets_repair where staff_id = #{id}) + " +
            "(select count(*) from assets_scrap where staff_id = #{id} or applicant_id = #{id}) + " +
            "(select count(*) from assets_transfer where from_staff_id = #{id} or to_staff_id = #{id} or transfer_staff_id = #{id}) + " +
            "(select count(*) from inventory where staff_id = #{id}) + " +
            "(select count(*) from inventory_item where staff_id = #{id})")
    int countReferences(Integer id);

    /**
     * 清空离职日期（员工重新在职时）
     */
    @Update("update staff set leave_date = null where id = #{id}")
    int clearLeaveDate(Integer id);
}
