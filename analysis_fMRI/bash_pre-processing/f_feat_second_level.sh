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
# Existing analyses are skipped: if the .gfeat directory that the (subject, suffix)
# combination would write to already exists, no .fsf is written and no array task
# is submitted. Set FORCE=1 to re-run everything regardless (existing directories
# are left untouched; FEAT would create <name>+.gfeat next to them).
#
# Per-subject session-to-target mapping
# -------------------------------------
# Stimulation target was randomised across sessions per subject. The template's
# higher-level EVs are fixed:
#   feat_files(1) -> EV1 "amygdala_stim" (target_1)
#   feat_files(2) -> EV2 "dacc_stim"     (target_2)
#   feat_files(3) -> EV3 "sham_stim"     (target_3)
#
# To wire each subject's actual session up to the right EV slot, this script
# reads a randomisation CSV with header:
#   subject-id;ses-mri02;ses-mri03;ses-mri04
# and rows like:
#   sub-001;target_3;target_1;target_2
# (semicolon-delimited; target_1 = amygdala, target_2 = dacc, target_3 = sham).
#
# So for sub-001, slot 1 (amygdala) gets ses-mri03, slot 2 (dacc) gets ses-mri04,
# and slot 3 (sham) gets ses-mri02. Subjects not listed in the CSV are skipped
# and logged.
#
# The per-subject mapping is reported at the point the .fsf is written, in
# feat_files() slot order, so the log mirrors the .fsf contents directly.
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

module load fsl/6.0.6
template="/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_fMRI/fsf_templates/feat_template_second_level.fsf"
randomisation="/project/3025011.02/TUS_simulations/segmentation_data/dummy_randomisation_list.csv"
derivdir="/project/3025011.02/bids/derivatives/fsl"
sessions=(ses-mri02 ses-mri03 ses-mri04)
joblist="${derivdir}/feat_second_level_joblist_$(date +%Y%m%d_%H%M%S).txt"
skiplog="${derivdir}/feat_second_level_skipped_$(date +%Y%m%d_%H%M%S).txt"

if [ ! -f "$template" ]; then
    echo "Template not found: $template"
    exit 1
fi

if [ ! -f "$randomisation" ]; then
    echo "Randomisation CSV not found: $randomisation"
    exit 1
fi

if [ -z "${FSLDIR:-}" ]; then
    echo "FSLDIR is not set. Source FSL's environment before running this script."
    exit 1
fi

> "$joblist"
> "$skiplog"
nexist=0    # count of (subject, suffix) combinations skipped because output exists

# featdir -> 1 if this run created the identity registration for it. Filled in by
# apply_reg_fix, read back when the .fsf is written so the log can flag which
# inputs were touched.
declare -A reg_fixed=()

# ---------------------------------------------------------------------------
# Load the randomisation CSV into associative arrays.
#   target_to_ses["<sub>|target_N"] -> session string (e.g. "ses-mri03")
#   sub_in_csv["<sub>"]             -> 1 if subject is listed in the CSV
#
# CSV is semicolon-delimited with header:
#   subject-id;ses-mri02;ses-mri03;ses-mri04
# We invert the row so we can look up "which session got target_N for this sub".
# ---------------------------------------------------------------------------
declare -A target_to_ses=()
declare -A sub_in_csv=()

# Read header to map column index -> session name
IFS=';' read -r -a header < <(head -n 1 "$randomisation" | tr -d '\r')
declare -a col_ses=("${header[@]:1}")    # header[0] = "subject-id"; rest = session names

# Parse body. Use process substitution so the populated arrays survive the loop.
while IFS=';' read -r sub_csv t1 t2 t3; do
    [ -z "$sub_csv" ] && continue
    sub_csv="${sub_csv//$'\r'/}"
    targets=("${t1//$'\r'/}" "${t2//$'\r'/}" "${t3//$'\r'/}")
    sub_in_csv["$sub_csv"]=1
    for i in 0 1 2; do
        ses="${col_ses[$i]}"
        target="${targets[$i]}"
        [ -z "$target" ] && continue
        target_to_ses["${sub_csv}|${target}"]="$ses"
    done
done < <(tail -n +2 "$randomisation")

if [ "${#target_to_ses[@]}" -eq 0 ]; then
    echo "ERROR: no rows parsed from $randomisation"
    exit 1
fi

echo "Loaded randomisation for ${#sub_in_csv[@]} subjects from $randomisation"

# ---------------------------------------------------------------------------
# Helper: add dummy identity registration to a 1st-level .feat directory.
# Returns 0 on success (or if already fixed), 1 if the required mean_func
# is missing. Directories fixed by this run are recorded in reg_fixed[] rather
# than logged here, so reporting can happen in feat_files() slot order.
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
    reg_fixed["$featdir"]=1
    return 0
}

