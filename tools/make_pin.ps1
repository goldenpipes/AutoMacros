# Draws the pushpin shown on a bar button whose popout is pinned (Ctrl+click):
# a white silhouette of a push pin (flat cap, neck, flared collar, base plate,
# needle), tilted so the needle points down-left, saved as an uncompressed 32-bit
# TGA with alpha (WoW reads it on every client). A .png path writes a preview.
# Usage, from the project folder:  & .\tools\make_pin.ps1 [Media\Pin.tga] [size]
param([string]$Out = "Media\Pin.tga", [int]$Size = 64)

Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# drawn upright (needle down) around (0, 0) in units of about 64 tall, then
# moved to the middle, scaled to the picture and turned 45 degrees clockwise
$g.TranslateTransform($Size / 2, $Size / 2)
$g.ScaleTransform($Size / 64.0 * 0.92, $Size / 64.0 * 0.92)
$g.RotateTransform(45)

function P([float]$x, [float]$y) { New-Object System.Drawing.PointF $x, $y }
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
# the cap (top), a step in to the neck
$path.AddPolygon(@((P -11 -32), (P 11 -32), (P 11 -26), (P 7 -26), (P 7 -10), (P -7 -10), (P -7 -26), (P -11 -26)))
# the collar: flares out from the neck to the base plate with curved sides
$collar = New-Object System.Drawing.Drawing2D.GraphicsPath
$collar.AddLine((P -7 -11), (P 7 -11))
$collar.AddBezier((P 7 -11), (P 8 -3), (P 17 -1), (P 17 4))
$collar.AddLine((P 17 4), (P -17 4))
$collar.AddBezier((P -17 4), (P -17 -1), (P -8 -3), (P -7 -11))
$collar.CloseFigure()
# the needle: straight, then a point
$needle = New-Object System.Drawing.Drawing2D.GraphicsPath
$needle.AddPolygon(@((P -2.2 3), (P 2.2 3), (P 2.2 24), (P 0 33), (P -2.2 24)))

$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$g.FillPath($white, $path)
$g.FillPath($white, $collar)
$g.FillPath($white, $needle)
$g.Dispose()

if ([System.IO.Path]::IsPathRooted($Out)) { $full = $Out }
else { $full = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Out)) }
$dir = Split-Path -Parent $full
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
if ($full -match '\.png$') {   # (a preview to look at, on a dark background: the pin is white)
    $view = New-Object System.Drawing.Bitmap $Size, $Size
    $vg = [System.Drawing.Graphics]::FromImage($view)
    $vg.Clear([System.Drawing.Color]::FromArgb(255, 40, 40, 45))
    $vg.DrawImage($bmp, 0, 0, $Size, $Size)
    $vg.Dispose()
    $view.Save($full, [System.Drawing.Imaging.ImageFormat]::Png)
    $view.Dispose()
    $bmp.Dispose()
    Write-Output "wrote $full"
    return
}
# TGA type 2: 18-byte header, then BGRA rows from the bottom up (descriptor 8 = 8 alpha bits)
$rect = New-Object System.Drawing.Rectangle 0, 0, $Size, $Size
$data = $bmp.LockBits($rect, 'ReadOnly', [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$row = $Size * 4
$px = New-Object byte[] ($row * $Size)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $px, 0, $px.Length)
$bmp.UnlockBits($data)
$bmp.Dispose()
$tga = New-Object System.IO.MemoryStream
$hdr = New-Object byte[] 18
$hdr[2] = 2
$hdr[12] = $Size -band 255; $hdr[13] = $Size -shr 8
$hdr[14] = $Size -band 255; $hdr[15] = $Size -shr 8
$hdr[16] = 32; $hdr[17] = 8
$tga.Write($hdr, 0, 18)
for ($y = $Size - 1; $y -ge 0; $y--) { $tga.Write($px, $y * $row, $row) }
[System.IO.File]::WriteAllBytes($full, $tga.ToArray())
Write-Output "wrote $full"
