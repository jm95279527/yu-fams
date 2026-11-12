package com.example.service;

import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.util.List;
import java.util.Map;

/**
 * 数据备份/恢复业务接口
 */
public interface DataBackupService {

    /** 备份文件列表 */
    List<Map<String, Object>> list();

    /** 立即手动备份（数据库 + 上传文件） */
    Map<String, Object> createManual();

    /** 上传导入备份文件 */
    void upload(MultipartFile file);

    /** 删除备份文件 */
    void delete(String name);

    /** 获取备份文件（用于下载） */
    File file(String name);

    /** 用指定备份恢复（恢复前自动备份当前数据） */
    Map<String, Object> restore(String name);

    /** 定时备份配置 */
    Map<String, Object> config();

    /** 保存定时备份配置 */
    void saveConfig(Map<String, Object> body);

    /** 定时任务每分钟调用：到点则自动备份，并按保留份数清理 */
    void scheduledBackupIfDue();
}
