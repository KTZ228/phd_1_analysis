#!/bin/bash
#SBATCH --job-name=fit_model_sub
#SBATCH --partition=batch
#SBATCH --array=1-27
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --output=/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_behavioural/modelling/martin_modelling/slurm_output/fit_model_job-%A_subjob-%a.log
#SBATCH --error=/home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_behavioural/modelling/martin_modelling/slurm_output/fit_model_job-%A_subjob-%a_error.txt

source /etc/profile.d/modules.sh
source /home/affneu/kenvdzee/.bashrc
#module load anaconda3
#eval "$(conda shell.bash hook)"
conda activate speakup_hpc

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

subject_ids=(5 10 11 14 15 16 20 22 23)
sessions=(2 3 4)

n_sessions=${#sessions[@]}

# Zero based index for SLURM
index=$(( SLURM_ARRAY_TASK_ID - 1 ))

# pick subject and session by division / modulo
subject_id=${subject_ids[$(( index / n_sessions ))]}
session=${sessions[$(( index % n_sessions ))]}

echo "Fitting model for subject ID: $subject_id and session $session"
python /home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_behavioural/modelling/martin_modelling/fit_models_per_sub.py "$subject_id" "$session"
