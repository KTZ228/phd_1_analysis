#!/bin/bash
#
# Generate .fsf files from template and run 2nd level (within-subject, across-session)
# FEAT analyses as a job array.
#
# For every subject, this script discovers all 1st-level FEAT directories across
# sessions 2, 3 and 4, groups them by their suffix, and only schedules a 2nd-level
# analysis for a (subject, suffix) combination when all THREE sessions have a
# matching .feat directory. Subjects/suffixes missing any session are skipped
# and reported.
#
# Since 1st-level data is already in MNI space (from fMRIPrep), this script
# also drops a dummy identity registration into each 1st-level .feat/reg/
# directory so that FEAT's higher-level pipeline (which unconditionally calls
# featregapply) doesn't fail. This fix is idempotent and safe to re-run.
#
# Expected 1st-level FEAT directory naming (from e_feat_first_level.sh):
#   ${derivdir}/<sub>/<ses>/func/<sub>_<ses>.feat                  (no suffix)
#   ${derivdir}/<sub>/<ses>/func/<sub>_<ses>_<suffix>.feat         (with suffix)
#
shopt -s nullglob

template="/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_fMRI/fsf_templates/feat_template_second_level.fsf"
derivdir="/project/3025011.02/bids/derivatives/fsl/old"
sessions=(ses-mri02 ses-mri03 ses-mri04)
joblist="${derivdir}/feat_second_level_joblist_$(date +%Y%m%d_%H%M%S).txt"
skiplog="${derivdir}/feat_second_level_skipped_$(date +%Y%m%d_%H%M%S).txt"

if [ ! -f "$template" ]; then
    echo "Template not found: $template"
    exit 1
fi

if [ -z "${FSLDIR:-}" ]; then
    echo "FSLDIR is not set. Source FSL's environment before running this script."
    exit 1
fi

> "$joblist"
> "$skiplog"

# ---------------------------------------------------------------------------
# Helper: add dummy identity registration to a 1st-level .feat directory.
# Returns 0 on success (or if already fixed), 1 if the required mean_func
# is missing.
# ---------------------------------------------------------------------------
apply_reg_fix() {
    local featdir="$1"
    local regdir="${featdir}/reg"

    # Idempotent: skip if already fixed
    if [ -f "${regdir}/example_func2standard.mat" ] && [ -f "${regdir}/standard.nii.gz" ]; then
        return 0
    fi

    if [ ! -f "${featdir}/mean_func.nii.gz" ]; then
        return 1
    fi

    mkdir -p "$regdir"
    cp "${FSLDIR}/etc/flirtsch/ident.mat" "${regdir}/example_func2standard.mat"
    cp "${FSLDIR}/etc/flirtsch/ident.mat" "${regdir}/standard2example_func.mat"
    cp "${featdir}/mean_func.nii.gz" "${regdir}/standard.nii.gz"
    echo "  Fixed registration: $featdir"
    return 0
}

