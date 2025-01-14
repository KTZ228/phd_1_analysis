# Run MRI quality control
### Load more ram into the terminal first
`srun --pty --mem=64G --time=24:00:00 bash`

### Navigate to the project folder
`cd /project/3025011.02/`

### import modules
`module load mriqc/24.0.2`

### Submit batch jobs to slurm for quality control
#### Subject level
`mriqc_sub /project/3025011.02/bids /project/3025011.02/post_mriqc/sub`

#### Group level
`mriqc_group /project/3025011.02/bids /project/3025011.02/post_mriqc/group`