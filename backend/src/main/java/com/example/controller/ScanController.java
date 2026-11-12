package com.example.controller;

import com.example.common.Result;
import com.example.entity.AssetsReceive;
import com.example.entity.AssetsRepair;
import com.example.service.AssetsReceiveService;
import com.example.service.AssetsRepairService;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;

/**
 * 扫码公开接口：任何人扫资产二维码后可直接提交「借用申请」「报修申请」
 * 说明：/scan/** 已在 WebConfig 中放行，无需登录；提交后分别为 待审核 / 处理中，仍由管理员审核
 */
@RestController
@RequestMapping("/scan")
public class ScanController {

    @Resource
    private AssetsReceiveService assetsReceiveService;

    @Resource
    private AssetsRepairService assetsRepairService;

    /**
     * 扫码提交借用申请
     */
    @PostMapping("/borrow")
    public Result borrow(@RequestBody AssetsReceive body) {
        AssetsReceive borrow = new AssetsReceive();
        borrow.setAssetsId(body.getAssetsId());
        borrow.setBorrowerName(body.getBorrowerName());
        borrow.setBorrowerPhone(body.getBorrowerPhone());
        borrow.setReturnDate(body.getReturnDate());
        borrow.setComment(body.getComment());
        assetsReceiveService.add(borrow);
        return Result.success();
    }

    /**
     * 扫码提交报修申请
     */
    @PostMapping("/repair")
    public Result repair(@RequestBody AssetsRepair body) {
        AssetsRepair repair = new AssetsRepair();
        repair.setAssetsId(body.getAssetsId());
        repair.setAssetsName(body.getAssetsName());
        repair.setAssetsCode(body.getAssetsCode());
        repair.setReporterName(body.getReporterName());
        repair.setReporterPhone(body.getReporterPhone());
        repair.setReason(body.getReason());
        repair.setFaultDesc(body.getFaultDesc());
        repair.setImg(body.getImg());
        assetsRepairService.add(repair);
        return Result.success();
    }
}
