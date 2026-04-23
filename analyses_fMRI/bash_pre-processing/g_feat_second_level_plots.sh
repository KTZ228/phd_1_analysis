#!/bin/bash
#SBATCH --mem=16G
#SBATCH --time=48:00:00
#SBATCH --job-name=second_level_plots
#
# Plot second-level FEAT results only.
#
# Walks the search directory looking for `copeN.feat` subfolders that live
# inside second-level .gfeat directories (produced by f_feat_second_level.sh).
# Expected structure:
#   <searchdir>/sub-XXX/sub-XXX_second-level[_<suffix>].gfeat/copeN.feat/
# For each match it renders zstat1.nii.gz at a cope-specific set of MNI
# coordinates:
#   - cope1       -> 4 coordinate sets
#   - cope2..cope5 -> 8 coordinate sets each
# Copes outside that range are skipped.
shopt -s nullglob

fsldir="${FSLDIR:-/opt/fsl/6.0.6}"
bg="${fsldir}/data/standard/MNI152_T1_2mm_brain.nii.gz"
searchdir="/project/3025011.02/bids/derivatives/fsl"

# ---------------------------------------------------------------------------
# Coordinates per cope (MNI, in mm), each with a label used in the output
# filename. Format: "x y z label" per line. The label should be filesystem-
# safe (no spaces / slashes); use hyphens or underscores.
# ---------------------------------------------------------------------------

# cope1 (e.g. "cue>baseline"): 4 coordinates
coords_cope1=(
    "-26 -18 68 motor_cortex_left"
    "26 -18 68 motor_cortex_right"
    "0 -92 -10 visual_cortex"
)

# cope2..cope5 (e.g. "angry>happy", "approach>avoid", "incongruent>congruent",
# "volatile>stable"): 8 coordinates each. Edit per-cope if they differ.
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
# Helper: echo the right coord array (space-separated, one triple per line)
# for a given cope number, or nothing if the cope is out of range.
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
# Walk second-level .gfeat directories and render each copeN.feat inside.
# The glob explicitly targets:
#   <searchdir>/sub-*/sub-*_second-level*.gfeat/cope*.feat
# so first-level .feat dirs and anything else are ignored automatically.
# ---------------------------------------------------------------------------
for copefeat in "${searchdir}"/sub-*/sub-*_second-level*.gfeat/cope*.feat; do
    [ -d "$copefeat" ] || continue

    zstat="${copefeat}/stats/zstat1.nii.gz"
    [ -f "$zstat" ] || continue

    # Extract the cope number from the folder name (cope<N>.feat -> N)
    copename=$(basename "$copefeat" .feat)     # e.g. cope3
    copenum="${copename#cope}"

    # Pull the matching coord list; skip if cope is out of our configured range
    mapfile -t coords < <(get_coords_for_cope "$copenum")
    if [ "${#coords[@]}" -eq 0 ]; then
        echo "Skipping ${copefeat} (cope${copenum} not configured)"
        continue
    fi

    outdir="$copefeat"

    for coord in "${coords[@]}"; do
        read -r x y z label <<< "$coord"
        out="${outdir}/zstat1_${label}.png"

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

echo "Done."
