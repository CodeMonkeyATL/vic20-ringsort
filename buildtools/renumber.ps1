param(
    [Parameter(Mandatory = $true)]
    [string]$BasFile,
    # where routines start: "old=new,old=new,..."; every other line follows the line before it by -Step
    [Parameter(Mandatory = $true)]
    [string]$Plan,
    [int]$Step = 10,
    # write here instead of over the source
    [string]$OutFile
)

# renumbers a petcat source file without changing its order: the lines named in -Plan get their new numbers,
# the rest follow at -Step, and every goto, gosub, then, on ... goto/gosub list (and BASIC 3.5's else, trap,
# resume, restore) is rewritten to match. Jumps are found with the same tokenizer as check-basic.ps1, so
# strings and rems are left alone. It refuses a plan that would reorder lines (fall-through and the speed of
# a jump depend on the order), push a line past 63999, or leave a jump to a line that doesn't exist.
# Prints the old -> new map, for updating the docs.
. (Join-Path $PSScriptRoot 'basic-tokens.ps1')
. (Join-Path $PSScriptRoot 'machine.ps1')
if ((Get-MachineForFile $BasFile).Basic -eq '3.5') { Use-Basic35 }

$planMap = @{}
foreach ($pair in ($Plan -split ',')) {
    if ($pair.Trim() -eq '') { continue }
    $parts = $pair -split '='
    if ($parts.Count -ne 2) { throw "renumber: bad plan entry '$pair' (expected old=new)" }
    $planMap[[int]$parts[0].Trim()] = [int]$parts[1].Trim()
}

$bytes = [System.IO.File]::ReadAllBytes($BasFile)
$crlf = [System.Text.Encoding]::ASCII.GetString($bytes).Contains("`r`n")
$lines = [System.IO.File]::ReadAllLines($BasFile)

# the new number of every numbered line (a typed dictionary: an [ordered] hashtable indexed by an int
# takes it as a position, not a key), and the old numbers in file order
$map = New-Object 'System.Collections.Generic.Dictionary[int,int]'
$order = New-Object System.Collections.Generic.List[int]
$last = -1
foreach ($raw in $lines) {
    if ($raw -notmatch '^\s*(\d+)') { continue }
    $old = [int]$Matches[1]
    if ($map.ContainsKey($old)) { throw "renumber: line $old appears twice" }
    $order.Add($old)
    $new = if ($planMap.ContainsKey($old)) { $planMap[$old] } else { $last + $Step }
    if ($last -ge 0 -and $new -le $last) {
        throw "renumber: line $old would become $new, not after the line before it ($last); the order can't change"
    }
    if ($new -gt 63999) { throw "renumber: line $old would become $new, past 63999" }
    $map[$old] = $new
    $last = $new
}
foreach ($k in $planMap.Keys) {
    if (-not $map.ContainsKey($k)) { throw "renumber: the plan names line $k, which doesn't exist" }
}

$jumpWords = @('goto', 'gosub', 'then', 'else', 'trap', 'resume', 'restore')

# rewrites the numbers after a jump keyword: a number, or a list of them for on ... goto/gosub
function Convert-Text([string]$text, [int]$lineNo) {
    $tokens = Get-Tokens $text
    $sb = New-Object System.Text.StringBuilder
    $i = 0
    while ($i -lt $tokens.Count) {
        $t = $tokens[$i]
        [void]$sb.Append($t.Text)
        $i++
        if ($t.Type -ne 'kw') { continue }
        if ($t.Text -eq 'go') {
            # "go to": the two keywords, possibly with spaces between
            $j = $i
            while ($j -lt $tokens.Count -and $tokens[$j].Type -eq 'ch' -and $tokens[$j].Text -eq ' ') { $j++ }
            if (-not ($j -lt $tokens.Count -and $tokens[$j].Type -eq 'kw' -and $tokens[$j].Text -eq 'to')) { continue }
            while ($i -le $j) { [void]$sb.Append($tokens[$i].Text); $i++ }
        } elseif ($jumpWords -notcontains $t.Text) {
            continue
        }
        # a list of numbers: digits, with spaces and commas between
        while ($i -lt $tokens.Count) {
            while ($i -lt $tokens.Count -and $tokens[$i].Type -eq 'ch' -and $tokens[$i].Text -eq ' ') {
                [void]$sb.Append(' '); $i++
            }
            $digits = ''
            while ($i -lt $tokens.Count -and $tokens[$i].Type -eq 'ch' -and $tokens[$i].Text -match '^\d$') {
                $digits += $tokens[$i].Text; $i++
            }
            if ($digits -eq '') { break }
            $target = [int]$digits
            if (-not $map.ContainsKey($target)) { throw "renumber: line $lineNo jumps to $target, which doesn't exist" }
            [void]$sb.Append($map[$target])
            $j = $i
            while ($j -lt $tokens.Count -and $tokens[$j].Type -eq 'ch' -and $tokens[$j].Text -eq ' ') { $j++ }
            if ($j -lt $tokens.Count -and $tokens[$j].Type -eq 'ch' -and $tokens[$j].Text -eq ',') {
                while ($i -le $j) { [void]$sb.Append($tokens[$i].Text); $i++ }
                continue
            }
            break
        }
    }
    return $sb.ToString()
}

$out = New-Object System.Collections.Generic.List[string]
foreach ($raw in $lines) {
    if ($raw -match '^(\s*)(\d+)(\s?)(.*)$') {
        $old = [int]$Matches[2]
        $out.Add($Matches[1] + $map[$old] + $Matches[3] + (Convert-Text $Matches[4] $old))
    } else {
        $out.Add($raw)
    }
}

$target = if ($OutFile) { $OutFile } else { $BasFile }
$eol = if ($crlf) { "`r`n" } else { "`n" }
[System.IO.File]::WriteAllText($target, (($out -join $eol) + $eol), [System.Text.Encoding]::ASCII)

foreach ($k in $order) {
    if ($k -ne $map[$k]) { "{0} -> {1}" -f $k, $map[$k] }
}
