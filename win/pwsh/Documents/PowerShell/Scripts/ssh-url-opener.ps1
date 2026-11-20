# Opens http(s) URLs sent from ssh'd-into hosts in the default Windows browser.
# Remote side: dots/scripts/open-local ($BROWSER / xdg-open there) writes "URL\n" to a
# Unix socket that ~/.ssh/config RemoteForwards to 127.0.0.1:47213 here. Started
# hidden by Invoke-Ssh in the pwsh profile; one instance per login session (mutex).
# Loopback only, and anything that isn't a single absolute http(s) URL is rejected,
# so the most a sender can do is open a web page.
$ErrorActionPreference = 'Stop'
$port = 47213
$mutex = [Threading.Mutex]::new($false, 'Local\ssh-url-opener')
if (-not $mutex.WaitOne(0)) { exit }

$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $port)
$listener.Start()
$utf8 = [Text.UTF8Encoding]::new($false)
while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
        $client.ReceiveTimeout = 2000
        $client.SendTimeout = 2000
        $stream = $client.GetStream()
        $reader = [IO.StreamReader]::new($stream, $utf8)
        $sb = [Text.StringBuilder]::new()
        while ($sb.Length -le 8192) {
            $ch = $reader.Read()
            if ($ch -lt 0 -or $ch -eq 10) { break }
            [void]$sb.Append([char]$ch)
        }
        $text = $sb.ToString().Trim()
        $uri = $null
        $ok = $sb.Length -le 8192 -and $text -match '^\S+$' -and
              [Uri]::TryCreate($text, [UriKind]::Absolute, [ref]$uri) -and
              $uri.Scheme -in 'http', 'https'
        if ($ok) { Start-Process $uri.AbsoluteUri }
        $reply = $utf8.GetBytes($(if ($ok) { "ok`n" } else { "rejected`n" }))
        $stream.Write($reply, 0, $reply.Length)
    } catch {
        # one bad or slow sender shouldn't take the listener down
    } finally {
        $client.Close()
    }
}
