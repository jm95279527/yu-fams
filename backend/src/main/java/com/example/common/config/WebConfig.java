package com.example.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import javax.annotation.Resource;

@Configuration
public class WebConfig implements  WebMvcConfigurer {

    @Resource
    private JwtInterceptor jwtInterceptor;

    // 加自定义拦截器JwtInterceptor，设置拦截规则
    // 仅放行真正的匿名接口：登录/静态文件/二维码/扫码/页面公开配置（已取消账号注册）
    // 其余业务接口统一进入 JwtInterceptor 做 token 校验 + 接口级角色鉴权
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(jwtInterceptor).addPathPatterns("/**")
                .excludePathPatterns("/")
                .excludePathPatterns("/login")
                .excludePathPatterns("/files/**")
                .excludePathPatterns("/qr/**")
                .excludePathPatterns("/scan/**")
                .excludePathPatterns("/inventoryPublic/**")
                .excludePathPatterns("/sysConfig/public")
                .excludePathPatterns("/assetField/public")
                .excludePathPatterns("/apiConfig/**");
    }
}