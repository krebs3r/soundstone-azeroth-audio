param(
    [Parameter(Mandatory=$true)][string]$Source,
    [string]$Destination = (Join-Path $PSScriptRoot '..\Soundstone\Media\Icons.tga')
)
# Mechanical size/format conversion only. The source artwork is made with Imagegen.
# WoW expects power-of-two, uncompressed TGA; colors are used with ADD blending.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sourceBitmap = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $Source))
$bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::Black)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.DrawImage($sourceBitmap, [System.Drawing.Rectangle]::new(0,0,512,512))
$graphics.Dispose()
$sourceBitmap.Dispose()
$destPath = [System.IO.Path]::GetFullPath($Destination)
[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($destPath)) | Out-Null
$stream = [System.IO.File]::Create($destPath)
$writer = [System.IO.BinaryWriter]::new($stream)
$header = [byte[]]::new(18)
$header[2] = 2
$header[13] = 2
$header[15] = 2
$header[16] = 32
$header[17] = 40
$writer.Write($header)
for ($y=0; $y -lt 512; $y++) {
    for ($x=0; $x -lt 512; $x++) {
        $pixel = $bitmap.GetPixel($x,$y)
        $writer.Write([byte]$pixel.B)
        $writer.Write([byte]$pixel.G)
        $writer.Write([byte]$pixel.R)
        $writer.Write([byte]255)
    }
}
$writer.Dispose()
$bitmap.Dispose()
Write-Output "TGA ready: $destPath (512 x 512, BGRA, top-left origin)"
