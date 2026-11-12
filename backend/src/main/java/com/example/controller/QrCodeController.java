package com.example.controller;

import com.example.common.Result;
import com.example.entity.Assets;
import com.example.service.AssetsService;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.Binarizer;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.EncodeHintType;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.client.j2se.BufferedImageLuminanceSource;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.common.GlobalHistogramBinarizer;
import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.qrcode.QRCodeWriter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.imageio.ImageIO;
import javax.servlet.http.HttpServletResponse;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.awt.image.ConvolveOp;
import java.awt.image.Kernel;
import java.io.ByteArrayInputStream;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 资产二维码接口：生成二维码图片 + 扫码查看资产信息（公开接口，无需登录）
 */
@RestController
@RequestMapping("/qr")
public class QrCodeController {

    private static final Logger log = LoggerFactory.getLogger(QrCodeController.class);

    @Resource
    private AssetsService assetsService;

    /**
     * 生成二维码图片 PNG
     *
     * @param text 二维码内容（扫码后打开的地址）
     * @param size 图片尺寸（像素）
     */
    @GetMapping("/png")
    public void png(@RequestParam String text,
                    @RequestParam(defaultValue = "300") int size,
                    HttpServletResponse response) throws Exception {
        Map<EncodeHintType, Object> hints = new LinkedHashMap<>();
        hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
        hints.put(EncodeHintType.MARGIN, 1);
        BitMatrix matrix = new QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, size, size, hints);
        response.setContentType("image/png");
        response.setHeader("Cache-Control", "max-age=3600");
        MatrixToImageWriter.writeToStream(matrix, "PNG", response.getOutputStream());
    }

    /**
     * 识别二维码图片（手机拍照上传后解析，公开接口）
     * 返回识别出的二维码文本（如 http://.../scan/HMDZ0426100001）
     * 手机拍照常见问题：反光、倾斜、二维码偏小、失焦，这里做多尺度/二值化/锐化/反色/旋转多轮尝试
     */
    @PostMapping("/decode")
    public Result decode(@RequestParam("file") MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return Result.error("500", "请选择二维码图片");
        }
        try {
            byte[] bytes = file.getBytes();
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(bytes));
            if (image == null) {
                log.warn("二维码图片无法解码, name={}, bytes={}", file.getOriginalFilename(), bytes.length);
                return Result.error("500", "图片格式无法识别，请重新拍照或从相册选择 JPG 图片");
            }
            String text = decodeQr(image);
            if (text != null) {
                log.info("二维码识别成功, {}x{}, bytes={}, text={}",
                        image.getWidth(), image.getHeight(), bytes.length, text);
                return Result.success(text);
            }
            log.warn("二维码识别失败, {}x{}, bytes={}", image.getWidth(), image.getHeight(), bytes.length);
            return Result.error("500", "未识别到二维码，请让二维码占满画面、保持清晰后重拍，或手动输入资产编号");
        } catch (Exception e) {
            log.error("二维码识别异常", e);
            return Result.error("500", "二维码识别失败，请重拍或手动输入资产编号");
        }
    }

    /**
     * 多轮识别：原图/缩放/锐化 × 两种二值化 × 反色
     */
    private String decodeQr(BufferedImage src) {
        int max = Math.max(src.getWidth(), src.getHeight());
        List<BufferedImage> variants = new ArrayList<>();
        variants.add(src);
        if (max > 2000) {
            variants.add(scale(src, 2000));
        }
        variants.add(sharpen(src));
        if (max > 1200) {
            variants.add(scale(src, 1200));
            variants.add(sharpen(scale(src, 1200)));
        }
        for (BufferedImage img : variants) {
            String text = tryDecode(img);
            if (text != null) {
                return text;
            }
            text = tryDecode(invert(img));
            if (text != null) {
                return text;
            }
        }
        return null;
    }

    private String tryDecode(BufferedImage img) {
        if (img == null) {
            return null;
        }
        try {
            LuminanceSource source = new BufferedImageLuminanceSource(img);
            Binarizer[] binarizers = {new HybridBinarizer(source), new GlobalHistogramBinarizer(source)};
            for (Binarizer binarizer : binarizers) {
                BinaryBitmap bitmap = new BinaryBitmap(binarizer);
                Map<DecodeHintType, Object> hints = new EnumMap<>(DecodeHintType.class);
                hints.put(DecodeHintType.CHARACTER_SET, "UTF-8");
                hints.put(DecodeHintType.TRY_HARDER, Boolean.TRUE);
                try {
                    return new MultiFormatReader().decode(bitmap, hints).getText();
                } catch (Exception ignore) {
                    // 换下一种二值化方式
                }
            }
        } catch (Exception ignore) {
            // 忽略单张图片处理异常
        }
        return null;
    }

    private BufferedImage sharpen(BufferedImage src) {
        float[] kernel = {0, -1, 0, -1, 5, -1, 0, -1, 0};
        return new ConvolveOp(new Kernel(3, 3, kernel), ConvolveOp.EDGE_NO_OP, null).filter(src, null);
    }

    private BufferedImage invert(BufferedImage src) {
        int w = src.getWidth(), h = src.getHeight();
        BufferedImage out = new BufferedImage(w, h, BufferedImage.TYPE_INT_RGB);
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                int p = src.getRGB(x, y);
                int r = 255 - ((p >> 16) & 0xff);
                int g = 255 - ((p >> 8) & 0xff);
                int b = 255 - (p & 0xff);
                out.setRGB(x, y, (r << 16) | (g << 8) | b);
            }
        }
        return out;
    }

    private BufferedImage scale(BufferedImage src, int maxSide) {
        int w = src.getWidth(), h = src.getHeight();
        int max = Math.max(w, h);
        if (max <= maxSide) {
            return src;
        }
        int nw = (int) Math.round(w * (double) maxSide / max);
        int nh = (int) Math.round(h * (double) maxSide / max);
        BufferedImage out = new BufferedImage(nw, nh, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = out.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        g.drawImage(src, 0, 0, nw, nh, null);
        g.dispose();
        return out;
    }

    /**
     * 扫码查看资产信息（只返回展示字段，不暴露内部ID等信息）
     */
    @GetMapping("/asset/{id}")
    public Result asset(@PathVariable Integer id) {
        // 兼容历史二维码（/scan/{id} 数字后缀）
        Assets assets = assetsService.selectJoinedById(id);
        if (assets == null) {
            return Result.error("404", "资产不存在或已删除");
        }
        return Result.success(scanData(assets));
    }

    /**
     * 按资产编号查看（新二维码 /scan/{资产编号}）
     */
    @GetMapping("/assetByNo/{no}")
    public Result assetByNo(@PathVariable String no) {
        Assets assets = assetsService.selectJoinedByNo(no);
        if (assets == null) {
            return Result.error("404", "资产不存在或已删除");
        }
        return Result.success(scanData(assets));
    }

    /**
     * 扫码页返回的数据（不暴露无关内部信息，仅返回借用/报修需要的资产ID）
     */
    private Map<String, Object> scanData(Assets assets) {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("assetId", assets.getId());
        data.put("name", assets.getName());
        data.put("category", assets.getCategory());
        data.put("no", assets.getNo());
        data.put("model", assets.getModel());
        data.put("img", assets.getImg());
        data.put("num", assets.getNum());
        data.put("date", assets.getDate());
        data.put("money", assets.getMoney());
        data.put("depreciate", assets.getDepreciate());
        data.put("status", assets.getStatus());
        data.put("companyName", assets.getCompanyName());
        data.put("departmentName", assets.getDepartmentName());
        data.put("staffName", assets.getStaffName());
        data.put("location", assets.getLocation());
        data.put("comment", assets.getComment());
        // 自定义字段（显示名称由「基础资料 → 自定义字段」配置）
        data.put("custom1", assets.getCustom1());
        data.put("custom2", assets.getCustom2());
        data.put("custom3", assets.getCustom3());
        data.put("custom4", assets.getCustom4());
        data.put("custom5", assets.getCustom5());
        data.put("custom6", assets.getCustom6());
        data.put("custom7", assets.getCustom7());
        data.put("custom8", assets.getCustom8());
        data.put("custom9", assets.getCustom9());
        data.put("custom10", assets.getCustom10());
        return data;
    }
}
