#!/bin/bash
#
# Generate .fsf files from template and run 3rd level (between-subjects, group
# mean) FEAT analyses as SLURM jobs.
#
# Usage
# -----
#   bash h_feat_third_level.sh                          # include all subjects
#   bash h_feat_third_level.sh -x 55                    # exclude sub-055
#   bash h_feat_third_level.sh -x 55 -x 57              # exclude multiple
#   bash h_feat_third_level.sh --exclude 55 57 60       # ...or all at once
#
# Subject numbers can be given as "55", "055", or "sub-055" — all are
# normalised to sub-055.
#
# Design
# ------
# For each subject, the 2nd level produced a .gfeat containing one cope*.feat
# per 1st-level contrast (e.g. 5 contrasts: cue>baseline, angry>happy,
# approach>avoid, incongruent>congruent, volatile>stable). Each of those
# cope*.feat has an internal stats/ with one cope per 2nd-level contrast
# (session_mean, session_2>3, session_2>4, session_3>4 = 4 internal copes).
#
# The 3rd level runs ONE group analysis PER 1st-level contrast: for contrast C,
# it feeds <subject.gfeat>/copeC.feat as the input for each subject, and takes
# all four 2nd-level copes forward into the group-level one-sample mean. FLAME
# 1 mixed effects, cluster-thresholded Z > 3.1, p < 0.05.
#
# Registration fix
# ----------------
# Because fMRIPrep already put the data in MNI space, the 1st and 2nd levels
# were run with no registration step. To keep FEAT's higher-level pipeline
# happy (featregapply is unconditionally called on each input), this script
# drops dummy identity registration files into every cope*.feat/reg/ directory.
# The fix is idempotent and safe to re-run.
#
# Expected 2nd-level .gfeat directory naming (from f_feat_second_level.sh):
#   ${derivdir}/<sub>/<sub>_second-level.gfeat                  (no suffix)
#   ${derivdir}/<sub>/<sub>_second-level_<suffix>.gfeat         (with suffix)
#
shopt -s nullglob

template="/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_fMRI/fsf_templates/feat_template_third_level.fsf"
derivdir="/project/3025011.02/bids/derivatives/fsl"
groupdir="${derivdir}/group"
skiplog="${groupdir}/feat_third_level_skipped_$(date +%Y%m%d_%H%M%S).txt"

# ---------------------------------------------------------------------------
# Parse command-line arguments: --exclude / -x to drop subjects from the
# analysis. Accepts "55", "055", or "sub-055"; all become "sub-055".
# ---------------------------------------------------------------------------
declare -A excluded_subs=()
while [ $# -gt 0 ]; do
    case "$1" in
        -x|--exclude)
            shift
            # Keep consuming args until the next flag or end of args
            while [ $# -gt 0 ] && [[ "$1" != -* ]]; do
                raw="$1"
                num="${raw#sub-}"               # strip optional sub- prefix
                if ! [[ "$num" =~ ^[0-9]+$ ]]; then
                    echo "ERROR: invalid subject '$raw' for --exclude (expected a number or sub-NNN)"
                    exit 1
                fi
                # Zero-pad to 3 digits so "55" -> "sub-055"
                sub_id=$(printf "sub-%03d" "$num")
                excluded_subs[$sub_id]=1
                shift
            done
            ;;
        -h|--help)
            sed -n '2,30p' "$0"
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument '$1'"
            echo "Usage: $0 [-x|--exclude <subject_number> ...]"
            exit 1
            ;;
    esac
done

if [ "${#excluded_subs[@]}" -gt 0 ]; then
    echo "Excluding subjects: ${!excluded_subs[*]}"
fi

if [ ! -f "$template" ]; then
    echo "Template not found: $template"
    exit 1
fi

if [ -z "${FSLDIR:-}" ]; then
    echo "FSLDIR is not set. Source FSL's environment before running this script."
    exit 1
fi

mkdir -p "$groupdir"
> "$skiplog"

# Log excluded subjects at the top of the skiplog for traceability
if [ "${#excluded_subs[@]}" -gt 0 ]; then
    echo "# Excluded by --exclude flag: ${!excluded_subs[*]}" >> "$skiplog"
fi

# ---------------------------------------------------------------------------
# Helper: add dummy identity registration to a .feat directory. Used for
# every cope*.feat inside each subject's .gfeat.
# Returns 0 on success (or if already fixed), 1 if mean_func is missing.
# ---------------------------------------------------------------------------
apply_reg_fix() {
    local featdir="$1"
    local regdir="${featdir}/reg"

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
    return 0
}

