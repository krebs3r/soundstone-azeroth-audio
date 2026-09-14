"""Render the exported game assets in an inspectable, size-accurate HTML preview."""
import json
import re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
assets={}
for name,w,h,uv in re.findall(r'(\w+) = \{ width=(\d+), height=(\d+), uv=\{ ([^}]+)',(root/'Soundstone/Assets.lua').read_text()):
    assets[name]={'width':int(w),'height':int(h),'uv':[float(n) for n in uv.split(',')]}
html='''<!doctype html><meta charset="utf-8"><title>Soundstone 0.2 – Asset preview</title>
<style>body{background:#171717;color:#e7d7ad;font:16px Georgia;margin:32px}h1{font-size:26px}p{color:#bcb6a7}section{display:flex;gap:32px;flex-wrap:wrap}canvas{width:600px;height:450px}small{color:#aaa}</style>
<h1>Soundstone 0.2 · Produktionsgrafiken</h1><p>300 × 45 / 300 × 160 UI-Einheiten · hier zweifach vergrößert. Schrift als Vorschau; die Spielversion verwendet WoWs Schrift.</p><section><div><h2>Retail</h2><canvas id="Retail" width="1200" height="900"></canvas></div><div><h2>Classic</h2><canvas id="Classic" width="1200" height="900"></canvas></div></section>
<script>const assets=ASSETS;const images={};
function draw(c,n,x,y,w,h){const a=assets[n],im=images[n],u=a.uv;c.drawImage(im,u[0]*im.width,u[2]*im.height,(u[1]-u[0])*im.width,(u[3]-u[2])*im.height,x,y,w,h)}
function skin(c,n,x,y,w,h){const a=assets[n],im=images[n],u=a.uv;let sc=n.startsWith('Classic')?52:23,corner=n.startsWith('Classic')?10:7;if(n.startsWith('Toggle')){sc=14;corner=4}
let xs=[u[0],u[0]+(u[1]-u[0])*sc/a.width,u[1]-(u[1]-u[0])*sc/a.width,u[1]],ys=[u[2],u[2]+(u[3]-u[2])*sc/a.height,u[3]-(u[3]-u[2])*sc/a.height,u[3]];
let dx=[x,x+corner,x+w-corner,x+w],dy=[y,y+corner,y+h-corner,y+h];for(let j=0;j<3;j++)for(let i=0;i<3;i++)c.drawImage(im,xs[i]*im.width,ys[j]*im.height,(xs[i+1]-xs[i])*im.width,(ys[j+1]-ys[j])*im.height,dx[i],dy[j],dx[i+1]-dx[i],dy[j+1]-dy[j])}
function glyph(c,n,x,y,size,mute){const a=assets[n],f=size/Math.max(a.width,a.height),w=a.width*f,h=a.height*f;c.save();if(mute)c.filter='grayscale(1)';draw(c,n,x+(size-w)/2,y+(size-h)/2,w,h);c.restore();if(mute){c.strokeStyle='#ef2430';c.lineWidth=2.1;c.beginPath();c.moveTo(x,y+size);c.lineTo(x+size,y);c.stroke()}}
function text(c,s,x,y,size=10,color='#f5efe1',align='left'){c.font=size+'px Georgia';c.fillStyle=color;c.textAlign=align;c.textBaseline='middle';c.fillText(s,x,y)}
function render(theme){const c=document.getElementById(theme).getContext('2d');c.scale(4,4);skin(c,theme+'Bar',0,0,300,45);
for(let r=0;r<3;r++)for(let k=0;k<2;k++)draw(c,'Rivet',10+k*5.3,15.7+r*5.3,3.1,3.1);
const ns=['Master','Sfx','Music'],labels=['Gesamt','Soundeffekte','Musik'],vals=[80,60,25];
for(let i=0;i<3;i++){let x=23+i*90;glyph(c,ns[i],x+5,10.5,24,i==2);text(c,vals[i]+' %',x+82,22.5,12,undefined,'right');if(i){c.fillStyle='#796029';c.fillRect(x,9.5,.6,26)}}
skin(c,theme+'Panel',0,62,300,160);text(c,'Soundstone',150,77,14,'#ffcf43','center');draw(c,'Close',275,66,20,20);
for(let r=0;r<3;r++)for(let k=0;k<2;k++)draw(c,'Rivet',12+k*4.1,71+r*4.1,2.5,2.5);
c.fillStyle='#888078';c.fillRect(7,89,286,1);
for(let i=0;i<3;i++){let y=62+29+i*42+21;if(theme=='Classic')skin(c,'ClassicPanel',12,y-16,25,32);glyph(c,ns[i],12.5,y-12,24,i==2);text(c,labels[i],42,y,10);skin(c,theme=='Classic'||i==2?'ToggleRed':'Toggle',111,y-9,34,18);text(c,i==2?'Aus':'An',128,y,10,'#ffd04b','center');
skin(c,'Toggle',155,y-4,98,8);c.fillStyle='#fab522';c.fillRect(158,y-1.5,92*vals[i]/100,3);draw(c,theme=='Classic'?'SilverThumb':'GoldThumb',155+88*vals[i]/100,y-9,10,18);text(c,vals[i]+' %',288,y,10,undefined,'right');if(i<2){c.fillStyle='#56514a';c.fillRect(14,y+21,272,.6)}}}
Promise.all(Object.keys(assets).map(n=>new Promise(resolve=>{const im=new Image();im.onload=()=>{images[n]=im;resolve()};im.src='assets/'+n+'.png'}))).then(()=>{render('Retail');render('Classic')});</script>'''
(root/'docs/ui-preview.html').write_text(html.replace('ASSETS',json.dumps(assets)),encoding='utf-8')
print('Wrote docs/ui-preview.html from production asset metadata.')
