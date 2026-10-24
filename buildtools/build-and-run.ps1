param(
    [Parameter(Mandatory = $true)]
    [string]$BasFile,
    [string]$PrgName
)
if ([System.IO.Path]::GetExtension($BasFile) -ne '.bas') {
    Write-Host 'Open a .bas file in the editor, then run Build.'
    exit 1
}

if (-not $PrgName) {
    $PrgName = [System.IO.Path]::GetFileNameWithoutExtension($BasFile)
}

$root = Split-Path -Parent $PSScriptRoot
$prgs = Join-Path $root 'prgs'
New-Item -ItemType Directory -Force -Path $prgs | Out-Null
$prg = Join-Path $prgs $PrgName

& petcat.exe -w2 -l 1001 -o $prg $BasFile
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

function Try-ViceAutostart([string]$prgPath) {
    $client = $null
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect('127.0.0.1', 6510)
        $stream = $client.GetStream()
        $unix = $prgPath -replace '\\', '/'
        $bytes = [System.Text.Encoding]::ASCII.GetBytes("autostart `"$unix`"`n")
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()

        # wait for xvic to confirm; a wedged monitor accepts the connection but never answers
        $reply = ''
        $buffer = New-Object byte[] 4096
        $deadline = [DateTime]::Now.AddSeconds(2)
        while ([DateTime]::Now -lt $deadline -and $reply -notmatch 'autostarting') {
            if ($stream.DataAvailable) {
                $count = $stream.Read($buffer, 0, $buffer.Length)
                $reply += [System.Text.Encoding]::ASCII.GetString($buffer, 0, $count)
            } else {
                Start-Sleep -Milliseconds 50
            }
        }
        return $reply -match 'autostarting'
    } catch {
        return $false
    } finally {
        if ($client) {
            $client.Close()
        }
    }
}

if (Try-ViceAutostart $prg) {
    Write-Host "Autostarted in running xvic: $prg"
    exit 0
}

$stale = Get-Process -Name xvic -ErrorAction SilentlyContinue
if ($stale) {
    Write-Host 'xvic remote monitor did not respond on 127.0.0.1:6510; restarting xvic.'
    $stale | Stop-Process -Force
    $stale | Wait-Process -Timeout 5 -ErrorAction SilentlyContinue
}

Start-Process xvic.exe -ArgumentList '-memory', 'none', '-keymap', '0', '-remotemonitor', '-autostart', $prg
Write-Host "Started xvic with remote monitor: $prg"
