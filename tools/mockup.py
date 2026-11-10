"""Code-drawn layout proposals using production sprites; never edits runtime assets.
Requires Pillow. Without arguments it generates the 0.3 boards and a local, switchable HTML mockup.
`python tools/mockup.py forever` only generates the WoW: Forever comparison board (see forever_board).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageStat
import math, re, sys
R=Path(__file__).resolve().parents[1]
S=3
W,H=1320,1260
assets={}
for n,w,h,uv in re.findall(r'(\w+) = \{ width=(\d+), height=(\d+), uv=\{ ([^}]+)',(R/'Soundstone/Assets.lua').read_text()):
    im=Image.open(R/'docs/assets'/f'{n}.png').convert('RGBA');u=[float(x) for x in uv.split(',')]
    assets[n]=(im.crop(tuple(round(v) for v in (u[0]*im.width,u[2]*im.height,u[1]*im.width,u[3]*im.height))),int(w),int(h))
fontroot=Path('C:/Windows/Fonts')
fonts={}
def font(size,bold=False,ui=False):
    key=size,bold,ui
    if key not in fonts:
        name=('georgiab.ttf' if bold else 'georgia.ttf') if ui else ('segoeuib.ttf' if bold else 'segoeui.ttf')
        fonts[key]=ImageFont.truetype(str(fontroot/name),round(size*S))
    return fonts[key]
def text(s,x,y,size=16,color='#e7e0d1',bold=False,anchor='lm',ui=False):
    d.text((round(x*S),round(y*S)),s,font=font(size,bold,ui),fill=color,anchor=anchor)
def rect(x,y,w,h,color):d.rectangle((x*S,y*S,(x+w)*S,(y+h)*S),fill=color)
def line(points,color,width=1):d.line([(round(x*S),round(y*S)) for x,y in points],fill=color,width=max(1,round(width*S)),joint='curve')
def sprite(n,x,y,w,h):
    im=assets[n][0].resize((round(w*S),round(h*S)),Image.Resampling.LANCZOS)
    board.alpha_composite(im,(round(x*S),round(y*S)))
def skin(n,x,y,w,h,corner=None):
    im,ow,oh=assets[n];sc=52 if n.startswith('Classic') else 23;c=10 if n.startswith('Classic') else 7
    if n.startswith('Toggle'):sc,c=14,4
    c=corner or c
    xs=[0,round(im.width*sc/ow),im.width-round(im.width*sc/ow),im.width]
    sy=min(sc,oh/2-1)
    ys=[0,round(im.height*sy/oh),im.height-round(im.height*sy/oh),im.height]
    dx=[round(z*S) for z in [x,x+c,x+w-c,x+w]];dy=[round(z*S) for z in [y,y+c,y+h-c,y+h]]
    for j in range(3):
        for i in range(3):
            tile=im.crop((xs[i],ys[j],xs[i+1],ys[j+1])).resize((dx[i+1]-dx[i],dy[j+1]-dy[j]),Image.Resampling.LANCZOS)
            board.alpha_composite(tile,(dx[i],dy[j]))
def glyph(n,x,y,box):
    _,w,h=assets[n];f=box/max(w,h);sprite(n,x+(box-w*f)/2,y+(box-h*f)/2,w*f,h*f)
def gear(x,y,k):
    pts=[]
    for i in range(32):
        a=i*math.pi/16;r=(7 if i%4<2 else 5.4)*k;pts.append((x+math.cos(a)*r,y+math.sin(a)*r))
    d.polygon([(a*S,b*S) for a,b in pts],fill='#cab783',outline='#584426',width=round(S*k*.7))
    d.ellipse(((x-2.4*k)*S,(y-2.4*k)*S,(x+2.4*k)*S,(y+2.4*k)*S),fill='#373026',outline='#f6dda0',width=max(1,round(S*k*.5)))
def action(n,x,y,k):
    sprite('ActionNormal',x,y,19*k,19*k);sprite(n,x+k,y+k,17*k,17*k)
def redbutton(n,x,y,k):
    name={'EyeOff':'HeaderHide','Collapse':'HeaderCompact','Close':'HeaderClose'}[n]
    sprite(name,x,y,20*k,20*k)
def grip(x,y,k):
    for r in range(3):
        for c in range(2):sprite('Rivet',x+c*5.3*k,y+r*5.3*k,3.1*k,3.1*k)
def toggle(label,x,y,w,k):skin('ToggleRed',x,y,w*k,20*k,4*k);text(label,x+w*k/2,y+10*k,10*k,'#ffdc64',anchor='mm',ui=True)
def track(theme,x,y,w,value,k):
    skin('Toggle',x,y-4*k,w*k,8*k,2*k);rect(x+3*k,y-1.5*k,(w-6)*k*value/100,3*k,'#edb230')
    sprite('SilverThumb' if theme=='Classic' else 'GoldThumb',x+(w-10)*k*value/100,y-9*k,10*k,18*k)
def compact(theme,x,y,k):
    skin(theme+'Bar',x,y,276*k,36*k,10*k if theme=='Classic' else 7*k)
    grip(x+8.3*k,y+11.15*k,k);gear(x+33.5*k,y+18*k,k);action('Expand',x+45*k,y+8.5*k,k)
    for i,n in enumerate(['Master','Sfx','Music']):
        a=x+(66+i*68)*k;glyph(n,a+4*k,y+7*k,22*k);text('100 %',a+65*k,y+18*k,11*k,anchor='rm',ui=True)
        if i:rect(a,y+5*k,.6*k,26*k,'#70654e')
def options(theme,x,y,k):
    skin(theme+'Panel',x,y,276*k,212*k,10*k if theme=='Classic' else 7*k)
    text('Optionen',x+10*k,y+14*k,12*k,'#ffcf43',ui=True);sprite('Close',x+251*k,y+6*k,18*k,18*k)
    text('Ausgabegerät',x+10*k,y+36*k,10*k,'#ffcf43',ui=True)
    skin('Toggle',x+10*k,y+44*k,256*k,24*k,4*k);text('Standardeinstellungen',x+17*k,y+56*k,10*k,ui=True)
    skin('Toggle',x+245*k,y+46*k,19*k,20*k,3*k)
    d.polygon([((x+a*k)*S,(y+b*k)*S) for a,b in [(249,53),(260,53),(254.5,60)]],fill='#ffdc55')
    text('Soundstone-Größe',x+10*k,y+79*k,10*k,'#ffcf43',ui=True)
    track(theme,x+10*k,y+96*k,208,100/3,k);text('100 %',x+266*k,y+96*k,10*k,anchor='rm',ui=True)
    for i,label in enumerate(['Minimap-Button anzeigen','Positionen sperren']):
        yy=y+(110+i*24)*k
        d.rectangle(((x+14*k)*S,(yy+4*k)*S,(x+30*k)*S,(yy+20*k)*S),fill='#202020',outline='#aaaa98',width=round(S*k))
        if not i:line([(x+14*k,yy+11*k),(x+20*k,yy+17*k),(x+32*k,yy+4*k)],'#ffdb24',2*k)
        text(label,x+36*k,yy+12*k,10*k,ui=True)
    toggle('Größe zurücksetzen',x+10*k,y+162*k,256,k);toggle('Position zurücksetzen',x+10*k,y+186*k,256,k)
def expanded(theme,x,y,k):
    skin(theme+'Panel',x,y,300*k,160*k,10*k if theme=='Classic' else 7*k)
    grip(x+10.8*k,y+7.65*k,k);gear(x+34.5*k,y+14.5*k,k)
    text('Soundstone',x+150*k,y+14.5*k,14*k,'#ffcf43',anchor='mm',ui=True)
    for n,xx in [('EyeOff',231),('Collapse',253),('Close',275)]:redbutton(n,x+xx*k,y+4*k,k)
    rect(x+7*k,y+27*k,286*k,k,'#786e5e')
    for i,(n,label) in enumerate(zip(['Master','Sfx','Music'],['Gesamt','Soundeffekte','Musik'])):
        yy=y+(50+42*i)*k
        if theme=='Classic':skin('ClassicPanel',x+12*k,yy-12.5*k,25*k,25*k,3*k)
        glyph(n,x+16*k,yy-8.5*k,17*k);text(label,x+42*k,yy,10*k,ui=True)
        toggle('An',x+111*k,yy-10*k,34,k);track(theme,x+155*k,yy,98,100,k);text('100 %',x+288*k,yy,10*k,anchor='rm',ui=True)
        if i<2:rect(x+14*k,yy+21*k,272*k,.6*k,'#5c564d')
    text('v0.3.0  ♥ by krebs3r',x+290*k,y+151*k,7.5*k,'#998d7e',anchor='rm')
def make(above):
    global board,d
    board=Image.new('RGBA',(W*S,H*S),'#151819');d=ImageDraw.Draw(board)
    text('SOUNDSTONE',48,51,15,'#bba073',True)
    text('Einheitliche Breite. Direkte Bedienung.',48,102,34,'#f5eddc',True)
    text('0.3.0 · Freigegebene Vorlage · Einstellungen '+('oberhalb' if above else 'unterhalb')+' der Kompaktleiste',48,148,18,'#a4acae')
    for theme,x in [('Retail',48),('Classic',696)]:
        text(theme,x,202,24,'#e7c990',True)
        text('276 UI-Einheiten · identische Außenkanten',x,236,16,'#9ba6a7')
        y=267;k=1.8
        if above:options(theme,x,y,k);compact(theme,x,y+216*k,k)
        else:compact(theme,x,y,k);options(theme,x,y+40*k,k)
        text('4 Einheiten Abstand · unten kein Platz → oberhalb',x,740,15,'#929d9d')
        text('Große Ansicht',x,808,24,'#e7c990',True)
        text('Auge → Kompaktansicht → X · alle 20 × 20',x,844,17,'#acb5b6')
        expanded(theme,x,875,k)
    rect(48,1191,1190,1,'#343b3e')
    text('Entwurf: Alle drei roten Buttons nutzen den identischen X-Rahmen und dieselben Außenmaße.',48,1217,15,'#94a0a2')
    text('Die Kompakt-Buttons bleiben unverändert. Keine Ingame-Aufnahme.',48,1240,15,'#94a0a2')
    out=R/'docs'/('ui-mockup-0.3-above.png' if above else 'ui-mockup-0.3.png')
    board.resize((W,H),Image.Resampling.LANCZOS).convert('RGB').save(out)
    print(out)
def button_detail():
    global board,d
    board=Image.new('RGBA',(720*S,240*S),'#151819');d=ImageDraw.Draw(board)
    text('Ein Rahmen. Drei gleich große Buttons.',32,32,23,'#f5eddc',True)
    for n,label,x in [('EyeOff','Ausblenden',95),('Collapse','Kompaktansicht',310),('Close','Schließen',525)]:
        redbutton(n,x,70,5)
        text(label,x+50,197,16,'#e7c990',anchor='mm')
        text('20 × 20',x+50,222,14,'#9ba6a7',anchor='mm')
    board.resize((720,240),Image.Resampling.LANCZOS).convert('RGB').save(R/'docs/ui-mockup-0.3-buttons.png')
html='''<!doctype html><html lang="de"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Soundstone 0.3 – Designvorschlag</title>
<style>body{margin:0;background:#151819;color:#eee5d4;font:16px system-ui}nav{position:sticky;top:0;padding:14px 24px;background:#202628f5;border-bottom:1px solid #474239;display:flex;gap:14px;align-items:center;flex-wrap:wrap}select{font:inherit;background:#342f25;color:#f5d69c;border:1px solid #8c7751;border-radius:5px;padding:7px}a{color:#dec085}p{margin:0;color:#abb5b6;font-size:14px}figure{margin:0 auto;max-width:1320px}img{display:block;width:100%;height:auto}details{padding:14px 24px;background:#202628}details p{margin-top:8px;max-width:950px}</style>
<nav><label for="attachment">Einstellungen öffnen</label><select id="attachment"><option value="below">Unterhalb der Leiste</option><option value="above">Oberhalb der Leiste</option></select><a href="ui-preview.html">Aktuell implementiertes UI</a><p>Freigegebenes Mockup – inzwischen lokal umgesetzt.</p></nav>
<details><summary>Maße und Verhalten im Entwurf</summary><p>Leiste: 276 × 36. Optionen: 276 × 212. Abstand: 4. Die Einstellungen öffnen bündig unterhalb der Leiste und bei fehlendem Platz darüber. Dropdown und Rücksetzknöpfe wachsen auf 256 Einheiten Innenbreite. Die große Ansicht bleibt 300 × 160. Ihr rechter Buttonblock enthält Auge, Ansichtswechsel und X mit identischem Rahmen, identischen sichtbaren Außenkanten und jeweils 20 × 20 Einheiten; die linke Zahnradposition und die Kompakt-Buttons bleiben erhalten. Bei geöffnetem großem Fenster werden die Optionen ebenfalls vertikal angebracht, ihre Breite bleibt 276.</p></details>
<figure><img id="proposal" src="ui-mockup-0.3.png" alt="Retail und Classic: gleich breite Kompaktleiste und angehängte Einstellungen; große Ansicht mit rotem Auge, Kompaktbutton und X rechts."></figure>
<script>document.querySelector('#attachment').addEventListener('change',e=>{document.querySelector('#proposal').src=e.target.value==='above'?'ui-mockup-0.3-above.png':'ui-mockup-0.3.png'});</script></html>'''

# --- WoW: Forever comparison board ---------------------------------------------------------------
# Drawn at the target pixel grid instead of supersampled, so that a line of one physical pixel stays
# one pixel. Geometry follows Soundstone/UI.lua. The outer columns use the shipped sprites. The middle
# column draws Forever's own window frame in code, after colors measured on lossless screenshots
# of Forever at FV_K; no Blizzard art is copied or shipped.
FV_K=1.3125  # physical pixels per UI unit, the scale of the Forever screenshots the palette was measured on
FV_SOUNDSTONE=dict(text=(245,240,222),gold=(255,207,66),gear=(230,204,145),sep=(148,110,48,166),header=(171,163,143,140),
    row=(140,133,115,77),fill=(255,176,33))
FV_FOREVER=dict(band=(10,8,6),line=(104,80,52),text=(240,233,218),muted=(166,160,148),title=(255,210,0),fill=(255,176,33),
    symbol=(213,159,32),red=(90,0,0))
# Forever's window frame (Blizzard's ButtonFrameTemplateNoPortrait, as Baganator wears it there) in physical
# pixels at FV_K. Every band lists its colors from the outer edge inward; the outer corners are cut at 45 degrees.
FV_WINDOW=dict(cut=7,
    top=[(102,72,43),(131,93,50),(149,111,66),(145,116,74),(47,27,8),(64,38,11),(69,45,20),(1,1,0)],
    left=[(34,22,11),(102,72,31),(133,102,63),(127,101,69),(52,35,13),(64,38,7),(66,40,11),(5,3,1)],
    # Lit from the top left, so the right band's bright part sits inward.
    right=[(25,16,15),(81,54,24),(66,41,8),(61,37,7),(130,98,61),(117,89,56),(81,51,16),(57,38,17),(5,5,4)],
    bottom=[(8,4,2),(66,42,13),(63,41,14),(138,107,70),(125,90,55),(116,80,43),(107,80,51),(46,32,17),(2,1,1)],
    # The band's soft shade on the body, as multipliers from the band inward.
    shade=dict(left=(.31,.73,.90),right=(.65,.84,.98),bottom=(.59,.80,.94)),
    strip=(34,20,11),separator=[(90,59,22),(104,70,29),(134,103,59),(33,10,0),(45,18,0),(23,13,4),(8,7,7)],
    body=(52,48,41),under=(9,8,7))
FV_SIDES=('top','left','right','bottom')
FV_STATE=dict(values=[80,60,25],on=[True,True,False],labels=['Master','Sound effects','Music'])
_fv_fonts={}
def fv_font(px,ui=True,bold=False):
    key=round(px*4)/4,ui,bold
    if key not in _fv_fonts:
        name=('georgiab.ttf' if bold else 'georgia.ttf') if ui else ('segoeuib.ttf' if bold else 'segoeui.ttf')
        _fv_fonts[key]=ImageFont.truetype(str(fontroot/name),max(1,round(px)))
    return _fv_fonts[key]
def fv_shade(im,tint=None,alpha=1,desat=False):
    if not tint and alpha==1 and not desat:return im
    r,g,b,a=im.split()
    if desat:r=g=b=Image.merge('RGB',(r,g,b)).convert('L')
    if tint:r,g,b=(c.point(lambda v,t=t:round(v*t)) for c,t in zip((r,g,b),tint))
    if alpha!=1:a=a.point(lambda v:round(v*alpha))
    return Image.merge('RGBA',(r,g,b,a))
class Pane:
    """One Soundstone frame at k pixels per UI unit, its top left on a whole pixel like the addon's root."""
    def __init__(s,img,ox,oy,k=FV_K):s.img,s.ox,s.oy,s.k=img,ox,oy,k
    def X(s,u):return s.ox+math.floor(u*s.k+.5)
    def Y(s,u):return s.oy+math.floor(u*s.k+.5)
    def box(s,x,y,w,h):return s.X(x),s.Y(y),s.X(x+w),s.Y(y+h)
    def px(s,x0,y0,x1,y1,rgba):
        if x1>x0 and y1>y0:s.img.alpha_composite(Image.new('RGBA',(x1-x0,y1-y0),tuple(rgba)+(() if len(rgba)==4 else (255,))),(x0,y0))
    def fill(s,x,y,w,h,rgba):s.px(*s.box(x,y,w,h),rgba)
    def sprite(s,n,x,y,w,h,**kw):
        x0,y0,x1,y1=s.box(x,y,w,h)
        if x1>x0 and y1>y0:s.img.alpha_composite(fv_shade(assets[n][0].resize((x1-x0,y1-y0),Image.Resampling.LANCZOS),**kw),(x0,y0))
    def glyph(s,n,x,y,size,**kw):
        _,w,h=assets[n];f=size/max(w,h);s.sprite(n,x+(size-w*f)/2,y+(size-h*f)/2,w*f,h*f,**kw)
    def skin(s,n,x,y,w,h,corner=None):
        # The client's nine-slice: a source corner wider than half the sprite gives a mirrored middle range.
        im,ow,oh=assets[n];sc=52 if n.startswith('Classic') else 23;c=10 if n.startswith('Classic') else 7
        if n.startswith('Toggle'):sc,c=14,4
        c=corner or c;cx,cy=im.width*sc/ow,im.height*sc/oh
        xs=[0,round(cx),round(im.width-cx),im.width];ys=[0,round(cy),round(im.height-cy),im.height]
        dx=[s.X(z) for z in (x,x+c,x+w-c,x+w)];dy=[s.Y(z) for z in (y,y+c,y+h-c,y+h)]
        for j in range(3):
            for i in range(3):
                if dx[i+1]<=dx[i] or dy[j+1]<=dy[j]:continue
                a,b,e,f=xs[i],ys[j],xs[i+1],ys[j+1]
                tile=im.crop((min(a,e),min(b,f),max(a,e)+(a==e),max(b,f)+(b==f)))
                if e<a:tile=tile.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                if f<b:tile=tile.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
                s.img.alpha_composite(tile.resize((dx[i+1]-dx[i],dy[j+1]-dy[j]),Image.Resampling.LANCZOS),(dx[i],dy[j]))
    def text(s,t,x,y,size,color,anchor='lm',alpha=1):
        ImageDraw.Draw(s.img,'RGBA').text((s.ox+x*s.k,s.oy+y*s.k),t,font=fv_font(size*s.k),fill=tuple(color[:3])+(round(255*alpha),),anchor=anchor)
    def fit(s,t,size,minimum,width):
        # Soundstone shrinks text in half steps until it fits (UI.lua fit); measured here with the stand-in font.
        while size>minimum and fv_font(size*s.k).getlength(t)/s.k>width-1:size-=.5
        return size
    def vector(s,x,y,w,h,draw,ss=4):
        x0,y0,x1,y1=s.box(x,y,w,h)
        if x1<=x0 or y1<=y0:return
        layer=Image.new('RGBA',((x1-x0)*ss,(y1-y0)*ss),(0,0,0,0));draw(ImageDraw.Draw(layer),(x1-x0)*ss/w,(y1-y0)*ss/h)
        s.img.alpha_composite(layer.resize((x1-x0,y1-y0),Image.Resampling.LANCZOS),(x0,y0))
    # One physical pixel, independent of k: what the plan's pixel lines do in the game.
    def ring(s,x,y,w,h,top,sides,bottom,inner=None):
        x0,y0,x1,y1=s.box(x,y,w,h)
        s.px(x0,y0,x1,y0+1,top);s.px(x0,y1-1,x1,y1,bottom);s.px(x0,y0+1,x0+1,y1-1,sides);s.px(x1-1,y0+1,x1,y1-1,sides)
        if inner:s.px(x0+1,y0+1,x1-1,y0+2,inner);s.px(x0+1,y1-2,x1-1,y1-1,inner);s.px(x0+1,y0+2,x0+2,y1-2,inner);s.px(x1-2,y0+2,x1-1,y1-2,inner)
    def hline(s,x,y,w,rgba):x0,y0,x1,_=s.box(x,y,w,0);s.px(x0,y0,x1,y0+1,rgba)
    def vline(s,x,y,h,rgba):x0,y0,_,y1=s.box(x,y,0,h);s.px(x0,y0,x0+1,y1,rgba)

