#!/bin/bash
#SBATCH --job-name=fit_models
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=32:00:00
#SBATCH --output=/home/affneu/marschl/slurm_logs/fit_models-compat-%j.out
#SBATCH --error=/home/affneu/marschl/slurm_logs/fit_models-compat-%j.err

source /etc/profile.d/modules.sh
module load anaconda3
eval "$(conda shell.bash hook)"
conda activate speakup_hpc
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
python fit_models.py
