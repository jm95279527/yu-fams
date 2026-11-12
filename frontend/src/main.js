import Vue from 'vue'
import App from './App.vue'
import router from './router'
import ElementUI from 'element-ui'
import 'element-ui/lib/theme-chalk/index.css'
import '@/assets/css/global.css'
import '@/assets/css/theme/index.css'
// 全局视觉精修（需在 element 主题之后加载）
import '@/assets/css/polish.css'
import request from "@/utils/request";
import siteConfig, { loadSiteConfig } from "@/utils/siteConfig";
import fieldStore, { loadFieldConfig, fieldLabel } from "@/utils/fields";

Vue.config.productionTip = false

Vue.prototype.$request = request
Vue.prototype.$baseUrl = process.env.VUE_APP_BASEURL
// 全局站点配置（系统名称/登录壁纸/Logo/页脚等），见「系统管理 → 页面设置」
Vue.prototype.$cfg = siteConfig
// 资产字段名称/自定义字段（基础资料 → 自定义字段）
Vue.prototype.$fieldStore = fieldStore
Vue.prototype.$field = fieldLabel
loadSiteConfig()
loadFieldConfig()

Vue.use(ElementUI, {size: "small"})

new Vue({
    router,
    render: h => h(App)
}).$mount('#app')
