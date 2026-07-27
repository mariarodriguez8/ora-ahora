import os, glob, subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter

URL = "https://d8j0ntlcm91z4.cloudfront.net/user_357fcxDIqY9TMqfewNOAYaGunxR/hf_20260727_212216_38591f77-2ac6-4719-b492-c22f96c38d1a.png"
RAW = "/tmp/pano.png"
subprocess.run(["curl","-fsSL","-o",RAW,URL], check=True)

PW, PH, N = 1080, 1920, 3
im = Image.open(RAW).convert("RGBA")
# escalar a alto 1920 y recortar el centro a 3240 de ancho (3 paneles)
w = round(im.width * PH / im.height)
im = im.resize((w, PH), Image.LANCZOS)
total = PW * N
if im.width >= total:
    x0 = (im.width - total)//2
    im = im.crop((x0, 0, x0+total, PH))
else:
    canvas = Image.new("RGBA",(total,PH),(20,24,20,255))
    canvas.paste(im, ((total-im.width)//2,0)); im = canvas

def find_font(bold=True):
    cands = glob.glob("/usr/share/fonts/**/*.ttf", recursive=True)
    pref = ["DejaVuSerif-Bold","DejaVuSans-Bold","LiberationSerif-Bold","NotoSerif-Bold","DejaVuSerif","DejaVuSans"]
    for p in pref:
        for c in cands:
            if p.lower() in os.path.basename(c).lower():
                return c
    return cands[0] if cands else None

FP = find_font()
def font(sz): return ImageFont.truetype(FP, sz) if FP else ImageFont.load_default()

titulos = [
    "tu momento\ncon Dios,\ntodos los días",
    "bloquea las apps\nque te distraen\nhasta que ores 🙏",
    "y mira crecer\ntu fe,\nun día a la vez 🌱",
]

os.makedirs("store_assets/capturas", exist_ok=True)
FTITLE = font(96)
FBRAND = font(40)

def draw_panel(idx):
    panel = im.crop((idx*PW, 0, (idx+1)*PW, PH)).convert("RGBA")
    # gradiente oscuro arriba para legibilidad
    grad = Image.new("L",(1,PH),0)
    for y in range(PH):
        a = max(0, int(190*(1 - y/(PH*0.5)))) if y < PH*0.5 else 0
        grad.putpixel((0,y), a)
    grad = grad.resize((PW,PH))
    overlay = Image.new("RGBA",(PW,PH),(15,20,18,255)); overlay.putalpha(grad)
    panel = Image.alpha_composite(panel, overlay)
    d = ImageDraw.Draw(panel)
    # marca arriba
    d.text((60,70), "Ora Ahora", font=FBRAND, fill=(255,255,255,235))
    # titulo
    y = 150
    for line in titulos[idx].split("\n"):
        # sombra + texto
        d.text((62,y+3), line, font=FTITLE, fill=(0,0,0,150))
        d.text((60,y), line, font=FTITLE, fill=(255,255,255,255))
        y += 116
    out = f"store_assets/capturas/captura_{idx+1}.png"
    panel.convert("RGB").save(out, "PNG")
    print("guardada", out, panel.size)

for i in range(N):
    draw_panel(i)
print("FUENTE:", FP)
print("===CAPTURAS_LISTAS===")
