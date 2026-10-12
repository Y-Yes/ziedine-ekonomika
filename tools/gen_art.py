"""Generate animated station sprite sheets for Žiedinė ekonomika.

Each station is drawn as a parametric SVG f(t), t in [0,1), rendered to N
frames and packed horizontally into one PNG sprite sheet.
"""
import io, math, sys, os
import cairosvg
from PIL import Image

N = 24          # frames per loop
OUT = 96        # output frame size (px)
RENDER = 256    # render size before downscale

TAU = math.tau


def s(x):  # sin of loop fraction
    return math.sin(TAU * x)


def lerp(a, b, u):
    return a + (b - a) * u


def qbez(p0, p1, p2, u):
    x = (1 - u) ** 2 * p0[0] + 2 * (1 - u) * u * p1[0] + u * u * p2[0]
    y = (1 - u) ** 2 * p0[1] + 2 * (1 - u) * u * p1[1] + u * u * p2[1]
    return x, y


def sparkle(cx, cy, R, fill, op=1.0, k=1.0):
    R *= k
    r = R * 0.23
    pts = [(cx, cy - R), (cx + r, cy - r), (cx + R, cy), (cx + r, cy + r),
           (cx, cy + R), (cx - r, cy + r), (cx - R, cy), (cx - r, cy - r)]
    p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    return f'<polygon points="{p}" fill="{fill}" opacity="{op:.2f}"/>'


def twinkle(t, phase):
    return 0.35 + 0.65 * abs(s(t + phase))


def svg(defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">'
            f'<defs>{defs}</defs>{body}</svg>')


SHADOW = '<ellipse cx="128" cy="226" rx="96" ry="9" fill="#000" opacity=".18"/>'


def grad(id_, a, b, x2=0, y2=1):
    return (f'<linearGradient id="{id_}" x1="0" y1="0" x2="{x2}" y2="{y2}">'
            f'<stop offset="0" stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient>')


# ---------------------------------------------------------------- 1 Naudotojas
def naudotojas(t):
    defs = grad("b1", "#ff9090", "#e0485c") + grad("bin", "#d3dae4", "#8e98a8") + \
        grad("btl", "#b5ecff", "#3fa9e0") + grad("skin", "#ffd0c2", "#ffad9c")
    bob = 2.0 * s(t)
    # throw cycle: arm swings forward at start of loop
    arm = -14 * max(0.0, s(t * 1.0 + 0.0)) if t < 0.5 else 0
    body = SHADOW
    body += f'<g transform="translate(0 {bob:.2f})">'
    body += '<rect x="50" y="110" width="60" height="112" rx="30" fill="url(#b1)"/>'
    body += '<rect x="62" y="122" width="10" height="60" rx="5" fill="#fff" opacity=".18"/>'
    body += '<circle cx="80" cy="80" r="26" fill="url(#skin)"/>'
    body += '<path d="M56 74 Q60 50 82 52 Q104 54 105 76 Q96 64 80 64 Q66 64 56 74 Z" fill="#7a3b3b"/>'
    body += f'<g transform="rotate({arm:.1f} 100 128)">'
    body += '<path d="M100 128 L138 98" stroke="#d6475a" stroke-width="17" stroke-linecap="round"/>'
    body += '<circle cx="140" cy="96" r="10" fill="url(#skin)"/></g>'
    body += '</g>'
    # dashed trajectory, flowing
    body += (f'<path d="M146 84 Q176 34 198 112" fill="none" stroke="#fff" stroke-width="3" '
             f'stroke-linecap="round" stroke-dasharray="3 8" stroke-dashoffset="{-22 * t:.1f}" opacity=".45"/>')

    def bottle(x, y, rot, k=1.0):
        return (f'<g transform="translate({x:.1f} {y:.1f}) rotate({rot:.1f}) scale({k:.2f}) translate(-178 -62)">'
                '<rect x="169" y="54" width="18" height="30" rx="6" fill="url(#btl)"/>'
                '<rect x="174" y="43" width="8" height="13" rx="2" fill="#d6f4ff"/>'
                '<rect x="172.5" y="40" width="11" height="5" rx="1.5" fill="#1f7fc2"/>'
                '<rect x="172" y="60" width="4" height="18" rx="2" fill="#fff" opacity=".5"/></g>')

    # bottle: flies 0..0.55, sits in hand 0.75..1
    if t < 0.55:
        u = t / 0.55
        x, y = qbez((146, 84), (180, 10), (196, 132), u)
        body += bottle(x, y, 20 + 400 * u)
    elif t >= 0.75:
        k = min(1.0, (t - 0.75) / 0.12)
        body += bottle(146, 84 + bob, 20, k)
    # bin, lid hops when bottle lands
    lid = 0.0
    if 0.5 <= t < 0.72:
        lid = -9 * math.sin(math.pi * (t - 0.5) / 0.22)
    body += '<path d="M164 136 H228 L219 220 H173 Z" fill="url(#bin)"/>'
    body += '<path d="M184 150 V206 M196 150 V206 M208 150 V206" stroke="#7d8797" stroke-width="4" stroke-linecap="round"/>'
    body += f'<g transform="translate(0 {lid:.2f}) rotate({lid * 0.8:.1f} 160 129)">'
    body += '<rect x="157" y="122" width="78" height="14" rx="7" fill="#c3cad6"/>'
    body += '<rect x="183" y="114" width="26" height="10" rx="5" fill="#c3cad6"/>'
    body += '<rect x="164" y="125" width="40" height="4" rx="2" fill="#fff" opacity=".45"/></g>'
    if 0.55 <= t < 0.8:
        k = 1 - (t - 0.55) / 0.25
        body += sparkle(214, 100, 9, "#fff3a8", k, 0.6 + 0.6 * (1 - k))
    return svg(defs, body)


# ---------------------------------------------------------------- 2 Surinkimas
def surinkimas(t):
    defs = grad("cont", "#ffc766", "#e88b14") + grad("cab", "#ffd88f", "#f0a02a") + \
        grad("win", "#4a6580", "#22303f")
    body = SHADOW
    # exhaust puffs
    for i in range(3):
        u = (t + i / 3) % 1
        x = lerp(30, 0, u)
        y = lerp(166, 118, u)
        r = lerp(4, 13, u)
        op = 0.65 * (1 - u)
        body += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="#d5dbe4" opacity="{op:.2f}"/>'
    bounce = -1.8 * abs(s(2 * t))
    body += f'<g transform="translate(0 {bounce:.2f})">'
    body += '<rect x="28" y="88" width="132" height="92" rx="12" fill="url(#cont)"/>'
    body += '<path d="M54 100 V168 M78 100 V168 M110 100 V168 M134 100 V168" stroke="#c9770f" stroke-width="5" stroke-linecap="round" opacity=".7"/>'
    body += '<rect x="36" y="94" width="116" height="7" rx="3.5" fill="#fff" opacity=".3"/>'
    body += '<circle cx="94" cy="134" r="17" fill="#fff"/>'
    body += f'<g transform="rotate({360 * t:.1f} 93 136)">'
    body += '<path d="M85 138 A10 10 0 1 1 98 143" fill="none" stroke="#2fb36a" stroke-width="4.5" stroke-linecap="round"/>'
    body += '<polygon points="81,133 89,135 84,142" fill="#2fb36a"/></g>'
    body += '<path d="M160 110 H198 Q208 110 213 120 L228 148 V182 H160 Z" fill="url(#cab)"/>'
    body += '<path d="M168 118 H194 Q200 118 203 124 L213 144 H168 Z" fill="url(#win)"/>'
    body += '<path d="M172 122 H186 L178 140 H172 Z" fill="#fff" opacity=".18"/>'
    blink = 0.55 + 0.45 * abs(s(2 * t))
    body += f'<rect x="222" y="160" width="9" height="9" rx="2.5" fill="#fff3b8" opacity="{blink:.2f}"/>'
    body += '<rect x="150" y="178" width="84" height="9" rx="4.5" fill="#a9620b"/>'
    body += '</g>'
    rot = 720 * t
    for cx in (70, 192):
        body += f'<circle cx="{cx}" cy="190" r="22" fill="#2b2d36"/>'
        body += f'<g transform="rotate({rot:.1f} {cx} 190)"><circle cx="{cx}" cy="190" r="10" fill="#d5dbe4"/>'
        body += f'<path d="M{cx - 10} 190 H{cx + 10} M{cx} 180 V200" stroke="#8a93a3" stroke-width="3"/>'
        body += f'<circle cx="{cx}" cy="190" r="3.5" fill="#2b2d36"/></g>'
    body += (f'<path d="M18 222 H238" stroke="#9aa3b2" stroke-width="4" stroke-linecap="round" '
             f'stroke-dasharray="18 12" stroke-dashoffset="{60 * t:.1f}" opacity=".7"/>')
    return svg(defs, body)


