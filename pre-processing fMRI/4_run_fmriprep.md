# Run MRI prep
### Navigate to the project folder
`cd /project/3025011.02/`

### import modules
`module load fmriprep/23.2.1`

### Run fmriprep 
`fmriprep_sub.py /project/3025011.02/bids -r slurm --mem_mb 64000 -a " --output-spaces MNI152NLin2009cAsym:res-native"`