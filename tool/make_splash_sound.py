"""Synthesises the splash screen's music (assets/audio/splash.wav).

A short, calm, original "sound logo" timed to the splash. A plucked-string
melody (Karplus-Strong physical model — somewhere between a harp and the
Armenian kanon) climbs gently with the dove's flight and resolves on a soft
chord as it lands; a warm, quiet string pad breathes underneath; a final
echo of the motif follows the light across the logo; and a convolution
reverb puts it all in a wide, still hall. Pure synthesis (numpy), so the
piece is our own and has no licensing questions.

Times are measured from take-off, which is when the app starts playback.
    python tool/make_splash_sound.py assets/audio/splash.wav
"""
import sys
import wave

import numpy as np

SR = 44100
LENGTH = 6.6          # take-off -> splash hand-off, plus a little tail
LANDING = 4.0         # flight duration in splash_screen.dart

rng = np.random.default_rng(11)
n_total = int(SR * LENGTH)
t = np.arange(n_total) / SR


def note(name):
    """Frequency of a note like 'D4' or 'F#5' (A4 = 440 Hz)."""
    names = {'C': -9, 'C#': -8, 'D': -7, 'D#': -6, 'E': -5, 'F': -4,
             'F#': -3, 'G': -2, 'G#': -1, 'A': 0, 'A#': 1, 'B': 2}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + 12 * (octave - 4)) / 12)


def pluck(freq, seconds, brightness=0.5, decay=0.996):
    """Karplus-Strong plucked string, computed a period at a time.

    The delay line starts as soft (low-passed) noise; each pass around it
    averages neighbouring samples, so the tone darkens and dies away the
    way a real string does.
    """
    period = int(round(SR / freq))
    n = int(SR * seconds)
    excite = rng.uniform(-1, 1, period)
    # Softer pick: smooth the excitation, more for a darker tone.
    for _ in range(int(1 + (1 - brightness) * 6)):
        excite = 0.5 * (excite + np.roll(excite, 1))
    out = np.zeros(n + period)
    out[:period] = excite
    for start in range(period, n + period, period):
        prev = out[start - period:start]
        avg = 0.5 * (prev + np.concatenate(([out[start - period - 1]
                                             if start > period else 0.0],
                                            prev[:-1])))
        seg = decay * avg
        out[start:start + period] = seg[:len(out[start:start + period])]
    out = out[:n]
    # Gentle fade at the very end so nothing clicks off.
    out[-int(0.05 * SR):] *= np.linspace(1, 0, int(0.05 * SR))
    return out / (np.abs(out).max() + 1e-9)


def place(signal, start, gain):
    i = int(start * SR)
    end = min(n_total, i + len(signal))
    track[i:end] += gain * signal[:end - i]


def pad_voice(freq):
    """Warm string-like voice: a band-limited saw with steeply falling
    upper harmonics (a gentle low-pass), plus a slow detuned twin."""
    v = np.zeros(n_total)
    for k in range(1, 9):
        amp = 1 / k ** 1.8
        v += amp * np.sin(2 * np.pi * k * freq * t + k * 0.7)
        v += amp * np.sin(2 * np.pi * k * freq * 1.0025 * t + k * 1.9)
    return v / 3.0


def swell(attack, hold_until, release):
    rise = np.clip(t / attack, 0, 1)
    fall = np.clip(1 - (t - hold_until) / release, 0, 1)
    return np.sin(rise * np.pi / 2) ** 2 * np.sin(fall * np.pi / 2) ** 2


track = np.zeros(n_total)

# Melody — D major pentatonic, rising with the flight, unhurried (one note
# roughly every 0.55-0.7 s), each a little brighter as the dove climbs.
melody = [
    (0.20, 'D4', 0.50), (0.85, 'A4', 0.55), (1.45, 'D5', 0.60),
    (2.05, 'E5', 0.60), (2.60, 'F#5', 0.65), (3.15, 'E5', 0.55),
    (3.55, 'A4', 0.50),
]
for start, name, gain in melody:
    place(pluck(note(name), 3.0, brightness=0.45), start, gain)

# Landing: a soft rolled chord (low to high), the resolution of the motif.
for k, name in enumerate(['D3', 'A3', 'F#4', 'A4', 'D5']):
    place(pluck(note(name), 3.0, brightness=0.35, decay=0.997),
          LANDING + 0.07 * k, 0.55 - 0.05 * k)

# Echo of the motif's peak while the light crosses the logo, quieter.
for start, name, gain in [(LANDING + 0.75, 'F#5', 0.28),
                          (LANDING + 1.25, 'E5', 0.22),
                          (LANDING + 1.75, 'D5', 0.20)]:
    place(pluck(note(name), 2.0, brightness=0.4), start, gain)

# Pad — D, A, D, F# low and open; it swells under the flight and blooms a
# little at the landing.
pad = sum(w * pad_voice(note(n)) for n, w in
          [('D2', 0.6), ('A2', 0.5), ('D3', 0.4), ('F#3', 0.25)])
bloom = 1 + 0.5 * np.exp(-((t - LANDING - 0.3) / 0.9) ** 2)
pad *= swell(2.5, LENGTH - 2.3, 2.3) * bloom
track += 0.10 * pad / np.abs(pad).max()


def hall_reverb(x, seconds=2.6, decay=0.7):
    """Convolution with a synthetic hall: exponentially decaying noise whose
    highs die faster than its lows, as in a real room."""
    n = int(SR * seconds)
    tt = np.arange(n) / SR
    noise = rng.standard_normal(n)
    # Two bands with different decay rates: bright early, dark tail.
    smooth = noise.copy()
    for _ in range(12):
        smooth = 0.5 * (smooth + np.roll(smooth, 1))
    bright = noise - smooth
    ir = smooth * np.exp(-tt / decay) + 0.35 * bright * np.exp(-tt / (decay * 0.3))
    ir[: int(0.012 * SR)] = 0          # small pre-delay
    ir /= np.sqrt(np.sum(ir ** 2))
    size = 1 << int(np.ceil(np.log2(len(x) + n)))
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)
    return wet[: len(x)]


wet = hall_reverb(track)
track = 0.7 * track + 0.55 * wet / (np.abs(wet).max() + 1e-9) * np.abs(track).max()

# Everything settles to silence by the end.
track *= np.clip((LENGTH - t) / 1.0, 0, 1) ** 1.5
track[: int(0.01 * SR)] *= np.linspace(0, 1, int(0.01 * SR))

# Levelled by average loudness (RMS), which is what the ear follows, to sit
# in the background; peaks stay well clear of clipping.
track *= 0.04 / np.sqrt(np.mean(track ** 2))
track *= min(1.0, 0.5 / np.abs(track).max())

pcm = (track * 32767).astype(np.int16)
with wave.open(sys.argv[1], 'wb') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
