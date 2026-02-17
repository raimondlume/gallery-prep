# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Fujifilm photo library organized by EXIF capture date (`YYYY/MM/`). RAFs (raw files) live in month folders; edited JPEGs from Fuji X app go into `jpegs/` subfolders. The `202*/` directories are gitignored — only scripts and docs are tracked.

## Scripts

### frame.sh — Add white borders to JPEGs

Requires **ImageMagick 7** (`magick`). Output goes to a `framed/` subfolder next to the input.

```bash
# Basic usage (2% border, pad to 4:5)
./frame.sh photo.jpg
./frame.sh /path/to/directory    # processes all JPEGs in dir (non-recursive)

# Common flags
./frame.sh --border 3 --frame photo.jpg      # 3% border + 10px black keyline
./frame.sh --pad 1:1 photo.jpg               # square padding
./frame.sh --no-pad photo.jpg                # border only, no aspect ratio padding
./frame.sh --instagram photo.jpg             # resize to 5000px long edge, q100, 4:4:4, sRGB
./frame.sh --dry-run /path/to/dir            # preview without writing

# Output filenames encode non-default options as suffixes:
#   photo_framed.jpg        (defaults)
#   photo_border3_frame.jpg (--border 3 --frame)
#   photo_1x1.jpg           (--pad 1:1)
```

### move-jpegs.sh — Sort stray JPEGs into jpegs/ subfolders

```bash
./move-jpegs.sh --dry-run   # preview
./move-jpegs.sh              # move .jpg files from YYYY/MM/ into YYYY/MM/jpegs/
```

## Testing frame.sh

Test images live in `test-frames/` (three sizes of the same photo: `_full`, `_2000`, `_1350`). There is no automated test suite — verify visually:

```bash
./frame.sh --dry-run test-frames/
./frame.sh --force test-frames/DSCF5017_2000.jpg
```

## Key Details

- `frame.sh` uses `magick identify` for dimensions and `magick` for processing — do not use legacy `convert`/`identify` commands.
- Pad logic is orientation-aware: 4:5 means short:long regardless of landscape/portrait.
- `--frame` without a value defaults to 10px; `--frame N` sets a custom keyline width.
- The output suffix system avoids filename collisions between different framing options.
