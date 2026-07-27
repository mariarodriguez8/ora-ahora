import os, glob, subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter

PANO="https://d8j0ntlcm91z4.cloudfront.net/user_357fcxDIqY9TMqfewNOAYaGunxR/hf_20260727_212216_38591f77-2ac6-4719-b492-c22f96c38d1a.png"
subprocess.run(["curl","-fsSL","-o","/tmp/pano.png",PANO],check=True)

PW,PH,N=1080,1920,3
CREAM=(247,243,234,255); TEAL=(15,110,86,255); TEALL=(225,245,238,255)
TEALB=(159,225,203,255); INK=(36,31,16,255); INKSOFT=(91,91,90,255)
GOLD=(186,117,23,255); WHITE=(255,255,255,255); GREEN=(29,158,117,255)

def ff(names):
    c=glob.glob("/usr/share/fonts/**/*.ttf",recursive=True)
    for n in names:
        for f in c:
            if n.lower() in os.path.basename(f).lower(): return f
    return c[0] if c else None
SERIF=ff(["DejaVuSerif-Bold","LiberationSerif-Bold"])
SANS=ff(["DejaVuSans.ttf","DejaVuSans-Regular","LiberationSans-Regular"])
SANSB=ff(["DejaVuSans-Bold","LiberationSans-Bold"])
def fs(p,s): return ImageFont.truetype(p,s) if p else ImageFont.load_default()

def ctext(d,cx,y,txt,font,fill,shadow=None):
    b=d.textbbox((0,0),txt,font=font); w=b[2]-b[0]
    x=cx-w//2
    if shadow: d.text((x+2,y+2),txt,font=font,fill=shadow)
    d.text((x,y),txt,font=font,fill=fill); return b[3]-b[1]

def rr(d,box,r,fill=None,outline=None,width=2):
    d.rounded_rectangle(box,radius=r,fill=fill,outline=outline,width=width)

