#!/bin/bash
# Dispatcher: submits ONE sbatch job per render entry in the Python script.
# Run interactively from a login node (this is not itself an sbatch job):
#
#   bash hpc_animations.sh
#
# It will:
#   1. Ask the Python script which renders are enabled (via --list).
#   2. Submit one Slurm job per render, naming the job after the render
#      and passing the render name to the worker via --export=NAME=...
#
# To re-run only some renders, comment out the relevant entries in the
# RENDERS list inside the Python script (or set 'enabled': False on them),
# then re-run this dispatcher.

set -euo pipefail

PY_SCRIPT="/home/affneu/kenvdzee/Documents/phd_1_analysis/animations/ultrasound_wave_animation.py"
WORKER="/home/affneu/kenvdzee/Documents/phd_1_analysis/animations/hpc_animations_worker.sh"
LOG_DIR="/home/affneu/kenvdzee/Documents/phd_1_analysis/animations/slurm_logs"

mkdir -p "${LOG_DIR}"

# Load the same environment Python will run in, so --list works.
source /etc/profile.d/modules.sh
module load anaconda3
eval "$(conda shell.bash hook)"
conda activate speakup_hpc

# Ask the Python script for the list of enabled renders. One name per line.
mapfile -t RENDERS < <(python -u "${PY_SCRIPT}" --list)

if [[ ${#RENDERS[@]} -eq 0 ]]; then
    echo "ERROR: Python script reported no enabled renders."
    exit 1
fi

echo "Submitting ${#RENDERS[@]} render job(s):"
for name in "${RENDERS[@]}"; do
    echo "  - ${name}"
done
echo ""

for name in "${RENDERS[@]}"; do
    # --job-name puts the render name in squeue / log filenames (%x).
    # --export=NAME=... passes the name into the worker's environment;
    # ALL is included so the rest of the login-shell environment is
    # preserved (conda, modules, PATH).
    jobid=$(sbatch --parsable \
                   --job-name="${name}" \
                   --export=ALL,NAME="${name}" \
                   "${WORKER}")
    echo "  submitted ${name} as job ${jobid}"
done

echo ""
echo "All ${#RENDERS[@]} job(s) submitted. Monitor with:  squeue -u $USER"