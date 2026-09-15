"""Code-drawn 0.3 layout proposal using production sprites; never edits runtime assets.
Requires Pillow. Generates the two PNG boards and a local, switchable HTML mockup.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math, re
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
make(False);make(True);button_detail()
html='''<!doctype html><html lang="de"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Soundstone 0.3 – Designvorschlag</title>
<style>body{margin:0;background:#151819;color:#eee5d4;font:16px system-ui}nav{position:sticky;top:0;padding:14px 24px;background:#202628f5;border-bottom:1px solid #474239;display:flex;gap:14px;align-items:center;flex-wrap:wrap}select{font:inherit;background:#342f25;color:#f5d69c;border:1px solid #8c7751;border-radius:5px;padding:7px}a{color:#dec085}p{margin:0;color:#abb5b6;font-size:14px}figure{margin:0 auto;max-width:1320px}img{display:block;width:100%;height:auto}details{padding:14px 24px;background:#202628}details p{margin-top:8px;max-width:950px}</style>
<nav><label for="attachment">Einstellungen öffnen</label><select id="attachment"><option value="below">Unterhalb der Leiste</option><option value="above">Oberhalb der Leiste</option></select><a href="ui-preview.html">Aktuell implementiertes UI</a><p>Freigegebenes Mockup – inzwischen lokal umgesetzt.</p></nav>
<details><summary>Maße und Verhalten im Entwurf</summary><p>Leiste: 276 × 36. Optionen: 276 × 212. Abstand: 4. Die Einstellungen öffnen bündig unterhalb der Leiste und bei fehlendem Platz darüber. Dropdown und Rücksetzknöpfe wachsen auf 256 Einheiten Innenbreite. Die große Ansicht bleibt 300 × 160. Ihr rechter Buttonblock enthält Auge, Ansichtswechsel und X mit identischem Rahmen, identischen sichtbaren Außenkanten und jeweils 20 × 20 Einheiten; die linke Zahnradposition und die Kompakt-Buttons bleiben erhalten. Bei geöffnetem großem Fenster werden die Optionen ebenfalls vertikal angebracht, ihre Breite bleibt 276.</p></details>
<figure><img id="proposal" src="ui-mockup-0.3.png" alt="Retail und Classic: gleich breite Kompaktleiste und angehängte Einstellungen; große Ansicht mit rotem Auge, Kompaktbutton und X rechts."></figure>
<script>document.querySelector('#attachment').addEventListener('change',e=>{document.querySelector('#proposal').src=e.target.value==='above'?'ui-mockup-0.3-above.png':'ui-mockup-0.3.png'});</script></html>'''
(R/'docs/ui-mockup-0.3.html').write_text(html,encoding='utf-8')
