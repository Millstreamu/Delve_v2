# Delve — Combat UI Art Asset Spec

Everything the combat screen renders, and what art it still needs. All UI art is
loaded from `res://assets/...` and swapped by **overwriting the file at the same
path** — no code changes needed as long as you keep the filename and rough aspect
ratio.

Legend: ✅ real art in place · 🟡 placeholder I generated (replace when ready)

---

## 1. Cards

| Asset | Path | Size / ratio | Format | Status | Description |
|---|---|---|---|---|---|
| Card frame | `assets/card_frame.png` | 1024×1536 (portrait, 2:3) | opaque | ✅ | Metal card frame: art window (top), name bar (middle), text panel (lower), two corner slots (bottom). Regions are measured off this file — if you redraw it, keep the panel positions or tell me and I'll re-measure. |
| Ability art ×10 | `assets/art/<name>.png` | **820×520** (≈1.59:1) | transparent or opaque | 🟡 | One illustration per ability, sits in the card's art window. Files: `slash, heavy_slash, ignite, fireball, guard, riposte, spark, growth, thorns, starfall`. |
| Card back / empty slot | `assets/card_back.png` *(not yet used)* | 1024×1536 | opaque | ➖ | Optional: face-down card + empty draw/discard slot art. |

## 2. Stat bars

| Asset | Path | Size | Format | Status | Description |
|---|---|---|---|---|---|
| Health frame | `assets/hp_frame.png` | ~1400×160 (long bar + heart socket left) | transparent bg preferred | ✅ | Empty health bar: heart icon in a socket, long empty channel. |
| Health fill | `assets/hp_fill.png` | ~1240×92 (rounded bar) | transparent | ✅ | Red fill drawn inside the health channel, revealed left→right by %. |
| Timer frame | `assets/timer_frame.png` | ~1410×184 (8 segments + hourglass socket) | transparent bg preferred | ✅ | Empty turn-gauge bar, hourglass icon + 8 cells. |
| Timer fill (blue) | `assets/timer_fill_blue.png` | ~1176×232 | transparent | 🟡 | Blue fill for the timer (recolored from your orange `timer_fill.png` to match the reference). Replace with hand-drawn blue if you want. |
| Timer fill (orange) | `assets/timer_fill.png` | ~1176×232 | transparent | ✅ | Your original orange fill (currently unused — swap the `TIMER_FILL` constant back to it to use orange). |

> **Note on bg:** the frame/fill sprites currently have a black background with a
> glow. On the dark scene they blend, but for a crisp result please export these
> with a **transparent** background.

## 3. Icons

| Asset | Path | Size | Format | Status | Description |
|---|---|---|---|---|---|
| Element tiles ×5 | `assets/icons/{blade,fire,guard,arcane,nature}.png` | 112×112 (rounded tile) | transparent | 🟡 | Top-left element key. Coloured tile + element glyph (sword / flame / shield / star / leaf). |
| Status icons ×4 | `assets/icons/{st_shield,st_heart,st_plus,st_wing}.png` | 64×64 | transparent | 🟡 | Top-right stat counters. Currently mapped shield→Defence, heart→Attack, plus→Power, wing→Speed (tell me the real meanings and I'll relabel). |
| Settings gear | `assets/icons/gear.png` | 64×64 | transparent | 🟡 | Top-right settings button. |
| Player portrait | `assets/icons/portrait.png` | 160×190 (bust) | transparent | 🟡 | Bottom-left hero portrait; a level badge overlaps its corner. |
| Equipment item icons ×N | `assets/icons/item_<slot>.png` *(not yet used)* | 64×64 | transparent | ➖ | Optional small icon per equipped item, to sit inside each equipment slot instead of text. |

## 4. Characters & scene

| Asset | Path | Size | Format | Status | Description |
|---|---|---|---|---|---|
| Enemy sprite | `assets/enemy_corrupted_vine.png` | ~420×300 | **transparent** | 🟡 | Centre-stage creature. I cropped this from your UI-kit sheet and feathered the edges — replace with a clean cut-out on transparency. One file per enemy type (e.g. `enemy_<name>.png`). |
| Combat background | `assets/bg_combat.png` | 1280×720 (16:9) | opaque | 🟡 | Dungeon arena. I generated a vignette + magic-circle floor; replace with real pixel-art dungeon (keep it dark so foreground UI stays readable). |

## 5. Buttons & panels (currently drawn with code styles — art optional)

| Asset | Suggested path | Size | Status | Description |
|---|---|---|---|---|
| Button plates | `assets/ui/btn_{green,blue,red,dark}.png` | 9-slice, ~64px tall | ➖ | For `CONFIRM / END TURN / MENU / FLEE / DRAW`. Ideally 9-slice with normal/hover/pressed. Your kit already has CONFIRM / END TURN / FLEE. |
| Equipment slot frame | `assets/ui/slot.png` | ~120×100, 9-slice | ➖ | Purple-bordered slot behind each equipment item (now a code-drawn panel). |
| Draw-pile plate | `assets/ui/draw_plate.png` | ~248×66, 9-slice | ➖ | Bottom-right draw button background. |

## 6. Feedback / FX (needed to make combat feel "alive" — none wired yet)

| Asset | Suggested path | Status | Description |
|---|---|---|---|
| Turn banners | `assets/ui/banner_{player,enemy,victory,defeat}.png` | ➖ | "PLAYER TURN / ENEMY TURN / VICTORY / DEFEAT" ribbons (in your kit). |
| Floating numbers | font or sprite sheet | ➖ | Damage (`-6`), heal (`+4`), block (`◈-5`) pop-ups over targets. |
| Word pop-ups | `assets/fx/{blocked,healed,chain}.png` | ➖ | "BLOCKED! / HEALED! / CHAIN!" callouts (in your kit). |
| Hit VFX sheets | `assets/fx/{slash,fireball,block,heal,arcane}.png` | ➖ | Impact effects per element; sprite sheets or single frames. |

---

## Priority order (biggest visual payoff first)
1. **Ability art ×10** — the cards are the focal point.
2. **Enemy sprite(s)** on clean transparency.
3. **Element + status icons** (5 + 5) — small but everywhere.
4. **Combat background** — sets the whole mood.
5. **Buttons / slot / draw plates** — cohesive frame around the play area.
6. **Feedback & FX** — turns a static screen into a game feel.

Anything you drop into these paths at the listed sizes appears automatically. If a
size or region needs to change, point me at the new file and I'll re-measure.