# ---------------------------------------------------------------------------
# Pass 1: collect valid 2nd-level .gfeat dirs grouped by suffix, apply the
# reg fix to every cope*.feat they contain, and record the per-subject set
# of 1st-level-contrast indices that are usable.
# ---------------------------------------------------------------------------
declare -A records_by_suffix=()

for gfeat in "${derivdir}"/sub-*/sub-*_second-level*.gfeat; do
    [ -d "$gfeat" ] || continue

    base=$(basename "$gfeat" .gfeat)
    sub=$(echo "$base" | grep -oP '^sub-\d+')

    # Skip excluded subjects
    if [ -n "${excluded_subs[$sub]:-}" ]; then
        echo "SKIP ${sub} (excluded via --exclude)" | tee -a "$skiplog"
        continue
    fi

    rest="${base#${sub}_second-level}"
    suffix="${rest#_}"

    copes=""
    ok=1
    for copefeat in "${gfeat}"/cope*.feat; do
        [ -d "$copefeat" ] || continue
        cname=$(basename "$copefeat" .feat)
        cidx="${cname#cope}"
        if ! apply_reg_fix "$copefeat"; then
            echo "SKIP ${sub} suffix='${suffix:-<no-suffix>}' (${cname}.feat has no mean_func.nii.gz)" \
                | tee -a "$skiplog"
            ok=0
            break
        fi
        copes+="${cidx} "
    done
    [ "$ok" -eq 1 ] || continue

    if [ -z "$copes" ]; then
        echo "SKIP ${sub} suffix='${suffix:-<no-suffix>}' (no cope*.feat found in .gfeat)" \
            | tee -a "$skiplog"
        continue
    fi

    records_by_suffix[$suffix]+="${sub}|${gfeat}|${copes% }"$'\n'
done

if [ "${#records_by_suffix[@]}" -eq 0 ]; then
    echo "No usable 2nd-level .gfeat directories found under $derivdir — nothing to submit."
    exit 0
fi

# ---------------------------------------------------------------------------
# Helper: inject per-subject blocks + outputdir + N into a fresh .fsf.
#
# Blocks expected by the template:
#   __FEAT_FILES_BLOCK__   one `set feat_files(N) "..."` per subject
#   __EV_BLOCK__           full per-subject EV definitions + evg grid
#                          (separate-means design: one EV per subject)
#   __GROUPMEM_BLOCK__     one `set fmri(groupmem.N) 1` per subject
#   __CON_REAL_BLOCK__     one `set fmri(con_real1.N) 1` per subject
#                          (group-mean contrast: every EV weighted 1)
#   __NSUBJECTS__          scalar, replaced inline
# ---------------------------------------------------------------------------
write_fsf() {
    local tmpl="$1" outdir="$2" n="$3" ff="$4" ev="$5" gm="$6" cr="$7" out="$8"
    awk -v n="$n" -v ff="$ff" -v ev="$ev" -v gm="$gm" -v cr="$cr" '
        {
            if ($0 ~ /__FEAT_FILES_BLOCK__/) { printf "%s", ff; if (substr(ff,length(ff)) != "\n") print ""; next }
            if ($0 ~ /__EV_BLOCK__/)         { printf "%s", ev; if (substr(ev,length(ev)) != "\n") print ""; next }
            if ($0 ~ /__GROUPMEM_BLOCK__/)   { printf "%s", gm; if (substr(gm,length(gm)) != "\n") print ""; next }
            if ($0 ~ /__CON_REAL_BLOCK__/)   { printf "%s", cr; if (substr(cr,length(cr)) != "\n") print ""; next }
            gsub(/__NSUBJECTS__/, n)
            print
        }
    ' "$tmpl" \
    | sed -e "s|^set fmri(outputdir).*|set fmri(outputdir) \"${outdir}\"|" \
    > "$out"
}

