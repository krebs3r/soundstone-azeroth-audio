param([string]$Root = (Join-Path $PSScriptRoot '..'))
$ErrorActionPreference = 'Stop'
[Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
Add-Type -AssemblyName System.Drawing
# Sprite packaging: slice the Imagegen sheet, clip each component's exterior,
# preserve aspect ratio, and encode real-alpha PNG / uncompressed BGRA TGA.
Add-Type -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives,System.Private.Windows.GdiPlus,System.Private.Windows.Core -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class SoundstoneSprites {
 public static void Export(string src, string dst, string png, int x,int y,int w,int h,int size,int corner,string mask) {
  using(var sheet=new Bitmap(src)) using(var crop=new Bitmap(w,h,PixelFormat.Format32bppArgb)) {
   for(int j=0;j<h;j++) for(int i=0;i<w;i++) {
    Color p=sheet.GetPixel(x+i,y+j); int alpha=255;
    int dx=Math.Min(i,w-1-i),dy=Math.Min(j,h-1-j);
    if(mask=="frame" && dx+dy<corner) alpha=0;
    if(mask=="diamond") {
     double d=Math.Abs((i-(w-1)/2.0)/(w/2.0))+Math.Abs((j-(h-1)/2.0)/(h/2.0));
     alpha=(int)(255*Math.Clamp((1-d)*Math.Min(w,h)/2,0,1));
    }
    if(mask=="circle") {
     double d=Math.Sqrt(Math.Pow((i-(w-1)/2.0)/(w/2.0),2)+Math.Pow((j-(h-1)/2.0)/(h/2.0),2));
     alpha=(int)(255*Math.Clamp((1-d)*Math.Min(w,h)/2,0,1));
    }
    if(mask=="black") {int v=Math.Max(p.R,Math.Max(p.G,p.B)); alpha=(int)(255*Math.Clamp((v-5)/27.0,0,1));}
    crop.SetPixel(i,j,Color.FromArgb(alpha,p.R,p.G,p.B));
   }
   using(var result=new Bitmap(size,size,PixelFormat.Format32bppArgb)) {
    using(var g=Graphics.FromImage(result)) {g.Clear(Color.Transparent);g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=InterpolationMode.HighQualityBicubic;
     double factor=(size-4.0)/Math.Max(w,h); int dw=(int)Math.Round(w*factor),dh=(int)Math.Round(h*factor);
     g.DrawImage(crop,new Rectangle((size-dw)/2,(size-dh)/2,dw,dh));}
    result.Save(png,ImageFormat.Png);
    using(var bw=new BinaryWriter(File.Create(dst))) {byte[] header=new byte[18];header[2]=2;header[12]=(byte)size;header[13]=(byte)(size>>8);header[14]=(byte)size;header[15]=(byte)(size>>8);header[16]=32;header[17]=40;bw.Write(header);
     for(int j=0;j<size;j++) for(int i=0;i<size;i++) {Color p=result.GetPixel(i,j);bw.Write(p.B);bw.Write(p.G);bw.Write(p.R);bw.Write(p.A);}}
   }
  }
 }
}
'@
$repo = [IO.Path]::GetFullPath($Root)
$media = Join-Path $repo 'Soundstone\Media'
$preview = Join-Path $repo 'docs\assets'
[IO.Directory]::CreateDirectory($preview) | Out-Null
$skin = Join-Path $repo 'docs\skin-source-v02.png'
$icons = Join-Path $repo 'docs\icons-source.png'
$entries = @(
 @('RetailPanel',$skin,34,158,711,379,512,22,'frame'),
 @('ClassicPanel',$skin,792,158,710,384,512,23,'frame'),
 @('RetailBar',$skin,23,607,724,96,512,21,'frame'),
 @('ClassicBar',$skin,792,607,721,97,512,22,'frame'),
 @('Close',$skin,120,814,92,87,128,15,'frame'),
 @('Toggle',$skin,262,815,155,82,128,13,'frame'),
 @('ToggleRed',$skin,465,816,159,80,128,13,'frame'),
 @('GoldThumb',$skin,674,808,56,100,128,0,'diamond'),
 @('SilverThumb',$skin,797,808,59,100,128,0,'diamond'),
 @('Rivet',$skin,930,839,42,42,64,0,'circle'),
 @('Master',$icons,712,181,426,352,128,0,'black'),
 @('Sfx',$icons,141,713,416,405,128,0,'black'),
 @('Music',$icons,743,699,365,423,128,0,'black'),
 @('Logo',$icons,34,108,583,473,128,0,'black')
)
$lua = [Collections.Generic.List[string]]::new()
$lua.Add('local _, A = ...')
$lua.Add('A.Assets = {')
foreach($e in $entries) {
 [SoundstoneSprites]::Export($e[1],(Join-Path $media ($e[0]+'.tga')),(Join-Path $preview ($e[0]+'.png')),$e[2],$e[3],$e[4],$e[5],$e[6],$e[7],$e[8])
 $factor=($e[6]-4.0)/[Math]::Max($e[4],$e[5]);$w=[Math]::Round($e[4]*$factor);$h=[Math]::Round($e[5]*$factor)
 $left=[Math]::Floor(($e[6]-$w)/2)/$e[6];$top=[Math]::Floor(($e[6]-$h)/2)/$e[6]
 $right=$left+$w/$e[6];$bottom=$top+$h/$e[6]
 $lua.Add(('    {0} = {{ width={1}, height={2}, uv={{ {3}, {4}, {5}, {6} }} }},' -f $e[0],$e[4],$e[5],$left,$right,$top,$bottom))
}
$lua.Add('}')
[IO.File]::WriteAllLines((Join-Path $repo 'Soundstone\Assets.lua'),$lua,[Text.UTF8Encoding]::new($false))
Write-Output "Exported $($entries.Count) alpha sprites and Assets.lua."
