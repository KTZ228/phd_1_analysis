#!/bin/bash
#
# Extract ROI statistics (mean, stddev, non-zero voxel count) from every
# copeX.nii.gz file under the FSL derivatives tree, using every mask in the
# MNI_masks directory.
#
# For each cope file found, writes a single CSV next to it:
#   <stats_dir>/<cope_basename>_roi_stats.csv
# with one row per mask:
#   mask,mean,stddev,nvoxels
#
# Usage
# -----
#   bash i_fslstats_roi_extraction.sh
#
# Notes
# -----
# - Uses fslstats -M -S -V to match the original reference command, which
#   reports the MEAN and STDDEV of NON-ZERO voxels within the mask, and the
#   COUNT of non-zero voxels (voxels + mm^3).
# - Search scope is the whole FSL derivatives tree, which picks up copes
#   inside 1st-level .feat/stats/, 2nd-level .gfeat/copeN.feat/stats/, and
#   3rd-level group/.gfeat/copeN.feat/stats/. If you want to narrow this,
#   edit `searchdir` below.
# - Idempotent: if the CSV already exists and is non-empty it is skipped.
#   Delete it (or pass --force) to regenerate.
shopt -s nullglob globstar

searchdir="/project/3025011.02/bids/derivatives/fsl"
maskdir="/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_fMRI/MNI_masks"
force=0

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force) force=1; shift ;;
        -h|--help)  sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "ERROR: unknown argument '$1'"; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------
if ! command -v fslstats >/dev/null 2>&1; then
    echo "ERROR: fslstats not found on PATH. Source FSL's environment first."
    exit 1
fi

if [ ! -d "$searchdir" ]; then
    echo "ERROR: searchdir does not exist: $searchdir"
    exit 1
fi

if [ ! -d "$maskdir" ]; then
    echo "ERROR: maskdir does not exist: $maskdir"
    exit 1
fi

# Collect masks once
masks=( "$maskdir"/*.nii.gz "$maskdir"/*.nii )
if [ "${#masks[@]}" -eq 0 ]; then
    echo "ERROR: no .nii / .nii.gz masks found in $maskdir"
    exit 1
fi

echo "Using ${#masks[@]} mask(s) from: $maskdir"
echo "Searching for cope files under: $searchdir"
echo

# ---------------------------------------------------------------------------
# Find all cope files. copeX.nii.gz live inside <...>.feat/stats/ directories.
# The globstar pattern below catches them at every nesting depth.
# ---------------------------------------------------------------------------
cope_files=( "$searchdir"/**/stats/cope*.nii.gz )
ncopes=${#cope_files[@]}

if [ "$ncopes" -eq 0 ]; then
    echo "No cope*.nii.gz files found under $searchdir/**/stats/"
    exit 0
fi

echo "Found $ncopes cope file(s)."
echo

# ---------------------------------------------------------------------------
# Loop: for each cope, write one CSV with one row per mask.
# ---------------------------------------------------------------------------
i=0
for cope in "${cope_files[@]}"; do
    i=$((i + 1))
    copedir=$(dirname "$cope")
    copebase=$(basename "$cope" .nii.gz)
    outcsv="${copedir}/${copebase}_roi_stats.csv"

    if [ "$force" -eq 0 ] && [ -s "$outcsv" ]; then
        echo "[$i/$ncopes] Skipping (exists): $outcsv"
        continue
    fi

    echo "[$i/$ncopes] $cope"
    echo "mask;mean;stddev;nvoxels;volume_mm3" > "$outcsv"

    for mask in "${masks[@]}"; do
        maskname=$(basename "$mask")
        maskname="${maskname%.nii.gz}"
        maskname="${maskname%.nii}"

        # fslstats -M -S -V:
        #   -M : mean of non-zero voxels within mask
        #   -S : stddev of non-zero voxels within mask
        #   -V : nvoxels (int)  volume_mm3 (float)
        # Output is space-separated on a single line:
        #   "<mean> <stddev> <nvox> <vol_mm3>"
        out=$(fslstats "$cope" -k "$mask" -M -S -V 2>/dev/null)
        if [ -z "$out" ]; then
            echo "    WARN: fslstats failed for mask=$maskname"
            echo "${maskname};NA;NA;NA;NA" >> "$outcsv"
            continue
        fi

        read -r mean sd nvox volmm3 <<< "$out"
        echo "${maskname};${mean};${sd};${nvox};${volmm3}" >> "$outcsv"
    done

    echo "    -> $outcsv"
done

echo
echo "Done. Wrote ROI stats CSVs next to each cope file."