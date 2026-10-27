# NothingOS — SDDM Theme

**NothingOS** is a minimal SDDM theme inspired by NothingOS.

![NothingOS SDDM theme preview](./assets/preview.png)

## Features

- Minimal, dark-themed panel with a dot-grid canvas and subtle orb background
- 24-hour clock rendered with the Doto font
- Dot-matrix avatars and password pills
- Optional wallpaper support drawn as a dot matrix

## Requirements

- Qt 6 (for the QML theme)
- SDDM version 2.0 or newer (Theme-API 2.0)

## Installation

```bash
# Clone the theme repository
git clone https://github.com/duckpah/Nothing-SDDM

# Copy the theme into SDDM's theme directory
sudo cp -r /Nothing-SDDM /usr/share/sddm/themes

```

Then add this to `/etc/sddm.conf`:

```ini
[Theme]
Current=Nothing-SDDM
```

## Configuration

Adjust appearance through `theme.conf` (e.g., `[General]`):

- `background` — optional wallpaper (path or file URL, drawn as dots)
- `backgroundDots` — render wallpaper as dots
- `clock24` — use a 24-hour clock
- `grid` / `orb` — toggle the dot-grid canvas and the subtle orb
- `bg` / `panel` / `line` / `grey` / `fg` / `accent` — panel colors
