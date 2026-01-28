#!/bin/bash
#
# MRI Processing Pipeline
# Combines: BIDScoin → Echo Combine → MRIQC → fMRIprep

# Run BIDScoin
## Navigate to the project folder
cd /project/3025011.02/

## Activate environment
module add bidscoin/4.5.0

## Run BIDScoin
bidscoiner raw bids

# Run Echo combine
## Load more ram into the terminal first
srun --pty --mem=64G --time=24:00:00 bash

## Then run echocombine itself
echocombine.py bids 'func/*task-AARL_echo-*'

## Navigate to the project folder
cd /project/3025011.02/

## Activate environment
module add bidscoin/4.5.0

# Run MRI quality control
## import modules
module load mriqc/24.0.2

## Submit batch jobs to slurm for quality control
### Subject level
mriqc_sub /project/3025011.02/bids -a " --no-sub"

### Group level, not sure if this has to wait before mriqc_sub finishes
mriqc_group /project/3025011.02/bids -a " --no-sub"

# Run fMRI prep
## Load the right version of fMRIprep
module load fmriprep/25.2.2

## Run fmriprep 
fmriprep_sub.py /project/3025011.02/bids --mem_mb 64000 --args " --output-spaces MNI152NLin2009cAsym:res-native --no-submm-recon"