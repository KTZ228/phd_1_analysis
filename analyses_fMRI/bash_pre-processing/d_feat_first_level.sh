#!/bin/bash
#
# Generate .fsf files from template and run 1st level FEAT analysis
shopt -s nullglob

template="/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_fMRI/fsf_templates/feat_template.fsf"
derivdir="/project/3025011.02/bids/derivatives/fsl"

if [ ! -f "$template" ]; then
    echo "Template not found: $template"
    exit 1
fi

# Generate .fsf files and submit FEAT jobs for each subject/session with a confounds file
for confounds in "${derivdir}"/sub-*/ses-*/func/*_task-AARL_confounds_for_feat.txt; do
    sub=$(echo "$confounds" | grep -oP 'sub-\d+' | head -1)
    ses=$(echo "$confounds" | grep -oP 'ses-\w+' | head -1)
    funcdir="${derivdir}/${sub}/${ses}/func"
    fsf="${funcdir}/${sub}_${ses}_task-AARL_design.fsf"

    echo "Creating: $fsf"
    sed -e "s/sub-000/${sub}/g" -e "s/ses-mri00/${ses}/g" "$template" > "$fsf"

    echo "Submitting: ${sub} ${ses}"
    sbatch --job-name="feat_${sub}_${ses}" \
           --mem=32G \
           --time=24:00:00 \
           --output="${funcdir}/feat_%j.log" \
           --wrap="export FSLPARALLEL=0; feat $fsf"
done