# Stand-ins for the client's own art, which this repository does not redistribute.
def fv_gear(p,cx,cy,tint):
    # GEAR_64GREY is a gray texture: the vertex color multiplies it. Its brightest pixel on Forever today is
    # 154/134/97 under the tint .9/.8/.57, i.e. about 0.67 of the tint.
    color=tuple(round(v*.67) for v in tint)+(255,)
    def draw(d,sx,sy):
        pts=[((9.5+math.cos(i*math.pi/16)*(7 if i%4<2 else 5.4))*sx,(9.5+math.sin(i*math.pi/16)*(7 if i%4<2 else 5.4))*sy) for i in range(32)]
        d.polygon(pts,fill=color);d.ellipse(((9.5-2.4)*sx,(9.5-2.4)*sy,(9.5+2.4)*sx,(9.5+2.4)*sy),fill=(0,0,0,0))
    p.vector(cx-9.5,cy-9.5,19,19,draw)
# The button, checkbox and device field follow Soundstone's own controls as Forever drew them, captured
# enabled and lossless on 8 November 2026 (see docs/FOREVER-THEME-PLAN.md).
def fv_button(p,label,x,y,w,h):
    # UIPanelButtonTemplate: dark edge, gray rim, red body #460000 -> #6B0000 -> #3F0000, gold label.
    def draw(d,sx,sy):
        W,H=w*sx,h*sy;r=2*sx
        d.rounded_rectangle((0,0,W-1,H-1),radius=r,fill=(10,10,10,255))
        d.rounded_rectangle((.8*sx,.8*sy,W-1-.8*sx,H-1-.8*sy),radius=r,fill=(74,73,74,255))
        d.rounded_rectangle((.8*sx,H*.55,W-1-.8*sx,H-1-.8*sy),radius=r,fill=(54,53,54,255))
        top,bottom=1.9*sy,H-1.9*sy
        for row in range(round(top),round(bottom)):
            t=(row-top)/max(1,bottom-top);v=70+(107-70)*min(1,t*6) if t<.17 else 102-(102-63)*max(0,(t-.6)/.4)
            d.line([(1.9*sx,row),(W-1.9*sx,row)],fill=(round(v),round(v*.02),round(v*.02),255))
    p.vector(x,y,w,h,draw);p.text(label,x+w/2,y+h/2,10,(255,210,0),'mm')
