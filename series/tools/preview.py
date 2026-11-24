#!/usr/bin/env python3
"""Draws previews of the six series faces without the Connect IQ SDK.

A small Python copy of each FaceView.mc layout (same design units, same angles) on a
fake Dc built on Pillow, with fixed sample data. Use it for store images and quick
layout checks; the simulator stays the real reference.

Usage:
  python3 series/tools/preview.py OUTDIR                 store set for every face
  python3 series/tools/preview.py OUTDIR --size 390      one 390px screenshot per face
"""
import argparse
import math
import os

from PIL import Image, ImageDraw, ImageFont

BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
for cand in ("/System/Library/Fonts/Supplemental/Arial Narrow Bold.ttf",):
    if os.path.exists(cand):
        BOLD = cand

PALETTE = [0xFFFFFF, 0x00E5A0, 0xFF3B5C, 0xFFB000, 0x2FA8FF, 0xFF4FA3, 0xB070FF, 0xFF7A1A, 0xFFE000, 0x808890]
SS = 3  # supersampling

# Sample data shown on every preview.
DATA = {
    "time": (10, 8, 36), "date": "TUE 24 NOV", "day": "TUE", "dayn": 24, "batt": 82,
    "sun": (8.2, 16.72), "now": 10.13,
}
FIELDS = {
    0: (-1.0, "", ""), 1: (0.82, "82%", "BATT"), 2: (0.16, "64", "BPM"), 3: (0.65, "6512", "STEPS"),
    4: (0.74, "1840", "KCAL"), 5: (0.8, "34", "ACTIVE"), 6: (0.72, "72", "ENERGY"), 7: (0.6, "6", "FLOORS"),
    8: (0.52, "5.2", "KM"), 9: (0.28, "28", "STRESS"), 10: (-1.0, "412", "ALT M"), 11: (-1.0, "7°", "TEMP"),
    12: (-1.0, "3", "ALERTS"), 13: (-1.0, "16:43", "SUNSET"),
}


def rgb(c):
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)


def dim(c, f):
    r, g, b = rgb(c)
    return (int(r * f) << 16) | (int(g * f) << 8) | int(b * f)


class Dc:
    """The parts of Toybox.Graphics.Dc the faces use, in device pixels."""

    def __init__(self, w, h, bg):
        self.w, self.h = w, h
        self.img = Image.new("RGB", (w * SS, h * SS), rgb(bg))
        self.d = ImageDraw.Draw(self.img)
        self.col = rgb(0xFFFFFF)
        self.pen = 1

    def setColor(self, c):
        self.col = rgb(c)

    def setPenWidth(self, p):
        self.pen = max(1, p)

    def fillRectangle(self, x, y, w, h):
        if w > 0 and h > 0:
            self.d.rectangle([x * SS, y * SS, (x + w) * SS - 1, (y + h) * SS - 1], fill=self.col)

    def fillRoundedRectangle(self, x, y, w, h, r):
        if w > 0 and h > 0:
            self.d.rounded_rectangle([x * SS, y * SS, (x + w) * SS, (y + h) * SS], radius=max(0, r * SS), fill=self.col)

    def drawRoundedRectangle(self, x, y, w, h, r):
        self.d.rounded_rectangle([x * SS, y * SS, (x + w) * SS, (y + h) * SS], radius=r * SS, outline=self.col, width=SS)

    def fillCircle(self, x, y, r):
        self.d.ellipse([(x - r) * SS, (y - r) * SS, (x + r) * SS, (y + r) * SS], fill=self.col)

    def drawCircle(self, x, y, r):
        R = r + self.pen / 2
        self.d.ellipse([(x - R) * SS, (y - R) * SS, (x + R) * SS, (y + R) * SS], outline=self.col, width=self.pen * SS)

    def drawArc(self, x, y, r, clockwise, a, b):
        """Garmin angles: degrees counter-clockwise from 3 o'clock."""
        R = r + self.pen / 2
        box = [(x - R) * SS, (y - R) * SS, (x + R) * SS, (y + R) * SS]
        start, end = (-a, -b) if clockwise else (-b, -a)
        self.d.arc(box, start % 360, end % 360, fill=self.col, width=self.pen * SS)

    def drawLine(self, x1, y1, x2, y2):
        self.d.line([x1 * SS, y1 * SS, x2 * SS, y2 * SS], fill=self.col, width=self.pen * SS)

    def fillPolygon(self, pts):
        self.d.polygon([(x * SS, y * SS) for x, y in pts], fill=self.col)

    def drawText(self, x, y, font, text, center_v=True):
        bold, size = font
        f = ImageFont.truetype(BOLD if bold else REG, max(6, int(size * SS * (0.84 if bold else 0.9))))
        self.d.text((x * SS, y * SS), text, font=f, fill=self.col, anchor="mm" if center_v else "mt")

    def image(self, round_):
        out = self.img.resize((self.w, self.h), Image.LANCZOS)
        if round_:
            mask = Image.new("L", (self.w * SS, self.h * SS), 0)
            ImageDraw.Draw(mask).ellipse([0, 0, self.w * SS - 1, self.h * SS - 1], fill=255)
            bg = Image.new("RGB", out.size, (0, 0, 0))
            out = Image.composite(out, bg, mask.resize(out.size, Image.LANCZOS))
        return out


