package com.example.service.impl;

import cn.hutool.core.date.DateUtil;
import cn.hutool.core.util.StrUtil;
import com.example.entity.SysConfig;
import com.example.exception.CustomException;
import com.example.mapper.SysConfigMapper;
import com.example.service.DataBackupService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

/**
 * 数据备份/恢复：数据库全部表 + 上传文件
 * 备份文件存放在应用工作目录 backup/ 下，可下载、导入、恢复
 */
@Service
public class DataBackupServiceImpl implements DataBackupService {

    private static final Logger log = LoggerFactory.getLogger(DataBackupServiceImpl.class);

    /** 备份文件名：backup_yyyyMMdd_HHmmss_类型.zip */
    private static final Pattern NAME_PATTERN =
            Pattern.compile("^backup_\\d{8}_\\d{6}_(manual|auto|before-restore|import)\\.zip$");
    private static final Map<String, String> TYPE_TEXT = new LinkedHashMap<>();
    static {
        TYPE_TEXT.put("manual", "手动备份");
        TYPE_TEXT.put("auto", "定时备份");
        TYPE_TEXT.put("before-restore", "恢复前自动");
        TYPE_TEXT.put("import", "导入备份");
    }

    private final AtomicBoolean busy = new AtomicBoolean(false);

    @Value("${spring.datasource.url}")
    private String datasourceUrl;
    @Value("${spring.datasource.username}")
    private String dbUser;
    @Value("${spring.datasource.password}")
    private String dbPassword;

    @Resource
    private SysConfigMapper sysConfigMapper;
    @Resource
    private JdbcTemplate jdbcTemplate;

    // ==================== 列表 / 创建 / 下载 / 删除 ====================

    @Override
    public List<Map<String, Object>> list() {
        File[] files = backupDir().listFiles((dir, name) -> NAME_PATTERN.matcher(name).matches());
        List<Map<String, Object>> rows = new ArrayList<>();
        if (files == null) {
            return rows;
        }
        Arrays.sort(files, Comparator.comparingLong(File::lastModified).reversed());
        for (File file : files) {
            rows.add(info(file));
        }
        return rows;
    }

    @Override
    public Map<String, Object> createManual() {
        if (!busy.compareAndSet(false, true)) {
            throw new CustomException("500", "正在执行备份或恢复，请稍后再试");
        }
        try {
            return doCreate("manual");
        } finally {
            busy.set(false);
        }
    }