def fv_check(p,x,y,checked):
    # UICheckButtonTemplate: a 16-unit box, gray rim, near-black inside, yellow check #FFFB21.
    def draw(d,sx,sy):
        d.rounded_rectangle((4*sx,4*sy,20*sx,20*sy),radius=2.5*sx,fill=(7,7,7,255))
        d.rounded_rectangle((4.7*sx,4.7*sy,19.3*sx,19.3*sy),radius=2*sx,fill=(74,73,74,255))
        d.rounded_rectangle((5.5*sx,5.5*sy,18.5*sx,18.5*sy),radius=1.5*sx,fill=(13,13,13,255))
        if checked:d.line([(5*sx,12*sy),(9.5*sx,16.5*sy),(20*sx,5*sy)],fill=(255,251,33,255),width=round(1.6*sx),joint='curve')
    p.vector(x,y,24,24,draw)
def fv_dropdown(p,x,y,w,label,forever):
    if forever:
        # WowStyle1DropdownTemplate on Forever: ground #110E09 inside a double bronze line, gold arrow in a gray box.
        def draw(d,sx,sy):
            W,H=w*sx,24*sy;c=2.5*sx
            def chamfer(i,fill):d.polygon([(c+i,i),(W-1-c-i,i),(W-1-i,c+i),(W-1-i,H-1-c-i),(W-1-c-i,H-1-i),(c+i,H-1-i),(i,H-1-c-i),(i,c+i)],fill=fill)
            chamfer(0,(97,79,53,255));chamfer(.8*sx,(29,23,15,255));chamfer(1.6*sx,(65,52,36,255));chamfer(2.4*sx,(17,14,9,255))
            d.rectangle((W-20*sx,3*sy,W-3.2*sx,H-3.2*sy),fill=(40,40,40,255),outline=(116,85,50,255),width=max(1,round(.8*sx)))
        p.vector(x,y,w,24,draw)
    else:p.skin('Toggle',x,y,w,24,4);p.skin('Toggle',x+w-21,y+2,19,20,3)
    p.vector(x+w-15.5,y+9,11,7,lambda d,sx,sy:d.polygon([(0,0),(11*sx,0),(5.5*sx,7*sy)],fill=(239,190,0,255) if forever else (255,220,85,255)))
    p.text(label,x+7,y+12,10,(255,255,255),'lm')

