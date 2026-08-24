#!/bin/bash
#SBATCH --mem=16G
#SBATCH --time=48:00:00
#SBATCH --job-name=first_level_plots
#
# Plot first-level FEAT results.
#
# Walks the search directory looking for 1st-level `.feat` folders produced by
# e_feat_first_level.sh, i.e.
#   ${searchdir}/<sub>/<ses>/func/<sub>_<ses>[_<suffix>].feat
#
# Only zstat1 is rendered — that is the first first-level contrast
# ("cue>baseline") — at a small set of sanity-check coordinates (bilateral
# motor cortex + visual cortex). If cue>baseline doesn't light up there, the
# model/regressors are almost certainly wrong.
#
# The glob is deliberately restricted to the <sub>/<ses>/func/ level so that
# `cope*.feat` directories living inside 2nd/3rd-level `.gfeat` folders are
# not picked up.
shopt -s nullglob

module load fsl/6.0.6
fsldir="${FSLDIR:-/opt/fsl/6.0.6}"
# 2mm background matches the fMRIPrep output space (MNI152NLin6Asym res-02)
bg="${fsldir}/data/standard/MNI152_T1_2mm_brain.nii.gz"
searchdir="/project/3025011.02/bids/derivatives/fsl"

# ---------------------------------------------------------------------------
# Coordinates (MNI, in mm), each with a label used in the output filename.
# Format: "x y z label" per line. The label should be filesystem-safe
# (no spaces / slashes); use hyphens or underscores.
# ---------------------------------------------------------------------------
coords=(
    "-38 -22 56 motor_cortex_left"
    "38 -22 56 motor_cortex_right"
    "-6 -98 2 visual_cortex_left"
    "6 -98 2 visual_cortex_right"
)

# Which stat image(s) to render. zstat1 = first-level contrast 1 (cue>baseline)
stats=("zstat1")

# First-level z-stats are noisier than group maps, so a wider display range
dispmin=-10
dispmax=10

# ---------------------------------------------------------------------------
# Walk all 1st-level .feat folders and render each configured stat image at
# every configured coordinate.
# ---------------------------------------------------------------------------
for featdir in "${searchdir}"/sub-*/ses-*/func/*.feat; do
    [ -d "$featdir" ] || continue

    for stat in "${stats[@]}"; do
        zstat="${featdir}/stats/${stat}.nii.gz"
        if [ ! -f "$zstat" ]; then
            echo "No ${stat}.nii.gz found at $zstat — skipping"
            continue
        fi

        outdir=$(dirname "$zstat")

        for coord in "${coords[@]}"; do
            read -r x y z label <<< "$coord"
            out="${outdir}/${stat}_${label}.png"

            echo "Rendering: $out  (x=$x y=$y z=$z)"
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
                    --modulateAlpha
        done
    done
done

echo "Done."