    @Override
    public void upload(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new CustomException("500", "请选择备份文件");
        }
        String original = file.getOriginalFilename();
        if (original == null || !original.toLowerCase().endsWith(".zip")) {
            throw new CustomException("500", "仅支持 .zip 备份文件");
        }
        File dir = backupDir();
        File tmp = new File(dir, ".upload_" + System.currentTimeMillis());
        try {
            tmp.mkdirs();
            unzip(file.getInputStream(), tmp);
            if (!new File(tmp, "db.sql").isFile()) {
                throw new CustomException("500", "不是有效的备份文件：压缩包内缺少 db.sql");
            }
            String name = "backup_" + DateUtil.format(new Date(), "yyyyMMdd_HHmmss") + "_import.zip";
            File target = new File(dir, name);
            if (target.exists()) {
                throw new CustomException("500", "同一秒已有导入记录，请稍后重试");
            }
            file.transferTo(target.getAbsoluteFile());
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException("500", "导入备份失败：" + e.getMessage());
        } finally {
            deleteRecursively(tmp);
        }
    }

    @Override
    public void delete(String name) {
        File file = file(name);
        if (!file.delete()) {
            throw new CustomException("500", "删除失败，请稍后重试");
        }
    }

    @Override
    public File file(String name) {
        if (name == null || !NAME_PATTERN.matcher(name).matches()) {
            throw new CustomException("500", "备份文件名无效");
        }
        File file = new File(backupDir(), name);
        if (!file.isFile()) {
            throw new CustomException("500", "备份文件不存在");
        }
        return file;
    }

    // ==================== 恢复 ====================

    @Override
    public Map<String, Object> restore(String name) {
        File zip = file(name);
        if (!busy.compareAndSet(false, true)) {
            throw new CustomException("500", "正在执行备份或恢复，请稍后再试");
        }
        File tmp = null;
        try {
            // 保留当前定时备份配置，避免被旧备份覆盖后丢失
            Map<String, Object> keepConfig = config();
            // 恢复前先自动备份当前数据
            Map<String, Object> safety = doCreate("before-restore");

            tmp = new File(backupDir(), ".restore_" + System.currentTimeMillis());
            tmp.mkdirs();
            unzip(new FileInputStream(zip), tmp);
            File sql = new File(tmp, "db.sql");
            if (!sql.isFile()) {
                throw new CustomException("500", "备份文件缺少 db.sql，无法恢复");
            }
            restoreDatabase(sql);

            File newFiles = new File(tmp, "files");
            if (newFiles.isDirectory()) {
                restoreFiles(newFiles);
            }
            ensureBackupMenu();
            try {
                saveConfig(keepConfig);
            } catch (Exception e) {
                log.warn("恢复后写回备份配置失败", e);
            }

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("restored", name);
            result.put("safetyBackup", safety.get("name"));
            log.info("数据恢复完成：{}，恢复前备份：{}", name, safety.get("name"));
            return result;
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            log.error("数据恢复失败", e);
            throw new CustomException("500", "恢复失败：" + e.getMessage());
        } finally {
            if (tmp != null) {
                deleteRecursively(tmp);
            }
            busy.set(false);
        }
    }

    // ==================== 定时备份配置 ====================

    @Override
    public Map<String, Object> config() {
        Map<String, String> raw = rawConfig();
        Map<String, Object> cfg = new LinkedHashMap<>();
        cfg.put("enabled", "1".equals(raw.get("backup_enabled")));
        cfg.put("time", StrUtil.blankToDefault(raw.get("backup_time"), "02:00"));
        cfg.put("keepCount", parseInt(raw.get("backup_keep"), 7));
        cfg.put("lastRunDate", StrUtil.blankToDefault(raw.get("backup_last_date"), ""));
        cfg.put("lastRunTime", StrUtil.blankToDefault(raw.get("backup_last_time"), ""));
        cfg.put("dir", backupDir().getAbsolutePath());
        return cfg;
    }

    @Override
    public void saveConfig(Map<String, Object> body) {
        String time = body.get("time") == null ? "02:00" : String.valueOf(body.get("time")).trim();
        if (!time.matches("([01]\\d|2[0-3]):[0-5]\\d")) {
            throw new CustomException("500", "备份时间格式应为 HH:mm");
        }
        int keep = parseInt(body.get("keepCount") == null ? null : String.valueOf(body.get("keepCount")), 7);
        if (keep < 1 || keep > 60) {
            throw new CustomException("500", "保留份数需在 1-60 之间");
        }
        boolean enabled = false;
        Object enabledObj = body.get("enabled");
        if (enabledObj != null) {
            enabled = Boolean.parseBoolean(String.valueOf(enabledObj));
        }
        saveValue("backup_enabled", enabled ? "1" : "0");
        saveValue("backup_time", time);
        saveValue("backup_keep", String.valueOf(keep));
    }

    @Override
    public void scheduledBackupIfDue() {
        try {
            Map<String, String> raw = rawConfig();
            if (!"1".equals(raw.get("backup_enabled"))) {
                return;
            }
            String time = StrUtil.blankToDefault(raw.get("backup_time"), "02:00");
            String nowHm = DateUtil.format(new Date(), "HH:mm");
            String today = DateUtil.today();
            if (!time.equals(nowHm) || today.equals(raw.get("backup_last_date"))) {
                return;
            }
            if (!busy.compareAndSet(false, true)) {
                return;
            }
            try {
                Map<String, Object> info = doCreate("auto");
                cleanupAuto(parseInt(raw.get("backup_keep"), 7));
                saveValue("backup_last_date", today);
                saveValue("backup_last_time", DateUtil.now());
                log.info("定时备份完成：{}", info.get("name"));
            } finally {
                busy.set(false);
            }
        } catch (Exception e) {
            log.error("定时备份失败", e);
        }
    }

    // ==================== 内部实现 ====================

    private Map<String, Object> doCreate(String type) {
        File dir = backupDir();
        String ts = DateUtil.format(new Date(), "yyyyMMdd_HHmmss");
        String name = "backup_" + ts + "_" + type + ".zip";
        File zip = new File(dir, name);
        File tmp = new File(dir, ".tmp_" + ts + "_" + type);
        File logFile = new File(dir, "backup.log");
        try {
            tmp.mkdirs();
            File sql = new File(tmp, "db.sql");
            dumpDatabase(sql, logFile);
            try (ZipOutputStream zos = new ZipOutputStream(
                    new BufferedOutputStream(new FileOutputStream(zip)))) {
                addFileToZip(zos, sql, "db.sql");
                File uploadFiles = filesDir();
                if (uploadFiles.isDirectory()) {
                    addDirToZip(zos, uploadFiles, "files");
                }
                zos.putNextEntry(new ZipEntry("manifest.json"));
                String manifest = "{\"time\":\"" + DateUtil.now() + "\",\"type\":\"" + type + "\"}";
                zos.write(manifest.getBytes("UTF-8"));
                zos.closeEntry();
            }
            log.info("数据备份完成：{}（{}）", name, sizeText(zip.length()));
            return info(zip);
        } catch (CustomException e) {
            deleteQuietly(zip);
            throw e;
        } catch (Exception e) {
            deleteQuietly(zip);
            log.error("数据备份失败", e);
            throw new CustomException("500", "备份失败：" + e.getMessage());
        } finally {
            deleteRecursively(tmp);
        }
    }

    private void dumpDatabase(File output, File logFile) throws Exception {
        DbInfo db = dbInfo();
        ProcessBuilder pb = new ProcessBuilder(
                "mysqldump", "-h", db.host, "-P", db.port, "-u", dbUser,
                "--single-transaction", "--quick", "--routines", "--triggers",
                "--default-character-set=utf8mb4", "--set-gtid-purged=OFF", db.name);
        pb.environment().put("MYSQL_PWD", dbPassword == null ? "" : dbPassword);
        pb.redirectOutput(ProcessBuilder.Redirect.to(output));
        pb.redirectError(ProcessBuilder.Redirect.appendTo(logFile));
        Process process = pb.start();
        if (!process.waitFor(30, TimeUnit.MINUTES)) {
            process.destroyForcibly();
            throw new CustomException("500", "数据库导出超时");
        }
        if (process.exitValue() != 0) {
            throw new CustomException("500", "数据库导出失败，请查看 backup/backup.log");
        }
        if (!output.isFile() || output.length() == 0) {
            throw new CustomException("500", "数据库导出结果为空");
        }
    }

    private void restoreDatabase(File sql) throws Exception {
        DbInfo db = dbInfo();
        ProcessBuilder pb = new ProcessBuilder(
                "mysql", "-h", db.host, "-P", db.port, "-u", dbUser,
                "--default-character-set=utf8mb4", db.name);
        pb.environment().put("MYSQL_PWD", dbPassword == null ? "" : dbPassword);
        pb.redirectInput(ProcessBuilder.Redirect.from(sql));
        pb.redirectOutput(ProcessBuilder.Redirect.appendTo(new File(backupDir(), "backup.log")));
        pb.redirectError(ProcessBuilder.Redirect.appendTo(new File(backupDir(), "backup.log")));
        Process process = pb.start();
        if (!process.waitFor(30, TimeUnit.MINUTES)) {
            process.destroyForcibly();
            throw new CustomException("500", "数据库恢复超时");
        }
        if (process.exitValue() != 0) {
            throw new CustomException("500", "数据库恢复失败，请查看 backup/backup.log");
        }
    }

    private void restoreFiles(File newFiles) throws IOException {
        File current = filesDir();
        File prev = new File(workDir(), "files_prev_" + DateUtil.format(new Date(), "yyyyMMdd_HHmmss"));
        if (current.exists()) {
            if (!current.renameTo(prev)) {
                log.warn("原上传目录重命名失败，改为复制后删除：{}", current.getAbsolutePath());
                copyDirectory(current, prev);
                deleteRecursively(current);
            }
        }
        copyDirectory(newFiles, current);
        log.info("上传文件恢复完成，原目录已备份到：{}", prev.getAbsolutePath());
    }

    private void cleanupAuto(int keepCount) {
        File[] files = backupDir().listFiles((dir, name) -> name.matches("^backup_\\d{8}_\\d{6}_auto\\.zip$"));
        if (files == null || files.length <= keepCount) {
            return;
        }
        Arrays.sort(files, Comparator.comparingLong(File::lastModified).reversed());
        for (int i = keepCount; i < files.length; i++) {
            deleteQuietly(files[i]);
        }
    }

    private Map<String, Object> info(File file) {
        String name = file.getName();
        Matcher matcher = NAME_PATTERN.matcher(name);
        String type = matcher.matches() ? matcher.group(1) : "";
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("name", name);
        row.put("type", type);
        row.put("typeText", TYPE_TEXT.getOrDefault(type, "备份"));
        row.put("size", file.length());
        row.put("sizeText", sizeText(file.length()));
        row.put("time", DateUtil.format(new Date(file.lastModified()), "yyyy-MM-dd HH:mm:ss"));
        return row;
    }

    private Map<String, String> rawConfig() {
        Map<String, String> raw = new LinkedHashMap<>();
        for (SysConfig config : sysConfigMapper.selectAll()) {
            raw.put(config.getConfigKey(), config.getConfigValue());
        }
        return raw;
    }

    private void saveValue(String key, String value) {
        SysConfig config = new SysConfig();
        config.setConfigKey(key);
        config.setConfigValue(value);
        config.setUpdateTime(DateUtil.now());
        sysConfigMapper.save(config);
    }

    private DbInfo dbInfo() {
        Matcher m = Pattern.compile("jdbc:mysql://([^/:]+)(?::(\\d+))?/([^?]+)").matcher(datasourceUrl);
        if (!m.find()) {
            throw new CustomException("500", "无法解析数据库连接地址");
        }
        return new DbInfo(m.group(1),
                m.group(2) == null ? "3306" : m.group(2),
                m.group(3));
    }

    /**
     * 恢复旧备份后，确保「数据备份」菜单仍然存在（否则页面入口会消失）
     */
    private void ensureBackupMenu() {
        try {
            jdbcTemplate.update("INSERT INTO sys_menu(id, parent_id, name, path, api, icon, type, sort) "
                    + "SELECT 57, 50, '数据备份', '/dataBackup', '/dataBackup', 'el-icon-folder-opened', 2, 4 "
                    + "FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = '/dataBackup') "
                    + "AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE id = 57)");
            jdbcTemplate.update("INSERT INTO sys_role_menu(role_id, menu_id) "
                    + "SELECT 1, id FROM sys_menu WHERE path = '/dataBackup' "
                    + "AND NOT EXISTS (SELECT 1 FROM sys_role_menu WHERE role_id = 1 AND menu_id = sys_menu.id)");
        } catch (Exception e) {
            log.warn("恢复后补齐数据备份菜单失败", e);
        }
    }

    private File workDir() {
        return new File(System.getProperty("user.dir"));
    }

    private File backupDir() {
        File dir = new File(workDir(), "backup");
        if (!dir.exists() && !dir.mkdirs()) {
            throw new CustomException("500", "无法创建备份目录：" + dir.getAbsolutePath());
        }
        return dir;
    }

    private File filesDir() {
        return new File(workDir(), "files");
    }

    private void addFileToZip(ZipOutputStream zos, File file, String entryName) throws IOException {
        zos.putNextEntry(new ZipEntry(entryName));
        try (InputStream in = new BufferedInputStream(new FileInputStream(file))) {
            byte[] buffer = new byte[8192];
            int len;
            while ((len = in.read(buffer)) > 0) {
                zos.write(buffer, 0, len);
            }
        }
        zos.closeEntry();
    }

    private void addDirToZip(ZipOutputStream zos, File dir, String base) throws IOException {
        File[] children = dir.listFiles();
        if (children == null) {
            return;
        }
        Arrays.sort(children, Comparator.comparing(File::getName));
        for (File child : children) {
            if (child.isDirectory()) {
                addDirToZip(zos, child, base + "/" + child.getName());
            } else {
                addFileToZip(zos, child, base + "/" + child.getName());
            }
        }
    }

    private void unzip(InputStream in, File targetDir) throws IOException {
        String base = targetDir.getCanonicalPath();
        try (ZipInputStream zis = new ZipInputStream(new BufferedInputStream(in))) {
            ZipEntry entry;
            byte[] buffer = new byte[8192];
            while ((entry = zis.getNextEntry()) != null) {
                File outFile = new File(targetDir, entry.getName());
                String path = outFile.getCanonicalPath();
                if (!path.equals(base) && !path.startsWith(base + File.separator)) {
                    throw new IOException("备份文件包含非法路径：" + entry.getName());
                }
                if (entry.isDirectory()) {
                    outFile.mkdirs();
                } else {
                    File parent = outFile.getParentFile();
                    if (parent != null) {
                        parent.mkdirs();
                    }
                    try (OutputStream os = new BufferedOutputStream(new FileOutputStream(outFile))) {
                        int len;
                        while ((len = zis.read(buffer)) > 0) {
                            os.write(buffer, 0, len);
                        }
                    }
                }
                zis.closeEntry();
            }
        }
    }

    private void copyDirectory(File src, File dest) throws IOException {
        if (!dest.exists() && !dest.mkdirs()) {
            throw new IOException("无法创建目录：" + dest.getAbsolutePath());
        }
        File[] children = src.listFiles();
        if (children == null) {
            return;
        }
        for (File child : children) {
            File target = new File(dest, child.getName());
            if (child.isDirectory()) {
                copyDirectory(child, target);
            } else {
                Files.copy(child.toPath(), target.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            }
        }
    }

    private void deleteRecursively(File file) {
        if (file == null || !file.exists()) {
            return;
        }
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteRecursively(child);
                }
            }
        }
        deleteQuietly(file);
    }

    private void deleteQuietly(File file) {
        try {
            if (file != null && file.exists()) {
                file.delete();
            }
        } catch (Exception ignore) {
            // ignore
        }
    }

    private String sizeText(long bytes) {
        if (bytes < 1024) {
            return bytes + " B";
        }
        if (bytes < 1024 * 1024) {
            return String.format("%.1f KB", bytes / 1024.0);
        }
        return String.format("%.1f MB", bytes / 1024.0 / 1024.0);
    }

    private int parseInt(String value, int fallback) {
        try {
            return Integer.parseInt(value == null ? "" : value.trim());
        } catch (Exception e) {
            return fallback;
        }
    }

    private static class DbInfo {
        private final String host;
        private final String port;
        private final String name;

        private DbInfo(String host, String port, String name) {
            this.host = host;
            this.port = port;
            this.name = name;
        }
    }
}