# Forever's own frames, drawn pixel by pixel from the colors measured on its screenshots.
def fv_image(w,h,color):
    """An RGBA image of w x h physical pixels; color(x,y) gives (r,g,b), (r,g,b,a) or None for clear."""
    data=bytearray()
    for y in range(h):
        for x in range(w):
            c=color(x,y)
            if c is None:data+=b'\0\0\0\0'
            else:data+=bytes(max(0,min(255,round(v))) for v in c)+(b'\xff' if len(c)==3 else b'')
    return Image.frombytes('RGBA',(w,h),bytes(data))
def fv_edge(x,y,w,h,widths,cut):
    """Where pixel x,y of a w x h rectangle lies: False in a cut-off corner, None inside every band, else
    (side, depth from the outer edge), or ('cut', depth, its two sides) along a corner cut with legs of `cut` pixels."""
    dh,hs=(x,'left') if x<=w-1-x else (w-1-x,'right')
    dv,vs=(y,'top') if y<=h-1-y else (h-1-y,'bottom')
    if dh+dv<cut:return False
    best=None
    for d,side in ((dv,vs),(dh,hs)):
        if d<widths[side] and (best is None or d<best[1]):best=(side,d)
    dc=dh+dv-cut
    if dc<min(widths[vs],widths[hs]) and (best is None or dc<best[1]):best=('cut',dc,vs,hs)
    return best