def paste_plant(scr,name,w,cx,y):
    p=f"assets/mascot/{name}"
    if os.path.exists(p):
        im=Image.open(p).convert("RGBA")
        h=round(im.height*w/im.width); im=im.resize((w,h),Image.LANCZOS)
        scr.alpha_composite(im,(cx-w//2,y)); return h
    return 0

SW,SH=648,1360  # pantalla interna

def screen_inicio():
    s=Image.new("RGBA",(SW,SH),CREAM); d=ImageDraw.Draw(s)
    d.text((36,34),"tu fe hoy",font=fs(SANS,28),fill=INKSOFT)
    rr(d,(SW-150,30,SW-36,74),22,fill=TEALL); d.text((SW-132,40),"nivel 3",font=fs(SANSB,22),fill=TEAL)
    paste_plant(s,"ovejita_planta_fruto.png",380,SW//2,90)
    ctext(d,SW//2,520,"floreciendo",fs(SERIF,60),TEAL)
    ctext(d,SW//2,600,"hoy la regaste, sigue así",fs(SANS,26),INKSOFT)
    rr(d,(40,660,SW-40,690),15,fill=(210,225,220,255))
    rr(d,(40,660,int((SW-80)*0.72)+40,690),15,fill=TEAL)
    ctext(d,SW//2,720,"«como árbol junto a corrientes de agua»",fs(SANS,22),INKSOFT)
    ctext(d,SW//2,752,"Salmo 1:3",fs(SANS,22),INKSOFT)
    rr(d,(40,SH-150,SW-40,SH-80),20,fill=TEAL)
    ctext(d,SW//2,SH-138,"regar mi fe hoy",fs(SANSB,30),WHITE)
    return s

def app_row(d,y,color,letter,name):
    rr(d,(36,y,SW-36,y+96),20,fill=WHITE)
    rr(d,(56,y+18,56+60,y+78),16,fill=color)
    b=d.textbbox((0,0),letter,font=fs(SANSB,34)); d.text((56+30-(b[2]-b[0])//2,y+30),letter,font=fs(SANSB,34),fill=WHITE)
    d.text((140,y+32),name,font=fs(SANSB,30),fill=INK)
    rr(d,(SW-124,y+28,SW-56,y+68),20,fill=GREEN)  # toggle on
    d.ellipse((SW-90,y+30,SW-58,y+66),fill=WHITE)

def screen_pausa():
    s=Image.new("RGBA",(SW,SH),CREAM); d=ImageDraw.Draw(s)
    ctext(d,SW//2,40,"Pausa y Ora",fs(SERIF,50),INK)
    ctext(d,SW//2,110,"elige qué apps te piden",fs(SANS,26),INKSOFT)
    ctext(d,SW//2,144,"una pausa para orar",fs(SANS,26),INKSOFT)
    y=220
    app_row(d,y,(20,20,20,255),"T","TikTok"); y+=120
    app_row(d,y,(214,83,126,255),"I","Instagram"); y+=120
    app_row(d,y,(226,75,74,255),"Y","YouTube"); y+=120
    app_row(d,y,(60,90,200,255),"F","Facebook"); y+=140
    rr(d,(36,y,SW-36,y+150),22,fill=TEALL)
    ctext(d,SW//2,y+30,"antes de abrirlas,",fs(SANSB,28),TEAL)
    ctext(d,SW//2,y+70,"una pausa para orar",fs(SANSB,28),TEAL)
    paste_plant(s,"ovejita_planta_brote.png",150,SW//2,y+95)
    return s

def screen_momento():
    s=Image.new("RGBA",(SW,SH),CREAM); d=ImageDraw.Draw(s)
    ctext(d,SW//2,60,"tu momento de hoy",fs(SERIF,46),INK)
    rr(d,(36,150,SW-36,620),26,fill=(255,255,255,235))
    lines=["Señor, aquí estoy.","antes que nada y antes","que nadie, quiero","buscarte a ti.","gracias por esperarme.","","Amén."]
    yy=210
    for ln in lines:
        ctext(d,SW//2,yy,ln,fs(SANS,32),INK); yy+=54
    paste_plant(s,"ovejita_planta_flor.png",300,SW//2,660)
    rr(d,(40,SH-150,SW-40,SH-80),20,fill=TEAL)
    ctext(d,SW//2,SH-138,"Amén, ya oré",fs(SANSB,30),WHITE)
    return s

def phone(screen):
    bez=26; PWp=SW+bez*2; PHp=SH+bez*2
    ph=Image.new("RGBA",(PWp,PHp),(0,0,0,0)); d=ImageDraw.Draw(ph)
    rr(d,(0,0,PWp,PHp),70,fill=(18,18,20,255))
    m=Image.new("L",(SW,SH),0); md=ImageDraw.Draw(m); md.rounded_rectangle((0,0,SW,SH),radius=48,fill=255)
    ph.paste(screen,(bez,bez),m)
    d.rounded_rectangle((PWp//2-70,14,PWp//2+70,30),radius=8,fill=(18,18,20,255))  # notch bar
    return ph

titulos=["tu momento\ncon Dios,\ntodos los días","bloquea las apps\nque te distraen\nhasta que ores","y mira crecer\ntu fe,\nun día a la vez"]
screens=[screen_inicio(),screen_pausa(),screen_momento()]

pano=Image.open("/tmp/pano.png").convert("RGBA")
w=round(pano.width*PH/pano.height); pano=pano.resize((w,PH),Image.LANCZOS)
total=PW*N
x0=max(0,(pano.width-total)//2); pano=pano.crop((x0,0,x0+total,PH)) if pano.width>=total else pano

os.makedirs("store_assets/capturas",exist_ok=True)
for i in range(N):
    panel=pano.crop((i*PW,0,(i+1)*PW,PH)).convert("RGBA")
    # oscurecer un poco el fondo para que el telefono resalte
    dark=Image.new("RGBA",(PW,PH),(10,15,13,90)); panel=Image.alpha_composite(panel,dark)
    # gradiente arriba para el titular
    g=Image.new("L",(1,PH),0)
    for y in range(PH): g.putpixel((0,y), int(150*(1-y/(PH*0.42))) if y<PH*0.42 else 0)
    g=g.resize((PW,PH)); ov=Image.new("RGBA",(PW,PH),(12,18,15,255)); ov.putalpha(g)
    panel=Image.alpha_composite(panel,ov)
    d=ImageDraw.Draw(panel)
    d.text((60,64),"Ora Ahora",font=fs(SANSB,38),fill=WHITE)
    yy=140
    for ln in titulos[i].split("\n"):
        d.text((62,yy+3),ln,font=fs(SERIF,72),fill=(0,0,0,150)); d.text((60,yy),ln,font=fs(SERIF,72),fill=WHITE); yy+=88
    ph=phone(screens[i])
    scale=1.0
    px=(PW-ph.width)//2; py=PH-ph.height-40
    panel.alpha_composite(ph,(px,py))
    panel.convert("RGB").save(f"store_assets/capturas/captura_{i+1}.png","PNG")
    print("ok",i+1)
print("===LISTO2===")
