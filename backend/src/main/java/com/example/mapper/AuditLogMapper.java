package com.example.mapper;

import com.example.entity.AuditLog;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface AuditLogMapper {

    void insert(AuditLog auditLog);

    List<AuditLog> selectAll(AuditLog query);

    void deleteById(Integer id);

    void deleteBatch(List<Integer> ids);

    void cleanBefore(Integer days);
}
