#!/usr/bin/env python3
"""Procedurally synthesize the SFX set for Vessel of Ash (48 kHz mono 16-bit WAV)."""
import os
import wave
import numpy as np

SR = 48000
OUT = "/data/my_game/assets/audio"
rng = np.random.default_rng(7)


def noise(n):
    return rng.uniform(-1.0, 1.0, n)


def sine(f, n):
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * f * t)


def sweep(f0, f1, n):
    t = np.arange(n) / SR
    k = (f1 - f0) / (n / SR)
    return np.sin(2 * np.pi * (f0 * t + 0.5 * k * t * t))


def env(n, a=0.01, d=0.3):
    t = np.arange(n) / SR
    return np.clip(t / a, 0, 1) * np.exp(-t / d)


def lp(x, cutoff):
    alpha = 1.0 - np.exp(-2.0 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def save(name, x, peak=0.85):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x))
    if m > 0:
        x = x / m * peak
    data = (x * 32767).astype(np.int16)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"{name:14s} {len(x)/SR:5.2f}s  {os.path.getsize(path)//1024:4d} KB")


def main():
    os.makedirs(OUT, exist_ok=True)
    n = int(0.16 * SR)
    save("swing_light", lp(noise(n), 3200) * env(n, 0.008, 0.05) + sweep(900, 300, n) * env(n, 0.005, 0.04) * 0.5)

    n = int(0.34 * SR)
    save("swing_heavy", lp(noise(n), 1400) * env(n, 0.02, 0.12) + sine(85, n) * env(n, 0.01, 0.1) * 0.6)

    n = int(0.10 * SR)
    save("hit_light", noise(n) * env(n, 0.002, 0.03) * 0.8 + sine(160, n) * env(n, 0.002, 0.05))

    n = int(0.30 * SR)
    save("hit_heavy", sine(70, n) * env(n, 0.004, 0.12) + lp(noise(n), 900) * env(n, 0.002, 0.08) * 0.7)

    n = int(0.5 * SR)
    met = (sine(1750, n) * 0.5 + sine(2350, n) * 0.35 + sine(3100, n) * 0.25) * env(n, 0.002, 0.16)
    save("parry", met + noise(n) * env(n, 0.001, 0.01) * 0.4)

    n = int(0.18 * SR)
    save("dodge", lp(noise(n), 5000) * env(n, 0.02, 0.06) * 0.7)

    n = int(0.45 * SR)
    save("telegraph", sweep(180, 430, n) * env(n, 0.05, 0.5) * 0.8 + lp(noise(n), 700) * env(n, 0.05, 0.4) * 0.3)

    n = int(1.2 * SR)
    chime = sine(523.25, n) * env(n, 0.004, 0.35) + sine(783.99, n) * env(n, 0.02, 0.3) * 0.7 + sine(1046.5, n) * env(n, 0.03, 0.2) * 0.4
    save("checkpoint", chime)

    n = int(0.22 * SR)
    vib = sine(110, n) * (1.0 + 0.2 * sine(7, n))
    save("hurt", vib * env(n, 0.01, 0.09) * 0.8 + lp(noise(n), 1200) * env(n, 0.005, 0.06) * 0.4)

    n = int(0.8 * SR)
    save("enemy_death", sweep(300, 70, n) * env(n, 0.02, 0.3) + lp(noise(n), 800) * env(n, 0.02, 0.25) * 0.4)

    n = int(1.4 * SR)
    growl = sine(55, n) * 0.7 + sine(82.5, n) * 0.5 + lp(noise(n), 400) * 0.5
    e = env(n, 0.15, 0.9)
    save("boss_roar", np.tanh(growl * e * 1.6))

    n = int(0.07 * SR)
    save("footstep", lp(noise(n), 2500) * env(n, 0.001, 0.02) * 0.7 + sine(95, n) * env(n, 0.001, 0.03))

    n = int(8.0 * SR)
    t = np.arange(n) / SR
    drone = sine(55, n) * 0.5 + sine(82.5, n) * 0.3 + sine(110, n) * 0.2
    swell = 0.6 + 0.4 * np.sin(2 * np.pi * 0.125 * t)
    amb = drone * swell + lp(noise(n), 300) * 0.25
    fade = int(0.4 * SR)
    amb[:fade] *= np.linspace(0, 1, fade)
    amb[-fade:] *= np.linspace(1, 0, fade)
    save("ambient", amb, peak=0.6)

    n = int(2.2 * SR)
    vic = np.zeros(n)
    for i, f in enumerate([392.0, 523.25, 659.25, 783.99]):
        off = int(i * 0.25 * SR)
        seg = sine(f, n - off) * env(n - off, 0.01, 0.9)
        vic[off:] += seg * 0.6
    save("victory", vic)

    # ---- ambient bed: cold wind through the Cinderhold + distant rumble -----
    n = int(12.0 * SR)
    t = np.arange(n) / SR
    wind = lp(noise(n), 420) * 0.5
    gust = 0.55 + 0.45 * np.sin(2 * np.pi * 0.083 * t) * np.sin(2 * np.pi * 0.031 * t)
    rumble = sine(38.0, n) * 0.22 + sine(57.0, n) * 0.12
    bed = wind * gust + rumble
    fade = int(1.2 * SR)
    bed[:fade] *= np.linspace(0, 1, fade)
    bed[-fade:] *= np.linspace(1, 0, fade)
    save("ambient_ash", bed, peak=0.5)

    # ---- music: crypt drone (slow, mournful) --------------------------------
    n = int(20.0 * SR)
    t = np.arange(n) / SR
    music = (sine(73.42, n) * 0.30 + sine(110.0, n) * 0.20 + sine(146.83, n) * 0.14
             + sine(196.0, n) * 0.07)
    music *= 0.6 + 0.4 * np.sin(2 * np.pi * 0.05 * t)
    music += lp(noise(n), 220) * 0.10
    # a struck bell every five seconds, drifting
    for k in range(4):
        off = int((0.5 + k * 5.0) * SR)
        if off + int(2.5 * SR) >= n:
            break
        seg = sine(146.83, int(2.5 * SR)) * env(int(2.5 * SR), 0.004, 1.1)
        seg += sine(293.66, int(2.5 * SR)) * env(int(2.5 * SR), 0.004, 0.5) * 0.4
        music[off:off + len(seg)] += seg * 0.22
    fade = int(1.5 * SR)
    music[:fade] *= np.linspace(0, 1, fade)
    music[-fade:] *= np.linspace(1, 0, fade)
    save("music_crypt", music, peak=0.45)

    # ---- music: the Choir (fast, percussive, choral-ish) --------------------
    n = int(16.0 * SR)
    t = np.arange(n) / SR
    beat = 0.375  # 160 bpm
    boss = np.zeros(n)
    # low drum on every beat, off-beat tick, rising drone
    for k in range(int(16.0 / beat)):
        off = int(k * beat * SR)
        d = int(0.16 * SR)
        if off + d < n:
            boss[off:off + d] += sine(58.0, d) * env(d, 0.002, 0.06) * 0.55
            boss[off:off + d] += lp(noise(d), 900) * env(d, 0.001, 0.03) * 0.18
        off2 = int((k * beat + beat * 0.5) * SR)
        d2 = int(0.05 * SR)
        if off2 + d2 < n:
            boss[off2:off2 + d2] += lp(noise(d2), 5200) * env(d2, 0.001, 0.012) * 0.10
    boss += sine(73.42, n) * (0.16 + 0.06 * np.sin(2 * np.pi * 0.11 * t))
    boss += sine(110.0, n) * 0.10
    boss += sine(220.0, n) * 0.05 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.05 * t))
    fade = int(1.0 * SR)
    boss[:fade] *= np.linspace(0, 1, fade)
    boss[-fade:] *= np.linspace(1, 0, fade)
    save("music_boss", boss, peak=0.55)


if __name__ == "__main__":
    main()
