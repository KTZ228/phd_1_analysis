#!/bin/bash
#SBATCH --mem=16G
#SBATCH --time=48:00:00
#SBATCH --job-name=third_level_plots
#
# Plot second-level FEAT results.
#
# Walks the search directory looking for `copeN.gfeat` folders (produced by
# f_feat_second_level.sh). Each such folder corresponds to one contrast from
# the first-level model; the cope number N determines which coordinate set
# is used for rendering.
#
# Inside every `copeN.gfeat` there is exactly one `zstat1.nii.gz` to render
# (found recursively — typical FSL layout puts it at
# `copeN.gfeat/cope1.feat/stats/zstat1.nii.gz`, but we don't hardcode that).
#
# Coordinate sets per cope:
#   - cope1        -> a few coordinates (e.g. motor/visual for "cue>baseline")
#   - cope2..cope5 -> a larger set each (regions of interest for the
#                     respective contrast)
# Copes outside that range are skipped.
shopt -s nullglob globstar

module load fsl/6.0.6
fsldir="${FSLDIR:-/opt/fsl/6.0.6}"
bg="${fsldir}/data/standard/MNI152_T1_1mm_brain.nii.gz"
searchdir="/project/3025011.02/bids/derivatives/fsl"

# ---------------------------------------------------------------------------
# Coordinates per cope (MNI, in mm), each with a label used in the output
# filename. Format: "x y z label" per line. The label should be filesystem-
# safe (no spaces / slashes); use hyphens or underscores.
# ---------------------------------------------------------------------------

# cope1 (e.g. "cue>baseline")
coords_cope1=(
    "-26 -18 68 motor_cortex_left"
    "26 -18 68 motor_cortex_right"
    "2 -82 6 visual_cortex"
)

# cope2..cope5 (e.g. "angry>happy", "approach>avoid", "incongruent>congruent",
# "volatile>stable"). Edit per-cope if they differ.
coords_cope2=(
    "-22 -6 -20 amygdala_left"
    "22 -6 -20 amygdala_right"
    "-14 -64 52 precuneus_left"
    "14 -64 52 precuneus_right"
    "-30 36 38 dlpfc_left"
    "30 36 38 dlpfc_right"
    "-10 62 2 frontal_pole_left"
    "10 62 2 frontal_pole_right"
    "-8 32 28 anterior_cingulate_left"
    "8 32 28 anterior_cingulate_right"
)
coords_cope3=(
    "-22 -6 -20 amygdala_left"
    "22 -6 -20 amygdala_right"
    "-26 -18 68 motor_cortex_left"
    "26 -18 68 motor_cortex_right"
    "-14 -64 52 precuneus_left"
    "14 -64 52 precuneus_right"
    "-30 36 38 dlpfc_left"
    "30 36 38 dlpfc_right"
    "-10 62 2 frontal_pole_left"
    "10 62 2 frontal_pole_right"
    "-8 32 28 anterior_cingulate_left"
    "8 32 28 anterior_cingulate_right"
)
coords_cope4=(
    "-22 -6 -20 amygdala_left"
    "22 -6 -20 amygdala_right"
    "-14 -64 52 precuneus_left"
    "14 -64 52 precuneus_right"
    "-30 36 38 dlpfc_left"
    "30 36 38 dlpfc_right"
    "-10 62 2 frontal_pole_left"
    "10 62 2 frontal_pole_right"
    "-8 32 28 anterior_cingulate_left"
    "8 32 28 anterior_cingulate_right"
)
coords_cope5=(
    "-22 -6 -20 amygdala_left"
    "22 -6 -20 amygdala_right"
    "-14 -64 52 precuneus_left"
    "14 -64 52 precuneus_right"
    "-30 36 38 dlpfc_left"
    "30 36 38 dlpfc_right"
    "-10 62 2 frontal_pole_left"
    "10 62 2 frontal_pole_right"
    "-8 32 28 anterior_cingulate_left"
    "8 32 28 anterior_cingulate_right"
)

dispmin=-6
dispmax=6

# ---------------------------------------------------------------------------
# Helper: echo the coord array for a given cope number (one triple per line),
# or nothing if the cope is out of range.
# ---------------------------------------------------------------------------
get_coords_for_cope() {
    local n="$1"
    case "$n" in
        1) printf '%s\n' "${coords_cope1[@]}" ;;
        2) printf '%s\n' "${coords_cope2[@]}" ;;
        3) printf '%s\n' "${coords_cope3[@]}" ;;
        4) printf '%s\n' "${coords_cope4[@]}" ;;
        5) printf '%s\n' "${coords_cope5[@]}" ;;
        *) : ;;
    esac
}

# ---------------------------------------------------------------------------
# Walk all copeN.gfeat folders, pick the cope number from the folder name,
# and render zstat1.nii.gz for every configured coordinate.
# ---------------------------------------------------------------------------
for gfeatdir in "${searchdir}"/**/*cope*.gfeat; do
    [ -d "$gfeatdir" ] || continue

    # Extract the cope number from the END of the folder name.
    # Handles both "copeN.gfeat" and "..._copeN.gfeat" (e.g.
    # group_third-level_f_a_comp_cor_cope1.gfeat -> 1).
    gfeatname=$(basename "$gfeatdir" .gfeat)
    copenum="${gfeatname##*cope}"

    # Sanity check: copenum must be a plain integer
    if ! [[ "$copenum" =~ ^[0-9]+$ ]]; then
        echo "Skipping ${gfeatdir} (could not parse cope number from '${gfeatname}')"
        continue
    fi

    # Pull the matching coord list; skip if cope is out of our configured range
    mapfile -t coords < <(get_coords_for_cope "$copenum")
    if [ "${#coords[@]}" -eq 0 ]; then
        echo "Skipping ${gfeatdir} (cope${copenum} not configured)"
        continue
    fi

    # Standard FSL higher-level layout:
    #   copeN.gfeat/cope1.feat/stats/zstat1.nii.gz
    zstat="${gfeatdir}/cope1.feat/stats/zstat1.nii.gz"
    if [ ! -f "$zstat" ]; then
        echo "No zstat1.nii.gz found at $zstat — skipping"
        continue
    fi

    outdir=$(dirname "$zstat")

    for coord in "${coords[@]}"; do
        read -r x y z label <<< "$coord"
        out="${outdir}/zstat1_${label}.png"

        echo "Rendering: $out  (cope${copenum}, x=$x y=$y z=$z)"
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

echo "Done."
