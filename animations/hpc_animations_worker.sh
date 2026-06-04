#!/bin/bash
# Per-render Slurm worker. Submitted once per RENDERS entry by the
# dispatcher script. The render name is passed in via --export=NAME=...
#
# Direct submission of a single render (without the dispatcher):
#   sbatch --export=NAME=transducer_flat hpc_animations_worker.sh
#
#SBATCH --job-name=TUS_anim
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=256G
#SBATCH --time=72:00:00
#SBATCH --output=/home/affneu/kenvdzee/Documents/phd_1_analysis/animations/slurm_logs/TUS_anim-%x-%j.log
#SBATCH --error=/home/affneu/kenvdzee/Documents/phd_1_analysis/animations/slurm_logs/TUS_anim-%x-%j.error

set -euo pipefail

if [[ -z "${NAME:-}" ]]; then
    echo "ERROR: NAME environment variable not set."
    echo "Use: sbatch --export=NAME=<render_name> --job-name=<render_name> $0"
    exit 1
fi

echo "=== Slurm worker starting ==="
echo "host:       $(hostname)"
echo "job id:     ${SLURM_JOB_ID:-(not set)}"
echo "render:     ${NAME}"
echo "start time: $(date -Is)"
echo ""

source /etc/profile.d/modules.sh

# Set up conda on the compute node. Order of attempts:
#   1. Source the known-good conda.sh directly (works regardless of
#      whether `module load anaconda3` is functional).
#   2. Fall back to `module load anaconda3` then derive the path
#      from `which conda`, in case the install moves.
KNOWN_CONDA_SH="/opt/anaconda3/2024.06/etc/profile.d/conda.sh"

if [[ -f "${KNOWN_CONDA_SH}" ]]; then
    # shellcheck disable=SC1090
    source "${KNOWN_CONDA_SH}"
    echo "sourced conda from: ${KNOWN_CONDA_SH}"
else
    echo "known path ${KNOWN_CONDA_SH} not present; falling back to 'module load anaconda3'"
    module load anaconda3 || echo "module load failed"
    echo "PATH after module load: ${PATH}"
    if command -v conda &>/dev/null; then
        conda_root="$(dirname "$(dirname "$(which conda)")")"
        conda_sh="${conda_root}/etc/profile.d/conda.sh"
        if [[ -f "${conda_sh}" ]]; then
            # shellcheck disable=SC1090
            source "${conda_sh}"
            echo "sourced conda from: ${conda_sh}"
        else
            echo "ERROR: conda binary at $(which conda) but no conda.sh at ${conda_sh}" >&2
            exit 1
        fi
    else
        echo "ERROR: conda not on PATH" >&2
        echo "Run 'which conda' on a login node and update KNOWN_CONDA_SH in this script." >&2
        exit 1
    fi
fi

conda activate speakup_hpc

python -u /home/affneu/kenvdzee/Documents/phd_1_analysis/animations/ultrasound_wave_animation.py \
    --name "${NAME}"

echo ""
echo "=== finished at $(date -Is) ==="
