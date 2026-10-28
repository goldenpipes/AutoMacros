# Draws the AutoMacros logo (CurseForge avatar): an action button with a red
# potion and its popout above it (mana potion, green elixir, the selected one
# ringed in gold). Usage: powershell -File tools\make_logo.ps1 [out.png|out.tga] [size]
# A .tga is saved as uncompressed 32-bit with alpha, which WoW reads: the AddOn
# List icon is `powershell -File tools\make_logo.ps1 Media\AutoMacros.tga 64`.
param([string]$Out = "releases\AutoMacros-logo.png", [int]$Size = 512)

Add-Type -AssemblyName System.Drawing
$S = 512   # drawn at 512, scaled to $Size
$bmp = New-Object System.Drawing.Bitmap $Size, $Size
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.InterpolationMode = 'HighQualityBicubic'
$g.ScaleTransform($Size / $S, $Size / $S)

function C([int]$a, [int]$r, [int]$gg, [int]$b) { [System.Drawing.Color]::FromArgb($a, $r, $gg, $b) }

# a square with cut corners (like Blizzard's action buttons)
function CutSquare([float]$x, [float]$y, [float]$w, [float]$cut) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pts = @(
        (New-Object System.Drawing.PointF ($x + $cut), $y),
        (New-Object System.Drawing.PointF ($x + $w - $cut), $y),
        (New-Object System.Drawing.PointF ($x + $w), ($y + $cut)),
        (New-Object System.Drawing.PointF ($x + $w), ($y + $w - $cut)),
        (New-Object System.Drawing.PointF ($x + $w - $cut), ($y + $w)),
        (New-Object System.Drawing.PointF ($x + $cut), ($y + $w)),
        (New-Object System.Drawing.PointF $x, ($y + $w - $cut)),
        (New-Object System.Drawing.PointF $x, ($y + $cut)))
    $p.AddPolygon([System.Drawing.PointF[]]$pts)
    return $p
}

# an action button: dark slot, stone-grey frame (gold when selected)
function Slot([float]$x, [float]$y, [float]$w, [bool]$selected) {
    $cut = $w * 0.1
    $outer = CutSquare $x $y $w $cut
    $rect = New-Object System.Drawing.RectangleF $x, $y, $w, $w
    $fill = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, (C 255 46 44 56), (C 255 18 17 24), 90
    $g.FillPath($fill, $outer)
    $ring = if ($selected) { C 255 240 196 70 } else { C 255 120 116 110 }
    $pen = New-Object System.Drawing.Pen $ring, ($w * 0.055)
    $pen.LineJoin = 'Miter'
    $g.DrawPath($pen, $outer)
    $inner = CutSquare ($x + $w * 0.05) ($y + $w * 0.05) ($w * 0.9) ($cut * 0.8)
    $dark = New-Object System.Drawing.Pen (C 160 0 0 0), ($w * 0.015)
    $g.DrawPath($dark, $inner)
}

# a potion flask centred in the square x, y, w: round body, neck, cork
function Potion([float]$x, [float]$y, [float]$w, $light, $deep) {
    $cx = $x + $w / 2
    $bodyR = $w * 0.27
    $by = $y + $w * 0.58
    $neckW = $w * 0.16; $neckTop = $y + $w * 0.2
    # glass neck
    $neck = New-Object System.Drawing.RectangleF ($cx - $neckW / 2), $neckTop, $neckW, ($by - $neckTop - $bodyR * 0.6)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush (C 120 200 220 235)), $neck)
    # cork
    $cork = New-Object System.Drawing.RectangleF ($cx - $neckW * 0.62), ($neckTop - $w * 0.07), ($neckW * 1.24), ($w * 0.1)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush (C 255 150 98 52)), $cork)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush (C 255 110 70 36)), $cork.X, ($cork.Y + $cork.Height * 0.65), $cork.Width, ($cork.Height * 0.35))
    # body: liquid with a lighter centre
    $body = New-Object System.Drawing.Drawing2D.GraphicsPath
    $body.AddEllipse(($cx - $bodyR), ($by - $bodyR), ($bodyR * 2), ($bodyR * 2))
    $pg = New-Object System.Drawing.Drawing2D.PathGradientBrush $body
    $pg.CenterPoint = New-Object System.Drawing.PointF ($cx - $bodyR * 0.25), ($by - $bodyR * 0.2)
    $pg.CenterColor = $light
    $pg.SurroundColors = [System.Drawing.Color[]]@($deep)
    $g.FillPath($pg, $body)
    # glass rim and a shine
    $g.DrawPath((New-Object System.Drawing.Pen (C 200 235 240 245), ($w * 0.025)), $body)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush (C 170 255 255 255)), ($cx - $bodyR * 0.62), ($by - $bodyR * 0.68), ($bodyR * 0.42), ($bodyR * 0.3))
}