def fv_paste(img,im,x,y):
    """alpha_composite that clips at the canvas's left and top edges (the close-up tile is smaller than a shadow)."""
    l,t=max(0,-x),max(0,-y);img.alpha_composite(im.crop((l,t,im.width,im.height)),(x+l,y+t))
def fv_band(palette,e):
    if e[0]!='cut':return palette[e[0]][e[1]]
    a,b=palette[e[2]],palette[e[3]];i=e[1]
    return tuple((u+v)/2 for u,v in zip(a[min(i,len(a)-1)],b[min(i,len(b)-1)]))
def fv_window(p,w,h,strip=True):
    """Forever's window frame on a frame of w x h units: drop shadow, band, title strip, separator and body.
    Without the strip (the compact bar, UI:BuildBarBand) the body starts under the top band's inner line."""
    F=FV_WINDOW;W,H=p.X(w)-p.X(0),p.Y(h)-p.Y(0);widths={s:len(F[s]) for s in FV_SIDES}
    # A soft black shadow, about 6 units, under the window.
    m=8;mask=Image.new('L',(W+2*m,H+2*m),0);ImageDraw.Draw(mask).rectangle((m,m+2,m+W-1,m+H+1),fill=150)
    shadow=Image.new('RGBA',mask.size,(0,0,0,255));shadow.putalpha(mask.filter(ImageFilter.GaussianBlur(3)))
    fv_paste(p.img,shadow,p.X(0)-m,p.Y(0)-m)
    # The title strip from 6.15 units down to 22.9, then the separator; the body from 29.7 units down, where
    # the client's streaks lift it from near black over about 45 pixels. On the bar they are pressed into 4 units.
    if strip:s0,s1,b0,fade=round(6.15*p.k),round(22.9*p.k),round(29.7*p.k),45
    else:s0=s1=b0=widths['top'];fade=4*p.k
    def color(x,y):
        e=fv_edge(x,y,W,H,widths,F['cut'])
        if e is False:return None
        if e:return fv_band(F,e)
        if y<s1:
            t=min(y-s0,s1-1-y);return tuple(v*((.55,.8,.93)[t] if t<3 else 1) for v in F['strip'])
        if y<b0:return F['separator'][min(y-s1,len(F['separator'])-1)]
        t=y-b0;f=(1-t/fade)**1.59 if t<fade else 0;c=[b-(b-u)*f for b,u in zip(F['body'],F['under'])]
        for d,side in ((x-widths['left'],'left'),(W-1-widths['right']-x,'right'),(H-1-widths['bottom']-y,'bottom')):
            if 0<=d<3:c=[v*F['shade'][side][d] for v in c]
        return c
    p.img.alpha_composite(fv_image(W,H,color),(p.X(0),p.Y(0)))
def fv_close(p,w):
    """Forever's red close button (28 units at the border's TOPRIGHT 0,3): 36 x 33 pixels of art flush with the
    frame's right edge, over its top-right corner. Bronze bevel, a black pixel, red field, yellow X."""
    W,H=36,33;widths=dict(top=3,left=3,right=3,bottom=3)
    rim=dict(top=[(230,205,169),(168,132,88)],left=[(168,132,88),(122,88,49)],right=[(122,88,49),(97,68,37)],bottom=[(88,60,31),(68,46,23)])
    def color(x,y):
        e=fv_edge(x,y,W,H,widths,4)
        if e is False:return None
        if e is None:return (110-30*(y-3)/(H-7),2,1)
        return (0,0,0) if e[1]==2 else fv_band(rim,e)
    im=fv_image(W,H,color);ss=4;layer=Image.new('RGBA',(W*ss,H*ss),(0,0,0,0));d=ImageDraw.Draw(layer)
    cx,cy,r=W/2*ss,H/2*ss,6.2*ss
    def cross(dx,dy,width,fill):
        for s in (1,-1):d.line([(cx-r+dx,cy-s*r+dy),(cx+r+dx,cy+s*r+dy)],fill=fill,width=round(width*ss))
    cross(0,0,5.6,(30,0,0,170));cross(.7*ss,.9*ss,3.4,(242,197,8,255));cross(0,0,3.4,(255,236,51,255))
    im.alpha_composite(layer.resize((W,H),Image.Resampling.LANCZOS))
    p.img.alpha_composite(im,(p.X(w)-W,p.Y(0)+2))
