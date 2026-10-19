"""Pack rendered frames into the sprite sheets the game expects."""
import os, sys, math
import numpy as np
from PIL import Image, ImageFilter

F = '/home/claude/gen/b3d/frames'
ART = sys.argv[1] if len(sys.argv) > 1 else '/home/claude/gen/b3d/art'
os.makedirs(ART, exist_ok=True)
os.makedirs(os.path.join(ART, 'kortos'), exist_ok=True)


def load(p, size=None):
    im = Image.open(p).convert('RGBA')
    if size:
        im = im.resize((size, size), Image.LANCZOS)
    return im


def stations():
    S = 224
    for n in ['1_naudotojas', '2_surinkimas', '3_rusiavimas', '4_perdirbimas', '5_gamykla', '6_parduotuve']:
        sh = Image.new('RGBA', (S * 24, S))
        for i in range(24):
            sh.paste(load(f'{F}/{n}_{i:02d}.png', S), (i * S, 0))
        sh.save(f'{ART}/{n}.png', optimize=True)


def glow_ring(size, R, col, strength, width):
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    c = (size - 1) / 2
    d = np.sqrt((x - c) ** 2 + (y - c) ** 2)
    outer = np.clip(1 - (d - R) / width, 0, 1) ** 2.2 * (d >= R)
    inner = np.clip(1 - (R - d) / (width * 0.35), 0, 1) ** 2 * (d < R) * 0.55
    a = (outer + inner) * strength
    img = np.zeros((size, size, 4), np.float32)
    img[..., :3] = col
    img[..., 3] = np.clip(a, 0, 1) * 255
    return Image.fromarray(img.astype(np.uint8), 'RGBA')


def shade(size, R):
    """Soft night-side darkening towards the lower right (sun upper-left)."""
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    c = (size - 1) / 2
    u = ((x - c) * 0.62 + (y - c) * 0.78) / R
    a = np.clip((u - 0.15) / 0.95, 0, 1) ** 1.6 * 0.55
    d = np.sqrt((x - c) ** 2 + (y - c) ** 2)
    a *= (d < R + 1)
    img = np.zeros((size, size, 4), np.float32)
    img[..., :3] = (8, 10, 24)
    img[..., 3] = a * 255
    return Image.fromarray(img.astype(np.uint8), 'RGBA')


def planets():
    S = 320
    cols, rows = 12, 4
    for kind, out, col, st in [('ok', 'planeta', (120, 190, 255), 0.85), ('bad', 'planeta_tarsa', (170, 150, 110), 0.8),
                               ('fire', 'planeta_dega', (255, 120, 40), 1.0)]:
        sh = Image.new('RGBA', (S * cols, S * rows))
        src0 = load(f'{F}/planet_{kind}_00.png')
        N = src0.size[0]
        R = N * (2 / 2.5) / 2       # sphere radius in px at render size
        ring = glow_ring(N, R, col, st, N * 0.07)
        sd = shade(N, R)
        for i in range(48):
            im = load(f'{F}/planet_{kind}_{i:02d}.png')
            im.alpha_composite(sd)
            base = Image.new('RGBA', (N, N))
            base.alpha_composite(ring)
            base.alpha_composite(im)
            # re-add the inner rim highlight on top of the surface
            base.alpha_composite(Image.fromarray((np.array(ring) * np.array([1, 1, 1, 0.6])).astype(np.uint8)))
            sh.paste(base.resize((S, S), Image.LANCZOS), ((i % cols) * S, (i // cols) * S))
        sh.save(f'{ART}/{out}.png', optimize=True)


def tokens():
    S = 96
    sh = Image.new('RGBA', (S * 6, S))
    for i in range(6):
        sh.paste(load(f'{F}/tok_{i}.png', S), (i * S, 0))
    sh.save(f'{ART}/zetonai.png')
    S = 96
    sh = Image.new('RGBA', (S * 3, S))
    for i in range(3):
        sh.paste(load(f'{F}/hud_{i}.png', S), (i * S, 0))
    sh.save(f'{ART}/ikonos.png')


def sorting():
    T = 160
    sh = Image.new('RGBA', (T * 6, T))
    for i in range(6):
        sh.paste(load(f'{F}/sort_{i}.png', T), (i * T, 0))
    sh.save(f'{ART}/rusiavimas_daiktai.png')
    B = 200
    bs = Image.new('RGBA', (B * 6, B))
    for i in range(3):
        bs.paste(load(f'{F}/bin_{i}_0.png', B), (i * B, 0))
        bs.paste(load(f'{F}/bin_{i}_1.png', B), ((i + 3) * B, 0))
    bs.save(f'{ART}/konteineriai.png')


def perks():
    S = 128
    ids = ['solar', 'repair', 'deposit', 'education', 'bond', 'automation', 'ecolabel', 'logistics', 'cleantech',
           'tax', 'venture', 'firebrigade']
    for pid in ids:
        sh = Image.new('RGBA', (S * 16, S))
        for i in range(16):
            im = load(f'{F}/perk_{pid}_{i:02d}.png')
            w = im.size[0]
            im = im.crop((int(w * 0.1), int(w * 0.1), int(w * 0.9), int(w * 0.9))).resize((S, S), Image.LANCZOS)
            sh.paste(im, (i * S, 0))
        sh.save(f'{ART}/kortos/{pid}.png')


if __name__ == '__main__':
    what = sys.argv[2:] or ['stations', 'planets', 'tokens', 'sorting', 'perks']
    for w in what:
        globals()[w]()
        print('ok', w)
