param(
    [string]$Root = "."
)

$ErrorActionPreference = "Stop"

function Make-Str {
    param([int[]]$CodePoints)
    $chars = foreach ($cp in $CodePoints) { [char]$cp }
    return -join $chars
}

function Get-TextEncodingAndString {
    param([byte[]]$Bytes)

    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        $utf8 = New-Object System.Text.UTF8Encoding($true, $true)
        return @{ EncodingName = "utf8-bom"; Text = $utf8.GetString($Bytes) }
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) {
        return @{ EncodingName = "utf16le-bom"; Text = [System.Text.Encoding]::Unicode.GetString($Bytes) }
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) {
        return @{ EncodingName = "utf16be-bom"; Text = [System.Text.Encoding]::BigEndianUnicode.GetString($Bytes) }
    }

    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        return @{ EncodingName = "utf8"; Text = $strictUtf8.GetString($Bytes) }
    }
    catch {
        $win1254 = [System.Text.Encoding]::GetEncoding(1254)
        return @{ EncodingName = "windows-1254"; Text = $win1254.GetString($Bytes) }
    }
}

function Detect-Newline {
    param([string]$Text)
    if ($Text.Contains("`r`n")) { return "`r`n" }
    return "`n"
}

function Ensure-Utf8MetaCharset {
    param([string]$HtmlText)

    $headOpen = [regex]::Match($HtmlText, '(?is)<head\b[^>]*>')
    if (-not $headOpen.Success) { return $HtmlText }

    $headClose = [regex]::Match($HtmlText, '(?is)</head\s*>')
    if (-not $headClose.Success) { return $HtmlText }

    $headStart = $headOpen.Index + $headOpen.Length
    $headEnd = $headClose.Index
    if ($headEnd -lt $headStart) { return $HtmlText }

    $headInner = $HtmlText.Substring($headStart, $headEnd - $headStart)
    if ([regex]::IsMatch($headInner, '(?is)<meta\s+charset\s*=\s*(?:\"|'''')?\s*utf-8\s*(?:\"|'''')?\s*/?>')) {
        return $HtmlText
    }

    $nl = Detect-Newline $HtmlText
    $insertion = "${nl}    <meta charset=`"UTF-8`">$nl"

    return $HtmlText.Substring(0, $headStart) + $insertion + $HtmlText.Substring($headStart)
}

function Fix-HttpEquivContentTypeCharset {
    param([string]$HtmlText)

    $pattern = '(?is)<meta\b[^>]*http-equiv\s*=\s*(?:\"|'''')content-type(?:\"|'''')[^>]*>'
    $charsetPattern = '(?is)(charset\s*=\s*)([^\s;\"''''>]+)'

    return [regex]::Replace($HtmlText, $pattern, {
        param($m)
        $tag = $m.Value
        if ([regex]::IsMatch($tag, $charsetPattern)) {
            return [regex]::Replace($tag, $charsetPattern, "`$1UTF-8", 1)
        }
        return $tag
    })
}

