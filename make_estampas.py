import os, subprocess, textwrap
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import glob

BASE="https://d8j0ntlcm91z4.cloudfront.net/user_357fcxDIqY9TMqfewNOAYaGunxR/"
CREAM=(247,243,234); TEAL=(15,110,86); GOLD=(150,90,20); INK=(36,31,16)

STAMPS=[
 ("hf_20260729_070320_6fbb79b5-1204-4584-8631-414ca3291274.png","Su misericordia es nueva cada mañana.","Lamentaciones 3:23"),
 ("hf_20260729_070329_f3eaa7a7-7edf-42cc-a506-7f6312270928.png","El que comenzó en ti la buena obra, la perfeccionará.","Filipenses 1:6"),
 ("hf_20260729_070333_c8273dcb-a322-47ed-b5fe-81d959b619bf.png","Jehová es mi pastor; nada me faltará.","Salmo 23:1"),
 ("hf_20260729_071105_3f0342cd-5021-4c72-9aba-a67316b10fa1.png","Este es el día que hizo Jehová; nos gozaremos en él.","Salmo 118:24"),
 ("hf_20260729_071139_605af894-5b71-48dc-b7ca-aca9c63cbe53.png","De día mandará su misericordia, y de noche su cántico.","Salmo 42:8"),
 ("hf_20260729_071148_595bfb9e-d2a2-4c95-997f-771f7795fa54.png","Lámpara es a mis pies tu palabra.","Salmo 119:105"),
 ("hf_20260729_071152_2ebcb304-2a9d-4751-aa8d-9a5a337d3786.png","Buscad primero el reino de Dios.","Mateo 6:33"),
 ("hf_20260729_071155_b3f6c76f-d4f0-4e92-90c9-c2e95a793fed.png","En paz me acostaré, y asimismo dormiré.","Salmo 4:8"),
 ("hf_20260729_071159_54dc536f-d052-4b76-97d7-b38910b45b38.png","Los que esperan en Jehová tendrán nuevas fuerzas.","Isaías 40:31"),
]

def ff(names):
    c=glob.glob("/usr/share/fonts/**/*.ttf",recursive=True)
    for n in names:
        for f in c:
            if n.lower() in os.path.basename(f).lower(): return f
    return c[0] if c else None
SERIF=ff(["DejaVuSerif-Bold"]); SERIFI=ff(["DejaVuSerif-Italic","DejaVuSerif.ttf"])
def font(p,s): return ImageFont.truetype(p,s) if p else ImageFont.load_default()

PW,PH=1080,1920
def cover(im):
    s=max(PW/im.width,PH/im.height); im=im.resize((int(im.width*s),int(im.height*s)),Image.LANCZOS)
    x=(im.width-PW)//2; y=(im.height-PH)//2; return im.crop((x,y,x+PW,y+PH))

def wrap(draw,text,font,maxw):
    words=text.split(); lines=[]; cur=""
    for w in words:
        t=(cur+" "+w).strip()
        if draw.textlength(t,font=font)<=maxw: cur=t
        else: lines.append(cur); cur=w
    if cur: lines.append(cur)
    return lines

os.makedirs("store_assets/estampas",exist_ok=True)
fv=font(SERIF,56); fr=font(SERIFI,36); fb=font(SERIF,34)
for i,(fn,verse,ref) in enumerate(STAMPS,1):
    subprocess.run(["curl","-fsSL","-o","/tmp/bg.png",BASE+fn],check=True)
    im=cover(Image.open("/tmp/bg.png").convert("RGBA"))
    d=ImageDraw.Draw(im)
    lines=wrap(d,verse,fv,PW-260)
    lh=76; block=len(lines)*lh+70
    px0,px1=60,PW-60; py0=150; py1=py0+block+60
    # panel crema translucido
    panel=Image.new("RGBA",(PW,PH),(0,0,0,0)); pd=ImageDraw.Draw(panel)
    pd.rounded_rectangle((px0,py0,px1,py1),radius=36,fill=(247,243,234,205))
    im=Image.alpha_composite(im,panel); d=ImageDraw.Draw(im)
    y=py0+40
    for ln in lines:
        w=d.textlength(ln,font=fv); d.text(((PW-w)//2,y),ln,font=fv,fill=TEAL); y+=lh
    y+=6; rw=d.textlength(ref,font=fr); d.text(((PW-rw)//2,y),ref,font=fr,fill=GOLD)
    # marca abajo
    brand="Ora Ahora"; bw=d.textlength(brand,font=fb)
    d.text(((PW-bw)//2,PH-96),brand,font=fb,fill=(247,243,234,230))
    im.convert("RGB").save(f"store_assets/estampas/estampa_{i:02d}.png","PNG")
    print("estampa",i,"ok")
print("===ESTAMPAS_LISTAS===")
