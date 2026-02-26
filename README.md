theoneultra.github.io

## 自动同步文章

脚本路径：`scripts/sync-articles.ps1`

作用：
- 扫描 `articles` 目录下所有 `*.pdf`
- 自动补齐缺失文章页（`articles/article-xxxxxxxx.html`）
- 自动补齐 `running.html` 中缺失的文章入口
- 文章标题默认使用 PDF 文件名（不含扩展名）

### 运行命令

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-articles.ps1
```

### 预览模式（不写文件）

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-articles.ps1 -DryRun
```
