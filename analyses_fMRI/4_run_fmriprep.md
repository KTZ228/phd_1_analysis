# Run MRI prep
### Load the right version of fMRIprep
`module load fmriprep/23.2.1`

### Navigate to the project folder to ensure slurm logs end up there
`cd /project/3025011.02/`

### Run fmriprep 
`fmriprep_sub /project/3025011.02/bids --mem_mb 64000 "-cw256" --args " --output-spaces MNI152NLin2009cAsym:res-native" -p x007`
--no-submm-recon"
