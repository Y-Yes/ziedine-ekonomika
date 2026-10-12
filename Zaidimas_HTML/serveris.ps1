# Small local web server for the HTML5 build of "Ziedine ekonomika".
# Browsers do not allow WebAssembly games to run from file://, so this script
# serves this folder on http://localhost and opens the game in the browser.
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# The engine file is stored compressed to keep the folder small -
# unpack it once on the first run.
$wasm = Join-Path $root "index.wasm"
$gz = Join-Path $root "index.wasm.gz"
if (-not (Test-Path $wasm) -and (Test-Path $gz)) {
    Write-Host "Ruosiamas zaidimas (tik pirma karta)..."
    $in = [IO.File]::OpenRead($gz)
    $out = [IO.File]::Create($wasm)
    $unzip = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress)
    $unzip.CopyTo($out)
    $unzip.Close(); $out.Close(); $in.Close()
}

$mime = @{
    ".html" = "text/html; charset=utf-8"; ".js" = "application/javascript";
    ".wasm" = "application/wasm"; ".pck" = "application/octet-stream";
    ".png" = "image/png"; ".ico" = "image/x-icon"; ".json" = "application/json";
    ".svg" = "image/svg+xml"
}

# Find a free port
$listener = $null
$port = 0
foreach ($p in 8060..8090) {
    try {
        $l = New-Object System.Net.HttpListener
        $l.Prefixes.Add("http://localhost:$p/")
        $l.Start()
        $listener = $l
        $port = $p
        break
    } catch { }
}
if ($null -eq $listener) { Write-Host "Nepavyko paleisti serverio."; exit 1 }

$url = "http://localhost:$port/index.html"
Write-Host ""
Write-Host "Zaidimas veikia: $url"
Write-Host "Kai baigsi zaisti - uzdaryk si langa."
Start-Process $url

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
        if ($path -eq "") { $path = "index.html" }
        $file = [IO.Path]::GetFullPath((Join-Path $root $path))
        if ($file.StartsWith($root) -and (Test-Path $file -PathType Leaf)) {
            $bytes = [IO.File]::ReadAllBytes($file)
            $ext = [IO.Path]::GetExtension($file).ToLower()
            if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] }
            else { $ctx.Response.ContentType = "application/octet-stream" }
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
        }
        $ctx.Response.Close()
    } catch { }
}