# ---------------------------------------------------------------- 3 Rūšiavimas
def rusiavimas(t):
    defs = grad("fun", "#ffe982", "#f2c81e") + grad("bb", "#6aa8f0", "#2f72c8") + \
        grad("by", "#ffe36a", "#e6b916") + grad("bg", "#6be08f", "#27a855")
    body = SHADOW
    shake = 1.5 * s(3 * t)
    body += f'<g transform="translate({shake:.2f} 0)">'
    body += '<path d="M82 22 H174 L152 58 H104 Z" fill="url(#fun)"/>'
    body += '<rect x="88" y="26" width="70" height="5" rx="2.5" fill="#fff" opacity=".45"/></g>'
    body += (f'<path d="M118 64 Q80 90 64 130 M128 64 V128 M138 64 Q176 90 192 130" fill="none" stroke="#fff" '
             f'stroke-width="3" stroke-linecap="round" stroke-dasharray="3 8" stroke-dashoffset="{-22 * t:.1f}" opacity=".45"/>')

    paper = ('<g transform="translate(-14 -17)"><rect x="0" y="0" width="28" height="34" rx="3" fill="#d9e9ff"/>'
             '<path d="M6 10 H22 M6 17 H22 M6 24 H18" stroke="#5b8fd0" stroke-width="2.5" stroke-linecap="round"/></g>')
    bottle = ('<g transform="translate(-128 -100)"><rect x="120" y="92" width="16" height="26" rx="5" fill="#fff0a0"/>'
              '<rect x="124" y="82" width="8" height="12" rx="2" fill="#fff7cc"/>'
              '<rect x="122.5" y="79" width="11" height="5" rx="1.5" fill="#d9a400"/></g>')
    glass = '<circle cx="0" cy="0" r="15" fill="#b9f3cb"/><circle cx="-5" cy="-5" r="4" fill="#fff" opacity=".7"/>'
    items = [(paper, (118, 60), (78, 86), (64, 176), -30),
             (bottle, (128, 60), (128, 110), (128, 176), 90),
             (glass, (138, 60), (178, 86), (192, 176), 0)]
    lids = [0.0, 0.0, 0.0]
    for i, (shape, p0, p1, p2, spin) in enumerate(items):
        u = (t + i / 3) % 1
        if u < 0.6:
            v = u / 0.6
            x, y = qbez(p0, p1, p2, v * v * 0.4 + v * 0.6)
            k = lerp(0.55, 1.0, min(1, v * 2))
            body += f'<g transform="translate({x:.1f} {y:.1f}) rotate({spin * v:.1f}) scale({k:.2f})">{shape}</g>'
        if 0.55 <= u < 0.75:
            lids[i] = -6 * math.sin(math.pi * (u - 0.55) / 0.2)
    bins = [("bb", "#2a62ad", 34, '<rect x="56" y="176" width="16" height="22" rx="2" fill="#fff" opacity=".85"/><path d="M60 183 H68 M60 189 H68" stroke="#2f72c8" stroke-width="2"/>'),
            ("by", "#c99f10", 98, '<rect x="122" y="180" width="12" height="20" rx="4" fill="#fff" opacity=".85"/><rect x="125" y="173" width="6" height="8" rx="1.5" fill="#fff" opacity=".85"/>'),
            ("bg", "#1f8f47", 162, '<circle cx="192" cy="188" r="11" fill="#fff" opacity=".85"/>')]
    for i, (g, lidc, x0, mark) in enumerate(bins):
        body += f'<path d="M{x0} 156 H{x0 + 60} L{x0 + 54} 222 H{x0 + 6} Z" fill="url(#{g})"/>{mark}'
        body += (f'<g transform="translate(0 {lids[i]:.2f})"><rect x="{x0 - 5}" y="144" width="70" height="14" rx="7" fill="{lidc}"/>'
                 f'<rect x="{x0 + 4}" y="147" width="30" height="4" rx="2" fill="#fff" opacity=".4"/></g>')
    return svg(defs, body)


# ---------------------------------------------------------------- 4 Perdirbimas
def perdirbimas(t):
    defs = grad("a1", "#7ef0a0", "#2fbf63", 1, 1) + grad("leaf", "#c9ffd9", "#6ee69a", 1, 1)
    arrows = [
        "M150.0,39.7 A91.0 91.0 0 0 1 218.9,131.2 L230.9,131.6 L196.9,164.6 L181.0,129.8 L193.0,130.3 A65.0 65.0 0 0 0 143.7,64.9 Z",
        "M193.5,191.2 A91.0 91.0 0 0 1 79.8,205.2 L73.4,215.3 L61.9,169.3 L99.9,172.9 L93.6,183.1 A65.0 65.0 0 0 0 174.8,173.2 Z",
        "M40.5,153.1 A91.0 91.0 0 0 1 85.3,47.7 L79.6,37.1 L125.3,50.0 L103.1,81.2 L97.5,70.6 A65.0 65.0 0 0 0 65.5,145.9 Z",
    ]
    body = SHADOW
    body += f'<g transform="rotate({120 * t:.2f} 128 128)">'
    for a in arrows:
        body += f'<path d="{a}" fill="url(#a1)" stroke="#1b8a45" stroke-width="2" stroke-linejoin="round"/>'
    body += '</g>'
    k = 1 + 0.09 * s(t)
    body += f'<g transform="translate(128 128) scale({k:.3f}) translate(-128 -128) rotate(-40 128 128)">'
    body += '<path d="M88 128 Q128 92 168 128 Q128 164 88 128 Z" fill="url(#leaf)"/>'
    body += '<path d="M92 128 H166" stroke="#22a052" stroke-width="3" stroke-linecap="round"/>'
    body += '<path d="M112 128 L124 116 M128 128 L140 116 M112 128 L124 140 M128 128 L140 140" stroke="#22a052" stroke-width="2" stroke-linecap="round" opacity=".7"/></g>'
    body += sparkle(196, 54, 9, "#eafff0", 0.9, twinkle(t, 0))
    body += sparkle(56, 200, 7, "#eafff0", 0.8, twinkle(t, 0.33))
    body += sparkle(214, 196, 6, "#eafff0", 0.7, twinkle(t, 0.66))
    return svg(defs, body)


