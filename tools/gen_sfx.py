"""Procedurally synthesised sound effects + a gentle music loop for the game.
Writes 16-bit mono WAV files into the given folder."""
import sys, os, wave
import numpy as np

SR = 22050
rng = np.random.default_rng(7)


def t_(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, r=None, curve=4.0):
    """Attack + exponential decay envelope."""
    e = np.ones(n)
    na = max(1, int(a * SR))
    e[:na] = np.linspace(0, 1, na)
    x = np.linspace(0, 1, n - na)
    e[na:] = np.exp(-curve * x)
    return e


def tone(freq, d, kind="sine", vol=0.5, a=0.004, curve=5.0, sweep=None):
    t = t_(d)
    f = np.full_like(t, freq) if sweep is None else np.linspace(freq, sweep, len(t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    if kind == "sine":
        w = np.sin(ph)
    elif kind == "tri":
        w = 2 / np.pi * np.arcsin(np.sin(ph))
    elif kind == "square":
        w = np.sign(np.sin(ph)) * 0.6
    elif kind == "saw":
        w = 2 * ((ph / (2 * np.pi)) % 1) - 1
    else:
        w = np.sin(ph)
    return w * env(len(t), a, curve=curve) * vol


def bell(freq, d, vol=0.4):
    out = tone(freq, d, "sine", vol, curve=6)
    out += tone(freq * 2.01, d, "sine", vol * 0.35, curve=9)
    out += tone(freq * 3.02, d, "sine", vol * 0.15, curve=12)
    return out


def noise(d, vol=0.3, curve=6.0, lp=None):
    n = rng.uniform(-1, 1, int(SR * d))
    if lp:
        # simple one-pole low pass
        k = lp
        y = np.zeros_like(n)
        acc = 0.0
        for i, v in enumerate(n):
            acc += k * (v - acc)
            y[i] = acc
        n = y / (np.max(np.abs(y)) + 1e-9)
    return n * env(len(n), 0.002, curve=curve) * vol


def mix(*parts, offsets=None):
    offsets = offsets or [0] * len(parts)
    n = max(int(o * SR) + len(p) for p, o in zip(parts, offsets))
    out = np.zeros(n)
    for p, o in zip(parts, offsets):
        s = int(o * SR)
        out[s:s + len(p)] += p
    return out


def save(path, x, peak=0.85):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) + 1e-9
    x = x / m * peak
    # tiny fade out to avoid clicks
    f = min(len(x), int(0.01 * SR))
    x[-f:] *= np.linspace(1, 0, f)
    data = (x * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def note(n):  # midi -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)


def build(out):
    os.makedirs(out, exist_ok=True)
    S = {}
    S["click"] = mix(tone(1800, 0.04, "sine", 0.5, curve=14), noise(0.02, 0.15, 20))
    S["work"] = mix(tone(220, 0.12, "sine", 0.7, curve=10, sweep=120), noise(0.05, 0.2, 18, lp=0.2))
    S["coin"] = mix(bell(note(83), 0.12, 0.5), bell(note(88), 0.35, 0.5), offsets=[0, 0.07])
    S["sale"] = mix(noise(0.06, 0.35, 14), bell(note(84), 0.25, 0.45), bell(note(91), 0.45, 0.4),
                    offsets=[0, 0.02, 0.09])
    S["upgrade"] = mix(*[bell(note(n), 0.35, 0.4) for n in (72, 76, 79, 84)], tone(note(96), 0.5, "sine", 0.12, curve=5),
                       offsets=[0, 0.06, 0.12, 0.18, 0.2])
    S["error"] = mix(tone(110, 0.18, "square", 0.35, curve=4), tone(104, 0.18, "square", 0.3, curve=4), offsets=[0, 0.0])
    S["bonus_spawn"] = tone(500, 0.16, "sine", 0.5, curve=6, sweep=1000)
    S["bonus_get"] = mix(*[bell(note(n), 0.3, 0.35) for n in (84, 88, 91, 96)], offsets=[0, 0.04, 0.08, 0.12])
    S["landfill"] = mix(tone(90, 0.25, "sine", 0.8, curve=8, sweep=50), noise(0.2, 0.35, 10, lp=0.08))
    siren = np.concatenate([tone(880 if i % 2 == 0 else 660, 0.18, "tri", 0.4, a=0.01, curve=0.5) for i in range(6)])
    S["fire"] = siren
    S["extinguish"] = noise(0.6, 0.45, 4, lp=0.35)
    S["flood"] = mix(noise(1.0, 0.5, 2.5, lp=0.05), tone(200, 1.0, "sine", 0.15, curve=3, sweep=80))
    S["event"] = mix(*[bell(note(n), 0.5, 0.35) for n in (76, 81, 85)], offsets=[0, 0.1, 0.2])
    S["year"] = mix(*[bell(note(n), 0.9, 0.3) for n in (60, 64, 67, 72, 76, 79, 84)],
                    *[tone(note(n), 1.2, "tri", 0.12, a=0.02, curve=2.5) for n in (48, 55, 60)],
                    offsets=[0, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.48, 0.48, 0.48])
    S["card"] = mix(noise(0.15, 0.2, 8, lp=0.3), bell(note(79), 0.3, 0.4), bell(note(86), 0.4, 0.35), offsets=[0, 0.05, 0.11])
    S["sort_ok"] = mix(bell(note(88), 0.25, 0.45), bell(note(95), 0.3, 0.3), offsets=[0, 0.05])
    S["sort_bad"] = mix(tone(180, 0.22, "saw", 0.3, curve=5, sweep=120), tone(170, 0.22, "square", 0.2, curve=5))
    S["sort_open"] = mix(noise(0.3, 0.25, 6, lp=0.15), *[bell(note(n), 0.3, 0.3) for n in (79, 83, 86)],
                         offsets=[0, 0.05, 0.1, 0.15])
    S["whoosh"] = noise(0.25, 0.35, 5, lp=0.25)
    S["confetti"] = mix(*[noise(0.05, 0.15, 20) for _ in range(6)], offsets=[i * 0.03 for i in range(6)])
    for k, v in S.items():
        save(os.path.join(out, f"{k}.wav"), v)
    # ---- Music: 8 bars @ 92 bpm, Am - F - C - G, soft pads + pluck arpeggio + light beat
    bpm = 92
    beat = 60 / bpm
    bars = 8
    total = bars * 4 * beat
    n = int(total * SR)
    mus = np.zeros(n + SR)
    chords = [(57, 60, 64), (53, 57, 60), (48, 52, 55), (55, 59, 62)] * 2
    for b, ch in enumerate(chords):
        start = b * 4 * beat
        # pad
        for m in ch:
            pad = tone(note(m), 4 * beat, "tri", 0.07, a=0.4, curve=0.6)
            pad += tone(note(m) * 1.004, 4 * beat, "sine", 0.05, a=0.4, curve=0.6)
            s = int(start * SR)
            mus[s:s + len(pad)] += pad
        # bass
        bs = tone(note(ch[0] - 12), 2 * beat, "sine", 0.18, a=0.01, curve=2)
        for k in (0, 2):
            s = int((start + k * beat) * SR)
            mus[s:s + len(bs)] += bs
        # arpeggio (8th notes)
        arp = [ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[1] + 12]
        for k in range(8):
            pl = tone(note(arp[k % 4]), 0.35, "tri", 0.07, a=0.003, curve=7)
            s = int((start + k * beat / 2) * SR)
            mus[s:s + len(pl)] += pl
        # soft kick + hat
        for k in range(4):
            kick = tone(110, 0.18, "sine", 0.22, a=0.002, curve=9, sweep=45)
            s = int((start + k * beat) * SR)
            mus[s:s + len(kick)] += kick
            hat = noise(0.04, 0.035, 25)
            s2 = int((start + k * beat + beat / 2) * SR)
            mus[s2:s2 + len(hat)] += hat
    # wrap the tail into the beginning so the loop is seamless
    tail = mus[n:]
    mus = mus[:n]
    mus[:len(tail)] += tail
    m = np.max(np.abs(mus))
    data = (mus / m * 0.6 * 32767).astype(np.int16)
    with wave.open(os.path.join(out, "muzika.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


if __name__ == "__main__":
    build(sys.argv[1])
