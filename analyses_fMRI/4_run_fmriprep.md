# Run fMRI prep
### Load the right version of fMRIprep
`module load fmriprep/25.2.2`

### Navigate to the project folder to ensure slurm logs end up there
`cd /project/3025011.02/`

### Run fmriprep 
`fmriprep_sub.py /project/3025011.02/bids --mem_mb 64000 --args " --output-spaces MNI152NLin2009cAsym:res-native"`
