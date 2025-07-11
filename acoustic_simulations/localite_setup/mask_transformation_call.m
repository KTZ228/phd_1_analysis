%% Clear house
clc; clear; close all;

%% Set the subject_name
subject_list = ["sub-030"];

output_location = '/project/3025011.02/localite';
log_location = fullfile(output_location, 'slurm_job_logs');
if ~isfolder(log_location)
    mkdir(log_location);
else 
    rmdir(log_location, 's');
    mkdir(log_location);
end

%% Run through participants
for subject_name = subject_list
	output_location_subject = sprintf('%s/%s', output_location, subject_name);

    freesurfer_call = sprintf('mask_transformation(''%s'')', subject_name);

	temp_slurm_file = tempname(log_location);
    job_name = 'mask_transformation';
    fid = fopen([temp_slurm_file '.sh'], 'w+');
    fprintf(fid, '#!/bin/bash\n');
    fprintf(fid, '#SBATCH --job-name=%s\n', job_name);
    fprintf(fid, '#SBATCH --nodes=1\n');
    fprintf(fid, '#SBATCH --ntasks=1\n');
    fprintf(fid, '#SBATCH --mem=20G\n');
    fprintf(fid, '#SBATCH --time=24:00:00\n');
    fprintf(fid, '#SBATCH --output=%s\n', fullfile(log_location, '%j_freesurfer_output.log'));
    fprintf(fid, '#SBATCH --error=%s\n', fullfile(log_location, '%j_freesurfer_error.log'));
    fprintf(fid, '#SBATCH --chdir=%s\n', pwd);
    fprintf(fid, '\nmodule load matlab/R2024b\n');
    
    % Add environment setup and the segmentation command
    fprintf(fid, 'matlab -nodisplay -nosplash -r "%s; exit;"', freesurfer_call);
    fclose(fid);

    % Create the full command to submit the batch script
    sbatch_call = sprintf('sbatch %s.sh', temp_slurm_file);

    % Submit segmentation job
    fprintf('Running mask segmentation with the command: \n%s\n', sbatch_call);
    [res, out] = system(sbatch_call);
    display(res);
    display(out);
end