#!/bin/bash
#
# Generate .fsf files from template and run 1st level FEAT analysis as a job array.
# Usage: d_feat_first_level.sh [suffix]
# If suffix is provided, it is appended to the output directory name with an underscore.
shopt -s nullglob

module load fsl/6.0.6
suffix="$1"
template="/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_fMRI/fsf_templates/feat_template_most_rewarding_response.fsf"
derivdir="/project/3025011.02/bids/derivatives/fsl"
joblist="${derivdir}/feat_joblist_$(date +%Y%m%d_%H%M%S).txt"

if [ ! -f "$template" ]; then
    echo "Template not found: $template"
    exit 1
fi

# Pass 1: generate all .fsf files and write their paths to a joblist
> "$joblist"
for confounds in "${derivdir}"/sub-*/ses-*/func/*_task-AARL_confounds_for_feat.txt; do
    sub=$(echo "$confounds" | grep -oP 'sub-\d+' | head -1)
    ses=$(echo "$confounds" | grep -oP 'ses-\w+' | head -1)
    funcdir="${derivdir}/${sub}/${ses}/func"
    fsf="${funcdir}/${sub}_${ses}_task-AARL_design.fsf"

    echo "Creating: $fsf"
    if [ -n "$suffix" ]; then
        sed -e "s|ses-mri00\"|ses-mri00_${suffix}\"|" \
            -e "s/sub-000/${sub}/g" -e "s/ses-mri00/${ses}/g" \
            "$template" > "$fsf"
    else
        sed -e "s/sub-000/${sub}/g" -e "s/ses-mri00/${ses}/g" "$template" > "$fsf"
    fi

    echo "$fsf" >> "$joblist"
done

njobs=$(wc -l < "$joblist")
if [ "$njobs" -eq 0 ]; then
    echo "No confound files found — nothing to submit."
    exit 0
fi

echo "Submitting job array with $njobs tasks (joblist: $joblist)"

# Pass 2: submit as a single job array
sbatch --job-name="feat_first_level${suffix:+_$suffix}" \
       --array=1-${njobs} \
       --mem=32G \
       --time=24:00:00 \
       --output="${derivdir}/feat_array_%A_%a.log" \
       --wrap="fsf=\$(sed -n \"\${SLURM_ARRAY_TASK_ID}p\" ${joblist}); export FSLPARALLEL=1; feat \$fsf"
