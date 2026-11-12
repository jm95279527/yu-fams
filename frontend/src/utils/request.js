import axios from 'axios'
import { Message } from 'element-ui'
import router from "@/router";

// 登录态失效相关错误码：401=无效/验证失败，1003=已过期，1004=格式错误
const AUTH_FAIL_CODES = ['401', '1003', '1004']
let authRedirecting = false

// 创建可一个新的axios对象
const request = axios.create({
    baseURL: process.env.VUE_APP_BASEURL,   // 后端的接口地址  ip:port
    timeout: 30000                          // 30s请求超时
})

// request 拦截器
// 可以自请求发送前对请求做一些处理
// 比如统一加token，对请求参数统一加密
request.interceptors.request.use(config => {
    // FormData（如扫码图片上传）由浏览器自动设置 multipart 边界，不能强制 JSON
    if (!(config.data instanceof FormData)) {
        config.headers['Content-Type'] = 'application/json;charset=utf-8';    // 设置请求头格式
    }
    let user = JSON.parse(localStorage.getItem("xm-user") || '{}')  // 获取缓存的用户信息
    config.headers['token'] = user.token  // 设置请求头

    return config
}, error => {
    console.error('request error: ' + error) // for debug
    return Promise.reject(error)
});

// response 拦截器
// 可以在接口响应后统一处理结果
request.interceptors.response.use(
    response => {
        // 二进制文件下载（responseType: 'blob'）：返回完整响应，调用方通过 res.data 取文件流
        if (response.config && response.config.responseType === 'blob') {
            return response
        }
        let res = response.data;

        // 兼容服务端返回的字符串数据
        if (typeof res === 'string') {
            res = res ? JSON.parse(res) : res
        }
        // 登录失效/过期：清理本地登录态并回到登录页，避免各页面继续显示“Token已过期”
        if (AUTH_FAIL_CODES.includes(String(res.code))) {
            localStorage.removeItem('xm-user')
            if (router.currentRoute.path !== '/login' && !authRedirecting) {
                authRedirecting = true
                Message.closeAll()
                Message.warning('登录已过期，请重新登录')
                router.push('/login')
                setTimeout(() => { authRedirecting = false }, 5000)
            }
        }
        return res;
    },
    error => {
        console.error('response error: ' + error) // for debug
        return Promise.reject(error)
    }
)


export default request