$rootPath = "d:\ai_future_competition"
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()
Write-Host "Server started at http://localhost:8080/"
Write-Host "Root path: $rootPath"
Write-Host "Press Ctrl+C to stop"

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    
    $url = $request.Url.LocalPath
    if ($url -eq "/") { $url = "/index.html" }
    
    $filePath = Join-Path $rootPath $url.TrimStart("/")
    
    if (Test-Path $filePath -PathType Leaf) {
        try {
            $content = Get-Content $filePath -Raw -Encoding UTF8
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
            
            $response.ContentLength64 = $buffer.Length
            
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            switch ($ext) {
                ".html" { $response.ContentType = "text/html; charset=utf-8" }
                ".css" { $response.ContentType = "text/css; charset=utf-8" }
                ".js" { $response.ContentType = "application/javascript; charset=utf-8" }
                default { $response.ContentType = "application/octet-stream" }
            }
            
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            Write-Host "Served: $filePath"
        } catch {
            Write-Host "Error reading $filePath : $_"
            $response.StatusCode = 500
        }
    } else {
        Write-Host "Not found: $filePath"
        $response.StatusCode = 404
        $notFound = [System.Text.Encoding]::UTF8.GetBytes("<h1>404 Not Found</h1><p>$filePath</p>")
        $response.ContentLength64 = $notFound.Length
        $response.ContentType = "text/html"
        $response.OutputStream.Write($notFound, 0, $notFound.Length)
    }
    
    $response.Close()
}

$listener.Stop()