# ---------------------------------------------------------------------------
# Pass 2: for each (suffix, 1st-level contrast C), build one .fsf feeding
# each subject's copeC.feat, and submit it.
# ---------------------------------------------------------------------------
submitted=0
for suffix in "${!records_by_suffix[@]}"; do
    mapfile -t recs < <(printf '%s' "${records_by_suffix[$suffix]}")
    subs=()
    gfeats=()
    copesets=()
    for rec in "${recs[@]}"; do
        [ -z "$rec" ] && continue
        IFS='|' read -r s g c <<< "$rec"
        subs+=("$s")
        gfeats+=("$g")
        copesets+=("$c")
    done

    declare -A contrast_count=()
    for c in "${copesets[@]}"; do
        for cidx in $c; do
            contrast_count[$cidx]=$(( ${contrast_count[$cidx]:-0} + 1 ))
        done
    done
    common_contrasts=()
    for cidx in $(printf '%s\n' "${!contrast_count[@]}" | sort -n); do
        if [ "${contrast_count[$cidx]}" -eq "${#subs[@]}" ]; then
            common_contrasts+=("$cidx")
        else
            label="${suffix:-<no-suffix>}"
            echo "NOTE suffix='${label}' cope${cidx} only in ${contrast_count[$cidx]}/${#subs[@]} subjects — skipping this contrast" \
                | tee -a "$skiplog"
        fi
    done
    unset contrast_count

    if [ "${#common_contrasts[@]}" -eq 0 ]; then
        label="${suffix:-<no-suffix>}"
        echo "SKIP suffix='${label}' (no 1st-level contrast present in all subjects)" | tee -a "$skiplog"
        continue
    fi

    if [ "${#subs[@]}" -lt 3 ]; then
        label="${suffix:-<no-suffix>}"
        echo "SKIP suffix='${label}' (only ${#subs[@]} subject(s) — need at least 3 for a group analysis)" \
            | tee -a "$skiplog"
        continue
    fi

    for cidx in "${common_contrasts[@]}"; do
        N=${#subs[@]}
        feat_files_block=""
        ev_block=""
        groupmem_block=""
        con_real_block=""

        for i in "${!subs[@]}"; do
            idx=$((i + 1))
            sub="${subs[$i]}"
            cf="${gfeats[$i]}/cope${cidx}.feat"

            # feat_files line for this subject
            feat_files_block+="set feat_files(${idx}) \"${cf}\""$'\n'

            # groupmem line (all in group 1)
            groupmem_block+="set fmri(groupmem.${idx}) 1"$'\n'

            # con_real1 element for this subject (group-mean => all ones)
            con_real_block+="set fmri(con_real1.${idx}) 1"$'\n'

            # --- Per-subject EV definition (separate-means design) ---
            # Each EV is a unit indicator for one subject: evg{M}.{idx} = 1 iff M==idx.
            ev_block+="# EV ${idx} (subject ${sub})"$'\n'
            ev_block+="set fmri(evtitle${idx}) \"${sub}\""$'\n'
            ev_block+="set fmri(shape${idx}) 2"$'\n'
            ev_block+="set fmri(convolve${idx}) 0"$'\n'
            ev_block+="set fmri(convolve_phase${idx}) 0"$'\n'
            ev_block+="set fmri(tempfilt_yn${idx}) 0"$'\n'
            ev_block+="set fmri(deriv_yn${idx}) 0"$'\n'
            ev_block+="set fmri(custom${idx}) \"dummy\""$'\n'

            # Orthogonalisation flags: ortho{idx}.0 .. ortho{idx}.N = 0
            for (( m=0; m<=N; m++ )); do
                ev_block+="set fmri(ortho${idx}.${m}) 0"$'\n'
            done

            # evg grid row for this EV: for each subject index j, evg{j}.{idx} = 1 iff j==idx
            for (( j=1; j<=N; j++ )); do
                if [ "$j" -eq "$idx" ]; then
                    ev_block+="set fmri(evg${j}.${idx}) 1"$'\n'
                else
                    ev_block+="set fmri(evg${j}.${idx}) 0"$'\n'
                fi
            done
            ev_block+=$'\n'
        done

        if [ -n "$suffix" ]; then
            stem="group_third-level_${suffix}_cope${cidx}"
            label="${suffix} cope${cidx}"
        else
            stem="group_third-level_cope${cidx}"
            label="<no-suffix> cope${cidx}"
        fi
        outdir="${groupdir}/${stem}"
        fsf="${groupdir}/${stem}.fsf"

        echo "Creating: $fsf  (${label}, N=${N})"
        write_fsf "$template" "$outdir" "$N" \
                  "$feat_files_block" "$ev_block" "$groupmem_block" "$con_real_block" "$fsf"

        echo "Submitting group analysis for ${label} (N=${N})"
        sbatch --job-name="feat_third_level_${stem}" \
               --mem=64G \
               --time=24:00:00 \
               --output="${groupdir}/${stem}_%j.log" \
               --wrap="export FSLPARALLEL=1; feat ${fsf}"

        submitted=$((submitted + 1))
    done
done

echo "Submitted ${submitted} group-level job(s)."
if [ -s "$skiplog" ]; then
    echo "Skipped subjects/suffixes logged to: $skiplog"
fi
exit 0
