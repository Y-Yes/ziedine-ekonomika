"""Derive clean / polluted / burning Earth textures from the three.js Earth maps."""
import numpy as np
from PIL import Image, ImageFilter
S = '/tmp/claude-0/tex/'
O = '/home/claude/gen/b3d/tex/'
rng = np.random.default_rng(3)
col = np.asarray(Image.open(S + 'earth_atmos_2048.jpg').convert('RGB'), np.float32) / 255
spec = np.asarray(Image.open(S + 'earth_specular_2048.jpg').convert('L'), np.float32) / 255
water = np.asarray(Image.fromarray((spec * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5)), np.float32) / 255
land = 1 - water
cl = Image.open(S + 'earth_clouds_1024.png').convert('L').resize((2048, 1024), Image.BICUBIC)
cl = np.asarray(cl, np.float32) / 255
H, W = spec.shape


def save(a, name):
    Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8)).save(O + name)


def noise(scale, oct=5):
    acc = np.zeros((H, W), np.float32); amp = 1; tot = 0
    for o in range(oct):
        n = int(scale * 2 ** o)
        sm = rng.random((max(2, n // 2), n)).astype(np.float32)
        im = Image.fromarray((sm * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
        acc += np.asarray(im, np.float32) / 255 * amp; tot += amp; amp *= 0.5
    return acc / tot


# clean: a touch more saturated / brighter
g = col.mean(axis=2, keepdims=True)
ok = np.clip(g + (col - g) * 1.25, 0, 1) ** 0.92
save(ok, 'ok_col.png')
save(water, 'water.png')
save(cl, 'clouds.png')

# polluted: brown dead land, murky grey-green seas
lum = col.mean(axis=2, keepdims=True)
dead = lum * np.array([1.25, 1.05, 0.75]) + np.array([0.12, 0.08, 0.03])
murky = np.array([0.22, 0.25, 0.2]) + lum * np.array([0.4, 0.42, 0.32])
n = noise(6)[..., None]
bad = dead * land[..., None] + murky * water[..., None]
bad *= 0.85 + 0.3 * n
save(np.clip(bad, 0, 1), 'bad_col.png')

# burning: charred land, dark seas, lava veins (emission map)
char = lum * np.array([0.35, 0.25, 0.2]) + np.array([0.08, 0.04, 0.03])
sea = np.array([0.12, 0.05, 0.03]) + lum * np.array([0.2, 0.08, 0.05])
fire = char * land[..., None] + sea * water[..., None]
save(np.clip(fire, 0, 1), 'fire_col.png')
v = noise(10, 6)
veins = np.clip(1 - np.abs(v - 0.5) / 0.022, 0, 1)
v2 = noise(18, 5)
veins = np.maximum(veins, np.clip(1 - np.abs(v2 - 0.5) / 0.015, 0, 1) * 0.7)
coast = np.asarray(Image.fromarray((land * 255).astype(np.uint8)).filter(ImageFilter.FIND_EDGES).filter(ImageFilter.GaussianBlur(2)), np.float32) / 255
em = np.clip(veins * (0.35 + 0.65 * land) + coast * 1.5, 0, 1)
emc = em[..., None] * np.array([1.0, 0.42, 0.1])
save(emc, 'fire_em.png')
print('ok')
