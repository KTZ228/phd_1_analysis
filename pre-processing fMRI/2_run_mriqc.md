# Run MRI quality control
### import modules
`module load mri_qc/24.0.2`

### Submit batch jobs to slurm for quality control
#### Subject level
`mriqc_sub /project/3025011.02/bids -r slurm`

#### Group level
`mriqc_group /project/3025011.02/bids -r slurm`