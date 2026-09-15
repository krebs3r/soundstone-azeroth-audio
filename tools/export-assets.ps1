param([string]$Root = (Join-Path $PSScriptRoot '..'), [string]$Python = 'python')
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
 private static GraphicsPath RoundedBox(float x,float y,float w,float h,float r) {
  var p=new GraphicsPath();float d=r*2;
  p.AddArc(x,y,d,d,180,90);p.AddArc(x+w-d,y,d,d,270,90);
  p.AddArc(x+w-d,y+h-d,d,d,0,90);p.AddArc(x,y+h-d,d,d,90,90);p.CloseFigure();return p;
 }
 public static void ActionPlate(string name,string dst,string png) {
  bool hover=name=="ActionHover",pressed=name=="ActionPressed";
  using(var result=new Bitmap(64,64,PixelFormat.Format32bppArgb)) {
   using(var g=Graphics.FromImage(result))
   using(var outer=RoundedBox(.5f,.5f,15,15,2.2f))
   using(var inner=RoundedBox(1.65f,1.65f,12.7f,12.7f,1.2f))
   using(var rim=new LinearGradientBrush(new PointF(0,0),new PointF(0,16),
    pressed?Color.FromArgb(49,39,25):(hover?Color.FromArgb(177,143,86):Color.FromArgb(116,97,66)),
    pressed?Color.FromArgb(122,100,64):(hover?Color.FromArgb(89,68,40):Color.FromArgb(57,44,29))))
   using(var face=new LinearGradientBrush(new PointF(0,1),new PointF(0,15),
    pressed?Color.FromArgb(15,16,16):(hover?Color.FromArgb(47,45,37):Color.FromArgb(36,37,34)),
    pressed?Color.FromArgb(28,27,23):Color.FromArgb(18,19,19)))
   using(var outline=new Pen(Color.FromArgb(235,12,11,9),.65f))
   using(var lip=new Pen(pressed?Color.FromArgb(170,16,14,10):Color.FromArgb(190,hover?208:156,hover?172:131,hover?104:87),.45f)) {
    g.Clear(Color.Transparent);g.SmoothingMode=SmoothingMode.AntiAlias;g.ScaleTransform(4,4);
    g.FillPath(rim,outer);g.DrawPath(outline,outer);g.FillPath(face,inner);
    g.DrawLine(lip,2.5f,1.15f,13.5f,1.15f);g.DrawLine(lip,1.15f,2.5f,1.15f,13.5f);
   }
   Write(result,dst,png);
  }
 }
 public static void Vector(string name,string dst,string png) {
  using(var result=new Bitmap(64,64,PixelFormat.Format32bppArgb)) {
   using(var g=Graphics.FromImage(result)) using(var pen=new Pen(Color.White,1.35f)) using(var path=new GraphicsPath()) {
    g.Clear(Color.Transparent);g.SmoothingMode=SmoothingMode.AntiAlias;g.ScaleTransform(4,4);
    pen.StartCap=pen.EndCap=LineCap.Round;pen.LineJoin=LineJoin.Round;
    if(name=="Expand") {
     path.AddLine(3,3,6.5f,6.5f);path.StartFigure();path.AddLines(new PointF[]{new PointF(3,7),new PointF(3,3),new PointF(7,3)});
     path.StartFigure();path.AddLine(9.5f,9.5f,13,13);path.StartFigure();path.AddLines(new PointF[]{new PointF(9,13),new PointF(13,13),new PointF(13,9)});
    } else if(name=="Collapse") {
     path.AddLine(3,3,6.5f,6.5f);path.StartFigure();path.AddLines(new PointF[]{new PointF(2.5f,6.5f),new PointF(6.5f,6.5f),new PointF(6.5f,2.5f)});
     path.StartFigure();path.AddLine(9.5f,9.5f,13,13);path.StartFigure();path.AddLines(new PointF[]{new PointF(9.5f,13.5f),new PointF(9.5f,9.5f),new PointF(13.5f,9.5f)});
    } else if(name=="EyeOff") {
     // Two separated curves keep the diagonal slash readable at small sizes.
     path.AddBezier(1.5f,8,3,5.5f,4,4.5f,5.5f,4.2f);
     path.StartFigure();path.AddBezier(8,4,11,3.5f,13,6,14.5f,8);
     path.AddBezier(14.5f,8,13,10.5f,12,11.5f,10.5f,11.8f);
     path.StartFigure();path.AddBezier(8,12,5,12.5f,3,10,1.5f,8);
     path.StartFigure();path.AddArc(5.7f,5.7f,4.6f,4.6f,220,160);path.StartFigure();path.AddLine(2.5f,2,13.5f,14);
    } else if(name=="Heart") {
     path.AddBezier(8,4,3,-1,0,5,3,8.5f);path.AddLine(3,8.5f,8,14);
     path.AddLine(8,14,13,8.5f);path.AddBezier(13,8.5f,16,5,13,-1,8,4);path.CloseFigure();
     g.FillPath(Brushes.White,path);
    } else throw new ArgumentException("Unknown vector symbol: "+name);
    if(name!="Heart") {
     // Leave room for the metal well, with thicker, darker old-gold strokes.
     g.TranslateTransform(.8f,.8f);g.ScaleTransform(.9f,.9f);pen.Width=1.7f;
     using(var outline=new Pen(Color.FromArgb(255,66,47,24),2.2f))
     using(var shadow=new Pen(Color.FromArgb(175,32,23,12),2.25f))
     using(var gold=new LinearGradientBrush(new PointF(0,1),new PointF(0,15),Color.FromArgb(200,173,112),Color.FromArgb(148,122,73)))
     using(var edge=new Pen(Color.FromArgb(210,182,121),.4f)) {
      outline.StartCap=outline.EndCap=shadow.StartCap=shadow.EndCap=edge.StartCap=edge.EndCap=LineCap.Round;
      outline.LineJoin=shadow.LineJoin=edge.LineJoin=LineJoin.Round;
      gold.InterpolationColors=new ColorBlend {Positions=new float[]{0,.2f,.65f,1},Colors=new Color[]{Color.FromArgb(201,173,112),Color.FromArgb(190,160,100),Color.FromArgb(176,145,86),Color.FromArgb(148,122,73)}};
      g.TranslateTransform(0,.4f);g.DrawPath(shadow,path);g.TranslateTransform(0,-.4f);
      g.DrawPath(outline,path);pen.Brush=gold;g.DrawPath(pen,path);
      g.TranslateTransform(0,-.35f);g.DrawPath(edge,path);g.TranslateTransform(0,.35f);
     }
    }
   }
   Write(result,dst,png);
  }
 }
 private static void Write(Bitmap result,string dst,string png) {
  int size=result.Width;result.Save(png,ImageFormat.Png);
  using(var bw=new BinaryWriter(File.Create(dst))) {byte[] header=new byte[18];header[2]=2;header[12]=(byte)size;header[13]=(byte)(size>>8);header[14]=(byte)size;header[15]=(byte)(size>>8);header[16]=32;header[17]=40;bw.Write(header);
   for(int j=0;j<size;j++) for(int i=0;i<size;i++) {Color p=result.GetPixel(i,j);bw.Write(p.B);bw.Write(p.G);bw.Write(p.R);bw.Write(p.A);}}
 }
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
    Write(result,dst,png);
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
$vectors=@('Expand','Collapse','EyeOff','Heart')
foreach($name in $vectors) {
 [SoundstoneSprites]::Vector($name,(Join-Path $media ($name+'.tga')),(Join-Path $preview ($name+'.png')))
 $lua.Add(('    {0} = {{ width=64, height=64, uv={{ 0, 1, 0, 1 }} }},' -f $name))
}
$plates=@('ActionNormal','ActionHover','ActionPressed')
foreach($name in $plates) {
 [SoundstoneSprites]::ActionPlate($name,(Join-Path $media ($name+'.tga')),(Join-Path $preview ($name+'.png')))
 $lua.Add(('    {0} = {{ width=64, height=64, uv={{ 0, 1, 0, 1 }} }},' -f $name))
}
$lua.Add('}')
[IO.File]::WriteAllLines((Join-Path $repo 'Soundstone\Assets.lua'),$lua,[Text.UTF8Encoding]::new($false))
Write-Output "Exported $($entries.Count + $vectors.Count + $plates.Count) alpha sprites and Assets.lua."
& $Python (Join-Path $PSScriptRoot 'header_art.py') --root $repo
if ($LASTEXITCODE -ne 0) { throw 'Red header export failed. Python with Pillow is required.' }