# ---------------------------------------------------------------- 5 Gamykla
def gear_poly(cx, cy, ro, ri, teeth, rot):
    pts = []
    for i in range(teeth):
        base = TAU * i / teeth + math.radians(rot)
        w = TAU / teeth
        for frac, r in ((0.0, ri), (0.15, ro), (0.45, ro), (0.6, ri)):
            a = base + w * frac
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)


def gamykla(t):
    defs = grad("wall", "#6cd0ff", "#2a96d6") + grad("roof", "#3aa6e6", "#1d78b8") + \
        grad("chim", "#2a8cc8", "#1a5f8e") + grad("gear", "#ffffff", "#cfe3f2") + \
        grad("glow", "#fff6b8", "#ffd84a")
    body = SHADOW
    for i in range(3):
        u = (t + i / 3) % 1
        x = lerp(180, 222, u)
        y = lerp(54, 6, u)
        r = lerp(8, 20, u)
        op = 0.95 * (1 - u) ** 0.8
        body += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="#e3e9f0" opacity="{op:.2f}"/>'
    body += '<rect x="166" y="60" width="28" height="80" fill="url(#chim)"/>'
    body += '<rect x="162" y="56" width="36" height="10" rx="3" fill="#174f78"/>'
    body += '<rect x="166" y="80" width="28" height="6" fill="#fff" opacity=".35"/>'
    body += '<path d="M30 140 V104 L72 140 V104 L114 140 V104 L156 140 Z" fill="url(#roof)"/>'
    body += '<rect x="30" y="136" width="196" height="88" rx="4" fill="url(#wall)"/>'
    body += '<rect x="30" y="136" width="196" height="8" fill="#fff" opacity=".2"/>'
    for j, x in enumerate((46, 180)):
        op = 0.75 + 0.25 * s(2 * t + j * 0.5)
        body += f'<rect x="{x}" y="156" width="30" height="26" rx="4" fill="url(#glow)" opacity="{op:.2f}"/>'
    body += '<path d="M61 156 V182 M195 156 V182" stroke="#2a96d6" stroke-width="3"/>'
    body += '<rect x="44" y="196" width="34" height="28" rx="3" fill="#1d78b8"/>'
    body += '<rect x="178" y="196" width="34" height="28" rx="3" fill="#1d78b8"/>'
    # gear: 10 teeth, rotate one tooth per loop -> seamless and calm; double for liveliness
    body += f'<polygon points="{gear_poly(128, 176, 35, 27, 10, 72 * t)}" fill="url(#gear)" stroke="#9cc3e0" stroke-width="1.5"/>'
    body += '<circle cx="128" cy="176" r="11" fill="#2a96d6"/><circle cx="128" cy="176" r="5" fill="#cfe3f2"/>'
    return svg(defs, body)


# ---------------------------------------------------------------- 6 Parduotuvė
def parduotuve(t):
    defs = grad("wall6", "#8f6ad6", "#6a49b0") + grad("glass", "#e6f3ff", "#a9d2ff", 1, 1) + \
        grad("sign", "#e2d1ff", "#c3a6ff") + grad("bag", "#ffffff", "#ece4fb")
    body = SHADOW
    body += '<rect x="38" y="104" width="180" height="120" fill="url(#wall6)"/>'
    body += '<rect x="92" y="38" width="72" height="30" rx="9" fill="url(#sign)"/>'
    body += '<path d="M112 68 V82 M144 68 V82" stroke="#6a49b0" stroke-width="4"/>'
    body += f'<g transform="rotate({90 * t:.1f} 128 53)">{sparkle(128, 53, 10, "#ffffff")}</g>'
    for i in range(8):
        x = 28 + 25 * i
        c = "#b388ff" if i % 2 == 0 else "#f5efff"
        body += f'<rect x="{x}" y="82" width="25" height="30" fill="{c}"/><path d="M{x} 111 A12.5 12.5 0 0 0 {x + 25} 111 Z" fill="{c}"/>'
    body += '<rect x="26" y="78" width="204" height="7" rx="3.5" fill="#7c58c4"/>'
    body += '<rect x="48" y="134" width="44" height="46" rx="4" fill="url(#glass)"/>'
    body += '<rect x="164" y="134" width="44" height="46" rx="4" fill="url(#glass)"/>'
    # moving window glint
    gx = lerp(-30, 60, (t * 1.0) % 1)
    body += (f'<clipPath id="wc"><rect x="48" y="134" width="44" height="46" rx="4"/><rect x="164" y="134" width="44" height="46" rx="4"/></clipPath>'
             f'<g clip-path="url(#wc)"><path d="M{48 + gx} 134 l14 0 l-20 46 l-14 0 Z M{164 + gx} 134 l14 0 l-20 46 l-14 0 Z" fill="#fff" opacity=".6"/></g>')
    body += '<rect x="106" y="146" width="44" height="78" rx="4" fill="#4a2f80"/>'
    body += '<circle cx="141" cy="188" r="3" fill="#ffd84a"/>'
    hop = -7 * abs(s(t))
    sq = 1 - 0.05 * (1 - abs(s(t)))
    body += f'<g transform="translate(128 222) scale({2 - sq:.3f} {sq:.3f}) translate(-128 -222) translate(0 {hop:.2f})">'
    body += '<path d="M114 172 Q114 150 128 150 Q142 150 142 172" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/>'
    body += '<path d="M100 170 H156 L160 222 H96 Z" fill="url(#bag)"/>'
    body += '<rect x="98" y="184" width="60" height="10" fill="#b388ff"/>'
    body += '<path d="M120 204 L128 212 L140 198" fill="none" stroke="#7c58c4" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></g>'
    body += sparkle(78, 206, 9, "#fff3a8", 1, twinkle(t, 0))
    body += sparkle(182, 204, 11, "#fff3a8", 1, twinkle(t, 0.25))
    body += sparkle(200, 124, 7, "#fff3a8", 0.9, twinkle(t, 0.5))
    body += sparkle(56, 120, 6, "#fff3a8", 0.9, twinkle(t, 0.75))
    return svg(defs, body)


STATIONS = [("1_naudotojas", naudotojas), ("2_surinkimas", surinkimas), ("3_rusiavimas", rusiavimas),
            ("4_perdirbimas", perdirbimas), ("5_gamykla", gamykla), ("6_parduotuve", parduotuve)]


def render(fn, t, size):
    png = cairosvg.svg2png(bytestring=fn(t).encode(), output_width=RENDER, output_height=RENDER)
    im = Image.open(io.BytesIO(png)).convert("RGBA")
    return im.resize((size, size), Image.LANCZOS)


def main(outdir):
    os.makedirs(outdir, exist_ok=True)
    big_frames = []
    for name, fn in STATIONS:
        sheet = Image.new("RGBA", (OUT * N, OUT), (0, 0, 0, 0))
        frames = []
        for i in range(N):
            fr = render(fn, i / N, OUT)
            sheet.paste(fr, (i * OUT, 0))
            frames.append(render(fn, i / N, 128))
        sheet.save(os.path.join(outdir, f"{name}.png"))
        big_frames.append(frames)
    # preview gif (all six side by side on the game background)
    W = 128
    gif = []
    for i in range(N):
        canvas = Image.new("RGBA", (W * 6 + 70, W + 20), (20, 24, 33, 255))
        for k in range(6):
            canvas.alpha_composite(big_frames[k][i], (10 + k * (W + 10), 10))
        gif.append(canvas.convert("RGB"))
    gif[0].save(os.path.join(outdir, "_perziura.gif"), save_all=True, append_images=gif[1:], duration=80, loop=0)