# ---------------------------------------------------------------------------
# Pass 1: for each subject, collect all suffixes that have a .feat for ALL
#         three required sessions, then generate a .fsf for each.
# ---------------------------------------------------------------------------
for subdir in "${derivdir}"/sub-*/; do
    sub=$(basename "$subdir")

    # Build a per-subject set of suffixes seen in each required session.
    # Suffix "" (empty) represents the no-suffix case.
    declare -A seen_count=()    # suffix -> number of sessions it appears in
    declare -A seen_paths=()    # "${suffix}|${ses}" -> full .feat path

    for ses in "${sessions[@]}"; do
        funcdir="${derivdir}/${sub}/${ses}/func"
        [ -d "$funcdir" ] || continue

        for featdir in "${funcdir}/${sub}_${ses}"*.feat; do
            [ -d "$featdir" ] || continue
            base=$(basename "$featdir" .feat)        # e.g. sub-001_ses-mri02_most-rewarding
            rest="${base#${sub}_${ses}}"             # "" or "_most-rewarding"
            suffix="${rest#_}"                       # strip leading underscore -> "" or "most-rewarding"

            key="${suffix}|${ses}"
            # Only process each (suffix, ses) pair once even if duplicates exist
            if [ -z "${seen_paths[$key]:-}" ]; then
                # Apply the identity-registration fix. If it fails (no mean_func),
                # skip this .feat entirely so we don't submit a doomed job.
                if ! apply_reg_fix "$featdir"; then
                    echo "SKIP ${sub} ${ses} '${base}.feat' (no mean_func.nii.gz — 1st level incomplete?)" \
                        | tee -a "$skiplog"
                    continue
                fi

                seen_paths[$key]="$featdir"
                seen_count[$suffix]=$(( ${seen_count[$suffix]:-0} + 1 ))
            fi
        done
    done

    # For each suffix that appears in all 3 sessions, generate the .fsf.
    # Also report any suffix that fell short.
    for suffix in "${!seen_count[@]}"; do
        if [ "${seen_count[$suffix]}" -ne "${#sessions[@]}" ]; then
            label="${suffix:-<no-suffix>}"
            present=""
            for ses in "${sessions[@]}"; do
                if [ -n "${seen_paths[${suffix}|${ses}]:-}" ]; then
                    present+=" ${ses}"
                fi
            done
            echo "SKIP ${sub} suffix='${label}' (only present in:${present})" | tee -a "$skiplog"
            continue
        fi

        feat_ses2="${seen_paths[${suffix}|${sessions[0]}]}"
        feat_ses3="${seen_paths[${suffix}|${sessions[1]}]}"
        feat_ses4="${seen_paths[${suffix}|${sessions[2]}]}"

        if [ -n "$suffix" ]; then
            outdir="${derivdir}/${sub}/${sub}_second-level_${suffix}"
            fsf="${derivdir}/${sub}/${sub}_second-level_${suffix}.fsf"
            label="$suffix"
        else
            outdir="${derivdir}/${sub}/${sub}_second-level"
            fsf="${derivdir}/${sub}/${sub}_second-level.fsf"
            label="<no-suffix>"
        fi

        echo "Creating: $fsf  (sub: ${sub}, suffix: ${label})"

        # Substitute output dir, the three feat_files() entries, and any
        # remaining sub-000 / ses-mri00 placeholders. The template's
        # feat_files() lines are matched by their index, not by their old
        # path content, so a stale hardcoded path in the template is fine.
        sed -e "s|^set fmri(outputdir).*|set fmri(outputdir) \"${outdir}\"|" \
            -e "s|^set feat_files(1).*|set feat_files(1) \"${feat_ses2}\"|" \
            -e "s|^set feat_files(2).*|set feat_files(2) \"${feat_ses3}\"|" \
            -e "s|^set feat_files(3).*|set feat_files(3) \"${feat_ses4}\"|" \
            -e "s/sub-000/${sub}/g" \
            "$template" > "$fsf"

        echo "$fsf" >> "$joblist"
    done

    unset seen_count seen_paths
done

njobs=$(wc -l < "$joblist")
if [ "$njobs" -eq 0 ]; then
    echo "No (subject, suffix) combinations had all 3 sessions present — nothing to submit."
    echo "See $skiplog for details on skipped combinations."
    exit 0
fi

echo "Submitting job array with $njobs tasks (joblist: $joblist)"
[ -s "$skiplog" ] && echo "Skipped combinations logged to: $skiplog"

# ---------------------------------------------------------------------------
# Pass 2: submit the whole thing as a single job array
# ---------------------------------------------------------------------------
sbatch --job-name="feat_second_level" \
       --array=1-${njobs} \
       --mem=64G \
       --time=24:00:00 \
       --output="${derivdir}/feat_second_level_array_%A_%a.log" \
       --wrap="fsf=\$(sed -n \"\${SLURM_ARRAY_TASK_ID}p\" ${joblist}); export FSLPARALLEL=0; feat \$fsf"