theoneultra.github.io

## 自动同步文章

脚本路径：`scripts/sync-articles.ps1`

作用：
- 扫描 `articles` 目录下所有 `*.pdf`
- 先删除多余文章项（没有对应 PDF 的文章页 + `running.html` 旧入口）
- 自动补齐缺失文章页（`articles/article-xxxxxxxx.html`）
- 再重建 `running.html` 文章入口（按 PDF 最新时间在前）
- 文章标题默认使用 PDF 文件名（不含扩展名）

### 运行命令

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-articles.ps1
```

### 预览模式（不写文件）

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-articles.ps1 -DryRun
```
