

addpath /home/common/matlab/fieldtrip/qsub; % for submitting jobs via matlab directly
addpath /project/3025003.01/code/fMRI/batch_spm12;

% run the preprocessing steps on all subject

subjects_list = dir('/project/3025003.01/bids/subject_mfiles/dual-fmri');
subjects = {};

s = 1;
for i = 1:length(subjects_list)
    if strcmp(subjects_list(i).name, '.') || strcmp(subjects_list(i).name, '..')
        continue
    else
        subjects{s} = subjects_list(i).name(1:end-2); % remove the '.m'
        s = s + 1;
    end
end

% run the preprocessing steps on the subjects defined in the variable 'subjects'
jobs = {};
for i = 1:length(subjects)
    jobs{i} = qsubfeval(@bch_spm12, subjects{i}, 'memreq', 30*1024^3, 'timreq', 3*3600);
end

% run the first-level analyses
jobs = {};
for i = 1:length(subjects)
    jobs{i} = qsubfeval(@bch_spm12_1stlevel, subjects{i}, 'memreq', 30*1024^3, 'timreq', 3*3600);
end

save 'jobs.mat' jobs