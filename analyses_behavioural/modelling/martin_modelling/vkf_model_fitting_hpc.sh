#!/bin/bash
#SBATCH --job-name=vkf_model_fitting
#SBATCH --partition=batch
#SBATCH --array=1-64
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=16G
#SBATCH --time=24:00:00

source /etc/profile.d/modules.sh
source /home/affneu/kenvdzee/.bashrc
conda activate speakup_hpc

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

subject_ids=(5 10 13 14 15 16 20 22 23 25 27 28 29 30 32 37)
session_numbers=(1 2 3 4)

n_sessions=${#session_numbers[@]}

# Zero based index for SLURM
index=$(( SLURM_ARRAY_TASK_ID - 1 ))

# pick subject and session by division / modulo
subject_id=${subject_ids[$(( index / n_sessions ))]}
session_number=${session_numbers[$(( index % n_sessions ))]}

# Create output directory if it doesn't exist
output_dir="/project/3025011.02/pre-processed/modelling/slurm_output"
mkdir -p "$output_dir"

# Define log and error file paths with subject and session info
log_file="${output_dir}/fit_model_job-${SLURM_ARRAY_JOB_ID}_sub-${subject_id}_ses-${session_number}.log"
error_file="${output_dir}/fit_model_job-${SLURM_ARRAY_JOB_ID}_sub-${subject_id}_ses-${session_number}_error.txt"

# Redirect stdout and stderr to our custom files
exec 1>"$log_file"
exec 2>"$error_file"

echo "Starting python model fitting code for sub-$subject_id and ses-$session_number"
python /home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_behavioural/modelling/martin_modelling/fit_models_per_sub.py "$subject_id" "$session_number"