function Apply-MojibakeFixes {
    param([string]$Text)

    $c = @{
        A_diaeresis = 0x00C4
        A_ring = 0x00C5
        A_tilde = 0x00C3

        ctrl_87 = 0x0087
        ctrl_96 = 0x0096
        ctrl_9C = 0x009C
        ctrl_9E = 0x009E
        ctrl_9F = 0x009F

        plus_minus = 0x00B1
        degree = 0x00B0
        quarter = 0x00BC
        pilcrow = 0x00B6
        section = 0x00A7
        daggerdbl = 0x2021
        endash = 0x2013
        oe = 0x0153
        Y_diaeresis = 0x0178
        z_caron = 0x017E
        cent = 0x00A2
        inv_excl = 0x00A1

        dotless_i = 0x0131
        I_dotted_upper = 0x0130
        s_cedilla_lower = 0x015F
        s_cedilla_upper = 0x015E
        g_breve_lower = 0x011F
        g_breve_upper = 0x011E
        u_umlaut_lower = 0x00FC
        u_umlaut_upper = 0x00DC
        o_umlaut_lower = 0x00F6
        o_umlaut_upper = 0x00D6
        c_cedilla_lower = 0x00E7
        c_cedilla_upper = 0x00C7
        a_circ = 0x00E2
        check = 0x2713
    }

    $map = @(
        @{ From = (Make-Str @(0x00C4, 0x00B1)); To = (Make-Str @(0x0131)) }, # U+00C4 U+00B1 -> U+0131
        @{ From = (Make-Str @(0x00C4, 0x00B0)); To = (Make-Str @(0x0130)) }, # U+00C4 U+00B0 -> U+0130
        @{ From = (Make-Str @(0x00C5, 0x0178)); To = (Make-Str @(0x015F)) }, # U+00C5 U+0178 -> U+015F
        @{ From = (Make-Str @(0x00C5, 0x017E)); To = (Make-Str @(0x015E)) }, # U+00C5 U+017E -> U+015E
        @{ From = (Make-Str @(0x00C4, 0x0178)); To = (Make-Str @(0x011F)) }, # U+00C4 U+0178 -> U+011F
        @{ From = (Make-Str @(0x00C4, 0x017E)); To = (Make-Str @(0x011E)) }, # U+00C4 U+017E -> U+011E
        @{ From = (Make-Str @(0x00C3, 0x00BC)); To = (Make-Str @(0x00FC)) }, # U+00C3 U+00BC -> U+00FC
        @{ From = (Make-Str @(0x00C3, 0x0153)); To = (Make-Str @(0x00DC)) }, # U+00C3 U+0153 -> U+00DC
        @{ From = (Make-Str @(0x00C3, 0x00B6)); To = (Make-Str @(0x00F6)) }, # U+00C3 U+00B6 -> U+00F6
        @{ From = (Make-Str @(0x00C3, 0x2013)); To = (Make-Str @(0x00D6)) }, # U+00C3 U+2013 -> U+00D6
        @{ From = (Make-Str @(0x00C3, 0x00A7)); To = (Make-Str @(0x00E7)) }, # U+00C3 U+00A7 -> U+00E7
        @{ From = (Make-Str @(0x00C3, 0x2021)); To = (Make-Str @(0x00C7)) }, # U+00C3 U+2021 -> U+00C7
        @{ From = (Make-Str @(0x00C3, 0x00A2)); To = (Make-Str @(0x00E2)) }, # U+00C3 U+00A2 -> U+00E2 (Ã¢ -> â)

        # ISO-8859-1 style mojibake remnants (second byte became control char)
        @{ From = (Make-Str @($c.A_ring, $c.ctrl_9F)); To = (Make-Str @($c.s_cedilla_lower)) },
        @{ From = (Make-Str @($c.A_ring, $c.ctrl_9E)); To = (Make-Str @($c.s_cedilla_upper)) },
        @{ From = (Make-Str @($c.A_diaeresis, $c.ctrl_9F)); To = (Make-Str @($c.g_breve_lower)) },
        @{ From = (Make-Str @($c.A_diaeresis, $c.ctrl_9E)); To = (Make-Str @($c.g_breve_upper)) },
        @{ From = (Make-Str @($c.A_tilde, $c.ctrl_9C)); To = (Make-Str @($c.u_umlaut_upper)) },
        @{ From = (Make-Str @($c.A_tilde, $c.ctrl_96)); To = (Make-Str @($c.o_umlaut_upper)) },
        @{ From = (Make-Str @($c.A_tilde, $c.ctrl_87)); To = (Make-Str @($c.c_cedilla_upper)) }
    )

    foreach ($entry in $map) {
        $Text = $Text.Replace($entry.From, $entry.To)
    }

    # Handle "dropped second byte" cases where only the first mojibake char remains
    $sb = New-Object System.Text.StringBuilder
    $chars = $Text.ToCharArray()
    for ($i = 0; $i -lt $chars.Length; $i++) {
        $ch = $chars[$i]
        $prev = if ($i -gt 0) { $chars[$i - 1] } else { [char]0 }
        $next = if ($i + 1 -lt $chars.Length) { $chars[$i + 1] } else { [char]0 }

        if ([int]$ch -eq $c.A_ring) {
            $isUpperContext = [char]::IsUpper($prev) -and [char]::IsUpper($next)
            $replacement = if ($isUpperContext) { [char]$c.s_cedilla_upper } else { [char]$c.s_cedilla_lower }
            [void]$sb.Append($replacement)
            continue
        }

        if ([int]$ch -eq $c.A_diaeresis) {
            $isUpperContext = [char]::IsUpper($prev) -and [char]::IsUpper($next)
            $replacement = if ($isUpperContext) { [char]$c.g_breve_upper } else { [char]$c.g_breve_lower }
            [void]$sb.Append($replacement)
            continue
        }

        if ([int]$ch -eq $c.A_tilde) {
            $replacement = $null
            switch ([string]$next) {
                'n' { $replacement = [char]$c.o_umlaut_upper; break }
                'N' { $replacement = [char]$c.o_umlaut_upper; break }
                'z' { $replacement = [char]$c.o_umlaut_upper; break }
                'Z' { $replacement = [char]$c.o_umlaut_upper; break }
                's' { $replacement = [char]$c.u_umlaut_upper; break }
                'S' { $replacement = [char]$c.u_umlaut_upper; break }
                'a' { $replacement = [char]$c.c_cedilla_upper; break }
                'A' { $replacement = [char]$c.c_cedilla_upper; break }
                'e' { $replacement = [char]$c.c_cedilla_upper; break }
                'E' { $replacement = [char]$c.c_cedilla_upper; break }
                'i' { $replacement = [char]$c.c_cedilla_upper; break }
                'I' { $replacement = [char]$c.c_cedilla_upper; break }
                'o' { $replacement = [char]$c.c_cedilla_upper; break }
                'O' { $replacement = [char]$c.c_cedilla_upper; break }
                'u' { $replacement = [char]$c.c_cedilla_upper; break }
                'U' { $replacement = [char]$c.c_cedilla_upper; break }
                ([char]$c.dotless_i) { $replacement = [char]$c.c_cedilla_upper; break }
                ([char]$c.I_dotted_upper) { $replacement = [char]$c.c_cedilla_upper; break }
                ([char]$c.o_umlaut_lower) { $replacement = [char]$c.c_cedilla_upper; break }
                ([char]$c.o_umlaut_upper) { $replacement = [char]$c.c_cedilla_upper; break }
                ([char]$c.u_umlaut_lower) { $replacement = [char]$c.c_cedilla_upper; break }
                ([char]$c.u_umlaut_upper) { $replacement = [char]$c.c_cedilla_upper; break }
            }

            if ($null -ne $replacement) {
                [void]$sb.Append($replacement)
                continue
            }
        }

        if ([int]$ch -eq $c.a_circ -and [int]$next -eq $c.inv_excl) {
            [void]$sb.Append([char]$c.check)
            $i++
            continue
        }

        [void]$sb.Append($ch)
    }

    return $sb.ToString()
}

