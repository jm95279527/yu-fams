package com.example.task;

import com.example.service.DataBackupService;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

/**
 * 定时数据备份任务：每分钟检查一次，到达配置的时间点则自动备份（每天一次）
 */
@Component
public class DataBackupTask {

    @Resource
    private DataBackupService dataBackupService;

    @Scheduled(cron = "0 * * * * ?")
    public void run() {
        dataBackupService.scheduledBackupIfDue();
    }
}
