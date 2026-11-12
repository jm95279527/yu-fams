package com.example.controller;

import com.example.common.Result;
import com.example.entity.RobotConfig;
import com.example.service.NotifyService;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;

/**
 * 群机器人配置接口
 */
@RestController
@RequestMapping("/robotConfig")
public class RobotConfigController {

    @Resource
    private NotifyService notifyService;

    /**
     * 查询所有
     */
    @GetMapping("/selectAll")
    public Result selectAll(RobotConfig robotConfig) {
        List<RobotConfig> list = notifyService.listRobots(robotConfig);
        return Result.success(list);
    }

    /**
     * 根据ID查询
     */
    @GetMapping("/selectById/{id}")
    public Result selectById(@PathVariable Integer id) {
        return Result.success(notifyService.getRobot(id));
    }

    /**
     * 新增
     */
    @PostMapping("/add")
    public Result add(@RequestBody RobotConfig robotConfig) {
        notifyService.saveRobot(robotConfig);
        return Result.success();
    }

    /**
     * 修改
     */
    @PutMapping("/update")
    public Result update(@RequestBody RobotConfig robotConfig) {
        notifyService.saveRobot(robotConfig);
        return Result.success();
    }

    /**
     * 删除
     */
    @DeleteMapping("/delete/{id}")
    public Result delete(@PathVariable Integer id) {
        notifyService.deleteRobot(id);
        return Result.success();
    }

    /**
     * 测试发送
     */
    @PostMapping("/test/{id}")
    public Result test(@PathVariable Integer id, @RequestParam(required = false) String message) {
        return Result.success(notifyService.testSend(id, message));
    }
}
