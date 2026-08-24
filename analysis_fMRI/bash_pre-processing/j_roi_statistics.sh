#!/bin/bash
#
# Run featquery for every cope*.feat inside every subject .gfeat directory,
# once per ROI mask in MNI_masks/. Outputs are named featquery_<maskname>
# inside each cope*.feat so multiple masks don't overwrite each other.
shopt -s nullglob

derivdir="/project/3025011.02/bids/derivatives/fsl"
maskdir="/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_fMRI/MNI_masks"
featquery="/opt/fsl/6.0.6/bin/featquery"

# Collect masks once
masks=( "${maskdir}"/*.nii.gz )
if [ "${#masks[@]}" -eq 0 ]; then
    echo "No masks found in $maskdir"
    exit 1
fi

# Loop over subject directories only (skips group/, etc.)
for subdir in "${derivdir}"/sub-*/; do
    sub=$(basename "$subdir")

    # All .gfeat directories for this subject
    for gfeat in "${subdir}"*.gfeat; do
        [ -d "$gfeat" ] || continue

        # Collect cope*.feat dirs and their stats/cope*.nii.gz images
        cope_feats=()
        cope_stats=()
        for copefeat in "${gfeat}"/cope*.feat; do
            [ -d "$copefeat" ] || continue
            cname=$(basename "$copefeat" .feat)   # e.g. cope1
            statimg="stats/${cname}"              # featquery wants relative paths
            if [ ! -f "${copefeat}/${statimg}.nii.gz" ]; then
                echo "  Skipping ${copefeat}: ${statimg}.nii.gz not found"
                continue
            fi
            cope_feats+=("$copefeat")
            cope_stats+=("$statimg")
        done

        if [ "${#cope_feats[@]}" -eq 0 ]; then
            echo "  No usable cope*.feat in $gfeat — skipping"
            continue
        fi

        # One featquery call per mask, processing all cope*.feat at once
        for mask in "${masks[@]}"; do
            maskname=$(basename "$mask" .nii.gz)
            outname="featquery_${maskname}"

            # Skip if already done for every cope*.feat in this gfeat
            all_done=1
            for cf in "${cope_feats[@]}"; do
                if [ ! -d "${cf}/${outname}" ]; then
                    all_done=0
                    break
                fi
            done
            if [ "$all_done" -eq 1 ]; then
                echo "  ${sub} $(basename "$gfeat") mask=${maskname}: already done, skipping"
                continue
            fi

            n_feats="${#cope_feats[@]}"
            n_stats="${#cope_stats[@]}"

            echo "Running featquery: ${sub} $(basename "$gfeat") mask=${maskname} (${n_feats} cope.feat dirs)"
            "$featquery" \
                "$n_feats" "${cope_feats[@]}" \
                "$n_stats" "${cope_stats[@]}" \
                "$outname" \
                -p -s -b \
                "$mask"
        done
    done
done

echo "Done."
