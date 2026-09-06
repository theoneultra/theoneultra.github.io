# 用 VS Code 发布亦弦日报

文章保存在 `_posts/`，图片保存在 `assets/images/`。在 VS Code 中写作、预览，再推送到 GitHub，Actions 会构建并更新网站。

可以先查看[页面预览与验证记录](verification.md)。初始五张示意配图的文件路径、内置 image_gen 生成方式和实际提示词记录在[配图说明](image-credits.md)中。

## 第一次使用

1. 用 VS Code 打开整个 `theoneultra.github.io` 文件夹。
2. Windows 安装 [RubyInstaller 的 Ruby+Devkit](https://rubyinstaller.org/downloads/)，选择 Ruby 3.3 系列 x64，和仓库的 Actions 环境一致。完成安装时运行 `ridk install`，选择 **MSYS2 and MINGW development toolchain**。重新打开 VS Code，让终端读取新的 PATH。这是 [Jekyll 官方 Windows 安装流程](https://jekyllrb.com/docs/installation/windows/)。
3. 在 VS Code 终端执行：

   ```powershell
   ruby -v
   gem install bundler
   bundle install
   ```

4. 仓库已提供 `Gemfile.lock`，包含 Windows 与 Linux 平台依赖，让本地与 Actions 使用同一组版本。更新依赖后，把更新的锁文件随代码一起提交。仓库使用 Jekyll 4.4、jekyll-feed 和 jekyll-sitemap。
5. 仓库提供 Markdown 与 PowerShell 扩展建议，可在“扩展 → 推荐”中安装。VS Code 自带的 Markdown 预览也能直接使用。

macOS / Linux 可以按 [Jekyll 安装文档](https://jekyllrb.com/docs/installation/) 安装 Ruby。新建文章任务需要 PowerShell 7（`pwsh`），也可以直接复制模板，预览和构建命令相同。

## 日常写作

按 `Ctrl+Shift+P`，执行 **Tasks: Run Task / 任务: 运行任务**，选择以下任务。[VS Code Tasks 文档](https://code.visualstudio.com/docs/debugtest/tasks)介绍了任务入口。

| 任务 | 用途 |
| --- | --- |
| 日报：新建文章 | 输入标题、英文短名和栏目，生成草稿并在 VS Code 打开 |
| 日报：本地预览 | 开启带实时刷新的完整网站预览，包括 `published: false` 的草稿 |
| 日报：构建站点 | 按线上设置生成 `_site/`，不包含未发布文章 |
| 日报：安装依赖 | 初次使用或修改 Gemfile 后安装依赖 |

新建文章的英文短名用于文件名和网址，例如 `my-first-story`。只用小写英文字母、数字、连字符。脚本自动生成北京时间的日期，同名文件不会被覆盖。

也可以在 PowerShell 终端运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/new-post.ps1 -Title '我的第一篇文章' -Slug 'my-first-story' -Category life -Open
```

或复制 `templates/post.md` 到 `_posts/YYYY-MM-DD-short-title.md`。Jekyll 的文章文件名应使用[日期加短名的格式](https://jekyllrb.com/docs/posts/)。

## 填写文章和图片

新文章开头的两条 `---` 之间是元数据：

```yaml
---
layout: post
title: "我的第一篇文章"
date: 2026-09-06 09:00:00 +0800
category: physics
tags: [宇宙, 观测]
image: /assets/images/2026/09/my-cover.webp
image_alt: "深蓝天空中的银河"
author: Huang Yixian
featured: true
breaking: false
published: true
summary: "用一两句话说明这篇文章的内容。"
---
```

| 字段 | 填写方式 |
| --- | --- |
| `category` | `physics` 物理、`technology` 科技、`life` 随笔、`fiction` 虚构 |
| `image` | 封面的站内路径，以 `/assets/images/` 开头；图片文件需实际存在 |
| `image_alt` | 简短描述图片内容，供屏幕阅读器和图片加载失败时使用 |
| `image_caption` | 可选的图片说明或来源；AI 示意图请明确注明 |
| `reading_time` | 预计阅读分钟数，例如 `2` |
| `featured` | `true` 加入首页精选轮播；建议同时保留 3–5 篇 |
| `breaking` | `true` 加入首页快讯栏 |
| `published` | `false` 为草稿，准备好后改成 `true` |
| `summary` | 首页卡片和精选区域展示的摘要 |
| `date` | 文章日期与时间，时区填写 `+0800` |

把图片拖入 `assets/images/`，可以按 `2026/09/` 这样的子目录整理。优先使用压缩过的 WebP 或 JPEG，文件名不要含空格。正文配图示例：

```markdown
![图片说明]({{ '/assets/images/2026/09/my-cover.webp' | relative_url }})
```

在第二条 `---` 后写 Markdown 正文，可以使用标题、列表、引用、链接、表格和代码块。虚构创作请选择 `fiction` 栏目，并在开头注明虚构性质。

## 预览与发布

1. 保存文章，运行 **日报：本地预览**，浏览器打开 <http://127.0.0.1:4000>。终端出现 `Server running` 后即可访问。停止预览用终端的 `Ctrl+C`，或执行“任务: 终止任务”。
2. 检查封面、摘要、正文和手机宽度下的排版。VS Code 的 `Ctrl+Shift+V` 只预览 Markdown，完整网站效果以 Jekyll 的浏览器预览为准。
3. 将准备发布的文章设为 `published: true`。未发布稿件不会进入线上页面，但如果仓库是公开的，Markdown 源文件仍然可见。
4. 按 `Ctrl+Shift+B` 构建网站，确认终端没有错误。
5. 在 VS Code 的“源代码管理”中暂存改动、填写提交说明、提交，再推送到 `main`。也可在终端执行：

   ```powershell
   git add .
   git commit -m "Add a new story"
   git push origin main
   ```

6. 打开 GitHub 仓库的 **Actions**，等待 **Build and deploy HXY DAILY** 成功。网站地址是 <https://theoneultra.github.io>。

`future: false` 会排除日期晚于构建时间的文章。当前没有定时发布任务，未来日期的文章需要等到日期后再次推送或手动运行 Actions 才会出现。草稿请使用 `published: false` 管理。

## GitHub Pages 首次配置

在 GitHub 仓库打开 **Settings → Pages → Build and deployment → Source**，选择 **GitHub Actions**。然后推送到 `main`，或在 Actions 页面手动运行工作流。流程遵循 [GitHub Pages 自定义工作流文档](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)，部署任务使用 `github-pages` 环境及 Pages 所需权限。

`.github/workflows/pages.yml` 使用 Ruby 3.3 和 Bundler 安装 Gemfile 中的依赖，再运行 `bundle exec jekyll build`。Pull request 会验证构建，`main` 推送会构建并部署。Ruby 与缓存设置使用 [ruby/setup-ruby 官方 Action](https://github.com/ruby/setup-ruby)。

构建后，Actions 还会检查站内链接、图片路径、页面锚点、搜索索引和订阅文件。本地安装 Python 3 后，也可运行 `python scripts/check-site.py _site` 执行同样的检查。

站名、作者、域名在 `_config.yml` 修改。个人站点的 `baseurl` 保持空字符串；如果以后迁移到项目子路径，需要一起修改 `url` / `baseurl` 并检查资源链接。

订阅地址是 `/feed.xml`，由 [jekyll-feed](https://github.com/jekyll/jekyll-feed) 自动生成 Atom 订阅源，可用于 RSS 阅读器。`/sitemap.xml` 由 [jekyll-sitemap](https://github.com/jekyll/jekyll-sitemap) 自动生成。

## 文件位置

```text
theoneultra.github.io/
├── _posts/                  # 你写的 Markdown 文章
├── assets/images/           # 封面与正文图片
├── _layouts/                # 页面模板
├── _includes/               # 共用页面片段
├── assets/css/              # 网站样式
├── assets/js/               # 轮播、筛选等交互
├── templates/post.md        # 文章模板
├── scripts/new-post.ps1     # 新建文章命令
├── .vscode/                 # 任务、编辑设置、扩展建议
├── .github/workflows/       # GitHub Pages 部署
├── _config.yml              # 站点设置
├── Gemfile                  # Ruby 依赖
└── docs/publishing.md        # 本文
```

`_site/` 是构建产物，不需要修改或提交。`README.md` 保留了最初的设计需求，发布方法以本文为准。

## 常见问题

- **提示找不到 ruby / bundle：**确认安装 Ruby+Devkit 并加入 PATH，关闭后重新打开 VS Code，再运行 `ruby -v`；Bundler 用 `gem install bundler` 安装。
- **安装 gems 时原生扩展编译失败：**运行 `ridk install` 补装 MSYS2/MINGW 工具链，然后重试 `bundle install`。
- **中文乱码或 front matter 不生效：**右下角将文件保存编码设为 UTF-8（无 BOM）；必要时先在终端运行 `chcp 65001`。仓库的 VS Code 设置默认使用 UTF-8。
- **改了 `_config.yml` 没生效：**停止 Jekyll 预览后重新运行任务。
- **图片显示不出来：**确认路径和大小写完全一致；Windows 忽略大小写，线上 Linux 构建会区分大小写。
- **文章没有上线：**检查 `published`、日期与 `main` 的 Actions 日志，并确认 Pages Source 已选 GitHub Actions。