if __name__ == "__main__":
    main(sys.argv[1])


# ============================================================ EXTRA ART (v2)
def radial(id_, a, b, cx=0.4, cy=0.35, r=0.75):
    return (f'<radialGradient id="{id_}" cx="{cx}" cy="{cy}" r="{r}">'
            f'<stop offset="0" stop-color="{a}"/><stop offset="1" stop-color="{b}"/></radialGradient>')


TOKEN_COLORS = [("#ff8a8c", "#c73e45"), ("#ffbb6e", "#cc7420"), ("#f0e27a", "#b8a51e"),
                ("#8ee6a0", "#2f9a4c"), ("#86bdf5", "#2b6cbf"), ("#c3a2f5", "#7346c4")]

GLYPHS = [
    # 0 used: crumpled bottle
    '<g transform="rotate(-25 128 128)"><path d="M112 96 H144 Q150 96 150 104 V112 L144 128 L152 146 L146 176 Q144 184 136 184 H120 Q112 184 110 176 L104 150 L114 130 L106 112 V104 Q106 96 112 96 Z" fill="#fff"/>'
    '<rect x="118" y="72" width="20" height="26" rx="4" fill="#fff"/><rect x="115" y="66" width="26" height="10" rx="3" fill="#ffd9da"/>'
    '<path d="M114 130 L140 136 M112 152 L142 158" stroke="#e46a6e" stroke-width="5" stroke-linecap="round"/></g>',
    # 1 collected: tied trash bag
    '<path d="M86 196 Q74 150 100 120 L110 110 H146 L156 120 Q182 150 170 196 Q128 208 86 196 Z" fill="#fff"/>'
    '<path d="M110 110 L100 76 L124 98 L128 70 L134 98 L158 76 L146 110 Z" fill="#fff"/>'
    '<rect x="106" y="104" width="44" height="12" rx="6" fill="#ffd7a8"/>'
    '<path d="M106 150 Q128 160 150 150" stroke="#f0a24e" stroke-width="5" fill="none" stroke-linecap="round"/>',
    # 2 sorted: strapped bale (iso cube)
    '<path d="M128 70 L184 98 L128 126 L72 98 Z" fill="#fff"/><path d="M72 98 L128 126 V190 L72 162 Z" fill="#f2ecc0"/>'
    '<path d="M184 98 L128 126 V190 L184 162 Z" fill="#e3d98c"/>'
    '<path d="M100 84 L156 112 V176 M156 84 L100 112 V176" stroke="#b8a51e" stroke-width="6" fill="none" stroke-linejoin="round"/>',
    # 3 recycled: pellets
    '<circle cx="104" cy="150" r="30" fill="#fff"/><circle cx="154" cy="150" r="30" fill="#e8fbe9"/><circle cx="128" cy="106" r="30" fill="#fff"/>'
    '<circle cx="94" cy="140" r="9" fill="#fff" opacity=".9"/><circle cx="118" cy="96" r="9" fill="#d8f5dc"/>'
    '<path d="M128 106 m-14 0 a14 14 0 1 0 28 0" stroke="#3fb460" stroke-width="5" fill="none" stroke-linecap="round"/>',
    # 4 factory: product box
    '<path d="M128 72 L184 96 V162 L128 188 L72 162 V96 Z" fill="#fff"/><path d="M72 96 L128 120 L184 96" stroke="#9cc3ef" stroke-width="5" fill="none" stroke-linejoin="round"/>'
    '<path d="M128 120 V188" stroke="#9cc3ef" stroke-width="5"/><path d="M100 84 L156 108 V130" stroke="#c9dff7" stroke-width="10" fill="none"/>',
    # 5 shop: price tag with euro
    '<g transform="rotate(-30 128 128)"><path d="M80 98 L116 70 H176 Q186 70 186 80 V176 Q186 186 176 186 H116 L80 158 Z" fill="#fff"/>'
    '<circle cx="104" cy="128" r="9" fill="#9a6ae0"/>'
    '<path d="M168 104 Q156 96 146 100 Q132 106 132 128 Q132 150 146 156 Q156 160 168 152 M124 120 H152 M124 136 H150" stroke="#7346c4" stroke-width="8" fill="none" stroke-linecap="round"/></g>',
]


def token_icon(i):
    a, b = TOKEN_COLORS[i]
    defs = radial("tg", a, b)
    body = '<ellipse cx="128" cy="236" rx="80" ry="12" fill="#000" opacity=".25"/>'
    body += '<circle cx="128" cy="128" r="112" fill="url(#tg)" stroke="#fff" stroke-width="10" stroke-opacity=".85"/>'
    body += GLYPHS[i]
    body += '<path d="M54 92 A84 84 0 0 1 120 40" stroke="#fff" stroke-width="12" fill="none" stroke-linecap="round" opacity=".35"/>'
    return svg(defs, body)


HUD_ICONS = [
    # coin with euro
    radial("c", "#ffe58a", "#e0a514"),
    '<circle cx="128" cy="128" r="104" fill="url(#c)" stroke="#a87405" stroke-width="10"/>'
    '<circle cx="128" cy="128" r="80" fill="none" stroke="#fff3c0" stroke-width="6" opacity=".7"/>'
    '<path d="M164 92 Q150 80 134 84 Q106 92 106 128 Q106 164 134 172 Q150 176 164 164 M88 116 H140 M88 140 H136" stroke="#8a5d00" stroke-width="14" fill="none" stroke-linecap="round"/>',
    # leaf
    grad("l", "#9af5b6", "#2fbf63", 1, 1),
    '<path d="M48 208 Q40 64 208 48 Q216 200 48 208 Z" fill="url(#l)" stroke="#1b8a45" stroke-width="8"/>'
    '<path d="M60 196 Q120 130 176 82 M108 150 L104 110 M140 120 L176 124" stroke="#1b8a45" stroke-width="8" fill="none" stroke-linecap="round"/>',
    # cycle arrows
    grad("cy", "#8fd0ff", "#3a8fe0"),
    ''.join(f'<g transform="rotate({k * 120} 128 128)"><path d="M128 36 A92 92 0 0 1 207 82 L224 72 L212 128 L162 104 L180 96 A62 62 0 0 0 128 66 Z" fill="url(#cy)" stroke="#1d5fa8" stroke-width="5" stroke-linejoin="round"/></g>' for k in range(3)),
]


