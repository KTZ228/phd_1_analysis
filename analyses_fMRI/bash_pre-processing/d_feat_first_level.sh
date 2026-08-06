#!/bin/bash
#
# Generate .fsf files from template and run 1st level FEAT analysis as a job array.
# For each subject/session, runs one FEAT analysis per confound file variant.
# Confound files must be named: <sub>_<ses>_task-AARL_confounds_for_feat_<suffix>.txt
#
# Existing analyses are skipped: if the .feat directory that the rendered .fsf
# points to already exists, no .fsf is written and no array task is submitted.
# Set FORCE=1 to re-run everything regardless (existing dirs are left untouched;
# FEAT will create <name>+.feat next to them).
shopt -s nullglob

module load fsl/6.0.6
template="/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_fMRI/fsf_templates/feat_template_first_level.fsf"
derivdir="/project/3025011.02/bids/derivatives/fsl"
joblist="${derivdir}/feat_joblist_$(date +%Y%m%d_%H%M%S).txt"

if [ ! -f "$template" ]; then
    echo "Template not found: $template"
    exit 1
fi

# Pass 1: generate all .fsf files and write their paths to a joblist
> "$joblist"
nskip=0
for confounds in "${derivdir}"/sub-*/ses-*/func/*_task-AARL_confounds_for_feat_*.txt; do
    fname=$(basename "$confounds")
    suffix="${fname#*_confounds_for_feat_}"
    suffix="${suffix%.txt}"

    sub=$(echo "$confounds" | grep -oP 'sub-\d+' | head -1)
    ses=$(echo "$confounds" | grep -oP 'ses-\w+' | head -1)
    funcdir="${derivdir}/${sub}/${ses}/func"
    fsf="${funcdir}/${sub}_${ses}_task-AARL_design_${suffix}.fsf"

    # Render the template in memory first, so we can read fmri(outputdir) and
    # decide whether to skip before writing anything to disk.
    fsf_content=$(sed -e "s|_confounds_for_feat\.txt|_confounds_for_feat_${suffix}.txt|" \
        -e "s|ses-mri00\"|ses-mri00_${suffix}\"|" \
        -e "s/sub-000/${sub}/g" -e "s/ses-mri00/${ses}/g" \
        "$template")

    # FEAT appends .feat to fmri(outputdir) unless the path already ends in .feat
    outputdir=$(printf '%s\n' "$fsf_content" | grep -oP 'set fmri\(outputdir\)\s+"\K[^"]+' | head -1)
    if [ -z "$outputdir" ]; then
        echo "WARNING: could not parse fmri(outputdir) for ${sub} ${ses} (${suffix}) — submitting anyway"
        featdir=""
    else
        featdir="$outputdir"
        [[ "$featdir" == *.feat ]] || featdir="${featdir}.feat"
    fi

    if [ -n "$featdir" ] && [ -d "$featdir" ] && [ -z "$FORCE" ]; then
        echo "Skipping:  $featdir  (already exists)"
        nskip=$((nskip + 1))
        continue
    fi

    echo "Creating: $fsf  (suffix: ${suffix})"
    printf '%s\n' "$fsf_content" > "$fsf"

    echo "$fsf" >> "$joblist"
done

njobs=$(wc -l < "$joblist")
echo "Skipped ${nskip} existing analyses."

if [ "$njobs" -eq 0 ]; then
    echo "Nothing to submit."
    rm -f "$joblist"
    exit 0
fi

echo "Submitting job array with $njobs tasks (joblist: $joblist)"

# Pass 2: submit the whole thing as a single job array
sbatch --job-name="feat_first_level" \
       --array=1-${njobs} \
       --mem=32G \
       --time=24:00:00 \
       --output="${derivdir}/feat_array_%A_%a.log" \
       --wrap="fsf=\$(sed -n \"\${SLURM_ARRAY_TASK_ID}p\" ${joblist}); export FSLPARALLEL=1; feat \$fsf"