$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8080
$url = "http://localhost:$port/"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
try {
  $listener.Start()
} catch {
  Write-Host "Could not start the server on port $port. Is it already running? Try opening $url in your browser."
  Read-Host "Press Enter to close"
  exit
}

Write-Host "Serving $dir at $url"
Write-Host "Opening your browser... close this window to stop the server."
Start-Process "$($url)index.html"

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $rel = $ctx.Request.Url.LocalPath.TrimStart('/')
  if ($rel -eq '') { $rel = 'index.html' }
  $path = Join-Path $dir $rel
  if (Test-Path $path -PathType Leaf) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $ext = [System.IO.Path]::GetExtension($path).ToLower()
    $ctx.Response.ContentType = switch ($ext) {
      ".html" { "text/html; charset=utf-8" }
      ".css"  { "text/css" }
      ".js"   { "application/javascript" }
      default { "application/octet-stream" }
    }
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $ctx.Response.StatusCode = 404
  }
  $ctx.Response.OutputStream.Close()
}
