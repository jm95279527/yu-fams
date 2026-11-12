package com.example.common.utils;

import com.example.exception.CustomException;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 登录防暴力破解：同一账号连续失败 MAX_ATTEMPTS 次后锁定 LOCK_MINUTES 分钟
 * 内存实现，重启后自动解锁；登出/登录成功即清除计数
 */
@Component
public class LoginGuard {

    /** 最大连续失败次数 */
    private static final int MAX_ATTEMPTS = 5;
    /** 锁定时长（毫秒） */
    private static final long LOCK_MILLIS = 10 * 60 * 1000L;

    private static class Attempt {
        int count;
        long lockUntil;
    }

    private final Map<String, Attempt> attempts = new ConcurrentHashMap<>();

    /**
     * 登录前校验：锁定期内直接拒绝
     */
    public void checkLocked(String key) {
        Attempt a = attempts.get(key);
        if (a == null) {
            return;
        }
        long now = System.currentTimeMillis();
        if (a.lockUntil > now) {
            long minutes = (a.lockUntil - now) / 60000 + 1;
            throw new CustomException("400", "登录失败次数过多，账号已临时锁定，请约" + minutes + "分钟后再试");
        }
        if (a.lockUntil > 0) {
            attempts.remove(key); // 锁定期满自动解锁
        }
    }

    /**
     * 记录一次失败；达到阈值则锁定
     */
    public void onFailure(String key) {
        Attempt a = attempts.computeIfAbsent(key, k -> new Attempt());
        synchronized (a) {
            a.count++;
            if (a.count >= MAX_ATTEMPTS) {
                a.lockUntil = System.currentTimeMillis() + LOCK_MILLIS;
                a.count = 0;
            }
        }
    }

    /**
     * 登录成功清除计数
     */
    public void onSuccess(String key) {
        attempts.remove(key);
    }
}
