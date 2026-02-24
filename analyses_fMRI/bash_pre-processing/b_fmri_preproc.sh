#!/bin/bash
#
# MRI Processing Pipeline
# Combines: BIDScoin → Echo Combine → MRIQC → fMRIprep

# Load more ram into the terminal for echocombine
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --job-name=fmri_preproc

# Run BIDScoin
## Navigate to the project folder
cd /project/3025011.02/

## Activate environment
module add bidscoin/4.5.0

## Run BIDScoin
bidscoiner raw bids

# Run Echo combine
echocombine.py /project/3025011.02/bids 'func/*task-AARL_echo-*'

# Run MRI quality control
## import modules
module load mriqc/24.0.2

## Submit batch jobs to slurm for quality control
### Subject level
mriqc_sub.py /project/3025011.02/bids --no-sub

### Group level, not sure if this has to wait before mriqc_sub finishes
mriqc_group.py /project/3025011.02/bids --no-sub

# Run fMRI prep
## Load the right version of fMRIprep
module load fmriprep/25.2.2

## Run fmriprep 
#fmriprep_sub.py /project/3025011.02/bids --mem_mb 64000 --output-spaces MNI152NLin2009cAsym:res-native --no-submm-recon # Old method, use res-02 for ICA-AROMA and since sub 2mm resolution is not needed for fMRI
fmriprep_sub.py /project/3025011.02/bids --mem_mb 64000 --output-spaces MNI152NLin6Asym:res-02 --no-submm-recon

# Run fMRIPost_AROMA
#module load fmripost-aroma/0.0.12

#cd /home/affneu/kenvdzee/Documents/phd_1_analysis/analyses_fMRI/bash_pre-processing

#python3 c_fmripost_aroma_sub.py /project/3025011.02/bids
