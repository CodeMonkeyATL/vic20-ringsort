param(
    [Parameter(Mandatory = $true)]
    [string]$BasFile
)

# checks a petcat source file against the BASIC guidelines (meta repo, docs/basic-guidelines.md) and prints warnings;
# it never fails the build, so it always exits 0
# the longest editable line depends on the machine, which the file name picks (see machine.ps1)
. (Join-Path $PSScriptRoot 'machine.ps1')
$machine = Get-MachineForFile $BasFile
$maxListed = $machine.MaxListed

# the keyword lists and Get-Tokens (the tokenizer) are shared with strip-rems.ps1
. (Join-Path $PSScriptRoot 'basic-tokens.ps1')
if ($machine.Basic -eq '3.5') { Use-Basic35 }

# finds keywords that ended up where no keyword belongs, the sign that a variable name ran into a keyword
# (tand7 is TAN d7, fori=stop has STOP, x=pto9 has TO); returns one message per problem
function Find-KeywordProblems($tokens, [string]$text) {
    $problems = New-Object System.Collections.Generic.List[string]
    $atStart = $true      # the next token begins a statement
    $statement = ''       # the statement's first keyword
    $seenIf = $false
    $seenOn = $false
    for ($t = 0; $t -lt $tokens.Count; $t++) {
        $tok = $tokens[$t]
        $next = if ($t + 1 -lt $tokens.Count) { $tokens[$t + 1] } else { $null }
        if ($tok.Type -eq 'ch' -and $tok.Text -eq ':') {
            $atStart = $true
            $statement = ''
            $seenIf = $false
            $seenOn = $false
            continue
        }
        if ($tok.Type -eq 'ch' -and $tok.Text -eq '?') {
            $problems.Add("'?' outside a string: petcat doesn't turn it into print, so the VIC sees a plain '?'; write print")
        }
        if ($tok.Type -ne 'kw') {
            $atStart = $false
            continue
        }
        $kw = $tok.Text
        # the source around the keyword, to show where it came from
        $from = [Math]::Max(0, $tok.Pos - 4)
        $context = $text.Substring($from, [Math]::Min($text.Length, $tok.Pos + $kw.Length + 4) - $from)
        $name = $kw.ToUpperInvariant()

        $previousKw = if ($t -gt 0 -and $tokens[$t - 1].Type -eq 'kw') { $tokens[$t - 1].Text } else { '' }
        if ($statementWords -contains $kw) {
            # goto/gosub/go may follow "if x" or "on x"; any other statement keyword must start a statement,
            # except BASIC 3.5's getkey (GET KEY) and resume next (RESUME NEXT), which are two tokens
            $allowed = $atStart -or (($kw -in @('goto', 'gosub', 'go')) -and ($seenIf -or $seenOn)) -or
                ($kw -eq 'key' -and $previousKw -eq 'get') -or ($kw -eq 'next' -and $previousKw -eq 'resume')
            if (-not $allowed) {
                $problems.Add("$name inside a statement ('$context'); a name probably ran into a keyword")
            }
            if ($atStart) { $statement = $kw }
            if ($kw -eq 'go' -and -not ($null -ne $next -and $next.Type -eq 'kw' -and $next.Text -eq 'to')) {
                $problems.Add("GO not followed by to ('$context'); a name probably ran into a keyword")
            }
        } elseif ($functionWords -contains $kw) {
            if (-not ($null -ne $next -and $next.Type -eq 'ch' -and $next.Text -eq '(')) {
                $problems.Add("$name not followed by '(' ('$context'); a name probably ran into a keyword")
            }
        } elseif ($kw -eq 'to' -and $statement -notin @('for', 'draw', 'copy', 'rename', 'backup') -and $previousKw -ne 'go') {
            # BASIC 3.5's draw, copy, rename and backup take a TO too
            $problems.Add("TO outside a for statement ('$context'); a name probably ran into a keyword")
        } elseif ($kw -eq 'using' -and $statement -notin @('print', 'print#')) {
            $problems.Add("USING outside a print statement ('$context'); a name probably ran into a keyword")
        } elseif ($kw -in @('while', 'until') -and $statement -notin @('do', 'loop')) {
            $problems.Add("$name outside a do or loop statement ('$context'); a name probably ran into a keyword")
        } elseif ($kw -eq 'step' -and $statement -ne 'for') {
            $problems.Add("STEP outside a for statement ('$context'); a name probably ran into a keyword")
        } elseif ($kw -eq 'then' -and -not $seenIf) {
            $problems.Add("THEN without if ('$context'); a name probably ran into a keyword")
        } elseif ($kw -eq 'fn' -and -not ($null -ne $next -and $next.Type -eq 'ch' -and $next.Text -match '^[a-z]$')) {
            $problems.Add("FN not followed by a function name ('$context'); a name probably ran into a keyword")
        }

        if ($kw -eq 'if') { $seenIf = $true }
        if ($kw -eq 'on') { $seenOn = $true }
        if ($kw -in @('then', 'else')) {
            # what follows then (or BASIC 3.5's else) is a new statement (or a line number)
            $atStart = $true
            $statement = ''
            $seenIf = $false
            $seenOn = $false
            continue
        }
        $atStart = $false
    }
    return , $problems
}

