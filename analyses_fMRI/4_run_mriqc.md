# Run MRI quality control
### import modules
`module load mriqc/24.0.2`

### Navigate to the project folder to ensure slurm logs end up there
`cd /project/3025011.02/`

### Submit batch jobs to slurm for quality control
#### Subject level
`mriqc_sub /project/3025011.02/bids -a " --no-sub"`

#### Group level
`mriqc_group /project/3025011.02/bids -a " --no-sub"`