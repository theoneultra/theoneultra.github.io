param(
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Escape-Html {
  param([string]$Text)
  if ($null -eq $Text) { return "" }
  return $Text.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;").Replace("'", "&#39;")
}

function Get-ShortHash {
  param([string]$Text)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  $sha1 = [System.Security.Cryptography.SHA1]::Create()
  try {
    $hash = $sha1.ComputeHash($bytes)
  } finally {
    $sha1.Dispose()
  }

  $hex = [System.BitConverter]::ToString($hash).Replace("-", "").ToLowerInvariant()
  return $hex.Substring(0, 8)
}

function Build-ArticleHtml {
  param(
    [string]$Title,
    [string]$PdfEncoded
  )

  $titleHtml = Escape-Html $Title
  $descHtml = Escape-Html "$Title - 文章与 PDF"
  $iframeTitle = Escape-Html "$Title PDF"

  return @"
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$titleHtml | theoneultra</title>
  <meta name="description" content="$descHtml" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Libre+Baskerville:wght@400;700&family=Noto+Sans+SC:wght@400;500;700&display=swap" rel="stylesheet" />
  <link rel="stylesheet" href="../styles/site.css" />
</head>
<body>
  <div class="bg-canvas" aria-hidden="true"></div>
  <div class="bg-grid" aria-hidden="true"></div>
  <div class="bg-aurora bg-aurora-a" aria-hidden="true"></div>
  <div class="bg-aurora bg-aurora-b" aria-hidden="true"></div>

  <div class="site-shell">
    <header class="gov-header">
      <div class="container header-row">
        <a class="brand" href="../index.html">THEONEULTRA.GITHUB.IO</a>
        <nav class="main-nav" aria-label="主导航">
          <a href="../index.html">Home</a>
          <a href="../running.html" class="active">Articles</a>
        </nav>
      </div>
    </header>

    <main class="container reveal">
      <article class="article-card">
        <p class="kicker">Article</p>
        <h1 class="headline-gradient">$titleHtml</h1>
        <p>这篇文章已内嵌在线预览，可直接滚动阅读，也可下载保存。</p>

        <div class="hero-actions">
          <a class="btn" href="$PdfEncoded" download>下载 PDF</a>
        </div>
        <p class="resize-tip">可拖动预览区域右下角，调整 PDF 视窗大小。</p>

        <div class="pdf-wrap">
          <iframe src="$PdfEncoded" title="$iframeTitle"></iframe>
        </div>
      </article>
    </main>

    <footer class="gov-footer">
      <div class="container footer-row">
        <span>Copyright © 2026 theoneultra. All rights reserved.</span>
        <span>未经授权，禁止转载或用于商业用途。</span>
      </div>
    </footer>
  </div>

  <script src="../scripts/site.js"></script>
</body>
</html>
"@
}

function Build-RunningEntry {
  param(
    [string]$PageFile,
    [string]$Title
  )

  $titleHtml = Escape-Html $Title
  $pageHref = Escape-Html "articles/$PageFile"

  return @(
    "        <a class=""article-link"" href=""$pageHref"">"
    "          <span class=""article-title"">$titleHtml</span>"
    "          <span class=""article-meta"">查看文章与 PDF</span>"
    "        </a>"
  ) -join "`r`n"
}

function Get-PagePdfName {
  param([string]$HtmlPath)
  $content = Get-Content -Raw -Path $HtmlPath
  $match = [regex]::Match($content, '<iframe[^>]*\ssrc="([^"]+\.pdf)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  if (-not $match.Success) {
    return $null
  }

  $src = $match.Groups[1].Value
  $decoded = [System.Uri]::UnescapeDataString($src)
  $pdfName = [System.IO.Path]::GetFileName($decoded)
  if ([string]::IsNullOrWhiteSpace($pdfName)) {
    return $null
  }
  return $pdfName
}

function Is-GeneratedPageName {
  param([string]$PageName)
  return [bool]($PageName -match '^article-[0-9a-f]{8}(-\d+)?\.html$')
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$articlesDir = Join-Path $repoRoot "articles"
$runningPath = Join-Path $repoRoot "running.html"

if (-not (Test-Path $articlesDir)) {
  throw "未找到 articles 目录: $articlesDir"
}
if (-not (Test-Path $runningPath)) {
  throw "未找到 running.html: $runningPath"
}

$pdfFiles = @(Get-ChildItem -Path $articlesDir -File -Filter *.pdf | Sort-Object LastWriteTime -Descending)
$pdfLookup = @{}
foreach ($pdf in $pdfFiles) {
  $pdfLookup[$pdf.Name] = $true
}

$htmlFiles = @(Get-ChildItem -Path $articlesDir -File -Filter *.html)
$pageInfos = @()
foreach ($html in $htmlFiles) {
  $pdfName = Get-PagePdfName -HtmlPath $html.FullName
  if ($null -eq $pdfName) { continue }
  $pageInfos += [pscustomobject]@{
    PageName = $html.Name
    PagePath = $html.FullName
    PdfName = $pdfName
  }
}

# Phase 1: delete extras
$deletedPages = @()
foreach ($info in $pageInfos) {
  if ($pdfLookup.ContainsKey($info.PdfName)) { continue }
  if (-not $DryRun) {
    Remove-Item -LiteralPath $info.PagePath -Force
  }
  $deletedPages += $info.PageName
}

$validInfos = @()
foreach ($info in $pageInfos) {
  if ($pdfLookup.ContainsKey($info.PdfName)) {
    $validInfos += $info
  }
}

$pdfToPages = @{}
foreach ($info in $validInfos) {
  if (-not $pdfToPages.ContainsKey($info.PdfName)) {
    $pdfToPages[$info.PdfName] = New-Object System.Collections.ArrayList
  }
  [void]$pdfToPages[$info.PdfName].Add($info.PageName)
}

$resolvedPages = @{}
$createdPages = @()

foreach ($pdf in $pdfFiles) {
  $pdfName = $pdf.Name
  $title = [System.IO.Path]::GetFileNameWithoutExtension($pdfName)
  $pdfEncoded = [System.Uri]::EscapeDataString($pdfName)

  if ($pdfToPages.ContainsKey($pdfName) -and $pdfToPages[$pdfName].Count -gt 0) {
    $selected = @($pdfToPages[$pdfName] | Sort-Object `
      @{ Expression = { if (Is-GeneratedPageName $_) { 1 } else { 0 } } }, `
      @{ Expression = { $_ } })[0]
    $resolvedPages[$pdfName] = $selected
    continue
  }

  $hash = Get-ShortHash $pdfName
  $pageFile = "article-$hash.html"
  $index = 1
  while (Test-Path (Join-Path $articlesDir $pageFile)) {
    $pageFile = "article-$hash-$index.html"
    $index += 1
  }

  $pagePath = Join-Path $articlesDir $pageFile
  $pageHtml = Build-ArticleHtml -Title $title -PdfEncoded $pdfEncoded

  if (-not $DryRun) {
    Set-Content -Path $pagePath -Value $pageHtml -Encoding utf8
  }

  $resolvedPages[$pdfName] = $pageFile
  $createdPages += $pageFile
}

$runningContent = Get-Content -Raw -Path $runningPath
$sectionPattern = '(?s)(<section class="article-list reveal delay-1" aria-label="文章列表">\r?\n)(.*?)(\r?\n[ \t]*</section>)'
$sectionMatch = [regex]::Match($runningContent, $sectionPattern)
if (-not $sectionMatch.Success) {
  throw "未能在 running.html 中定位文章列表区域。"
}

$existingInner = $sectionMatch.Groups[2].Value
$existingEntryCount = [regex]::Matches($existingInner, '<a class="article-link" href="[^"]+">').Count

# Phase 1.5: clear running entries (delete first)
$clearedRunning = [regex]::Replace(
  $runningContent,
  $sectionPattern,
  { param($m) $m.Groups[1].Value + $m.Groups[3].Value },
  1
)

# Phase 2: add current entries
$entries = New-Object System.Collections.ArrayList
foreach ($pdf in $pdfFiles) {
  $title = [System.IO.Path]::GetFileNameWithoutExtension($pdf.Name)
  $pageFile = $resolvedPages[$pdf.Name]
  [void]$entries.Add((Build-RunningEntry -PageFile $pageFile -Title $title))
}

$entryBlock = ""
if ($entries.Count -gt 0) {
  $normalizedEntries = @($entries | ForEach-Object { $_.TrimEnd() })
  $entryBlock = ($normalizedEntries -join "`r`n")
}

$finalRunning = [regex]::Replace(
  $clearedRunning,
  $sectionPattern,
  { param($m) $m.Groups[1].Value + $entryBlock + $m.Groups[3].Value },
  1
)
$finalRunning = $finalRunning.TrimEnd() + "`r`n"

if (-not $DryRun) {
  Set-Content -Path $runningPath -Value $finalRunning -Encoding utf8
}

Write-Output "扫描完成: $($pdfFiles.Count) 个 PDF"
Write-Output "删除多余文章页: $($deletedPages.Count)"
foreach ($page in $deletedPages) {
  Write-Output "  - $page"
}
Write-Output "新建文章页: $($createdPages.Count)"
foreach ($page in $createdPages) {
  Write-Output "  + $page"
}
Write-Output "running 旧入口已清空: $existingEntryCount"
Write-Output "running 新入口已写入: $($entries.Count)"

if ($DryRun) {
  Write-Output "DryRun 模式：未写入任何文件。"
}
