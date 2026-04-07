#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
The fmripost_aroma_sub utility is a wrapper around fmripost-aroma that queries the fMRIPrep
derivatives directory for preprocessed participants and then runs them (as single-participant
fmripost-aroma jobs) on the compute cluster.

fMRIPost-AROMA requires that fMRIPrep was run with --output-spaces MNI152NLin6Asym:res-02.
It performs ICA-AROMA denoising on the preprocessed BOLD data and produces denoised outputs
along with mixing matrices and noise component classifications.
"""

import os
import shutil
import subprocess
import argparse
import textwrap
import shlex
from pathlib import Path

CONTAINER = '/opt/fmripost-aroma/0.0.12/fmripost-aroma-0.0.12.sif'


def main(bidsdir: str, derivdir: str, outputdir: str, workroot: str, subject_label=(), force=False, mem_mb=10000, walltime=8, file_gb_=50, nthreads=None, denoising=('nonaggr',), argstr='', qargstr='', dryrun=False, skip=True):

    # Defaults
    bidsdir   = Path(bidsdir)
    derivdir  = Path(derivdir)
    outputdir = Path(outputdir)
    if not derivdir.name:
        derivdir = bidsdir/'derivatives'/'fmriprep'
    if not outputdir.name:
        outputdir = bidsdir/'derivatives'/'fmripost-aroma'
    if not nthreads:
        nthreads = min(8, max(1, round(mem_mb / 10000)))    # Allocating ~10GB / CPU core
    manager = 'slurm' if 'slurm' in os.getenv('PATH') else 'torque'

    # Check that the fMRIPrep derivatives directory exists
    if not derivdir.is_dir():
        print(f"ERROR: fMRIPrep derivatives directory does not exist: {derivdir}")
        return

    # Map the subject directories from the fMRIPrep derivatives
    if not subject_label:
        sub_dirs = sorted(derivdir.glob('sub-*'))
        sub_dirs = [d for d in sub_dirs if d.is_dir()]
    else:
        sub_dirs = [derivdir/('sub-' + label.replace('sub-','')) for label in subject_label]

    # Loop over the subject directories and submit a job for every (new) subject
    for n, sub_dir in enumerate(sub_dirs, 1):

        if not sub_dir.is_dir():
            print(f">>> Directory does not exist: {sub_dir}")
            continue

        # Check if the subject has BOLD data in MNI152NLin6Asym space
        sub_id    = sub_dir.name
        bold_mni  = list(sub_dir.rglob('*space-MNI152NLin6Asym*_bold.nii*'))
        if not bold_mni:
            print(f">>> No MNI152NLin6Asym BOLD files found for {sub_id}. Was fMRIPrep run with --output-spaces MNI152NLin6Asym:res-02?")
            continue

        # Define a (clean) subject specific work directory and allocate space there
        file_gb = ''                # By default, we don't need to allocate local scratch space
        if not workroot:
            workdir = Path('\\$TMPDIR')/sub_id
            if manager == 'torque':
                file_gb = f",file={file_gb_}gb"
            elif manager == 'slurm':
                file_gb = f"--tmp={file_gb_}G"
        else:
            workdir = Path(workroot)/sub_id

        # A subject is considered already done if there is an html-report in the output directory
        report = outputdir/(sub_id + '.html')
        if force or not report.is_file():

            # Start with a clean directory if we are forcing to reprocess the data
            if not dryrun:
                if force and workdir.is_dir():
                    shutil.rmtree(workdir, ignore_errors=True)
                if force and report.is_file():
                    report.unlink()

            # Generate the submit-command
            if manager == 'torque':
                submit  = f"qsub -l nodes=1:ppn={nthreads},walltime={walltime}:00:00,mem={mem_mb}mb{file_gb} -N aromapost_{sub_id} {qargstr}"
                running = subprocess.run('if [ ! -z "$(qselect -s RQH)" ]; then qstat -f $(qselect -s RQH) | grep Job_Name | grep aromapost_; fi', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            elif manager == 'slurm':
                submit  = f"sbatch --job-name=aromapost_{sub_id} --mem={mem_mb} --time={walltime}:00:00 --ntasks=1 --cpus-per-task={nthreads} {file_gb} {qargstr}"
                running = subprocess.run('squeue -u $USER -o format=%j | grep aromapost_', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            else:
                print(f"ERROR: Invalid resource manager `{manager}`")
                exit(1)

            # Build the denoising-method argument
            denoise_arg = '--denoising-method ' + ' '.join(denoising) if denoising else ''

            # Generate the fmripost-aroma job
            job = textwrap.dedent('''\
                #!/bin/bash
                {sleep}
                ulimit -v unlimited
                echo using: TMPDIR=\\$TMPDIR
                cd {pwd}
                {fmripost_aroma} {bidsdir} {outputdir} participant -w {workdir} --participant-label {sub_id} -d fmriprep={derivdir} {denoise_arg} --mem {mem_mb} --omp-nthreads {nthreads} --nprocs {nthreads} {args}'''
                .format(pwd              = Path.cwd(),
                        sleep            = 'sleep 1m' if n>1 else '',
                        fmripost_aroma   = f'apptainer run --cleanenv --bind \\$TMPDIR:/tmp,\\$TMPDIR:/var/tmp {CONTAINER}',
                        bidsdir          = bidsdir,
                        outputdir        = outputdir,
                        workdir          = workdir,
                        sub_id           = sub_id[4:],
                        derivdir         = derivdir,
                        denoise_arg      = denoise_arg,
                        nthreads         = nthreads,
                        mem_mb           = mem_mb,
                        args             = argstr))

            # Submit the job to the compute cluster
            command = f"{submit} <<EOF\n{job}\nEOF\n"
            if skip and f'aromapost_{sub_id}' in running.stdout:
                print(f">>> Skipping already running/scheduled job ({n}/{len(sub_dirs)}): aromapost_{sub_id}")
            else:
                print(f">>> Submitting job ({n}/{len(sub_dirs)}):\n{command}")
                if not dryrun:
                    process = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    if process.returncode != 0:
                        print(f"ERROR {process.returncode}: Job submission failed\n{process.stderr}\n{process.stdout}")

        else:
            print(f">>> Nothing to do for job ({n}/{len(sub_dirs)}): {sub_dir} (--> {report})")

    if not sub_dirs:
        print(f"No sub-folders found in {derivdir}")
    elif dryrun:
        print('\n----------------\nDone! NB: The printed jobs were not actually submitted')
    else:
        print('\n----------------\n'
              'Done! Now wait for the jobs to finish... Check that e.g. with this command:\n\n'
             f"  {'qstat -a $(qselect -s RQ)' if manager=='torque' else 'squeue -u '+os.getenv('USER')} -o %j | grep aromapost_\n\n"
              'When finished, the AROMA-denoised BOLD images and component classifications\n'
             f'will be available in: {outputdir}\n')


# Shell usage
if __name__ == "__main__":

    # Parse the input arguments and run main(args)
    class CustomFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter):
        pass

    parser = argparse.ArgumentParser(formatter_class=CustomFormatter, description=textwrap.dedent(__doc__),
                                     epilog='Any unrecognized options are forwarded directly to fmripost-aroma\n\n'
                                            'for more information see:\n'
                                            '  fmripost_aroma -h\n'
                                            '  https://fmripost-aroma.readthedocs.io\n\n'
                                            'examples:\n'
                                            '  fmripost_aroma_sub.py /project/3017065.01/bids\n'
                                            '  fmripost_aroma_sub.py /project/3017065.01/bids -e /project/3017065.01/bids/derivatives/fmriprep\n'
                                            '  fmripost_aroma_sub.py /project/3017065.01/bids -o /project/3017065.01/derivatives/fmripost-aroma\n'
                                            '  fmripost_aroma_sub.py /project/3017065.01/bids -p sub-P010 sub-P018\n'
                                            '  fmripost_aroma_sub.py /project/3017065.01/bids --denoising-method aggr nonaggr\n'
                                            '  fmripost_aroma_sub.py -f -m 16000 /project/3017065.01/bids\n\n'
                                            'author:\n'
                                            '  Marcel Zwiers\n ')
    parser.add_argument('bidsdir',                  help='The bids-directory with the raw subject data')
    parser.add_argument('-e','--derivdir',          help='The fMRIPrep derivatives directory (default = bidsdir/derivatives/fmriprep)', default='')
    parser.add_argument('-o','--outputdir',         help='The output-directory where the fmripost-aroma output is stored (default = bidsdir/derivatives/fmripost-aroma)', default='')
    parser.add_argument('-w','--workdir',           help='The working-directory where intermediate files are stored (default = a temporary directory)', default='')
    parser.add_argument('-p','--participant_label', help='Space separated list of sub-# identifiers to be processed (the sub- prefix can be removed). Otherwise all sub-folders in the derivatives directory will be processed', nargs='+')
    parser.add_argument('-f','--force',             help='If this flag is given subjects will be processed, regardless of existing output. Otherwise existing output will be skipped', action='store_true')
    parser.add_argument('-i','--ignore',            help='If this flag is given then already running or scheduled jobs with the same name are ignored, otherwise job submission is skipped', action='store_false')
    parser.add_argument('-m','--mem_mb',            help='Required amount of memory (in MB)', default=10000, type=int)
    parser.add_argument('-n','--nthreads',          help='Number of compute threads (CPU cores) per job (subject)', choices=range(1,9), type=int)
    parser.add_argument('-t','--time',              help='Required walltime (in hours)', default=8, type=int)
    parser.add_argument('-s','--scratch_gb',        help='Required free diskspace of the local temporary workdir (in GB)', default=50, type=int)
    parser.add_argument('-q','--qargs',             help='Additional arguments that are passed to qsub/sbatch (NB: Use quotes and include at least one space character to prevent overearly parsing)', type=str, default='')
    parser.add_argument('-d','--dryrun',            help='Add this flag to just print the fmripost-aroma commands without actually submitting them (useful for debugging)', action='store_true')
    parser.add_argument('--denoising-method',       help='Denoising method(s) to apply', nargs='+', choices=('aggr', 'nonaggr', 'orthaggr'), default=['nonaggr'])

    # Parse only what we know
    args, passthrough = parser.parse_known_args()

    main(bidsdir       = args.bidsdir,
         derivdir      = args.derivdir,
         outputdir     = args.outputdir,
         workroot      = args.workdir,
         subject_label = args.participant_label,
         force         = args.force,
         mem_mb        = args.mem_mb,
         walltime      = args.time,
         nthreads      = args.nthreads,
         file_gb_      = args.scratch_gb,
         denoising     = args.denoising_method,
         argstr        = " ".join(shlex.quote(a) for a in passthrough),
         qargstr       = args.qargs,
         dryrun        = args.dryrun,
         skip          = args.ignore)