def planet(t, polluted):
    if polluted:
        ocean = radial("oc", "#7d8794", "#3c434f", 0.35, 0.3, 0.8)
        land, land2, atm, cloud = "#8a7a5c", "#6b5d45", "#a08a6a", "#7a6f62"
    else:
        ocean = radial("oc", "#6fc3ff", "#1f5fae", 0.35, 0.3, 0.8)
        land, land2, atm, cloud = "#5fd47f", "#2f9a4c", "#7fd8ff", "#ffffff"
    defs = ocean + '<clipPath id="pc"><circle cx="128" cy="128" r="96"/></clipPath>' + \
        radial("atm", atm, atm, 0.5, 0.5, 0.5).replace(f'<stop offset="0" stop-color="{atm}"/>', f'<stop offset="0.8" stop-color="{atm}" stop-opacity="0"/><stop offset="0.9" stop-color="{atm}" stop-opacity=".45"/>').replace(f'<stop offset="1" stop-color="{atm}"/>', f'<stop offset="1" stop-color="{atm}" stop-opacity="0"/>') + \
        radial("shade", "#000", "#000", 0.3, 0.25, 0.9).replace('<stop offset="0" stop-color="#000"/>', '<stop offset="0.45" stop-color="#000" stop-opacity="0"/>').replace('<stop offset="1" stop-color="#000"/>', '<stop offset="1" stop-color="#000" stop-opacity=".55"/>')
    W = 384  # pattern period
    off = -W * t
    blobs = [  # continents in pattern space (x, y, path offsets)
        "M0 0 q30 -26 66 -10 q24 16 10 40 q-14 30 -46 26 q-34 -6 -34 -30 q0 -16 4 -26 Z",
        "M0 0 q40 -10 54 14 q8 26 -18 52 q-18 18 -30 0 q-10 -20 -24 -30 q-6 -26 18 -36 Z",
        "M0 0 q26 -18 50 0 q20 18 4 30 q-22 10 -40 4 q-20 -10 -14 -34 Z",
        "M0 0 q18 -8 40 2 q14 14 -2 26 q-22 8 -38 -6 q-6 -12 0 -22 Z",
    ]
    places = [(40, 92, 0), (150, 120, 1), (250, 70, 2), (300, 160, 3), (90, 176, 2)]
    land_svg = ""
    for rep in (0, W):
        for x, y, b in places:
            land_svg += (f'<path transform="translate({x + rep + off + 32:.1f} {y}) scale(1.1)" d="{blobs[b]}" '
                         f'fill="{land}" stroke="{land2}" stroke-width="3"/>')
    clouds = ""
    coff = -W * 2 * t  # clouds move faster -> period W/2 loops seamlessly
    for rep in (0, W):
        for x, y, w in ((20, 60, 60), (200, 110, 70), (120, 190, 50), (300, 40, 46)):
            clouds += (f'<rect x="{x + rep + coff:.1f}" y="{y}" width="{w}" height="12" rx="6" fill="{cloud}" opacity="{".55" if not polluted else ".75"}"/>')
    body = '<circle cx="128" cy="128" r="124" fill="url(#atm)"/>'
    body += '<circle cx="128" cy="128" r="96" fill="url(#oc)"/>'
    body += f'<g clip-path="url(#pc)">{land_svg}{clouds}'
    if polluted:
        body += '<rect x="20" y="96" width="220" height="22" fill="#5a5048" opacity=".45"/><rect x="20" y="150" width="220" height="14" fill="#5a5048" opacity=".35"/>'
    body += '<circle cx="128" cy="128" r="96" fill="url(#shade)"/></g>'
    body += '<path d="M66 84 A72 72 0 0 1 112 48" stroke="#fff" stroke-width="8" fill="none" stroke-linecap="round" opacity=".35"/>'
    return svg(defs, body)


def background():
    W, H = 1920, 1080
    defs = ('<radialGradient id="bgr" cx="0.5" cy="0.52" r="0.65"><stop offset="0" stop-color="#1d2536"/>'
            '<stop offset="0.6" stop-color="#151a26"/><stop offset="1" stop-color="#0e1119"/></radialGradient>'
            '<pattern id="dots" width="36" height="36" patternUnits="userSpaceOnUse"><circle cx="18" cy="18" r="1.6" fill="#2a3346"/></pattern>'
            '<linearGradient id="fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".35"/></linearGradient>')
    b = f'<rect width="{W}" height="{H}" fill="url(#bgr)"/><rect width="{W}" height="{H}" fill="url(#dots)" opacity=".7"/>'
    # far hills
    b += f'<path d="M0 900 Q240 820 480 880 T960 860 T1440 870 T1920 850 V{H} H0 Z" fill="#192030"/>'
    # wind turbines
    for x, y, s_ in ((260, 860, 1.0), (380, 880, 0.75), (1560, 850, 1.1), (1700, 870, 0.8)):
        b += (f'<g transform="translate({x} {y}) scale({s_})" fill="#222b3e"><rect x="-4" y="-170" width="8" height="170"/>'
              f'<circle cx="0" cy="-170" r="8"/>' +
              ''.join(f'<path transform="rotate({a} 0 -170)" d="M-4 -170 L0 -270 L5 -170 Z"/>' for a in (0, 120, 240)) + '</g>')
    # near hills + trees + buildings
    b += f'<path d="M0 960 Q300 900 640 950 T1280 940 T1920 930 V{H} H0 Z" fill="#1b2232"/>'
    for x in (120, 170, 720, 760, 1180, 1230, 1820):
        b += f'<g fill="#202a3c"><rect x="{x - 3}" y="910" width="6" height="40"/><circle cx="{x}" cy="900" r="22"/></g>'
    for x, w, h in ((880, 70, 90), (960, 50, 130), (1020, 80, 70), (1110, 40, 110)):
        b += f'<rect x="{x}" y="{950 - h}" width="{w}" height="{h + 20}" fill="#1e2637"/>'
        for wy in range(950 - h + 14, 940, 22):
            for wx in range(x + 10, x + w - 10, 16):
                b += f'<rect x="{wx}" y="{wy}" width="6" height="8" fill="#2c3852"/>'
    b += f'<rect width="{W}" height="{H}" fill="url(#fade)"/>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs>{defs}</defs>{b}</svg>'


def render_static(svg_text, size):
    png = cairosvg.svg2png(bytestring=svg_text.encode(), output_width=RENDER, output_height=RENDER)
    return Image.open(io.BytesIO(png)).convert("RGBA").resize((size, size), Image.LANCZOS)


def main2(outdir):
    os.makedirs(outdir, exist_ok=True)
    T = 64
    sheet = Image.new("RGBA", (T * 6, T), (0, 0, 0, 0))
    for i in range(6):
        sheet.paste(render_static(token_icon(i), T), (i * T, 0))
    sheet.save(os.path.join(outdir, "zetonai.png"))
    hs = Image.new("RGBA", (T * 3, T), (0, 0, 0, 0))
    for k in range(3):
        hs.paste(render_static(svg(HUD_ICONS[2 * k], HUD_ICONS[2 * k + 1]), T), (k * T, 0))
    hs.save(os.path.join(outdir, "ikonos.png"))
    P = 256
    for name, pol in (("planeta", False), ("planeta_tarsa", True)):
        sh = Image.new("RGBA", (P * N, P), (0, 0, 0, 0))
        for i in range(N):
            png = cairosvg.svg2png(bytestring=planet(i / N, pol).encode(), output_width=512, output_height=512)
            sh.paste(Image.open(io.BytesIO(png)).convert("RGBA").resize((P, P), Image.LANCZOS), (i * P, 0))
        sh.save(os.path.join(outdir, f"{name}.png"))
    cairosvg.svg2png(bytestring=background().encode(), write_to=os.path.join(outdir, "fonas.png"))


if __name__ == "__main__" and len(sys.argv) > 2 and sys.argv[2] == "v2":
    main2(sys.argv[1])


