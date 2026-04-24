#!/bin/bash
#SBATCH --mem=16G
#SBATCH --time=48:00:00
#SBATCH --job-name=roi_plots
#
# Plot second-level FEAT results.
#
# Walks the search directory looking for `copeN.gfeat` folders (produced by
# f_feat_second_level.sh). Each such folder corresponds to one contrast from
# the first-level model.
#
# Inside every `copeN.gfeat` two zstat images are rendered per mask:
#   - `cope1.feat/stats/zstat1.nii.gz`   — unthresholded z-statistic
#   - `cope1.feat/thresh_zstat1.nii.gz`  — cluster-thresholded z-statistic
# Output filenames are prefixed with `zstat1_` or `thresh_zstat1_` so both
# versions coexist side-by-side and can be compared.
#
# For each zstat, this script iterates over every NIfTI mask found in
# `maskdir`, computes the centre of gravity of that mask, and renders an
# ortho view with:
#   - the MNI template as background
#   - the zstat1 as a hot/cold overlay
#   - the mask as a contour outline
#   - the crosshair placed at the mask's centre of gravity
#
# One PNG is produced per (zstat, mask) combination, stored alongside the
# zstat and named after the mask.
shopt -s nullglob globstar

fsldir="${FSLDIR:-/opt/fsl/6.0.6}"
bg="${fsldir}/data/standard/MNI152_T1_2mm_brain.nii.gz"
searchdir="/project/3025011.02/bids/derivatives/fsl"
maskdir="/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_fMRI/MNI_masks"

dispmin=-6
dispmax=6

# ---------------------------------------------------------------------------
# Collect masks up-front. Accept both .nii and .nii.gz.
# ---------------------------------------------------------------------------
masks=( "${maskdir}"/*.nii.gz "${maskdir}"/*.nii )
if [ "${#masks[@]}" -eq 0 ]; then
    echo "No masks found in ${maskdir} — nothing to do."
    exit 0
fi

# ---------------------------------------------------------------------------
# Helper: strip .nii / .nii.gz extension to get a filesystem-safe label
# from the mask filename.
# ---------------------------------------------------------------------------
mask_label() {
    local f
    f=$(basename "$1")
    f="${f%.nii.gz}"
    f="${f%.nii}"
    printf '%s' "$f"
}

# ---------------------------------------------------------------------------
# Helper: compute the MNI (mm) centre of gravity of a binary mask via
# `fslstats -c`, which returns "x y z" in mm.
# ---------------------------------------------------------------------------
mask_cog() {
    fslstats "$1" -c
}

# ---------------------------------------------------------------------------
# Walk all copeN.gfeat folders and render zstat1.nii.gz once per mask.
# ---------------------------------------------------------------------------
for gfeatdir in "${searchdir}"/**/*cope*.gfeat; do
    [ -d "$gfeatdir" ] || continue

    # Render both the unthresholded zstat (inside stats/) and the
    # cluster-thresholded zstat (one level up, next to cope1.feat/).
    # Each entry is "path|stem" — the stem is used in the output filename.
    zstats=(
        "${gfeatdir}/cope1.feat/stats/zstat1.nii.gz|zstat1"
        "${gfeatdir}/cope1.feat/thresh_zstat1.nii.gz|thresh_zstat1"
    )

    for entry in "${zstats[@]}"; do
        zstat="${entry%%|*}"
        stem="${entry##*|}"

        if [ ! -f "$zstat" ]; then
            echo "No ${stem}.nii.gz found at $zstat — skipping"
            continue
        fi

        outdir=$(dirname "$zstat")

        for mask in "${masks[@]}"; do
            [ -f "$mask" ] || continue

            label=$(mask_label "$mask")

            # Centre of gravity in MNI mm
            read -r x y z <<< "$(mask_cog "$mask")"
            if [ -z "$x" ] || [ -z "$y" ] || [ -z "$z" ]; then
                echo "Could not compute CoG for $mask — skipping"
                continue
            fi

            out="${outdir}/${stem}_${label}.png"

            # Clip the unthresholded zstat to voxels inside the mask so the
            # rendered activity is confined to the ROI. The cluster-thresholded
            # `thresh_zstat1` keeps full-brain visibility.
            clip_opts=()
            if [ "$stem" = "zstat1" ]; then
                clip_opts=( --clipImage "$mask" --clippingRange 0.5 1.5 )
            fi

            echo "Rendering: $out  (mask=${label}, CoG x=$x y=$y z=$z)"
            fsleyes render \
                --scene ortho \
                --worldLoc "$x" "$y" "$z" \
                --outfile "$out" \
                --size 1500 600 \
                "$bg" \
                "$zstat" \
                    --cmap red \
                    --useNegativeCmap \
                    --negativeCmap blue \
                    --displayRange "$dispmin" "$dispmax" \
                    --modulateAlpha \
                    "${clip_opts[@]}" \
                "$mask" \
                    --overlayType mask \
                    --outline \
                    --outlineWidth 2 \
                    --maskColour 0 1 0
        done
    done
done

echo "Done."