def fv_header(p,x,y,symbol,w=32,size=None):
    """A header button as Baganator's on Forever: UIPanelButtonTemplate at w x 22 units, its visible bevel
    2.3 units in from each side and 19 high (27.4 x 19 at 32 wide: 36 x 25 pixels), a gold symbol on the dark red."""
    x0,y0,x1,y1=p.box(x,y,w,22);W,H=round((w-4.6)*p.k),round(19*p.k);ox,oy=x0+(x1-x0-W)//2,y0+(y1-y0-H)//2
    widths=dict(top=2,left=2,right=2,bottom=2);light,dark=(84,83,84),(52,47,48)
    def color(px,py):
        e=fv_edge(px,py,W,H,widths,3)
        if e is False:return None
        if e is None:return (90-12*(py-2)/(H-5),0,0)
        if e[1]==1:return (0,0,0)
        side=e[2] if e[0]=='cut' else e[0]
        if side in ('top','bottom'):return light if side=='top' else dark
        return tuple(a+(b-a)*py/(H-1) for a,b in zip(light,dark))
    p.img.alpha_composite(fv_image(W,H,color),(ox,oy))
    cx,cy=x+w/2,y+11;gold=FV_FOREVER['symbol']
    if symbol=='gear':
        # GEAR_64GREY (17 units in the header, 15 on the bar), tinted: drawn as a stand-in, like the gear elsewhere on this board.
        size=size or 17;c=size/2;g=size/17
        def draw(d,sx,sy):
            pts=[((c+math.cos(i*math.pi/16)*(7.1 if i%4<2 else 5.6)*g)*sx,(c+math.sin(i*math.pi/16)*(7.1 if i%4<2 else 5.6)*g)*sy) for i in range(32)]
            d.polygon(pts,fill=gold+(255,));d.ellipse(((c-2.5*g)*sx,(c-2.5*g)*sy,(c+2.5*g)*sx,(c+2.5*g)*sy),fill=(0,0,0,0))
        p.vector(cx-c,cy-c,size,size,draw)
    else:
        # Soundstone's own symbol sprite (16 units in the header, 14 for Expand on the bar), tinted to the measured gold.
        im,sw,sh=assets[symbol];f=(size or 16)/max(sw,sh);bx0,by0,bx1,by1=p.box(cx-sw*f/2,cy-sh*f/2,sw*f,sh*f)
        mean=ImageStat.Stat(im.convert('RGB'),im.getchannel('A').point(lambda v:255 if v>200 else 0)).mean
        r,g,b,a=im.resize((bx1-bx0,by1-by0),Image.Resampling.LANCZOS).split()
        r,g,b=(c.point(lambda v,t=t/m:min(255,round(v*t))) for c,t,m in zip((r,g,b),gold,mean))
        p.img.alpha_composite(Image.merge('RGBA',(r,g,b,a)),(bx0,by0))
def fv_slot(p,x,y):
    """Forever's action-button frame around a 25-unit channel icon (46:45 of it): a 2-pixel rim, light outside,
    a 2-pixel shadow inside on the top and left, corners cut; the middle stays open."""
    x0,y0,x1,y1=p.box(x,y,25*46/45,25);W,H=x1-x0,y1-y0;shadow=[(4,3,2,235),(4,3,2,120)]
    pal=dict(top=[(130,112,95),(87,68,51)]+shadow,left=[(102,85,70),(74,56,38)]+shadow,right=[(154,135,115),(67,49,32)],bottom=[(142,122,102),(63,46,28)])
    widths={s:len(pal[s]) for s in FV_SIDES}
    p.img.alpha_composite(fv_image(W,H,lambda px,py:(lambda e:fv_band(pal,e) if e else None)(fv_edge(px,py,W,H,widths,3))),(x0,y0))
def fv_pill(p,x,y,w):
    """Forever's settings-slider track: a pill about 10.7 units tall around y. Outline, ring, interior."""
    x0,x1=p.X(x),p.X(x+w);h=round(10.7*p.k);top=p.oy+math.floor(y*p.k-h/2+.5);W=x1-x0;r=h/2
    ends,sides,ring,inner=(59,45,38),(78,56,42),(38,28,24),(27,21,19)
    def color(px,py):
        X,Y=px+.5,py+.5;dx,dy=X-min(max(X,r),W-r),Y-r;dist=math.hypot(dx,dy);d=dist-r
        alpha=max(0,min(1,.5-d))
        if not alpha:return None
        n=abs(dy)/dist if dist else 1;line=[e+(s-e)*n for e,s in zip(ends,sides)]
        c=[i+(g-i)*max(0,min(1,d+2.5)) for i,g in zip(inner,ring)];c=[v+(l-v)*max(0,min(1,d+1.5)) for v,l in zip(c,line)]
        return c+[255*alpha]
    p.img.alpha_composite(fv_image(W,h,color),(x0,top))

# The two looks. 'sprites' is today's Retail or Classic skin; 'forever' is Forever's own window frame, drawn.
def fv_track(p,look,x,y,w,value,sprites):
    if look=='forever':
        # Forever's pill; the fill keeps 4 units clear of its rounded ends (UI.lua showTrack).
        fv_pill(p,x,y,w);p.fill(x+4,y-1.5,(w-8)*value/100,3,FV_FOREVER['fill'])
        # The thumb is the client's own Minimal_SliderBar_Button atlas at its own size, about 20 units. Drawn here after
        # Forever's settings slider: a copper diamond 14.5 units across (median #926545, brightest at its tip,
        # #F1D6C1) inside a near-black rim and shadow.
        def diamond(d,sx,sy):
            c=10*sx;r=7.25*sx
            d.polygon([(c,c-r-2*sy),(c+r+2*sx,c),(c,c+r+2.6*sy),(c-r-2*sx,c)],fill=(8,7,6,170))
            d.polygon([(c,c-r),(c+r,c),(c,c+r),(c-r,c)],fill=(26,18,12,255))
            i=r-1.1*sx;d.polygon([(c,c-i),(c+i,c),(c,c+i),(c-i,c)],fill=(140,96,65,255))
            d.polygon([(c,c-i),(c-i*.45,c-i*.55),(c+i*.45,c-i*.55)],fill=(200,160,128,255))
            d.line([(c-i*.3,c-i*.7),(c,c-i),(c+i*.3,c-i*.7)],fill=(241,214,193,255),width=max(1,round(.7*sx)))
        p.vector(x+(w-20)*value/100,y-10,20,20,diamond)
    else:
        p.skin('Toggle',x,y-4,w,8,2);p.fill(x+3,y-1.5,(w-6)*value/100,3,FV_SOUNDSTONE['fill'])
        p.sprite('GoldThumb' if sprites=='Retail' else 'SilverThumb',x+(w-10)*value/100,y-9,10,18)
