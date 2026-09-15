"""Export the approved, equal-sized red header buttons (requires Pillow)."""
from pathlib import Path
import argparse
import math
import re
import struct
from PIL import Image, ImageDraw

NAMES=('HeaderHide','HeaderCompact','HeaderClose')

def render(root, name, size=128):
    meta=(root/'Soundstone/Assets.lua').read_text(encoding='utf-8')
    u=[float(n) for n in re.search(r'Close = \{[^\n]+uv=\{ ([^}]+)',meta).group(1).split(',')]
    source=Image.open(root/'docs/assets/Close.png').convert('RGBA')
    face=source.crop(tuple(round(v) for v in (u[0]*source.width,u[2]*source.height,u[1]*source.width,u[3]*source.height)))
    original=face.copy()
    if name!='HeaderClose':
        # Retain the source frame/alpha; compose the empty face between its inner edges.
        x0,x1=round(face.width*.2),round(face.width*.8)
        y0,y1=round(face.height*.2),round(face.height*.8)
        for y in range(y0,y1):
            left,right=face.getpixel((x0-1,y)),face.getpixel((x1,y))
            for x in range(x0,x1):
                t=(x-x0+1)/(x1-x0+1)
                face.putpixel((x,y),tuple(round(a+(b-a)*t) for a,b in zip(left,right)))
    # Draw at high resolution, then downsample once for identical edge antialiasing.
    scale=4;image=face.resize((size*scale,size*scale),Image.Resampling.LANCZOS)
    if name!='HeaderClose':
        if name=='HeaderCompact':
            paths=[[(3,3),(6.5,6.5)],[(2.5,6.5),(6.5,6.5),(6.5,2.5)],[(9.5,9.5),(13,13)],[(9.5,13.5),(9.5,9.5),(13.5,9.5)]]
        else:
            paths=[[(1.5,8),(3,6),(5,4.6)],[(8,4),(11,4.4),(14.5,8),(12,10.8)],[(9,12),(6,11.8),(3,10),(1.5,8)],[(2.5,2),(13.5,14)]]
            paths+=[[(8+2*math.cos(j*math.pi/12),8+2*math.sin(j*math.pi/12)) for j in range(25)]]
        points=[p for path in paths for p in path]
        left,right=min(p[0] for p in points),max(p[0] for p in points)
        top,bottom=min(p[1] for p in points),max(p[1] for p in points)
        factor=10.5/(max(right-left,bottom-top)+2.8)
        unit=size*scale/20
        def point(a,b):return round((10+(a-(left+right)/2)*factor)*unit),round((10+(b-(top+bottom)/2)*factor)*unit)
        draw=ImageDraw.Draw(image)
        for width,color in [(2.8,'#170d02'),(1.65,'#f3c950'),(.55,'#ffe6a0')]:
            for path in paths:draw.line([point(*p) for p in path],fill=color,width=max(1,round(width*factor*unit)),joint='curve')
    result=image.resize((size,size),Image.Resampling.LANCZOS)
    if name!='HeaderClose':
        # Resampling the new interior must not bleed into the shared frame pixels.
        frame=original.resize((size*scale,size*scale),Image.Resampling.LANCZOS).resize((size,size),Image.Resampling.LANCZOS)
        edge=round(size*.2)
        for box in [(0,0,size,edge),(0,size-edge,size,size),(0,edge,edge,size-edge),(size-edge,edge,size,size-edge)]:
            result.paste(frame.crop(box),box)
    return result

def export(root):
    images={name:render(root,name) for name in NAMES}
    reference=images['HeaderClose'].getchannel('A').tobytes()
    assert all(im.getchannel('A').tobytes()==reference for im in images.values()),'Header alpha silhouettes differ'
    for name,im in images.items():
        im.save(root/'docs/assets'/f'{name}.png')
        header=bytearray(18);header[2]=2;struct.pack_into('<HH',header,12,im.width,im.height);header[16:18]=bytes((32,40))
        (root/'Soundstone/Media'/f'{name}.tga').write_bytes(header+im.tobytes('raw','BGRA'))
    path=root/'Soundstone/Assets.lua';meta=path.read_text(encoding='utf-8')
    meta=re.sub(r'^    Header(?:Hide|Compact|Close) = .*\n','',meta,flags=re.M)
    end=meta.rfind('}')
    meta=meta[:end]+''.join(f'    {name} = {{ width=128, height=128, uv={{ 0, 1, 0, 1 }} }},\n' for name in NAMES)+meta[end:]
    path.write_text(meta,encoding='utf-8')
    print('Exported 3 red header buttons with identical dimensions and alpha silhouettes.')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    export(parser.parse_args().root.resolve())
