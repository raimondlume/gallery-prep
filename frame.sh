#!/bin/bash
# Adds a white frame around JPEGs, optionally pads to a target aspect ratio.
# Output goes to a framed/ subfolder alongside the input file(s).

set -euo pipefail

# --- Defaults ---
BORDER=2
PAD="4:5"
INSTAGRAM=0
FRAME=0          # 0 = off, N = keyline width in px (default 10 when enabled)
DRY_RUN=0
FORCE=0

# --- Helper functions ---

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <file-or-directory>

Add a white border to JPEG images. Output goes to a framed/ subfolder.

Options:
  -h, --help        Show this help and exit
  --border N        Border size as %% of longer side (default: 2)
  --pad RATIO       Pad to aspect ratio: 4:5 (default), 1:1
  --no-pad, --nopad Border only, no aspect ratio padding
  --frame [N]       Add a black keyline around the photo (default: 10px)
  --instagram       Resize for Instagram, JPEG quality 100, no chroma subsampling, sRGB
  --dry-run         Show what would happen without writing files
  --force           Overwrite existing output files

Use -- to end option parsing (e.g. for files starting with -)
EOF
}

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

check_deps() {
  command -v magick >/dev/null 2>&1 || die "error: magick (ImageMagick 7) not found"
}

# --- Core function ---

frame_image() {
  local src="$1"
  local dir
  dir="$(dirname "$src")"
  local outdir="$dir/framed"
  local filename
  filename="$(basename "$src")"
  local base="${filename%.*}"
  local ext="${filename##*.}"
  local outfile="$outdir/${base}${SUFFIX}.${ext}"

  if [[ -f "$outfile" ]] && [[ $FORCE -eq 0 ]]; then
    echo "skipped $src (already framed)"
    return 1
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    local extra=""
    if [[ "$PAD" == "none" ]]; then
      extra+=" [no-pad]"
    else
      extra+=" [pad: ${PAD}]"
    fi
    if [[ $FRAME -gt 0 ]]; then
      extra+=" [frame: ${FRAME}px]"
    fi
    if [[ $INSTAGRAM -eq 1 ]]; then
      local ig_long
      case "$PAD" in
        4:5)  ig_long="5000" ;;
        *)    ig_long="4000" ;;
      esac
      extra+=" [instagram: ${ig_long}px long edge, q100, 4:4:4]"
    fi
    echo "[dry-run] $src -> $outfile (border: ${BORDER}%)${extra}"
    return 0
  fi

  mkdir -p "$outdir"

  local dims w h longer border_px
  dims="$(magick identify -format '%w %h' "$src")"
  w="${dims% *}"
  h="${dims#* }"
  longer=$(( w > h ? w : h ))
  border_px=$(( longer * BORDER / 100 ))

  local cmd=(magick "$src")
  if [[ $FRAME -gt 0 ]]; then
    cmd+=(-bordercolor black -border "$FRAME")
  fi
  cmd+=(-bordercolor white -border "${border_px}")

  if [[ "$PAD" != "none" ]]; then
    local w_b h_b target_w target_h
    local frame_px=$FRAME
    w_b=$(( w + 2 * frame_px + 2 * border_px ))
    h_b=$(( h + 2 * frame_px + 2 * border_px ))

    case "$PAD" in
      4:5)
        # ratio_short:ratio_long = 4:5, applied respecting orientation
        if (( w_b >= h_b )); then
          # landscape: width is long side → 5:4
          if (( w_b * 4 >= h_b * 5 )); then
            target_w=$w_b
            target_h=$(( w_b * 4 / 5 ))
          else
            target_h=$h_b
            target_w=$(( h_b * 5 / 4 ))
          fi
        else
          # portrait: height is long side → 4:5
          if (( h_b * 4 >= w_b * 5 )); then
            target_h=$h_b
            target_w=$(( h_b * 4 / 5 ))
          else
            target_w=$w_b
            target_h=$(( w_b * 5 / 4 ))
          fi
        fi
        ;;
      1:1)
        local side=$(( w_b > h_b ? w_b : h_b ))
        target_w=$side
        target_h=$side
        ;;
    esac

    cmd+=(-gravity center -background white -extent "${target_w}x${target_h}")
  fi

  if [[ $INSTAGRAM -eq 1 ]]; then
    local ig_long
    case "$PAD" in
      4:5)  ig_long="5000" ;;
      *)    ig_long="4000" ;;
    esac
    cmd+=(-resize "${ig_long}x${ig_long}" -colorspace sRGB -quality 100 -sampling-factor 4:4:4)
  fi

  cmd+=("$outfile")
  "${cmd[@]}"

  echo "framed $src -> $outfile"
  return 0
}

# --- Argument parsing ---

INPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --border)
      [[ $# -ge 2 ]] || die "error: --border requires an argument"
      BORDER="$2"
      shift 2
      ;;
    --border=*)
      BORDER="${1#--border=}"
      shift
      ;;
    --pad)
      [[ $# -ge 2 ]] || die "error: --pad requires an argument"
      PAD="$2"
      shift 2
      ;;
    --pad=*)
      PAD="${1#--pad=}"
      shift
      ;;
    --no-pad|--nopad)
      PAD="none"
      shift
      ;;
    --frame)
      if [[ $# -ge 2 ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
        FRAME="$2"
        shift 2
      else
        FRAME=10
        shift
      fi
      ;;
    --frame=*)
      FRAME="${1#--frame=}"
      shift
      ;;
    --instagram)
      INSTAGRAM=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --)
      shift
      break
      ;;
    --*)
      die "error: unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

# Remaining args are the input path
if [[ $# -eq 0 ]] && [[ -z "$INPUT" ]]; then
  die "error: no input file or directory specified (use --help for usage)"
fi
INPUT="${1:-}"

# --- Input validation ---

[[ "$BORDER" =~ ^[0-9]+$ ]] || die "error: --border must be a positive integer, got '$BORDER'"
[[ "$BORDER" -gt 0 ]] || die "error: --border must be greater than 0, got '$BORDER'"
[[ "$FRAME" =~ ^[0-9]+$ ]] || die "error: --frame must be a positive integer, got '$FRAME'"
[[ "$PAD" =~ ^(4:5|1:1|none)$ ]] || die "error: --pad must be 4:5, 1:1, or none, got '$PAD'"
[[ -e "$INPUT" ]] || die "error: '$INPUT' does not exist"

check_deps

# Build filename suffix from non-default flags
SUFFIX=""
[[ "$BORDER" -ne 2 ]] && SUFFIX+="_border${BORDER}"
[[ $FRAME -eq 10 ]] && SUFFIX+="_frame"
[[ $FRAME -gt 0 ]] && [[ $FRAME -ne 10 ]] && SUFFIX+="_frame${FRAME}"
case "$PAD" in
  1:1)  SUFFIX+="_1x1" ;;
  none) SUFFIX+="_nopad" ;;
esac
[[ $INSTAGRAM -eq 1 ]] && SUFFIX+="_instagram"
# Ensure suffix is never empty (use _framed as baseline)
[[ -z "$SUFFIX" ]] && SUFFIX="_framed"

# --- Main loop ---

count=0
skipped=0

process() {
  if frame_image "$1"; then
    ((count++)) || true
  else
    ((skipped++)) || true
  fi
}

if [[ -d "$INPUT" ]]; then
  while IFS= read -r -d '' file; do
    process "$file"
  done < <(find "$INPUT" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -print0 | sort -z)
else
  process "$INPUT"
fi

echo "Processed $count file(s), skipped $skipped. Border: ${BORDER}%."