$extensions = @(".html", ".css", ".js", ".txt")
$skipDirs = @("\.git\", "\node_modules\", "\dist\", "\build\")

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$files = Get-ChildItem -LiteralPath $rootPath -Recurse -File |
    Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } |
    Where-Object {
        $full = $_.FullName.ToLowerInvariant()
        foreach ($sd in $skipDirs) {
            if ($full.Contains($sd)) { return $false }
        }
        return $true
    }

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$modified = 0
$touched = @()

foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $decoded = Get-TextEncodingAndString $bytes
    $text = $decoded.Text
    $original = $text

    $text = Apply-MojibakeFixes $text

    if ($f.Extension.ToLowerInvariant() -eq ".html") {
        $text = Fix-HttpEquivContentTypeCharset $text
        $text = Ensure-Utf8MetaCharset $text
    }

    if ($text -ne $original -or $decoded.EncodingName -ne "utf8") {
        [System.IO.File]::WriteAllBytes($f.FullName, $utf8NoBom.GetBytes($text))
        $modified++
        $touched += $f.FullName
    }
}

Write-Host "Processed $($files.Count) files under $rootPath"
Write-Host "Modified  $modified files (UTF-8 without BOM + content fixes)"
if ($modified -gt 0) {
    Write-Host ""
    Write-Host "Changed files:"
    $touched | Sort-Object | ForEach-Object { Write-Host " - $_" }
}
