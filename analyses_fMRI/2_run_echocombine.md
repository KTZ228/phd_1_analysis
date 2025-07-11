# Run BIDScoin
### Load more ram into the terminal first
`srun --pty --mem=64G --time=24:00:00 bash`

### Navigate to the project folder to ensure slurm logs end up there
`cd /project/3025011.02/`

### Activate environment
`module add bidscoin`
`source activate /opt/bidscoin`

### Combine BOLD echos
`echocombine.py bids 'func/*task-AARL_echo-*' -p x013`
`echocombine.py bids 'func/*task-AARL_echo-*'`