class Screen:
    def __init__(self, w, h):
        self.w, self.h, self.cx, self.cy = w, h, w // 2, h // 2
        m = min(w, h)
        self.r, self.s = m // 2, m / 454.0
        self.round = w == h

    def n(self, v):
        return int(v * self.s)

    def half_width(self, dy):
        if not self.round:
            return self.cx
        d = dy * self.s
        return 0 if d * d >= self.r * self.r else int(math.sqrt(self.r * self.r - d * d))

    def font(self, bold, size):
        return (bold, size * self.s)


def px(cx, deg, r):
    return cx + math.cos(math.radians(deg)) * r


def py(cy, deg, r):
    return cy - math.sin(math.radians(deg)) * r


def arc_cw(dc, cx, cy, r, start, sweep):
    if sweep <= 0:
        return
    if sweep >= 360:
        dc.drawCircle(cx, cy, r)
        return
    dc.drawArc(cx, cy, r, True, start % 360, (start - sweep) % 360)


def hm(cfg):
    h, m, s = DATA["time"]
    return "%d:%02d" % (h, m)


# ---- Bitlevel --------------------------------------------------------------------

PIX_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ:%-/. "
PIX_BITS = [31599, 11415, 29671, 29647, 23497, 31183, 31215, 29266, 31727, 31695, 11245, 27566, 14627, 27502, 31143,
            31140, 14699, 23533, 29847, 4714, 23469, 18727, 24557, 27501, 11114, 27556, 11123, 27565, 14478, 29842,
            23407, 23402, 23549, 23213, 23186, 29351, 1040, 21157, 448, 4772, 2, 0]
HEART = [54, 127, 127, 62, 28, 8]


def pixel_text(dc, x, y, text, p):
    w = len(text) * 4 * p - p
    cx = x - w // 2
    for ch in text.upper():
        i = PIX_CHARS.find(ch)
        if i >= 0:
            bits = PIX_BITS[i]
            for row in range(5):
                for col in range(3):
                    if (bits >> (14 - row * 3 - col)) & 1:
                        dc.fillRectangle(cx + col * p, y + row * p, p, p)
        cx += 4 * p


