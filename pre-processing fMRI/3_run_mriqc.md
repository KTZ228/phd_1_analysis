# Run MRI quality control
### Navigate to the project folder
`cd /project/3025011.02/`

### import modules
`module load mriqc/24.0.2`

### Submit batch jobs to slurm for quality control
#### Subject level
`mriqc_sub /project/3025011.02/bids -r slurm`

#### Group level
`mriqc_group /project/3025011.02/bids -r slurm`