#!/bin/bash
#
# Apply spatial smoothing to preprocessed BOLD files as a job array.
shopt -s nullglob

module load fsl/6.0.6
derivdir="/project/3025011.02/bids/derivatives/fmriprep"
fwhm_mm=8  # Smoothing kernel in mm (FWHM)
joblist="${derivdir}/smooth_joblist_$(date +%Y%m%d_%H%M%S).txt"

# Convert FWHM to sigma for fslmaths
sigma=$(echo "$fwhm_mm / 2.355" | bc -l)
echo "Smoothing with FWHM = ${fwhm_mm}mm (sigma = ${sigma}mm)"

# Pass 1: build joblist of (input, output) pairs for files that need smoothing
> "$joblist"
for bold in "${derivdir}"/sub-*/ses-*/func/sub-*_ses-*_task-AARL_space-MNI152NLin6Asym_res-02_desc-preproc_bold.nii.gz; do
    output="${bold%.nii.gz}_smoothed.nii.gz"

    if [ -f "$output" ]; then
        echo "Skipping (already exists): $output"
        continue
    fi

    echo "${bold}	${output}" >> "$joblist"
done

njobs=$(wc -l < "$joblist")
if [ "$njobs" -eq 0 ]; then
    echo "Nothing to smooth."
    exit 0
fi

echo "Submitting job array with $njobs tasks (joblist: $joblist)"

# Pass 2: submit as a single job array
sbatch --job-name="smooth_array" \
       --array=1-${njobs} \
       --mem=16G \
       --time=01:00:00 \
       --output="${derivdir}/smooth_array_%A_%a.log" \
       --wrap="line=\$(sed -n \"\${SLURM_ARRAY_TASK_ID}p\" ${joblist}); bold=\$(echo \"\$line\" | cut -f1); output=\$(echo \"\$line\" | cut -f2); fslmaths \$bold -s ${sigma} \$output"