def bitlevel(dc, sc, cfg):
    cx, cy = sc.cx, sc.cy
    accent, heart_col = PALETTE[cfg.get("AccentColor", 1)], PALETTE[cfg.get("HeartColor", 2)]
    x0, y0 = cx - sc.n(227), cy - sc.n(227)
    stars = [70, 150, 120, 95, 330, 90, 390, 160, 250, 40, 175, 60, 300, 135, 95, 230, 365, 240]
    star = max(2, sc.n(4))
    dc.setColor(0x6A7090)
    for i in range(0, len(stars), 2):
        dc.fillRectangle(x0 + sc.n(stars[i]), y0 + sc.n(stars[i + 1]), star, star)
    hp = max(2, sc.n(4))
    full = (DATA["batt"] + 10) // 20
    step = hp * 9
    hx, hy = cx - (5 * step - 2 * hp) // 2, y0 + sc.n(58)
    for i in range(5):
        dc.setColor(heart_col if i < full else 0x3A3A48)
        for row in range(6):
            for col in range(7):
                if (HEART[row] >> (6 - col)) & 1:
                    dc.fillRectangle(hx + i * step + col * hp, hy + row * hp, hp, hp)
    tp = max(2, sc.n(4))
    dc.setColor(0xC8CCE0)
    pixel_text(dc, cx, cy - sc.n(100), DATA["date"], tp)
    dc.setColor(0xFFFFFF)
    pixel_text(dc, cx, cy - sc.n(62), hm(cfg), max(4, sc.n(16)))
    f = FIELDS[cfg.get("XpField", 3)]
    sp = max(2, sc.n(3))
    dc.setColor(accent)
    pixel_text(dc, cx, cy + sc.n(34), "XP " + f[1], sp)
    bw, bh = sc.n(240), sc.n(22)
    bx, by = cx - bw // 2, cy + sc.n(58)
    dc.setColor(0xC8CCE0)
    dc.fillRectangle(bx, by, bw, bh)
    dc.setColor(0)
    dc.fillRectangle(bx + sp, by + sp, bw - 2 * sp, bh - 2 * sp)
    inner = bw - 4 * sp
    blocks = int(max(0.0, f[0]) * (inner // (2 * sp)))
    dc.setColor(accent)
    for i in range(blocks):
        dc.fillRectangle(bx + 2 * sp + i * 2 * sp, by + 2 * sp, sp + sp // 2, bh - 4 * sp)
    f1, f2 = FIELDS[cfg.get("Field1", 2)], FIELDS[cfg.get("Field2", 6)]
    dc.setColor(0xC8CCE0)
    pixel_text(dc, cx - sc.n(82), cy + sc.n(104), f1[1] + " " + f1[2], sp)
    pixel_text(dc, cx + sc.n(82), cy + sc.n(104), f2[1] + " " + f2[2], sp)
    top, grass, brick = cy + sc.n(150), sc.n(12), max(6, sc.n(24))
    dc.setColor(0x7A4A21)
    dc.fillRectangle(0, top + grass, sc.w, sc.h - top - grass)
    dc.setColor(0x4E2E12)
    row, y = 0, top + grass
    while y < sc.h:
        dc.fillRectangle(0, y, sc.w, 2)
        for x in range(0 if row % 2 == 0 else brick, sc.w, brick * 2):
            dc.fillRectangle(x, y, 2, brick)
        row, y = row + 1, y + brick
    dc.setColor(0x3CB043)
    dc.fillRectangle(0, top, sc.w, grass)
    dc.setColor(0x2A8A30)
    for x in range(0, sc.w, grass * 2):
        dc.fillRectangle(x, top + grass - grass // 3, grass, grass // 3)


# ---- Ridgeline -------------------------------------------------------------------

BACK = [-240, 105, -185, 65, -140, 87, -95, 30, -55, 65, -10, 17, 40, 75, 85, 40, 135, 80, 180, 50, 240, 95]
FRONT = [-240, 145, -190, 120, -135, 137, -70, 105, -20, 127, 35, 101, 95, 131, 150, 111, 240, 143]


def ridgeline(dc, sc, cfg):
    cx, cy = sc.cx, sc.cy
    accent = PALETTE[cfg.get("AccentColor", 3)]
    bg = 0x0A1028 if cfg.get("Sky", 0) == 1 else 0
    dc.setColor(0x9AA0AA)
    dc.drawText(cx, cy - sc.n(196), sc.font(True, 22), "%d%%" % DATA["batt"])
    dc.setColor(accent)
    dc.drawText(cx, cy - sc.n(160), sc.font(True, 28), DATA["date"])
    dc.setColor(0xFFFFFF)
    dc.drawText(cx, cy - sc.n(92), sc.font(True, 118), hm(cfg))
    rise, set_ = DATA["sun"]
    now = DATA["now"]
    frac = (now - rise) / (set_ - rise)
    dc.setColor(0x3A4050)
    for i in range(21):
        f = i / 20.0
        dc.fillCircle(cx + sc.n(-190 + 380 * f), cy + sc.n(55 - math.sin(math.pi * f) * 70), max(1, sc.n(2)))
    x, y, r = cx + sc.n(-190 + 380 * frac), cy + sc.n(55 - math.sin(math.pi * frac) * 70), sc.n(16)
    dc.setColor(dim(0xFFB000, 0.3))
    dc.fillCircle(x, y, r + sc.n(8))
    dc.setColor(0xFFC830)
    dc.fillCircle(x, y, r)

    def poly(pts):
        out = [(cx + sc.n(pts[i]), cy + sc.n(pts[i + 1])) for i in range(0, len(pts), 2)]
        return out + [(cx + sc.n(240), sc.h), (cx - sc.n(240), sc.h)]

    def outline(pts):
        for i in range(0, len(pts) - 3, 2):
            dc.drawLine(cx + sc.n(pts[i]), cy + sc.n(pts[i + 1]), cx + sc.n(pts[i + 2]), cy + sc.n(pts[i + 3]))

    dc.setColor(dim(accent, 0.22))
    dc.fillPolygon(poly(BACK))
    dc.setColor(dim(accent, 0.7))
    dc.setPenWidth(max(1, sc.n(3)))
    outline(BACK)
    dc.setColor(0x10141A)
    dc.fillPolygon(poly(FRONT))
    dc.setColor(accent)
    outline(FRONT)
    dc.setPenWidth(1)
    for i, (k, d) in enumerate([("Field1", 10), ("Field2", 13), ("Field3", 11)]):
        m = FIELDS[cfg.get(k, d)]
        x = cx + sc.n((i - 1) * 100)
        dc.setColor(0xFFFFFF)
        dc.drawText(x, cy + sc.n(158), sc.font(True, 32), m[1])
        dc.setColor(0x9AA0AA)
        dc.drawText(x, cy + sc.n(186), sc.font(False, 17), m[2])
    return bg


# ---- Meridian Chrono ----------------------------------------------------------

def hand(dc, sc, deg, length, tail, width):
    a = math.radians(deg)
    dx, dy = math.sin(a), -math.cos(a)
    L, B, W = sc.n(length), sc.n(tail), max(1.0, sc.n(width) / 2.0)
    cx, cy = sc.cx, sc.cy
    dc.fillPolygon([
        (cx - dx * B - dy * W, cy - dy * B + dx * W),
        (cx + dx * L * 0.88 - dy * W * 0.6, cy + dy * L * 0.88 + dx * W * 0.6),
        (cx + dx * L, cy + dy * L),
        (cx + dx * L * 0.88 + dy * W * 0.6, cy + dy * L * 0.88 - dx * W * 0.6),
        (cx - dx * B + dy * W, cy - dy * B - dx * W)])


def meridian(dc, sc, cfg):
    cx, cy = sc.cx, sc.cy
    accent = PALETTE[cfg.get("AccentColor", 7)]
    bg = [0x000000, 0x0B1A2E, 0x1A1410, 0x0E1116][cfg.get("DialColor", 0)]
    for i in range(60):
        deg = 90 - i * 6
        major = i % 5 == 0
        if major and i == 0:
            continue
        dc.setColor(0xD0D4DA if major else 0x6A707A)
        dc.setPenWidth(max(2, sc.n(7)) if major else max(1, sc.n(2)))
        inner = 192 if major else 212
        dc.drawLine(px(cx, deg, sc.n(inner)), py(cy, deg, sc.n(inner)), px(cx, deg, sc.n(222)), py(cy, deg, sc.n(222)))
    dc.setPenWidth(1)
    dc.setColor(0xFFFFFF)
    dc.drawText(cx, cy - sc.n(168), sc.font(True, 40), "12")
    bw, bh = sc.n(96), sc.n(30)
    dc.setColor(0x2A2E36)
    dc.fillRoundedRectangle(cx - bw // 2, cy - sc.n(120) - bh // 2, bw, bh, sc.n(6))
    dc.setColor(0xFFFFFF)
    dc.drawText(cx, cy - sc.n(120), sc.font(True, 22), "%s %d" % (DATA["day"], DATA["dayn"]))
    for (k, d), (ox, oy) in zip([("Field1", 1), ("Field2", 3), ("Field3", 2)], [(-112, 8), (112, 8), (0, 118)]):
        m = FIELDS[cfg.get(k, d)]
        x, y, r = cx + sc.n(ox), cy + sc.n(oy), sc.n(50)
        dc.setPenWidth(max(2, sc.n(6)))
        dc.setColor(0x2A2E36)
        dc.drawCircle(x, y, r)
        if m[0] > 0:
            dc.setColor(accent)
            arc_cw(dc, x, y, r, 90, int(m[0] * 360))
        dc.setPenWidth(1)
        dc.setColor(0xFFFFFF)
        dc.drawText(x, y - sc.n(6), sc.font(True, 26), m[1])
        dc.setColor(0x9AA0AA)
        dc.drawText(x, y + sc.n(20), sc.font(False, 14), m[2])
    h, mi, s = DATA["time"]
    hd, md = ((h % 12) + mi / 60.0) * 30.0, (mi + s / 60.0) * 6.0
    dc.setColor(0xFFFFFF)
    hand(dc, sc, hd, 128, 22, 16)
    hand(dc, sc, md, 196, 26, 12)
    dc.setColor(accent)
    hand(dc, sc, hd, 100, -30, 4)
    a = math.radians(s * 6.0)
    dx, dy = math.sin(a), -math.cos(a)
    dc.setPenWidth(max(1, sc.n(3)))
    dc.drawLine(cx - dx * sc.n(40), cy - dy * sc.n(40), cx + dx * sc.n(206), cy + dy * sc.n(206))
    dc.setPenWidth(1)
    dc.fillCircle(cx - dx * sc.n(40), cy - dy * sc.n(40), sc.n(7))
    dc.setColor(0xFFFFFF)
    dc.fillCircle(cx, cy, sc.n(11))
    dc.setColor(accent)
    dc.fillCircle(cx, cy, sc.n(5))
    return bg


# ---- Stacked Hours ---------------------------------------------------------------

def stacked(dc, sc, cfg):
    cx, cy = sc.cx, sc.cy
    accent, min_col = PALETTE[cfg.get("AccentColor", 4)], PALETTE[cfg.get("MinuteColor", 0)]
    h, m, s = DATA["time"]
    dx = cx - sc.n(40)
    dc.setColor(accent)
    dc.drawText(dx, cy - sc.n(80), sc.font(True, 176), "%02d" % h)
    dc.setColor(min_col)
    dc.drawText(dx, cy + sc.n(80), sc.font(True, 176), "%02d" % m)
    col = cx + sc.n(124)
    dc.setColor(accent)
    dc.drawText(col, cy - sc.n(96), sc.font(True, 24), DATA["day"])
    dc.setColor(0xFFFFFF)
    dc.drawText(col, cy - sc.n(58), sc.font(True, 48), str(DATA["dayn"]))
    dc.setColor(0x3A3E46)
    dc.fillRectangle(col - sc.n(28), cy - sc.n(24), sc.n(56), max(1, sc.n(3)))
    f1, f2 = FIELDS[cfg.get("Field1", 3)], FIELDS[cfg.get("Field2", 2)]
    dc.setColor(0xFFFFFF)
    dc.drawText(col, cy + sc.n(10), sc.font(True, 30), f1[1])
    dc.drawText(col, cy + sc.n(80), sc.font(True, 30), f2[1])
    dc.setColor(0x8A909A)
    dc.drawText(col, cy + sc.n(36), sc.font(False, 15), f1[2])
    dc.drawText(col, cy + sc.n(106), sc.font(False, 15), f2[2])
    r = sc.r - sc.n(12)
    dc.setPenWidth(max(2, sc.n(6)))
    dc.setColor(0x24282E)
    dc.drawArc(cx, cy, r, True, 135, 45)
    dc.drawArc(cx, cy, r, False, 225, 315)
    dc.setColor(accent)
    arc_cw(dc, cx, cy, r, 135, int(FIELDS[3][0] * 90))
    dc.setColor(min_col)
    dc.drawArc(cx, cy, r, False, 225, 225 + DATA["batt"] * 90 // 100)
    dc.setPenWidth(1)


# ---- Gridwork --------------------------------------------------------------------

def gridwork(dc, sc, cfg):
    cx, cy = sc.cx, sc.cy
    accent = PALETTE[cfg.get("AccentColor", 1)]
    dc.setColor(0x9AA0AA)
    dc.drawText(cx, cy - sc.n(168), sc.font(True, 26), DATA["date"])
    dc.setColor(0xFFFFFF)
    dc.drawText(cx, cy - sc.n(104), sc.font(True, 112), hm(cfg))
    bw, bh, by = sc.n(150), max(2, sc.n(6)), cy - sc.n(42)
    dc.setColor(0x24282E)
    dc.fillRoundedRectangle(cx - bw // 2, by, bw, bh, bh // 2)
    dc.setColor(accent)
    dc.fillRoundedRectangle(cx - bw // 2, by, bw * DATA["batt"] // 100, bh, bh // 2)
    gap, tile_h = sc.n(8), sc.n(74)
    top1 = cy - sc.n(22)
    top2 = top1 + tile_h + gap
    half = min(sc.half_width((top2 + tile_h - cy) / sc.s) - sc.n(14), sc.n(200))
    tile_w = (2 * half - 2 * gap) // 3
    defs = [3, 2, 6, 4, 11, 13]
    for i in range(6):
        m = FIELDS[cfg.get("Field%d" % (i + 1), defs[i])]
        x, y = cx - half + (i % 3) * (tile_w + gap), top1 if i < 3 else top2
        rad = sc.n(10)
        dc.setColor(0x161A20)
        dc.fillRoundedRectangle(x, y, tile_w, tile_h, rad)
        strip = max(2, sc.n(5))
        dc.setColor(dim(accent, 0.3))
        dc.fillRectangle(x + rad, y + sc.n(6), tile_w - 2 * rad, strip)
        dc.setColor(accent)
        fw = tile_w - 2 * rad if m[0] < 0 else int((tile_w - 2 * rad) * m[0])
        dc.fillRectangle(x + rad, y + sc.n(6), fw, strip)
        dc.setColor(0xFFFFFF)
        dc.drawText(x + tile_w // 2, y + tile_h // 2 + sc.n(2), sc.font(True, 30), m[1])
        dc.setColor(0x8A909A)
        dc.drawText(x + tile_w // 2, y + tile_h - sc.n(13), sc.font(False, 15), m[2])


# ---- Sunpath 24 ------------------------------------------------------------------

def sunpath(dc, sc, cfg):
    cx, cy = sc.cx, sc.cy
    day_col = PALETTE[cfg.get("AccentColor", 3)]
    rise, set_ = DATA["sun"]
    now = DATA["now"]
    ang = lambda hrs: 270.0 - hrs * 15.0
    r = sc.n(204)
    dc.setPenWidth(max(4, sc.n(16)))
    dc.setColor(0x16244A)
    dc.drawCircle(cx, cy, r)
    dc.setColor(day_col)
    arc_cw(dc, cx, cy, r, ang(rise), int((set_ - rise) * 15))
    dc.setPenWidth(1)
    for h in range(24):
        a = ang(h)
        major = h % 6 == 0
        dc.setColor(0xFFFFFF if major else 0x5A6070)
        dc.fillCircle(px(cx, a, sc.n(224)), py(cy, a, sc.n(224)), sc.n(3) + 1 if major else sc.n(2) + 1)
        if major:
            dc.setColor(0xB0B6C2)
            dc.drawText(px(cx, a, sc.n(174)), py(cy, a, sc.n(174)), sc.font(True, 22), str(h))
    a = ang(now)
    mx, my, mr = px(cx, a, r), py(cy, a, r), sc.n(15)
    dc.setColor(0)
    dc.fillCircle(mx, my, mr + sc.n(5))
    dc.setColor(dim(0xFFC830, 0.35))
    dc.fillCircle(mx, my, mr + sc.n(4))
    dc.setColor(0xFFD84A)
    dc.fillCircle(mx, my, mr)
    dc.setColor(0x9AA0AA)
    dc.drawText(cx, cy - sc.n(78), sc.font(True, 24), DATA["date"])
    dc.setColor(0xFFFFFF)
    dc.drawText(cx, cy - sc.n(18), sc.font(True, 100), hm(cfg))
    fmt = lambda hf: "%d:%02d" % (int(hf * 60) // 60, int(hf * 60) % 60)
    dc.drawText(cx - sc.n(62), cy + sc.n(52), sc.font(True, 26), fmt(rise))
    dc.drawText(cx + sc.n(62), cy + sc.n(52), sc.font(True, 26), fmt(set_))
    dc.setColor(day_col)
    dc.drawText(cx - sc.n(62), cy + sc.n(76), sc.font(False, 15), "SUNRISE")
    dc.drawText(cx + sc.n(62), cy + sc.n(76), sc.font(False, 15), "SUNSET")
    mins = int((set_ - now) * 60)
    dc.setColor(0x8A909A)
    dc.drawText(cx, cy + sc.n(106), sc.font(False, 15), "DAYLIGHT %d:%02d" % (mins // 60, mins % 60))
    f = FIELDS[cfg.get("Field1", 1)]
    dc.setColor(0xFFFFFF)
    dc.drawText(cx, cy + sc.n(138), sc.font(True, 26), f[1] + " " + f[2])


FACES = {
    "bitlevel": ("Bitlevel", bitlevel, [{}, {"AccentColor": 8, "HeartColor": 5}, {"AccentColor": 4, "XpField": 6}]),
    "ridgeline": ("Ridgeline", ridgeline, [{}, {"AccentColor": 1, "Sky": 1}, {"AccentColor": 4, "Sky": 1}]),
    "meridian": ("Meridian Chrono", meridian, [{}, {"AccentColor": 2, "DialColor": 1}, {"AccentColor": 3, "DialColor": 2}]),
    "stacked": ("Stacked Hours", stacked, [{}, {"AccentColor": 7}, {"AccentColor": 5, "MinuteColor": 9}]),
    "gridwork": ("Gridwork", gridwork, [{}, {"AccentColor": 4}, {"AccentColor": 3}]),
    "sunpath": ("Sunpath 24", sunpath, [{}, {"AccentColor": 7}, {"AccentColor": 5}]),
}


def render(face_id, cfg, w=454, h=454):
    _, fn, _ = FACES[face_id]
    sc = Screen(w, h)
    # The background depends on settings for some faces; draw once to learn it.
    probe = Dc(w, h, 0)
    bg = fn(probe, sc, cfg) or 0
    dc = Dc(w, h, bg)
    fn(dc, sc, cfg)
    return dc.image(sc.round)


def hero(face_id, shots, accent):
    name = FACES[face_id][0]
    img = Image.new("RGB", (1440, 720), (0, 0, 0))
    img.paste(shots[0].resize((660, 660), Image.LANCZOS), (30, 30))
    for i, s in enumerate(shots[1:3]):
        img.paste(s.resize((260, 260), Image.LANCZOS), (1150, 70 + i * 300))
    d = ImageDraw.Draw(img)
    words = name.upper().split()
    room = 410  # text column between the big face and the two thumbnails

    def fit(text, size):
        while size > 12 and d.textlength(text, font=ImageFont.truetype(BOLD, size)) > room:
            size -= 2
        return size

    size = min(fit(w, 110) for w in words)
    f = ImageFont.truetype(BOLD, size)
    y = 360 - len(words) * size // 2 - 40
    for i, word in enumerate(words):
        d.text((720, y + i * (size + 8)), word, font=f, fill=rgb(accent if i == 0 else 0xFFFFFF))
    lines = ["Fenix 8 & Venu watch face", "Customizable in Garmin Connect"]
    small = ImageFont.truetype(BOLD, min(fit(l, 28) for l in lines))
    y2 = y + len(words) * (size + 8) + 30
    for i, line in enumerate(lines):
        d.text((722, y2 + i * 42), line, font=small, fill=(138, 144, 154))
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("outdir")
    ap.add_argument("--size", type=int, default=0, help="only one screenshot per face at this size")
    args = ap.parse_args()
    for fid, (name, _, variants) in FACES.items():
        out = os.path.join(args.outdir, fid)
        os.makedirs(out, exist_ok=True)
        if args.size:
            render(fid, {}, args.size, args.size).save(os.path.join(out, "preview-%d.png" % args.size))
            continue
        shots = [render(fid, v) for v in variants]
        for i, (s, label) in enumerate(zip(shots, ["default", "variant-a", "variant-b"])):
            s.save(os.path.join(out, "screenshot-%d-%s.png" % (i + 1, label)))
        accent = PALETTE[variants[0].get("AccentColor", 3)] if variants[0] else 0x00E5A0
        accent = {"bitlevel": 0x00E5A0, "ridgeline": 0xFFB000, "meridian": 0xFF7A1A, "stacked": 0x2FA8FF,
                  "gridwork": 0x00E5A0, "sunpath": 0xFFB000}[fid]
        hero(fid, shots, accent).save(os.path.join(out, "hero-1440x720.png"))
        icon = Image.new("RGB", (512, 512), (0, 0, 0))
        icon.paste(shots[0].resize((512, 512), Image.LANCZOS), (0, 0))
        icon.save(os.path.join(out, "icon-512.png"))
        icon.resize((256, 256), Image.LANCZOS).save(os.path.join(out, "icon-256.png"))
        print("wrote", out)


if __name__ == "__main__":
    main()
