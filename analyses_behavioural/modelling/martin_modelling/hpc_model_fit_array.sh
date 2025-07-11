#!/bin/bash
#SBATCH --job-name=fit_model_sub
#SBATCH --partition=batch
#SBATCH --array=1-4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --output=/home/affneu/kenvdzee/Documents/phd_1_analysis/analysis_behavioural/modelling/martin_modelling/slurm_output/fit_model_sub_%a_job-%A_log.log
#SBATCH --error=/home/affneu/kenvdzee/Documents/phd_1_analysis/analysis_behavioural/modelling/martin_modelling/slurm_output/fit_model_sub_%a_job-%A_error.out

source /etc/profile.d/modules.sh
module load anaconda3
eval "$(conda shell.bash hook)"
conda activate speakup_hpc

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

subject_ids=(5 10 11 14)
subject_id=${subject_ids[$SLURM_ARRAY_TASK_ID-1]}

echo "Fitting model for subject ID: $subject_id"
python fit_models_per_sub.py $subject_id
