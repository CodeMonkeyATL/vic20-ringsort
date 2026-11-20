param(
    [Parameter(Mandatory = $true)]
    [string]$BasFile,
    [Parameter(Mandatory = $true)]
    [string]$OutFile
)

# writes a copy of a petcat source file without its rems, for the build: a line that holds only a rem
# is dropped, and a ":rem ..." at the end of a line is cut off. rems cost memory in the PRG (their text,
# plus 5 bytes for a line of their own), so the source keeps them and the PRG doesn't. The rem is found
# with the same tokenizer as check-basic.ps1, so a "rem" inside a string is left alone.
# A rem-only line that a goto/gosub/then jumps to is kept as a bare "rem" (6 bytes), so the program still
# runs; check-basic.ps1 warns about it, since the rem belongs at the end of the routine's first code line.
# used by build-and-run.ps1 and the CI workflow (with pwsh), so local and CI builds stay byte-identical
. (Join-Path $PSScriptRoot 'basic-tokens.ps1')
# a BASIC 3.5 program (name-plus4.bas) is tokenized with its own keywords, as the lint does
. (Join-Path $PSScriptRoot 'machine.ps1')
if ((Get-MachineForFile $BasFile).Basic -eq '3.5') { Use-Basic35 }

$lines = New-Object System.Collections.Generic.List[object]
$targets = @{}
foreach ($raw in [System.IO.File]::ReadAllLines($BasFile)) {
    if ($raw -match '^(\s*(\d+)\s?)(.*)$') {
        $line = [pscustomobject]@{ Raw = $raw; Prefix = $Matches[1]; Number = [int]$Matches[2]; Text = $Matches[3] }
    } else {
        # blank lines (petcat skips them) and unnumbered lines
        $line = [pscustomobject]@{ Raw = $raw; Prefix = ''; Number = -1; Text = $raw }
    }
    $line | Add-Member Tokens (Get-Tokens $line.Text)
    foreach ($t in (Get-JumpTargets $line.Tokens)) {
        $targets[$t] = $true
    }
    $lines.Add($line)
}

$out = New-Object System.Collections.Generic.List[string]
foreach ($line in $lines) {
    $rem = $null
    foreach ($t in $line.Tokens) {
        if ($t.Type -eq 'kw' -and $t.Text -eq 'rem') {
            $rem = $t
            break
        }
    }
    if ($null -eq $rem) {
        $out.Add($line.Raw)
        continue
    }

    # the code before the rem, without the ":" that joined them
    $code = $line.Text.Substring(0, $rem.Pos).TrimEnd()
    if ($code.EndsWith(':')) {
        $code = $code.Substring(0, $code.Length - 1)
    }
    if ($code -ne '') {
        $out.Add($line.Prefix + $code)
    } elseif ($targets.ContainsKey($line.Number)) {
        $out.Add($line.Prefix + 'rem')
    }
}
[System.IO.File]::WriteAllLines($OutFile, $out)