def fv_plate(p,look,sprites,kind,w,h):p.skin(sprites+kind,0,0,w,h)
def fv_grip(p,look,x,y):
    for r in range(3):
        for c in range(2):
            if look=='forever':
                cx,cy=p.X(x+c*5.3+1.55),p.Y(y+r*5.3+1.55);n=max(1,round(2*p.k))
                p.px(cx-n//2,cy-n//2,cx-n//2+n,cy-n//2+n,FV_FOREVER['muted'])
            else:p.sprite('Rivet',x+c*5.3,y+r*5.3,3.1,3.1)
def fv_colors(look):
    if look=='forever':F=FV_FOREVER;return dict(text=F['text'],title=F['title'],label=F['title'],gear=F['muted'],footer=F['muted'],footer_alpha=.85)
    S=FV_SOUNDSTONE;return dict(text=S['text'],title=S['gold'],label=S['gold'],gear=S['gear'],footer=S['text'],footer_alpha=.55)
def fv_compact(p,look,sprites):
    if look=='forever':return fv_framed_compact(p)
    c=fv_colors(look);fv_plate(p,look,sprites,'Bar',276,36);fv_grip(p,look,8.3,11.15);fv_gear(p,33.5,18,c['gear'])
    p.sprite('ActionNormal',45,8.5,19,19);p.sprite('Expand',46,9.5,17,17,tint=(.9,.9,.9))
    for i,n in enumerate(['Master','Sfx','Music']):
        a=66+i*68;on=FV_STATE['on'][i]
        p.glyph(n,a+4,7,22,desat=not on,alpha=1 if on else .66)
        t='%d %%'%FV_STATE['values'][i];p.text(t,a+66,18,p.fit(t,11,9,38),c['text'],'rm')
        if i:p.fill(a,5,.6,26,FV_SOUNDSTONE['sep'])
# Inside Forever's window frame the controls take the frame's places (framePlace in UI:BuildWindows).
FV_BORDER=dict(left=-4.4,top=-3.35,right=.5,bottom=.35)
def fv_framed_compact(p):
    # The bar wears the window's band without its title strip (UI:BuildBarBand). Gear and Expand become the
    # mixer header's red buttons, and the channels take 64 units each. Each piece's visible art sits on the
    # middle of the band's opening: the grip centred, the buttons 1 unit up, the channels half a unit down.
    F=FV_FOREVER;fv_window(p,276,36,strip=False)
    # Grip 19 x 28 at LEFT 5,0 with its squares as before.
    fv_grip(p,'forever',10.3,11.15)
    # Gear and Expand: the red button at the template's narrowest (two 12-unit caps), 24 x 22 at LEFT 25,1 and 49,1.
    fv_header(p,25,6,'gear',24,15);fv_header(p,49,6,'Expand',24,14)
    for i,n in enumerate(['Master','Sfx','Music']):
        # Channels of 64 at LEFT 75+64i,-0.5: icon at +4, the value in a 38-unit field from +24, ending 2 units early.
        a=75+i*64;on=FV_STATE['on'][i]
        p.glyph(n,a+4,7.5,22,desat=not on,alpha=1 if on else .66)
        t='%d %%'%FV_STATE['values'][i];p.text(t,a+62,18.5,p.fit(t,11,9,38),F['text'],'rm')
        # The channel dividers: one physical pixel, 26 units tall, on the channel's left edge (they ride with it).
        if i:p.vline(a,5.5,26,F['line'])
def fv_framed_title(p,w,t,size,cx):
    # Blizzard's window title: 12 units, its top 6 units below the border's top.
    p.text(t,cx,-FV_BORDER['top']+6+size/2,size,FV_FOREVER['title'],'mm')
def fv_framed_expanded(p):
    F=FV_FOREVER;fv_window(p,300,160)
    for i,n in enumerate(['Master','Sfx','Music']):
        top=30+37*i;cy=top+18.5;on=FV_STATE['on'][i]
        p.glyph(n,16,cy-8.5,17,desat=not on,alpha=1 if on else .66);fv_slot(p,12,cy-12.5)
        p.text(FV_STATE['labels'][i],42,cy,p.fit(FV_STATE['labels'][i],10,8,69),F['text'],'lm')
        fv_button(p,'On' if on else 'Off',111,cy-10,34,20)
        fv_track(p,'forever',155,cy,98,FV_STATE['values'][i],None)
        t='%d %%'%FV_STATE['values'][i];p.text(t,288,cy,p.fit(t,10,8,32),F['text'],'rm')
        # Row dividers on the rows' bottom edge: one physical pixel, muted at 0.18.
        if i<2:x0,_,x1,_=p.box(14,0,272,0);yy=p.Y(top+37)-1;p.px(x0,yy,x1,yy+1,F['muted']+(46,))
    # The footer at BOTTOMRIGHT -12,10, its texts centered 146 units down.
    w=fv_font(7.5*p.k).getlength('by krebs3r')/p.k
    p.text('by krebs3r',288,146,7.5,F['muted'],'rm',.85);p.sprite('Heart',288-w-11,142,8,8,tint=(.95,.3,.38),alpha=.85)
    p.text('v0.4.0',288-w-14,146,7.5,F['muted'],'rm',.85)
    # Header: gear at the border's TOPLEFT 8,1; hide and compact against the close button.
    left,right=FV_BORDER['left'],300+FV_BORDER['right'];y=-FV_BORDER['top']-1
    fv_header(p,left+8,y,'gear');fv_header(p,right-28-64,y,'EyeOff');fv_header(p,right-28-32,y,'Collapse');fv_close(p,300)
    # The title between gear and hide button: 12 units, smaller down to 10 to fit (UI:FitText), else the short name.
    t='Soundstone – Azeroth Audio';width=300+FV_BORDER['right']-FV_BORDER['left']-132-4;size=p.fit(t,12,10,width)
    if fv_font(size*p.k).getlength(t)/p.k>width:t='Soundstone'
    fv_framed_title(p,300,t,size,(left+40+right-92)/2)
def fv_framed_options(p):
    F=FV_FOREVER;fv_window(p,276,236)
    p.text('Output device',10,37,10,F['title'],'lm');fv_dropdown(p,10,44,256,'System Default',True)
    p.text('Soundstone size',10,78,10,F['title'],'lm');fv_track(p,'forever',10,95,208,100/3,None);p.text('100 %',266,95,10,F['text'],'rm')
    for i,label in enumerate(['Show minimap button','Lock positions','Avoid overlap when placing']):
        y=107+23*i;fv_check(p,10,y,i!=1);p.text(label,36,y+12,10,F['text'],'lm')
    fv_button(p,'Reset size',10,181,256,20);fv_button(p,'Reset position',10,204,256,20)
    fv_close(p,276);fv_framed_title(p,276,'Options',12,(FV_BORDER['left']+276+FV_BORDER['right'])/2)
def fv_expanded(p,look,sprites):
    if look=='forever':return fv_framed_expanded(p)
    c=fv_colors(look);fv_plate(p,look,sprites,'Panel',300,160);fv_grip(p,look,10.8,7.65);fv_gear(p,34.5,14.5,c['gear'])
    t='Soundstone – Azeroth Audio';p.text(t,150,14.5,p.fit(t,14,10,152),c['title'],'mm')
    for n,xx in [('HeaderHide',231),('HeaderCompact',253),('HeaderClose',275)]:p.sprite(n,xx,4,20,20)
    p.fill(7,27,286,1,FV_SOUNDSTONE['header'])
    for i,n in enumerate(['Master','Sfx','Music']):
        y0=29+42*i;on=FV_STATE['on'][i];cy=y0+21
        if sprites=='Classic':p.skin('ClassicPanel',12,y0+8.5,25,25,3)
        p.glyph(n,16,y0+12.5,17,desat=not on,alpha=1 if on else .66)
        p.text(FV_STATE['labels'][i],42,cy,p.fit(FV_STATE['labels'][i],10,8,69),c['text'],'lm')
        fv_button(p,'On' if on else 'Off',111,y0+11,34,20)
        fv_track(p,look,155,cy,98,FV_STATE['values'][i],sprites)
        t='%d %%'%FV_STATE['values'][i];p.text(t,288,cy,p.fit(t,10,8,32),c['text'],'rm')
        if i<2:p.fill(14,y0+42-.6,272,.6,FV_SOUNDSTONE['row'])
    w=fv_font(7.5*p.k).getlength('by krebs3r')/p.k;a=c['footer_alpha']
    # The footer is 8 units high at BOTTOMRIGHT -10,5 (UI.lua): its texts are centered at 151, the heart spans 147-155.
    p.text('by krebs3r',290,151,7.5,c['footer'],'rm',a);p.sprite('Heart',290-w-11,147,8,8,tint=(.95,.3,.38),alpha=a)
    p.text('v0.3.8',290-w-14,151,7.5,c['footer'],'rm',a)
def fv_options(p,look,sprites,forever_client):
    if look=='forever':return fv_framed_options(p)
    c=fv_colors(look);fv_plate(p,look,sprites,'Panel',276,236)
    p.text('Options',10,14,12,c['title'],'lm');p.sprite('Close',251,6,18,18)
    p.text('Output device',10,37,10,c['label'],'lm');fv_dropdown(p,10,44,256,'System Default',forever_client)
    p.text('Soundstone size',10,80,10,c['label'],'lm');fv_track(p,look,10,96,208,100/3,sprites);p.text('100 %',266,97,10,c['text'],'rm')
    for i,label in enumerate(['Show minimap button','Lock positions','Avoid overlap when placing']):
        y=110+24*i;fv_check(p,10,y,i!=1);p.text(label,36,y+12,10,c['text'],'lm')
    fv_button(p,'Reset size',10,186,256,20);fv_button(p,'Reset position',10,210,256,20)

def forever_board():
    k=FV_K;M=24;CW=round(300*k);GAP=40;W=M*2+CW*3+GAP*2;TOP=118;COL=TOP+58;H=COL+round(470*k)+340
    img=Image.new('RGBA',(W,H),(21,24,25,255));d=ImageDraw.Draw(img,'RGBA')
    def note(s,x,y,size,color,bold=False,anchor='la'):d.text((x,y),s,font=fv_font(size,False,bold),fill=color,anchor=anchor)
    note('SOUNDSTONE · WOW: FOREVER',M,22,14,(187,160,115),True)
    note('Forever in its own look, everywhere else unchanged',M,44,26,(245,237,220),True)
    note('Drawn, not captured, with tools/mockup.py at %s pixels per UI unit on the physical pixel grid: the outer columns from the shipped sprites, the middle one in code.'%k,M,84,14,(164,172,174))
    columns=[('Forever · 0.3.8','Classic sprites, as Forever shows them now','sprites','Classic',True),
        ('Forever · 0.4.0',"Forever's own window frame, drawn",'forever','Classic',True),
        ('Retail · unchanged','the Retail sprites stay exactly as they are','sprites','Retail',False)]
    for i,(title,sub,look,sprites,forever_client) in enumerate(columns):
        x=M+i*(CW+GAP);note(title,x,TOP,18,(231,201,144),True);note(sub,x,TOP+26,13,(155,166,167))
        # A flat backdrop stands in for the game world, so the windows' drop shadow has something to fall on.
        backdrop=Image.new('RGBA',(CW+16,round(470*k)+16));bd=ImageDraw.Draw(backdrop)
        for row in range(backdrop.height):v=row/backdrop.height;bd.line([(0,row),(backdrop.width,row)],fill=(round(66-26*v),round(57-22*v),round(48-19*v),255))
        img.alpha_composite(backdrop,(x-8,COL-8))
        fv_compact(Pane(img,x,COL,k),look,sprites)
        fv_options(Pane(img,x,COL+round(40*k),k),look,sprites,forever_client)
        fv_expanded(Pane(img,x,COL+round(300*k),k),look,sprites)
    # Close-up of the compact bar's top-left corner, eight times, nearest-neighbor: every square is one pixel.
    y=COL+round(470*k)+40;note('Top-left corner of the compact bar, every square one physical pixel (8×)',M,y,16,(231,201,144),True)
    for i,(label,look,sprites) in enumerate([('today: Classic sprite','sprites','Classic'),("proposed: the window frame's band, drawn",'forever','Classic')]):
        tile=Image.new('RGBA',(40,22),(54,47,41,255));fv_compact(Pane(tile,4,4,k),look,sprites)
        cx=M+i*(40*8+60);img.alpha_composite(tile.resize((320,176),Image.Resampling.NEAREST),(cx,y+30));note(label,cx,y+214,13,(155,166,167))
    F,Wn=FV_FOREVER,FV_WINDOW;lx=M+2*(40*8+60)
    for j,(name,rgb) in enumerate([('window band, brightest row 149/111/66',Wn['top'][2]),('title strip 34/20/11',Wn['strip']),('body of windows and bar 52/48/41',Wn['body']),
            ("shade under the separator and the bar's top band 9/8/7",Wn['under']),('bar dividers 104/80/52',F['line']),('header buttons: red 78–90/0/0, gold symbols',F['red']),
            ('text 240/233/218',F['text']),('titles and section labels: NORMAL_FONT_COLOR',F['title']),('volume fill 255/176/33, unchanged',F['fill'])]):
        yy=y+30+j*18;d.rectangle((lx,yy,lx+12,yy+12),fill=rgb[:3]+(255,),outline=(90,96,98,255));note(name,lx+20,yy-2,13,(200,204,204))
    y+=246
    note('Georgia stands in for the client font and a drawing for the gear. Music is muted in all three. Window frame, buttons, close button, icon frames, slider, thumb,',M,y,13,(148,160,162))
    note("checkboxes and device field are drawn after lossless screenshots of Forever, not captured; Blizzard's art itself is not in the repository. The Retail column uses the same buttons.",M,y+18,13,(148,160,162))
    img=img.crop((0,0,W,y+44)).convert('RGB')
    img.save(R/'docs/ui-mockup-forever.png',optimize=True)
    img.resize((img.width*2,img.height*2),Image.Resampling.NEAREST).save(R/'docs/ui-mockup-forever-2x.png',optimize=True)
    print(R/'docs/ui-mockup-forever.png');print(R/'docs/ui-mockup-forever-2x.png')

if __name__=='__main__':
    if sys.argv[1:]==['forever']:forever_board()
    elif sys.argv[1:]:sys.exit('usage: python tools/mockup.py [forever]')
    else:
        make(False);make(True);button_detail()
        (R/'docs/ui-mockup-0.3.html').write_text(html,encoding='utf-8')
