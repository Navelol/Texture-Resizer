# TextureResizer

A dead-simple texture downscaling tool for Windows. No installation required — runs entirely on built-in Windows .NET Framework. No Python, no ImageMagick, just two files.

## Download

Grab the latest release from the [Releases](../../releases/latest) page and extract the zip anywhere.

## Usage

**Option A — Double-click**
1. Double-click `TextureResizer.bat`
2. A file picker opens — select one or more texture files
3. Choose your target size: **2K**, **1K**, or **512px**
4. Choose where to save the output
5. Done — the output folder opens automatically

**Option B — Drag and drop**
1. Select one or more image files in Explorer
2. Drag them onto `TextureResizer.bat`
3. Choose your target size and output folder
4. Done

## Supported Formats

PNG · JPG/JPEG · BMP · TIF/TIFF

## Output Filenames

Originals are never overwritten — the target size is appended to the filename:

```
MyTexture_4K.png  →  MyTexture_2K.png
MyTexture_4K.png  →  MyTexture_1K.png
MyTexture_4K.png  →  MyTexture_512px.png
```

## Requirements

- Windows 10 or Windows 11
- Nothing else

## Troubleshooting

**"Windows protected your PC" popup**

SmartScreen shows this for any newly downloaded executable that hasn't built up a reputation yet. It's not a virus warning.

1. Click **More info**
2. Click **Run anyway**

**"Execution policy" error**

Right-click `TextureResizer.bat` → **Run as Administrator**.

---

*Resizing uses high-quality bicubic interpolation (System.Drawing) for clean downscale results.*

## License

MIT — free to use, modify, and distribute.