# background: dark, rounded
$g.Clear([System.Drawing.Color]::Transparent)
$bgPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$r = 70
$bgPath.AddArc(0, 0, $r * 2, $r * 2, 180, 90); $bgPath.AddArc($S - $r * 2, 0, $r * 2, $r * 2, 270, 90)
$bgPath.AddArc($S - $r * 2, $S - $r * 2, $r * 2, $r * 2, 0, 90); $bgPath.AddArc(0, $S - $r * 2, $r * 2, $r * 2, 90, 90)
$bgPath.CloseFigure()
$bg = New-Object System.Drawing.Drawing2D.PathGradientBrush $bgPath
$bg.CenterPoint = New-Object System.Drawing.PointF 256, 300
$bg.CenterColor = C 255 52 40 58
$bg.SurroundColors = [System.Drawing.Color[]]@((C 255 14 12 18))
$g.FillPath($bg, $bgPath)

# the popout: two items rising above the button, centred on it
$main = 190; $item = 104; $gap = 10
$total = $item * 2 + $gap + 26 + $main            # the whole stack, centred top to bottom
$mx = (512 - $main) / 2; $my = (512 + $total) / 2 - $main
$ix = (512 - $item) / 2
$y1 = $my - 26 - $item            # nearest the button (selected)
$y2 = $y1 - $gap - $item
# the popout indicator: a gold tab on top of the button
$g.FillRectangle((New-Object System.Drawing.SolidBrush (C 255 240 196 70)), (256 - 40), ($my - 15), 80, 8)

Slot $ix $y2 $item $false
Potion $ix $y2 $item (C 255 140 220 255) (C 255 30 70 200)       # mana
Slot $ix $y1 $item $true
Potion $ix $y1 $item (C 255 170 255 140) (C 255 40 140 50)       # green elixir
Slot $mx $my $main $false
Potion $mx $my $main (C 255 255 140 120) (C 255 170 20 30)       # health

$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
$full = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Out))
$g.Dispose()
if ($full -match '\.tga$') {
    # TGA type 2: 18-byte header, then BGRA rows from the bottom up (descriptor 8 = 8 alpha bits)
    $rect = New-Object System.Drawing.Rectangle 0, 0, $Size, $Size
    $data = $bmp.LockBits($rect, 'ReadOnly', [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $row = $Size * 4
    $px = New-Object byte[] ($row * $Size)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $px, 0, $px.Length)
    $bmp.UnlockBits($data)
    $tga = New-Object System.IO.MemoryStream   # not $out: PowerShell names ignore case ($Out)
    $hdr = New-Object byte[] 18
    $hdr[2] = 2
    $hdr[12] = $Size -band 255; $hdr[13] = $Size -shr 8
    $hdr[14] = $Size -band 255; $hdr[15] = $Size -shr 8
    $hdr[16] = 32; $hdr[17] = 8
    $tga.Write($hdr, 0, 18)
    for ($y = $Size - 1; $y -ge 0; $y--) { $tga.Write($px, $y * $row, $row) }
    [System.IO.File]::WriteAllBytes($full, $tga.ToArray())
} else {
    $bmp.Save($full, [System.Drawing.Imaging.ImageFormat]::Png)
}
$bmp.Dispose()
"saved $full ($Size x $Size)"
