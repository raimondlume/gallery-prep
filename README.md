# FUJI MAIN

Photo library from a Fujifilm camera, organized by capture date.

## Structure

```
FUJI MAIN/
├── YYYY/
│   ├── MM/
│   │   ├── *.RAF       # Raw files (Fujifilm RAW)
│   │   ├── *.MP4       # Videos (if any)
│   │   └── jpegs/      # Edited JPEGs exported from Fuji X app
```

- Photos are sorted into `YYYY/MM/` folders based on EXIF capture date.
- RAFs (raw files) live directly in the month folder.
- The `jpegs/` subfolder in each month holds edited exports from Fuji X app.
- JPEGs from the camera were deleted — only raws are kept as source files.

## Tools

- **exiftool** was used to organize files by date: `exiftool -r -d "%Y/%m" '-directory<DateTimeOriginal' .`
- Edits are done in **Fuji X app**, exported JPEGs go into the corresponding `jpegs/` folder.
- **move-jpegs.sh** moves stray `.jpg` files from month folders into their `jpegs/` subfolders. Use `--dry-run` to preview.

## Notes

- This folder is backed up externally.
- FP2/FP3 (Film Simulation preset) files were removed — originals remain on the camera's SD card.
