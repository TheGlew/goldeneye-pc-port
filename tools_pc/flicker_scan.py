#!/usr/bin/env python3
"""flicker_scan.py - find A/B/A single-frame flicker in GE_PCDUMP captures.

  flicker_scan.py DIR [--scale 4] [--thresh T] [--csv out.csv]

Loads DIR/frame_NNNNNN.ppm in frame order (gaps skipped: only frames that
exist are compared), block-average downscales by --scale, and flags frame n
when diff(n, n-1) > T and diff(n, n-2) < T/4 -- i.e. n differs from its
predecessor but the frame before that looks like n again (or n-1 was the
odd one out). diff = mean abs channel difference (0-255). Default T = 12.
Pure stdlib; uses numpy if present. Always exits 0.
"""
import argparse, os, re, sys

try:
    import numpy as np
except ImportError:
    np = None


def read_ppm(path):
    with open(path, 'rb') as f:
        data = f.read()
    toks, pos = [], 0
    while len(toks) < 4:
        while data[pos:pos + 1].isspace():
            pos += 1
        if data[pos:pos + 1] == b'#':
            while data[pos:pos + 1] != b'\n':
                pos += 1
            continue
        s = pos
        while not data[pos:pos + 1].isspace():
            pos += 1
        toks.append(data[s:pos])
    pos += 1
    if toks[0] != b'P6' or int(toks[3]) != 255:
        raise ValueError('not an 8-bit P6 ppm')
    return int(toks[1]), int(toks[2]), data[pos:]


def downscale(w, h, px, k):
    """Block-average to (w//k, h//k); returns a flat sequence of ints."""
    ow, oh = w // k, h // k
    if np is not None:
        a = np.frombuffer(px, dtype=np.uint8, count=w * h * 3).reshape(h, w, 3)
        a = a[:oh * k, :ow * k].astype(np.float32)
        return a.reshape(oh, k, ow, k, 3).mean(axis=(1, 3)).ravel()
    out = []
    n = k * k
    for by in range(oh):
        rows = [by * k + dy for dy in range(k)]
        for bx in range(ow):
            for c in range(3):
                t = 0
                for r in rows:
                    base = (r * w + bx * k) * 3 + c
                    for dx in range(k):
                        t += px[base + dx * 3]
                out.append(t / n)
    return out


def diff(a, b):
    if np is not None:
        return float(np.abs(a - b).mean())
    return sum(abs(x - y) for x, y in zip(a, b)) / max(len(a), 1)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('dir')
    ap.add_argument('--scale', type=int, default=4)
    ap.add_argument('--thresh', type=float, default=12.0)
    ap.add_argument('--csv')
    a = ap.parse_args()
    files = []
    for n in os.listdir(a.dir):
        m = re.fullmatch(r'frame_(\d+)\.ppm', n)
        if m:
            files.append((int(m.group(1)), n))
    files.sort()
    t = a.thresh
    rows, flagged = [], []
    prev = []   # last two (frame, thumb)
    for fn, name in files:
        try:
            w, h, px = read_ppm(os.path.join(a.dir, name))
            th = downscale(w, h, px, max(a.scale, 1))
        except Exception as e:
            print('skip %s: %s' % (name, e), file=sys.stderr)
            continue
        d1 = diff(th, prev[-1][1]) if len(prev) >= 1 else None
        d2 = diff(th, prev[-2][1]) if len(prev) >= 2 else None
        flag = d1 is not None and d2 is not None and d1 > t and d2 < t / 4
        rows.append((fn, d1, d2, flag))
        if flag:
            flagged.append(fn)
            print('FLICKER frame %d (odd frame: %d): diff(n-1)=%.2f diff(n-2)=%.2f'
                  % (fn, prev[-1][0], d1, d2))
        prev = (prev + [(fn, th)])[-2:]
    if a.csv:
        with open(a.csv, 'w') as f:
            f.write('frame,diff_prev,diff_prev2,flag\n')
            for fn, d1, d2, fl in rows:
                f.write('%d,%s,%s,%d\n' % (fn, '' if d1 is None else '%.3f' % d1,
                                           '' if d2 is None else '%.3f' % d2, int(fl)))
    print('scanned %d frames, %d flagged (thresh %.1f, scale %d)' %
          (len(rows), len(flagged), t, a.scale))
    return 0


if __name__ == '__main__':
    sys.exit(main())
