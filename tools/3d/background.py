"""Painted space backdrop for the ring: soft nebula, stars, vignette."""
import sys
import numpy as np
from PIL import Image, ImageFilter

W, H = 1920, 1080
rng = np.random.default_rng(7)


def fbm(octaves=6, base=4):
    acc = np.zeros((H, W), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        n = base * 2 ** o
        small = rng.random((max(2, n * H // W), n)).astype(np.float32)
        im = Image.fromarray((small * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
        acc += np.asarray(im, np.float32) / 255 * amp
        tot += amp
        amp *= 0.5
    return acc / tot


y, x = np.mgrid[0:H, 0:W].astype(np.float32)
u, v = x / W, y / H
top = np.array([14, 22, 40], np.float32)
bot = np.array([20, 34, 48], np.float32)
img = top * (1 - v[..., None]) + bot * v[..., None]

# nebula: two tinted clouds
n1 = fbm(7, 5)
n2 = fbm(7, 6)
m1 = np.clip((n1 - 0.4) * 2.0, 0, 1) ** 1.4
m2 = np.clip((n2 - 0.45) * 2.2, 0, 1) ** 1.5
# keep them mostly to the corners so the centre stays calm
cx, cy = u - 0.5, (v - 0.5) * H / W
r = np.sqrt(cx ** 2 + cy ** 2)
edge = np.clip((r - 0.12) / 0.45, 0, 1)
img += m1[..., None] * edge[..., None] * np.array([30, 62, 78], np.float32) * 1.5
img += m2[..., None] * edge[..., None] * np.array([70, 34, 62], np.float32) * 1.1

# central warm-cool glow behind the planet
g = np.exp(-(r / 0.28) ** 2)
img += g[..., None] * np.array([22, 38, 52], np.float32)

# stars
stars = np.zeros((H, W), np.float32)
n = 900
sx = rng.integers(0, W, n)
sy = rng.integers(0, H, n)
sb = rng.random(n) ** 3
stars[sy, sx] = sb * 255
st = Image.fromarray(stars.astype(np.uint8))
glow = np.asarray(st.filter(ImageFilter.GaussianBlur(1.2)), np.float32)
stars = np.maximum(stars * 0.9, glow * 2.2)
img += stars[..., None] * np.array([0.85, 0.9, 1.0]) * 0.75

# vignette
vig = np.clip(1 - (r / 0.75) ** 2 * 0.55, 0.35, 1)
img *= vig[..., None]

# subtle grain so gradients don't band
img += rng.normal(0, 1.6, img.shape)
out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
out.save(sys.argv[1] if len(sys.argv) > 1 else '/home/claude/gen/b3d/art/fonas.png', optimize=True)
