# the BASIC V2 tokenizer shared by check-basic.ps1 and strip-rems.ps1: dot-source it

# BASIC V2 keywords in token order ($80 upward); the tokenizer takes the first one in this order that matches
# at the current position, so input# is tried before input, and go (last) only when goto doesn't match
$keywords = @(
    'end', 'for', 'next', 'data', 'input#', 'input', 'dim', 'read', 'let', 'goto', 'run', 'if', 'restore', 'gosub',
    'return', 'rem', 'stop', 'on', 'wait', 'load', 'save', 'verify', 'def', 'poke', 'print#', 'print', 'cont', 'list',
    'clr', 'cmd', 'sys', 'open', 'close', 'get', 'new', 'tab(', 'to', 'fn', 'spc(', 'then', 'not', 'step',
    '+', '-', '*', '/', '^', 'and', 'or', '>', '=', '<',
    'sgn', 'int', 'abs', 'usr', 'fre', 'pos', 'sqr', 'rnd', 'log', 'exp', 'cos', 'sin', 'tan', 'atn', 'peek', 'len',
    'str$', 'val', 'asc', 'chr$', 'left$', 'right$', 'mid$', 'go'
)
# keywords that begin a statement, and functions, which must be followed by "("
$statementWords = @('end', 'for', 'next', 'data', 'input#', 'input', 'dim', 'read', 'let', 'goto', 'run', 'if',
    'restore', 'gosub', 'return', 'rem', 'stop', 'on', 'wait', 'load', 'save', 'verify', 'def', 'poke', 'print#',
    'print', 'cont', 'list', 'clr', 'cmd', 'sys', 'open', 'close', 'get', 'new', 'go')
$functionWords = @('sgn', 'int', 'abs', 'usr', 'fre', 'pos', 'sqr', 'rnd', 'log', 'exp', 'cos', 'sin', 'tan', 'atn',
    'peek', 'len', 'str$', 'val', 'asc', 'chr$', 'left$', 'right$', 'mid$')

# the Plus/4's BASIC 3.5 keeps V2's tokens and adds these, in token order ($CC upward), searched after V2's
# (the list petcat -k3 prints). Call it once, after dot-sourcing this file, for a BASIC 3.5 program.
function Use-Basic35 {
    $script:keywords += @(
        'rgr', 'rclr', 'rlum', 'joy', 'rdot', 'dec', 'hex$', 'err$', 'instr', 'else', 'resume', 'trap', 'tron',
        'troff', 'sound', 'vol', 'auto', 'pudef', 'graphic', 'paint', 'char', 'box', 'circle', 'gshape', 'sshape',
        'draw', 'locate', 'color', 'scnclr', 'scale', 'help', 'do', 'loop', 'exit', 'directory', 'dsave', 'dload',
        'header', 'scratch', 'collect', 'copy', 'rename', 'backup', 'delete', 'renumber', 'key', 'monitor',
        'using', 'until', 'while'
    )
    # using, until and while only follow print, do or loop; check-basic.ps1 checks them on their own
    $script:statementWords += @('else', 'resume', 'trap', 'tron', 'troff', 'sound', 'vol', 'auto', 'pudef',
        'graphic', 'paint', 'char', 'box', 'circle', 'gshape', 'sshape', 'draw', 'locate', 'color', 'scnclr',
        'scale', 'help', 'do', 'loop', 'exit', 'directory', 'dsave', 'dload', 'header', 'scratch', 'collect',
        'copy', 'rename', 'backup', 'delete', 'renumber', 'key', 'monitor')
    $script:functionWords += @('rgr', 'rclr', 'rlum', 'joy', 'rdot', 'dec', 'hex$', 'err$', 'instr')
}

# splits a line's text the way petcat and the VIC tokenize it: keywords (kw), other characters (ch),
# strings (str, with quotes), and the text after rem or data, which isn't tokenized (rem, data; data runs to ":")
function Get-Tokens([string]$text) {
    $tokens = New-Object System.Collections.Generic.List[object]
    $lower = $text.ToLowerInvariant()
    $i = 0
    while ($i -lt $text.Length) {
        $ch = $text[$i]
        if ($ch -eq '"') {
            $end = $text.IndexOf('"', $i + 1)
            if ($end -lt 0) { $end = $text.Length - 1 }
            $tokens.Add([pscustomobject]@{ Type = 'str'; Text = $text.Substring($i, $end - $i + 1); Pos = $i })
            $i = $end + 1
            continue
        }
        if ($ch -eq '{') {
            # a petcat {code} outside a string is one character
            $end = $text.IndexOf('}', $i)
            if ($end -lt 0) { $end = $text.Length - 1 }
            $tokens.Add([pscustomobject]@{ Type = 'ch'; Text = $text.Substring($i, $end - $i + 1); Pos = $i })
            $i = $end + 1
            continue
        }
        $kw = $null
        foreach ($k in $keywords) {
            if ($i + $k.Length -le $lower.Length -and $lower.Substring($i, $k.Length) -eq $k) {
                $kw = $k
                break
            }
        }
        if ($null -eq $kw) {
            $tokens.Add([pscustomobject]@{ Type = 'ch'; Text = [string]$ch; Pos = $i })
            $i++
            continue
        }
        $tokens.Add([pscustomobject]@{ Type = 'kw'; Text = $kw; Pos = $i })
        $i += $kw.Length
        if ($kw -eq 'rem') {
            if ($i -lt $text.Length) {
                $tokens.Add([pscustomobject]@{ Type = 'rem'; Text = $text.Substring($i); Pos = $i })
            }
            break
        }
        if ($kw -eq 'data') {
            # data items stay as typed up to the next ":" outside quotes
            $start = $i
            $inQuote = $false
            while ($i -lt $text.Length -and ($inQuote -or $text[$i] -ne ':')) {
                if ($text[$i] -eq '"') { $inQuote = -not $inQuote }
                $i++
            }
            if ($i -gt $start) {
                $tokens.Add([pscustomobject]@{ Type = 'data'; Text = $text.Substring($start, $i - $start); Pos = $start })
            }
        }
    }
    return , $tokens
}

# the line numbers a line's tokens jump to: goto/gosub/then targets, including "on x goto a,b,c" lists,
# and BASIC 3.5's else, trap, resume and restore with a line number (V2 never has a number after these)
function Get-JumpTargets($tokens) {
    $code = -join ($tokens | Where-Object { $_.Type -in @('kw', 'ch') } | ForEach-Object { $_.Text })
    $result = New-Object System.Collections.Generic.List[int]
    foreach ($m in [regex]::Matches($code, '(goto|gosub|then|else|trap|resume|restore)\s*(\d+(\s*,\s*\d+)*)')) {
        foreach ($t in ($m.Groups[2].Value -split ',')) {
            $result.Add([int]$t.Trim())
        }
    }
    return , $result
}