$warnings = New-Object System.Collections.Generic.List[string]
function Warn([int]$srcLine, [string]$label, [string]$message) {
    $warnings.Add(("{0}:{1}: line {2}: {3}" -f (Split-Path -Leaf $BasFile), $srcLine, $label, $message))
}

$lines = [System.IO.File]::ReadAllLines($BasFile)
$numbers = @{}
$targets = New-Object System.Collections.Generic.List[object]
# lines that hold only a rem: strip-rems.ps1 drops them from the build, so nothing may jump to them
$remOnly = @{}
$previous = -1

for ($n = 0; $n -lt $lines.Length; $n++) {
    $srcLine = $n + 1
    $raw = $lines[$n]
    if ($raw.Trim() -eq '') {
        continue
    }

    if ($raw -match '^\s*(\d+)\s?(.*)$') {
        $number = [int]$Matches[1]
        $text = $Matches[2]
    } else {
        # petcat numbers an unnumbered line as the previous line + 2
        $number = $previous + 2
        $text = $raw.Trim()
        Warn $srcLine $number 'unnumbered line; petcat numbers it previous + 2'
    }
    $label = [string]$number

    if ($numbers.ContainsKey($number)) {
        Warn $srcLine $label ("duplicate line number (also source line {0}); petcat keeps both, but the VIC editor can't" -f $numbers[$number])
    } elseif ($number -le $previous) {
        Warn $srcLine $label ("line number not above the previous line ({0})" -f $previous)
    }
    $numbers[$number] = $srcLine
    $previous = $number

    $tokens = Get-Tokens $text
    if ($tokens.Count -gt 0 -and $tokens[0].Type -eq 'kw' -and $tokens[0].Text -eq 'rem') {
        $remOnly[$number] = $true
    }

    # the VIC lists "<number> <text>", with each petcat {code} as one character; the build strips the rem
    # (strip-rems.ps1), so only the code before it counts
    $listedText = $text
    $remToken = $tokens | Where-Object { $_.Type -eq 'kw' -and $_.Text -eq 'rem' } | Select-Object -First 1
    if ($null -ne $remToken) {
        $listedText = $text.Substring(0, $remToken.Pos).TrimEnd().TrimEnd(':')
    }
    $listed = $label.Length + 1 + ($listedText -replace '\{[^}]*\}', 'x').Length
    if ($listedText -ne '' -and $listed -gt $maxListed) {
        Warn $srcLine $label ("{0} characters as listed (limit {1})" -f $listed, $maxListed)
    }
    foreach ($p in (Find-KeywordProblems $tokens $text)) {
        Warn $srcLine $label $p
    }

    # the code part: strings and rem text removed, including quoted strings among the data items
    $code = -join ($tokens | Where-Object { $_.Type -in @('kw', 'ch', 'data') } | ForEach-Object { $_.Text -replace '"[^"]*"?', '' })
    $spaces = ($code.ToCharArray() | Where-Object { $_ -eq ' ' }).Count
    if ($spaces -gt 0) {
        Warn $srcLine $label ("{0} space(s) outside strings" -f $spaces)
    }

    foreach ($t in (Get-JumpTargets $tokens)) {
        $targets.Add([pscustomobject]@{ Target = $t; SrcLine = $srcLine; Label = $label })
    }
}

foreach ($t in $targets) {
    if (-not $numbers.ContainsKey($t.Target)) {
        Warn $t.SrcLine $t.Label ("jumps to line {0}, which doesn't exist" -f $t.Target)
    } elseif ($remOnly.ContainsKey($t.Target)) {
        Warn $t.SrcLine $t.Label ("jumps to line {0}, which holds only a rem; the build keeps it as a bare rem (6 bytes), so put the rem at the end of the routine's first code line" -f $t.Target)
    }
}

foreach ($w in $warnings) {
    Write-Host "warning: $w"
}
Write-Host ("check-basic: {0} warning(s) in {1}" -f $warnings.Count, (Split-Path -Leaf $BasFile))
exit 0
