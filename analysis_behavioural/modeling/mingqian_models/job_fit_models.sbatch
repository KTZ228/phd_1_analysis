#!/usr/bin/env bash
# Submit all models with:
#   sbatch --array=0-13 job_fit_models.sbatch
# Submit one model with:
#   sbatch job_fit_models.sbatch rw_transfer

#SBATCH --job-name=fit_stan
#SBATCH --time=72:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=80G
#SBATCH --output=log/%x_%A_%a.out
#SBATCH --error=log/%x_%A_%a.err
#SBATCH --export=ALL

set -euo pipefail

MODELS=(
  rw_sep
  rw_transfer
  rw_transfer_dual_lr
  vkf_bias_intercept
  vkf_bias_lambda
  vkf_bias_intercept_ddm_drift_cue
  vkf_bias_intercept_ddm_start_cue
  vkf_bias_intercept_ddm_drift_start_cue
  vkf_bias_scale
  vkf_transfer_1
  vkf_transfer_2
  vkf_transfer_3
  vkf_transfer_4
  vkf_transfer_5
)

# SLURM copies a batch file to its spool directory before execution. Prefer the
# original submission directory so outputs never resolve under /var/spool.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="${WORKDIR:-${SLURM_SUBMIT_DIR:-$SCRIPT_DIR}}"
OUTDIR="${OUTDIR:-$WORKDIR/fit_result}"
# Conda paths are hardcoded to this cluster (values from `conda info --base`
# and `conda env list` on the login node). Activation must succeed or the job
# aborts -- no silent fallback to a system Python that lacks CmdStanPy.
# Override at submit time only if the cluster layout changes, e.g.:
#   CONDA_ENV=/path/to/other-env sbatch job_fit_models.sbatch rw_transfer
CONDA_BASE="${CONDA_BASE:-/opt/anaconda3/2024.06}"
CONDA_ENV="${CONDA_ENV:-/home/affneu/kenvdzee/.conda/envs/stan-fit}"

if [[ -z "${PYTHON_BIN:-}" ]]; then
  CONDA_SH="$CONDA_BASE/etc/profile.d/conda.sh"

  if [[ ! -f "$CONDA_SH" ]]; then
    echo "ERROR: conda.sh not found at: $CONDA_SH" >&2
    echo "Re-check 'conda info --base' on the login node and update CONDA_BASE." >&2
    exit 1
  fi

  if [[ ! -d "$CONDA_ENV" ]]; then
    echo "ERROR: Conda environment directory not found: $CONDA_ENV" >&2
    echo "Re-check 'conda env list' on the login node and update CONDA_ENV." >&2
    echo "If /home is not mounted on this compute node, that is the cause." >&2
    exit 1
  fi

  # Conda's activation scripts read unset variables, which trips `set -u`.
  set +u
  source "$CONDA_SH"
  conda activate "$CONDA_ENV" || {
    set -u
    echo "ERROR: failed to activate Conda environment: $CONDA_ENV" >&2
    exit 1
  }
  set -u

  PYTHON_BIN="$CONDA_PREFIX/bin/python"
fi

if [[ ! -x "$PYTHON_BIN" ]]; then
  echo "ERROR: Python executable not found or not executable: $PYTHON_BIN" >&2
  exit 1
fi
RUNNER="$WORKDIR/python_script/run_fit_models.py"

if [[ $# -ge 1 ]]; then
  MODEL="$1"
elif [[ -n "${SLURM_ARRAY_TASK_ID:-}" ]]; then
  MODEL="${MODELS[$SLURM_ARRAY_TASK_ID]}"
else
  echo "Provide a model name or submit as an array job (0-$(( ${#MODELS[@]} - 1 )))." >&2
  exit 2
fi

if [[ ! " ${MODELS[*]} " =~ " ${MODEL} " ]]; then
  echo "Unknown model: ${MODEL}" >&2
  printf 'Known models: %s\n' "${MODELS[*]}" >&2
  exit 2
fi

mkdir -p "$OUTDIR"

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"
export OPENBLAS_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"
export MKL_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"
export MPLCONFIGDIR="${MPLCONFIGDIR:-$OUTDIR/.matplotlib}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$OUTDIR/.cache}"
mkdir -p "$MPLCONFIGDIR" "$XDG_CACHE_HOME"

echo "Requested Conda env: $CONDA_ENV"
echo "Active Conda prefix: ${CONDA_PREFIX:-not set}"
echo "Python executable: $PYTHON_BIN"
"$PYTHON_BIN" -c '
import sys
import arviz, cmdstanpy, matplotlib, seaborn
print("Python:", sys.executable)
print("arviz:", arviz.__version__)
print("cmdstanpy:", cmdstanpy.__version__)
print("matplotlib:", matplotlib.__version__)
print("seaborn:", seaborn.__version__)
'

"$PYTHON_BIN" -u "$RUNNER" \
  --workdir "$WORKDIR" \
  --pkl stan_fit.pkl \
  --model "$MODEL" \
  --chains 2 \
  --parallel-chains 2 \
  --iter-warmup 5500 \
  --iter-sampling 5000 \
  --outdir "$OUTDIR" \
  --one-step-ahead \
  --clean-tmp
