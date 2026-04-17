#!/bin/bash
shopt -s nullglob globstar

fsldir="${FSLDIR:-/opt/fsl/6.0.6}"
bg="${fsldir}/data/standard/MNI152_T1_2mm_brain.nii.gz"
searchdir="/project/3025011.02/bids/derivatives/fsl/old"

coords=(
    "22 -6 -20"
    "-18 -6 -20"
)

stats=("zstat1")

dispmin=-10
dispmax=10

for stat in "${stats[@]}"; do
    for zstat in "${searchdir}"/**/"${stat}.nii.gz"; do
        [ -f "$zstat" ] || continue
        outdir=$(dirname "$zstat")

        for coord in "${coords[@]}"; do
            read -r x y z <<< "$coord"
            xn=${x/-/n}; yn=${y/-/n}; zn=${z/-/n}
            out="${outdir}/${stat}_x${xn}_y${yn}_z${zn}.png"

            echo "Rendering: $out"
            fsleyes render \
                --scene ortho \
                --worldLoc "$x" "$y" "$z" \
                --outfile "$out" \
                "$bg" \
                "$zstat" \
                    --cmap red \
                    --useNegativeCmap \
                    --negativeCmap blue \
                    --displayRange "$dispmin" "$dispmax" \
                    --modulateAlpha \
                    --alpha 100
        done
    done
done

echo "Done."

# bash Documents/phd_1_analysis/analyses_fMRI/bash_pre-processing/f_feat_first_level_plots.sh