# ---------------------------------------------------------------------------
# Pass 1: for each subject, collect all suffixes that have a .feat for ALL
#         three required sessions, then generate a .fsf for each.
# ---------------------------------------------------------------------------
for subdir in "${derivdir}"/sub-*/; do
    sub=$(basename "$subdir")

    # Skip subjects not listed in the randomisation CSV — we don't know how
    # to wire their sessions up to EVs.
    if [ -z "${sub_in_csv[$sub]:-}" ]; then
        echo "SKIP ${sub} (not present in randomisation CSV)" | tee -a "$skiplog"
        continue
    fi

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

    # Resolve target -> session for this subject (slot 1 = amygdala, 2 = dacc, 3 = sham)
    ses_amygdala="${target_to_ses[${sub}|target_1]:-}"
    ses_dacc="${target_to_ses[${sub}|target_2]:-}"
    ses_sham="${target_to_ses[${sub}|target_3]:-}"

    if [ -z "$ses_amygdala" ] || [ -z "$ses_dacc" ] || [ -z "$ses_sham" ]; then
        echo "SKIP ${sub} (incomplete randomisation row: amygdala='${ses_amygdala}' dacc='${ses_dacc}' sham='${ses_sham}')" \
            | tee -a "$skiplog"
        unset seen_count seen_paths
        continue
    fi

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

        # Wire up feat_files() slots according to the randomisation:
        #   slot 1 -> amygdala -> session that got target_1
        #   slot 2 -> dacc     -> session that got target_2
        #   slot 3 -> sham     -> session that got target_3
        feat_amygdala="${seen_paths[${suffix}|${ses_amygdala}]}"
        feat_dacc="${seen_paths[${suffix}|${ses_dacc}]}"
        feat_sham="${seen_paths[${suffix}|${ses_sham}]}"

        if [ -n "$suffix" ]; then
            outdir="${derivdir}/${sub}/${sub}_second-level_${suffix}"
            fsf="${derivdir}/${sub}/${sub}_second-level_${suffix}.fsf"
            label="$suffix"
        else
            outdir="${derivdir}/${sub}/${sub}_second-level"
            fsf="${derivdir}/${sub}/${sub}_second-level.fsf"
            label="<no-suffix>"
        fi

        # A higher-level FEAT analysis writes to <outputdir>.gfeat (unless the
        # path already ends in .gfeat). If that directory is already there, this
        # combination has been run before — don't write a .fsf, don't submit.
        gfeatdir="$outdir"
        [[ "$gfeatdir" == *.gfeat ]] || gfeatdir="${gfeatdir}.gfeat"

        if [ -d "$gfeatdir" ] && [ -z "$FORCE" ]; then
            echo "Skipping: ${gfeatdir} (already exists)"
            echo "SKIP ${sub} suffix='${label}' (output already exists: ${gfeatdir})" >> "$skiplog"
            nexist=$(( nexist + 1 ))
            continue
        fi

        # Report the mapping in feat_files() slot order, mirroring the .fsf that
        # is about to be written. Inputs whose identity registration was created
        # during this run are flagged.
        echo "Creating: $fsf  (sub: ${sub}, suffix: ${label})"
        slot=1
        for entry in "amygdala|${ses_amygdala}|${feat_amygdala}" \
                     "dacc|${ses_dacc}|${feat_dacc}" \
                     "sham|${ses_sham}|${feat_sham}"; do
            IFS='|' read -r tname tses tpath <<< "$entry"
            printf '  feat_files(%d) %-8s <- %-10s %s%s\n' \
                "$slot" "$tname" "$tses" "$tpath" \
                "${reg_fixed[$tpath]:+  [identity reg added]}"
            slot=$(( slot + 1 ))
        done

        # Substitute output dir, the three feat_files() entries, and any
        # remaining sub-000 / ses-mri00 placeholders. The template's
        # feat_files() lines are matched by their index, not by their old
        # path content, so a stale hardcoded path in the template is fine.
        sed -e "s|^set fmri(outputdir).*|set fmri(outputdir) \"${outdir}\"|" \
            -e "s|^set feat_files(1).*|set feat_files(1) \"${feat_amygdala}\"|" \
            -e "s|^set feat_files(2).*|set feat_files(2) \"${feat_dacc}\"|" \
            -e "s|^set feat_files(3).*|set feat_files(3) \"${feat_sham}\"|" \
            -e "s/sub-000/${sub}/g" \
            "$template" > "$fsf"

        echo "$fsf" >> "$joblist"
    done

    unset seen_count seen_paths
done

njobs=$(wc -l < "$joblist")
echo "Applied identity registration to ${#reg_fixed[@]} 1st-level FEAT directories."
echo "Skipped ${nexist} (subject, suffix) combinations with existing output."

if [ "$njobs" -eq 0 ]; then
    echo "Nothing to submit."
    echo "See $skiplog for details on skipped combinations."
    rm -f "$joblist"
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