# ============================================================ v3: burning planet
def planet_fire(t):
    base = planet(t, True)
    defs_add = ('<radialGradient id="fireglow" cx="0.5" cy="0.5" r="0.5">'
                '<stop offset="0.72" stop-color="#ff5a1f" stop-opacity="0"/>'
                '<stop offset="0.86" stop-color="#ff5a1f" stop-opacity=".55"/>'
                '<stop offset="1" stop-color="#ff2a00" stop-opacity="0"/></radialGradient>')
    W = 384
    off = -W * t
    flames = ""
    spots = [(70, 100), (180, 130), (282, 80), (330, 168), (120, 188), (230, 60)]
    for rep in (0, W):
        for j, (x, y) in enumerate(spots):
            fx = x + rep + off + 32
            if fx < 20 or fx > 236:
                continue
            ph = (t * 3 + j * 0.37) % 1
            h = 36 + 10 * math.sin(TAU * ph)
            w = 15 + 3 * math.sin(TAU * (ph + 0.3))
            # fade near the planet edge
            dx = (fx - 128) / 96
            op = max(0.0, 1 - dx * dx * 1.1)
            flames += (f'<g opacity="{op:.2f}"><path d="M{fx - w:.1f} {y} Q{fx - w:.1f} {y - h * 0.6:.1f} {fx:.1f} {y - h:.1f} '
                       f'Q{fx + w:.1f} {y - h * 0.6:.1f} {fx + w:.1f} {y} Q{fx:.1f} {y + 6} {fx - w:.1f} {y} Z" fill="#ff5a1f"/>'
                       f'<path d="M{fx - w * 0.5:.1f} {y} Q{fx - w * 0.5:.1f} {y - h * 0.4:.1f} {fx:.1f} {y - h * 0.65:.1f} '
                       f'Q{fx + w * 0.5:.1f} {y - h * 0.4:.1f} {fx + w * 0.5:.1f} {y} Z" fill="#ffd23f"/></g>')
    base = base.replace('<defs>', '<defs>' + defs_add, 1)
    base = base.replace('</svg>', f'<circle cx="128" cy="128" r="126" fill="url(#fireglow)"/>'
                                  f'<g clip-path="url(#pc)">{flames}</g></svg>')
    # darker, redder ocean
    base = base.replace('#7d8794', '#7a5a50').replace('#3c434f', '#3a2626')
    return base


def main3(outdir):
    P = 256
    sh = Image.new("RGBA", (P * N, P), (0, 0, 0, 0))
    for i in range(N):
        png = cairosvg.svg2png(bytestring=planet_fire(i / N).encode(), output_width=512, output_height=512)
        sh.paste(Image.open(io.BytesIO(png)).convert("RGBA").resize((P, P), Image.LANCZOS), (i * P, 0))
    sh.save(os.path.join(outdir, "planeta_dega.png"))


if __name__ == "__main__" and len(sys.argv) > 2 and sys.argv[2] in ("v2", "v3"):
    main3(sys.argv[1])


# ============================================================ v4: sorting mini-game
SORT_ITEMS = [
    # 0 PET bottle -> yellow
    grad("pet", "#d9f4ff", "#7cc8ef") +
    '', '<g transform="rotate(-12 128 128)"><rect x="98" y="88" width="60" height="130" rx="22" fill="url(#pet)" stroke="#3d8fbf" stroke-width="5"/>'
        '<rect x="112" y="56" width="32" height="36" rx="6" fill="#d9f4ff" stroke="#3d8fbf" stroke-width="5"/>'
        '<rect x="108" y="40" width="40" height="18" rx="5" fill="#2f7fd0"/>'
        '<rect x="98" y="132" width="60" height="34" fill="#ff7a5a"/><rect x="110" y="98" width="10" height="100" rx="5" fill="#fff" opacity=".6"/></g>',
    # 1 can -> yellow
    grad("can", "#f2f4f7", "#9aa4b2"),
    '<rect x="86" y="64" width="84" height="140" rx="14" fill="url(#can)" stroke="#6b7685" stroke-width="5"/>'
    '<rect x="86" y="100" width="84" height="64" fill="#e0403a"/><path d="M98 132 Q128 112 158 132" stroke="#fff" stroke-width="7" fill="none"/>'
    '<ellipse cx="128" cy="66" rx="40" ry="8" fill="#cfd5dd"/><rect x="118" y="58" width="20" height="8" rx="3" fill="#8b95a3"/>',
    # 2 jar -> green
    grad("jar", "#e9fff2", "#9fdcb7"),
    '<rect x="78" y="96" width="100" height="116" rx="20" fill="url(#jar)" stroke="#3f9a64" stroke-width="5" opacity=".95"/>'
    '<rect x="88" y="66" width="80" height="32" rx="6" fill="#d6a23a" stroke="#9a6d12" stroke-width="5"/>'
    '<rect x="92" y="128" width="72" height="44" rx="6" fill="#fff" opacity=".9"/><circle cx="128" cy="150" r="12" fill="#e0575a"/>'
    '<rect x="90" y="104" width="10" height="90" rx="5" fill="#fff" opacity=".6"/>',
    # 3 glass bottle -> green
    grad("gb", "#7fe0a8", "#1f8a4c"),
    '<g transform="rotate(10 128 128)"><path d="M112 40 H144 V92 Q172 104 172 136 V214 Q172 222 164 222 H92 Q84 222 84 214 V136 Q84 104 112 92 Z" fill="url(#gb)" stroke="#145c33" stroke-width="5"/>'
    '<rect x="110" y="32" width="36" height="14" rx="4" fill="#d6a23a"/><rect x="96" y="140" width="64" height="44" rx="6" fill="#f3ead2"/>'
    '<rect x="96" y="116" width="10" height="90" rx="5" fill="#fff" opacity=".45"/></g>',
    # 4 newspaper -> blue
    grad("np", "#ffffff", "#e3e7ee"),
    '<g transform="rotate(-8 128 128)"><rect x="56" y="64" width="144" height="128" rx="6" fill="url(#np)" stroke="#7d8798" stroke-width="5"/>'
    '<rect x="70" y="78" width="116" height="20" rx="3" fill="#3a4250"/>'
    '<rect x="70" y="108" width="52" height="40" rx="3" fill="#9fb3d1"/>'
    '<path d="M132 112 H186 M132 124 H186 M132 136 H180 M70 160 H186 M70 172 H170" stroke="#9aa3b2" stroke-width="6" stroke-linecap="round"/></g>',
    # 5 cardboard box -> blue
    grad("cb", "#e9b878", "#b77a35"),
    '<path d="M128 72 L196 102 V174 L128 206 L60 174 V102 Z" fill="url(#cb)" stroke="#7a4f1d" stroke-width="5" stroke-linejoin="round"/>'
    '<path d="M60 102 L128 132 L196 102 M128 132 V206" stroke="#7a4f1d" stroke-width="5" fill="none"/>'
    '<path d="M94 86 L162 116 V140" stroke="#f3d39c" stroke-width="12" fill="none"/>'
    '<path d="M76 150 l12 6 M76 162 l12 6" stroke="#7a4f1d" stroke-width="4"/>',
]

BIN_SPECS = [("#ffe36a", "#e6b916", "#c99f10", "PLASTIKAS\nMETALAS"),
             ("#6be08f", "#27a855", "#1f8f47", "STIKLAS"),
             ("#6aa8f0", "#2f72c8", "#2a62ad", "POPIERIUS")]


def sort_bin(i, open_=0.0):
    a, b, lid, _ = BIN_SPECS[i]
    defs = grad("bb", a, b)
    body = '<ellipse cx="128" cy="236" rx="90" ry="10" fill="#000" opacity=".25"/>'
    body += '<path d="M52 92 H204 L190 232 H66 Z" fill="url(#bb)"/>'
    body += '<path d="M86 112 V212 M128 112 V212 M170 112 V212" stroke="#000" stroke-opacity=".12" stroke-width="8" stroke-linecap="round"/>'
    body += '<rect x="62" y="96" width="12" height="120" rx="6" fill="#fff" opacity=".25"/>'
    body += f'<g transform="rotate({-25 * open_:.1f} 44 86)"><rect x="40" y="70" width="176" height="26" rx="12" fill="{lid}"/>'
    body += '<rect x="58" y="75" width="80" height="7" rx="3.5" fill="#fff" opacity=".4"/></g>'
    # recycling symbol
    body += '<g transform="translate(128 160) scale(0.55) translate(-128 -128)">'
    for k in range(3):
        body += (f'<g transform="rotate({k * 120} 128 128)"><path d="M128 36 A92 92 0 0 1 207 82 L224 72 L212 128 L162 104 L180 96 '
                 f'A62 62 0 0 0 128 66 Z" fill="#fff" opacity=".85"/></g>')
    body += '</g>'
    return svg(defs, body)


