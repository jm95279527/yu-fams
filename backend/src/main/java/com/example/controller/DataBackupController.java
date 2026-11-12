package com.example.controller;

import com.example.common.Result;
import com.example.service.DataBackupService;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.file.Files;
import java.util.Map;

/**
 * 数据备份 / 恢复 / 导出导入
 */
@RestController
@RequestMapping("/dataBackup")
public class DataBackupController {

    @Resource
    private DataBackupService dataBackupService;

    /**
     * 备份文件列表
     */
    @GetMapping("/list")
    public Result list() {
        return Result.success(dataBackupService.list());
    }

    /**
     * 立即备份全部数据（数据库 + 上传文件）
     */
    @PostMapping("/create")
    public Result create() {
        return Result.success(dataBackupService.createManual());
    }

    /**
     * 导入备份文件（上传 zip 到服务器备份目录）
     */
    @PostMapping("/upload")
    public Result upload(@RequestParam("file") MultipartFile file) {
        dataBackupService.upload(file);
        return Result.success();
    }

    /**
     * 下载/导出备份文件
     */
    @GetMapping("/download")
    public void download(@RequestParam String name, HttpServletResponse response) throws IOException {
        File file = dataBackupService.file(name);
        response.setContentType("application/zip");
        response.setHeader("Content-Disposition",
                "attachment;filename=" + URLEncoder.encode(file.getName(), "UTF-8"));
        response.setContentLengthLong(file.length());
        Files.copy(file.toPath(), response.getOutputStream());
        response.getOutputStream().flush();
    }

    /**
     * 用指定备份恢复（恢复前自动备份当前数据）
     */
    @PostMapping("/restore")
    public Result restore(@RequestParam String name) {
        return Result.success(dataBackupService.restore(name));
    }

    /**
     * 删除备份文件
     */
    @DeleteMapping("/delete")
    public Result delete(@RequestParam String name) {
        dataBackupService.delete(name);
        return Result.success();
    }

    /**
     * 定时备份配置
     */
    @GetMapping("/config")
    public Result config() {
        return Result.success(dataBackupService.config());
    }

    /**
     * 保存定时备份配置：body {enabled, time:"02:00", keepCount:7}
     */
    @PostMapping("/config")
    public Result saveConfig(@RequestBody Map<String, Object> body) {
        dataBackupService.saveConfig(body);
        return Result.success();
    }
}
