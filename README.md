# gallery-prep

A collection of scripts to sort, stage and prep my personal photo gallery.

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

## Tools

- **exiftool** was used to organize files by date: `exiftool -r -d "%Y/%m" '-directory<DateTimeOriginal' .`
- Edits are done in **Fuji X app**, exported JPEGs go into the corresponding `jpegs/` folder.