def main4(outdir):
    T = 128
    sh = Image.new("RGBA", (T * 6, T), (0, 0, 0, 0))
    for i in range(6):
        sh.paste(render_static(svg(SORT_ITEMS[2 * i], SORT_ITEMS[2 * i + 1]), T), (i * T, 0))
    sh.save(os.path.join(outdir, "rusiavimas_daiktai.png"))
    B = 160
    bs = Image.new("RGBA", (B * 6, B), (0, 0, 0, 0))   # 3 closed + 3 open lids
    for i in range(3):
        bs.paste(render_static(sort_bin(i, 0.0), B), (i * B, 0))
        bs.paste(render_static(sort_bin(i, 1.0), B), ((i + 3) * B, 0))
    bs.save(os.path.join(outdir, "konteineriai.png"))


if __name__ == "__main__" and len(sys.argv) > 2 and sys.argv[2] in ("v2", "v3", "v4"):
    main4(sys.argv[1])


# ============================================================ v5: investment card icons (animated)
def _gear(cx, cy, ro, ri, teeth, rot, fill, stroke):
    return f'<polygon points="{gear_poly(cx, cy, ro, ri, teeth, rot)}" fill="{fill}" stroke="{stroke}" stroke-width="4"/><circle cx="{cx}" cy="{cy}" r="{ri*0.38:.1f}" fill="{stroke}"/>'


