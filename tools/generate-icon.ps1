# Generates D:\DSH\icon.ico — a simple DeepSeek-blue rounded "DSH" app icon.
Add-Type -AssemblyName System.Drawing

$outIco = Join-Path (Split-Path -Parent $PSScriptRoot) 'icon.ico'
$size   = 256

$bmp = New-Object System.Drawing.Bitmap $size, $size
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# Rounded-rectangle background path.
$rect   = New-Object System.Drawing.Rectangle 0, 0, $size, $size
$radius = 56
$path   = New-Object System.Drawing.Drawing2D.GraphicsPath
$d      = $radius * 2
$path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
$path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
$path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
$path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
$path.CloseFigure()

# Vertical gradient fill.
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.Color]::FromArgb(255, 77, 107, 254),
    [System.Drawing.Color]::FromArgb(255, 37, 60, 190),
    90.0
)
$g.FillPath($brush, $path)

# "DSH" label.
$font  = New-Object System.Drawing.Font('Segoe UI', 96, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$sf    = New-Object System.Drawing.StringFormat
$sf.Alignment     = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center
$g.DrawString('DSH', $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF(0, 0, $size, $size)), $sf)

# Save PNG bytes, then wrap them in an ICO container (PNG-compressed ICO).
$ms = New-Object System.IO.MemoryStream
$bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
$png = $ms.ToArray()

$fs = [System.IO.File]::Create($outIco)
$bw = New-Object System.IO.BinaryWriter($fs)
# ICONDIR
$bw.Write([UInt16]0)          # reserved
$bw.Write([UInt16]1)          # type: icon
$bw.Write([UInt16]1)          # count
# ICONDIRENTRY (PNG-compressed)
$bw.Write([Byte]0)            # width  (0 = 256)
$bw.Write([Byte]0)            # height (0 = 256)
$bw.Write([Byte]0)            # palette
$bw.Write([Byte]0)            # reserved
$bw.Write([UInt16]1)          # planes
$bw.Write([UInt16]32)         # bit count
$bw.Write([UInt32]$png.Length) # bytes in resource
$bw.Write([UInt32]22)         # image offset (6 + 16)
$bw.Write($png)
$bw.Close()

$g.Dispose(); $path.Dispose(); $brush.Dispose(); $font.Dispose(); $sf.Dispose(); $bmp.Dispose(); $ms.Dispose()
Write-Output "Icon written: $outIco ($($png.Length) bytes PNG)"
