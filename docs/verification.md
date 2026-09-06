# 重建设计与验证记录

验证日期：2026-09-06。

## 交付内容

亦弦日报采用 Jekyll + Markdown + GitHub Pages，以 VS Code 本地写作与 Git 推送作为发布流程。首页提供精选轮播、分类筛选、文章推荐和 RSS 入口；另有分类页、文章归档、文章正文、关于页、搜索与 404 页面。

初始内容为 7 篇示例文章与 5 张 AI 示意配图。原始 README 需求文本保留。旧站页面、脚本、样式和文章资源已清除，清理前的副本保存在本机临时目录 `hxy-daily-old-content-20260906-191300`。

## 已完成验证

- Ruby 3.3.12 / Jekyll 4.4.1 正式构建成功，生成 12 个 HTML 页面与 7 条搜索记录。
- `python scripts/check-site.py _site` 通过：站内链接、图片路径、锚点、分类与归档文章完整性、搜索 JSON、Feed 与 Sitemap。
- 24 项 Edge / Playwright 浏览器检查通过，无未捕获 JavaScript 错误。
- 检查包含轮播自动播放、按钮与方向键、焦点保持、搜索与单次 Esc 关闭、四分类筛选、归档查询、复制文章链接、虚构内容标注。
- 桌面首页、320/390/768px 首页，以及 320/390px 的文章、分类、归档和关于页均无横向溢出；5 个轮播指示按钮也能适配小屏幕。
- VS Code 任务 JSON、PowerShell 新建文章脚本，以及中文标题、引号转义、无 BOM 编码、重复文件保护和非法短名拒绝已验证。

本次仅完成本地重建与验证。线上部署需按[发布说明](publishing.md)设置 GitHub Pages Source 并推送代码。

## 预览

- [桌面首页](previews/home-desktop.png)
- [手机首页](previews/home-mobile.png)
- [配图文件、内置 image_gen 模式与实际提示词](image-credits.md)