def perk_icon(pid, t):
    d = ""
    b = ""
    if pid == "solar":
        d = grad("pan", "#5fb2ff", "#1d4f9c") + radial("sun", "#fff6b0", "#ffb020")
        rot = 360 * t / 4
        b += f'<g transform="rotate({rot*4:.1f} 176 70)">' + ''.join(
            f'<rect x="172" y="18" width="8" height="22" rx="4" fill="#ffd34a" transform="rotate({k*45} 176 70)"/>' for k in range(8)) + '</g>'
        b += f'<circle cx="176" cy="70" r="{28 + 2*math.sin(TAU*t):.1f}" fill="url(#sun)"/>'
        b += '<path d="M40 150 L200 120 L222 196 L62 226 Z" fill="url(#pan)" stroke="#0f2f5f" stroke-width="5" stroke-linejoin="round"/>'
        b += '<path d="M93 140 L114 216 M146 130 L167 206 M51 188 L211 158" stroke="#9fd2ff" stroke-width="3" opacity=".7"/>'
        sx = lerp(40, 220, t)
        b += f'<path d="M{sx-10} {150-(sx-40)*0.19:.1f} l18 -3 l20 76 l-18 3 Z" fill="#fff" opacity=".35"/>'
    elif pid == "repair":
        d = grad("wr", "#e8eef5", "#8e9aab")
        b += _gear(110, 150, 62, 46, 10, 36 * t, "#5ac26e", "#2f7d43")
        a = 18 * math.sin(TAU * t)
        b += (f'<g transform="rotate({a - 35:.1f} 150 120)"><path d="M150 40 a28 28 0 1 0 22 46 l-12 -10 l2 -16 l14 -8 l12 8 A28 28 0 0 0 150 40 Z" fill="url(#wr)" stroke="#5b6573" stroke-width="4"/>'
              f'<rect x="140" y="80" width="24" height="120" rx="12" fill="url(#wr)" stroke="#5b6573" stroke-width="4"/></g>')
    elif pid == "deposit":
        d = grad("mach", "#ffc766", "#e88b14") + grad("btl", "#b5ecff", "#3fa9e0")
        b += '<rect x="70" y="60" width="130" height="170" rx="14" fill="url(#mach)" stroke="#a9620b" stroke-width="5"/>'
        b += '<rect x="96" y="84" width="78" height="20" rx="10" fill="#3a2a10"/><rect x="96" y="128" width="78" height="44" rx="6" fill="#22303f"/>'
        u = t
        by = lerp(-10, 92, min(1, u / 0.5)) if u < 0.5 else 200
        if u < 0.5:
            b += f'<g transform="translate(135 {by:.1f})"><rect x="-11" y="-30" width="22" height="40" rx="7" fill="url(#btl)" stroke="#1f7fc2" stroke-width="3"/><rect x="-6" y="-42" width="12" height="13" rx="3" fill="#1f7fc2"/></g>'
        if u >= 0.5:
            k = (u - 0.5) / 0.5
            b += f'<g transform="translate({135} {200 - 60*math.sin(math.pi*k):.1f})" opacity="{1-k*0.6:.2f}"><circle r="18" fill="#ffd84a" stroke="#b9860b" stroke-width="4"/><text x="-8" y="8" font-size="22" font-family="sans-serif" font-weight="bold" fill="#8a5d00">€</text></g>'
        b += f'<rect x="108" y="140" width="{54*abs(math.sin(TAU*t*2)):.1f}" height="8" rx="4" fill="#5ac26e"/>'
    elif pid == "education":
        d = grad("bk", "#7fb4ff", "#2f6fd0") + radial("bulb", "#fffbd0", "#ffd84a")
        glow = 0.5 + 0.5 * math.sin(TAU * t)
        b += f'<circle cx="128" cy="78" r="{46 + 8*glow:.1f}" fill="#ffe680" opacity="{0.25 + 0.25*glow:.2f}"/>'
        b += '<circle cx="128" cy="78" r="38" fill="url(#bulb)" stroke="#c99f10" stroke-width="4"/><rect x="112" y="112" width="32" height="22" rx="5" fill="#9aa4b2"/>'
        b += '<path d="M40 160 Q84 140 128 162 Q172 140 216 160 V226 Q172 208 128 228 Q84 208 40 226 Z" fill="url(#bk)" stroke="#1d4f9c" stroke-width="5"/>'
        b += '<path d="M128 162 V228" stroke="#1d4f9c" stroke-width="4"/>'
        fl = math.cos(math.pi * t)
        b += f'<path d="M128 162 Q{128 + 44*fl:.1f} 146 {128 + 86*fl:.1f} 162 V222 Q{128 + 44*fl:.1f} 206 128 226 Z" fill="#e8f1ff" stroke="#1d4f9c" stroke-width="3" opacity=".9"/>'
    elif pid == "bond":
        d = grad("doc", "#ffffff", "#dfe7d8")
        b += '<rect x="50" y="40" width="130" height="170" rx="10" fill="url(#doc)" stroke="#5a7a50" stroke-width="5"/>'
        b += '<path d="M72 76 H158 M72 100 H158 M72 124 H136" stroke="#8aa880" stroke-width="7" stroke-linecap="round"/>'
        b += '<circle cx="138" cy="170" r="24" fill="#5ac26e" stroke="#2f7d43" stroke-width="4"/><path d="M130 160 q14 -6 14 10 q0 14 -14 10 M126 166 H140 M126 174 H140" stroke="#fff" stroke-width="4" fill="none"/>'
        for k in range(3):
            u = (t + k / 3) % 1
            y = 210 - 80 * math.sin(math.pi * u)
            b += f'<g transform="translate({192 + k*14} {y:.1f})"><circle r="17" fill="#ffd84a" stroke="#b9860b" stroke-width="4"/></g>'
    elif pid == "automation":
        b += _gear(96, 150, 58, 44, 10, 36 * t, "#86bdf5", "#2b6cbf")
        b += _gear(176, 92, 42, 31, 8, -45 * t + 22, "#c3a2f5", "#7346c4")
        b += f'<circle cx="190" cy="196" r="{10 + 3*math.sin(TAU*t*2):.1f}" fill="#5ac26e"/>'
    elif pid == "ecolabel":
        d = grad("lf", "#9af5b6", "#2fbf63", 1, 1)
        b += '<circle cx="128" cy="128" r="96" fill="#1f5c33" stroke="#5ac26e" stroke-width="8"/>'
        b += f'<g transform="rotate({8*math.sin(TAU*t):.1f} 128 140)"><path d="M70 186 Q60 70 190 62 Q198 182 70 186 Z" fill="url(#lf)"/><path d="M80 176 Q126 126 172 82" stroke="#1b8a45" stroke-width="7" fill="none" stroke-linecap="round"/></g>'
        sx = lerp(-60, 300, t)
        b += f'<clipPath id="cc"><circle cx="128" cy="128" r="92"/></clipPath><g clip-path="url(#cc)"><path d="M{sx} 20 l28 0 l-60 220 l-28 0 Z" fill="#fff" opacity=".28"/></g>'
        b += sparkle(196, 56, 14, "#fff7c0", 1, twinkle(t, 0))
    elif pid == "logistics":
        d = grad("wh", "#8fa6c4", "#55698a") + grad("bx", "#e9b878", "#b77a35")
        b += '<path d="M30 120 L128 60 L226 120 V226 H30 Z" fill="url(#wh)" stroke="#2f3d55" stroke-width="5" stroke-linejoin="round"/>'
        b += '<rect x="70" y="136" width="116" height="90" fill="#26324a"/>'
        for k in range(3):
            u = min(1.0, max(0.0, t * 3 - k))
            y = lerp(60, 196 - k * 30, u * u)
            if t * 3 >= k:
                b += f'<rect x="108" y="{y:.1f}" width="40" height="30" rx="3" fill="url(#bx)" stroke="#7a4f1d" stroke-width="3"/>'
    elif pid == "cleantech":
        d = grad("fl", "#b9f0ff", "#4aa8d8")
        b += '<rect x="56" y="130" width="144" height="96" rx="16" fill="url(#fl)" stroke="#1f6f99" stroke-width="5"/>'
        b += '<path d="M76 154 H180 M76 176 H180 M76 198 H180" stroke="#ffffff" stroke-width="5" opacity=".6"/>'
        for k in range(6):
            u = (t + k / 6) % 1
            x = 80 + (k * 37) % 100
            y = 120 - 90 * u
            b += f'<circle cx="{x + 8*math.sin(TAU*(u+k*0.2)):.1f}" cy="{y:.1f}" r="{6 + 6*u:.1f}" fill="#e6fbff" opacity="{(1-u)*0.9:.2f}"/>'
        for k in range(3):
            u = (t + k / 3) % 1
            b += f'<circle cx="{110 + k*20}" cy="{240 + 0*u}" r="5" fill="#6b5a45" opacity="{u*0.8:.2f}"/>'
    elif pid == "tax":
        d = radial("tg", "#fff2a8", "#f2c81e")
        b += '<circle cx="128" cy="128" r="96" fill="url(#tg)" stroke="#b9860b" stroke-width="7"/>'
        b += '<circle cx="96" cy="96" r="18" fill="none" stroke="#7a5600" stroke-width="12"/><circle cx="160" cy="160" r="18" fill="none" stroke="#7a5600" stroke-width="12"/><path d="M168 82 L88 174" stroke="#7a5600" stroke-width="12" stroke-linecap="round"/>'
        y = 12 * abs(math.sin(TAU * t))
        b += f'<g transform="translate(206 {150 + y:.1f})"><path d="M-18 -30 H18 V8 H34 L0 44 L-34 8 H-18 Z" fill="#5ac26e" stroke="#2f7d43" stroke-width="4"/></g>'
    elif pid == "venture":
        d = grad("rk", "#ffffff", "#c9d6e6")
        y = 8 * math.sin(TAU * t)
        fl = 0.7 + 0.3 * abs(math.sin(TAU * t * 3))
        b += f'<g transform="translate(0 {y:.1f}) rotate(35 128 128)">'
        b += f'<path d="M110 186 Q128 {186 + 60*fl:.1f} 146 186 Z" fill="#ff7a2a"/><path d="M118 186 Q128 {186 + 36*fl:.1f} 138 186 Z" fill="#ffd84a"/>'
        b += '<path d="M128 26 Q170 70 160 170 H96 Q86 70 128 26 Z" fill="url(#rk)" stroke="#4a5a72" stroke-width="5"/>'
        b += '<circle cx="128" cy="100" r="18" fill="#4a90e0" stroke="#4a5a72" stroke-width="5"/>'
        b += '<path d="M96 140 L70 186 L100 172 Z M160 140 L186 186 L156 172 Z" fill="#e0575a" stroke="#8a2e30" stroke-width="4"/></g>'
        for k in range(3):
            u = (t + k / 3) % 1
            b += sparkle(40 + k * 70, 230 - 200 * u, 7, "#fff7c0", 1 - u)
    elif pid == "firebrigade":
        d = grad("ex", "#ff6a6a", "#c22a2a")
        fl = 1 - t
        b += f'<g transform="translate(196 196) scale({0.4 + 0.6*fl:.2f})"><path d="M-26 20 Q-30 -20 0 -50 Q30 -20 26 20 Z" fill="#ff7a2a"/><path d="M-12 20 Q-14 -6 0 -24 Q14 -6 12 20 Z" fill="#ffd84a"/></g>'
        b += '<rect x="46" y="86" width="64" height="140" rx="22" fill="url(#ex)" stroke="#7a1a1a" stroke-width="5"/>'
        b += '<rect x="64" y="58" width="28" height="30" rx="6" fill="#4a5a72"/><path d="M92 66 H140 L150 80" stroke="#4a5a72" stroke-width="10" fill="none" stroke-linecap="round"/>'
        for k in range(7):
            u = (t * 2 + k / 7) % 1
            x = lerp(150, 200, u)
            y = lerp(84, 186, u) + 10 * math.sin(k)
            b += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{5 + 7*u:.1f}" fill="#e6f6ff" opacity="{0.9 - 0.6*u:.2f}"/>'
    return svg(d, b)


PERK_IDS = ["solar", "repair", "deposit", "education", "bond", "automation", "ecolabel", "logistics",
            "cleantech", "tax", "venture", "firebrigade"]


def main5(outdir):
    F = 16
    S = 96
    for pid in PERK_IDS:
        sh = Image.new("RGBA", (S * F, S), (0, 0, 0, 0))
        for i in range(F):
            png = cairosvg.svg2png(bytestring=perk_icon(pid, i / F).encode(), output_width=256, output_height=256)
            sh.paste(Image.open(io.BytesIO(png)).convert("RGBA").resize((S, S), Image.LANCZOS), (i * S, 0))
        os.makedirs(os.path.join(outdir, "kortos"), exist_ok=True)
        sh.save(os.path.join(outdir, "kortos", f"{pid}.png"))
