#!/bin/bash
#
# Extract ROI statistics (mean, stddev, non-zero voxel count) from every
# copeX.nii.gz file under the FSL derivatives tree, and from the matching
# zstatX.nii.gz in the same stats/ directory, using every mask in the
# MNI_masks directory.
#
# For each cope file found, writes a single CSV next to it:
#   <stats_dir>/<cope_basename>_roi_stats.csv
# with one row per mask and paired cope/zstat columns:
#   mask;cope_mean;cope_stddev;cope_nvoxels;cope_volume_mm3;zstat_mean;zstat_stddev;zstat_nvoxels;zstat_volume_mm3
#
# Usage
# -----
#   bash i_fslstats_roi_extraction.sh
#   bash i_fslstats_roi_extraction.sh --force
#
# Notes
# -----
# - Uses fslstats -M -S -V to match the original reference command, which
#   reports the MEAN and STDDEV of NON-ZERO voxels within the mask, and the
#   COUNT of non-zero voxels (voxels + mm^3).
# - For zstat this means non-zero z-values; if you want stats across ALL
#   in-mask voxels (including zeros), swap -M/-S for -m/-s.
# - Search scope is the whole FSL derivatives tree, which picks up copes
#   inside 1st-level .feat/stats/, 2nd-level .gfeat/copeN.feat/stats/, and
#   3rd-level group/.gfeat/copeN.feat/stats/. If you want to narrow this,
#   edit `searchdir` below.
# - Idempotent: if the CSV already exists and is non-empty it is skipped.
#   Delete it (or pass --force) to regenerate.
# - If a cope has no matching zstat in the same stats/ dir, the zstat
#   columns are filled with NA.
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
        -h|--help)  sed -n '2,35p' "$0"; exit 0 ;;
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
# Helper: run fslstats on an image with a mask and return the 4 values as
# semicolon-separated "mean;stddev;nvox;volmm3". Returns "NA;NA;NA;NA" if
# the image is missing or fslstats fails.
# ---------------------------------------------------------------------------
run_fslstats() {
    local img="$1" mask="$2"

    if [ ! -f "$img" ]; then
        echo "NA;NA;NA;NA"
        return
    fi

    local out
    out=$(fslstats "$img" -k "$mask" -M -S -V 2>/dev/null)
    if [ -z "$out" ]; then
        echo "NA;NA;NA;NA"
        return
    fi

    local mean sd nvox volmm3
    read -r mean sd nvox volmm3 <<< "$out"
    echo "${mean};${sd};${nvox};${volmm3}"
}

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
# Loop: for each cope, write one CSV with one row per mask (cope + zstat).
# ---------------------------------------------------------------------------
i=0
for cope in "${cope_files[@]}"; do
    i=$((i + 1))
    copedir=$(dirname "$cope")
    copebase=$(basename "$cope" .nii.gz)          # e.g. cope1
    copeidx="${copebase#cope}"                    # e.g. 1
    zstat="${copedir}/zstat${copeidx}.nii.gz"
    outcsv="${copedir}/${copebase}_roi_stats.csv"

    if [ ! -f "$zstat" ]; then
        echo "[$i/$ncopes] $cope"
        echo "    NOTE: no matching zstat${copeidx}.nii.gz — zstat columns will be NA"
    else
        echo "[$i/$ncopes] $cope"
    fi

    echo "mask;cope_mean;cope_stddev;cope_nvoxels;cope_volume_mm3;zstat_mean;zstat_stddev;zstat_nvoxels;zstat_volume_mm3" > "$outcsv"

    for mask in "${masks[@]}"; do
        maskname=$(basename "$mask")
        maskname="${maskname%.nii.gz}"
        maskname="${maskname%.nii}"

        cope_stats=$(run_fslstats "$cope"  "$mask")
        zstat_stats=$(run_fslstats "$zstat" "$mask")

        # Warn (but still write the row) if cope extraction actually failed
        if [[ "$cope_stats" == "NA;NA;NA;NA" ]] && [ -f "$cope" ]; then
            echo "    WARN: fslstats failed on cope for mask=$maskname"
        fi

        echo "${maskname};${cope_stats};${zstat_stats}" >> "$outcsv"
    done

    echo "    -> $outcsv"
done

echo
echo "Done. Wrote ROI stats CSVs (cope + zstat) next to each cope file."
