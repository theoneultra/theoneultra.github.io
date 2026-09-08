[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ $_ -notmatch "[\r\n]" })]
  [string]$Title,

  [Parameter(Mandatory = $true)]
  [ValidateLength(1, 80)]
  [ValidatePattern('(?-i)^[a-z0-9]+(?:-[a-z0-9]+)*$')]
  [string]$Slug,

  [ValidateSet('science', 'life', 'review', 'fiction')]
  [string]$Category = 'science',

  [switch]$Open
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$postsPath = Join-Path $projectRoot '_posts'
$templatePath = Join-Path $projectRoot 'templates/post.md'
$now = [DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(8))
$fileName = $now.ToString('yyyy-MM-dd') + '-' + $Slug + '.md'
$postPath = Join-Path $postsPath $fileName

if (Test-Path -LiteralPath $postPath) {
  throw "Article already exists: $postPath. Choose another slug."
}

$lines = (Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8) -split '\r?\n'
if ($lines[0] -ne '---') {
  throw 'The post template must begin with YAML front matter.'
}

for ($lineIndex = 1; $lineIndex -lt $lines.Length; $lineIndex++) {
  if ($lines[$lineIndex] -eq '---') { break }
  if ($lines[$lineIndex] -match '^title:') {
    $lines[$lineIndex] = "title: '" + $Title.Replace("'", "''") + "'"
  }
  elseif ($lines[$lineIndex] -match '^date:') {
    $lines[$lineIndex] = 'date: ' + $now.ToString('yyyy-MM-dd HH:mm:ss') + ' +0800'
  }
  elseif ($lines[$lineIndex] -match '^category:') {
    $lines[$lineIndex] = 'category: ' + $Category.ToLowerInvariant()
  }
}

$null = New-Item -ItemType Directory -Path $postsPath -Force
$content = ($lines -join "`n").TrimEnd() + "`n"
$bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($content)
$stream = [System.IO.File]::Open($postPath, [System.IO.FileMode]::CreateNew)
try {
  $stream.Write($bytes, 0, $bytes.Length)
}
finally {
  $stream.Dispose()
}

Write-Host "Created draft: $postPath"
Write-Host 'Add your text and cover image. Set published: true when ready to publish.'
if ($Open) {
  $editor = Get-Command code -ErrorAction SilentlyContinue
  if ($editor) {
    & $editor.Source --reuse-window $postPath
  }
  else {
    Write-Host 'Open the new Markdown file in VS Code to begin writing.'
  }
}
