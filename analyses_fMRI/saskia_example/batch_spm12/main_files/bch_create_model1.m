function [cfg] = bch_create_model1(cfg)

% Open SPM8 and select 1st level specification.
% Do not change anything and save this as 'model1_spec' in cfg.dir.root.
% More information on this can be found in the SPM8 tutorial.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% setting up the batch configuration
spm('defaults','fmri');
spm_jobman('initcfg');

% load basic matlab batch of SPM12
load(fullfile(cfg.bch.root,cfg.preproc));

% fill in name subject/func directory
func_dir = cfg.dir.func;

matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_named_dir.dirs = {func_dir};

model_dir = fullfile(cfg.dir.preproc, cfg.subj, 'ses-tcg/mri/first_level_half');
if ~exist(model_dir,'dir'); mkdir(model_dir);end

matlabbatch{1}.spm.stats.fmri_spec.dir = {model_dir};

matlabbatch{1}.spm.stats.fmri_spec.timing.RT = cfg.TR;

matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = cfg.micro_res;

matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = cfg.micro_ons;

matlabbatch{1}.spm.stats.fmri_spec.mthresh = cfg.mthresh; %added RK

matlabbatch{1}.spm.stats.fmri_spec.mask    = cfg.expmask; %added RK

try
    tm = matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond.tmod;
catch
    tm = 0;
end

direc_func = fullfile(cfg.dir.func);
direc_info = fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg/mri',cfg.dir.regr);

img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];
run = cfg_getfile('FPList',direc_func,'any',img_prefix);
run = spm_select('expand', run);
matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = run;

load(fullfile(direc_info,[cfg.prefix.cond,'_tcg_',cfg.subj]));

for r = 1:length(names)
    cond(r).name = names{r};
    cond(r).onset = onsets{r};
    cond(r).duration = durations{r};
end

matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond = cond;
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {''}; 

load(fullfile(direc_info,[cfg.prefix.regr,'_',cfg.subj]));

matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress = regressors;
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {''};
matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = 128;

fname = [cfg.preproc '_' cfg.subj '.mat'];
cfg.jobname = fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg/mri',cfg.dir.batch,fname);
save(fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg/mri',cfg.dir.batch,fname), 'matlabbatch');

        %     if exist('tmod','var')
%         cond(r).tmod = tmod{r};
%     else
%         cond(r).tmod = tm;
%     end
% 
%     if r < 5
%         %cond(r).tmod = tmod{r};
% 
%         cond(r).pmod(1).name = pmod{r}.name;
%         cond(r).pmod(1).param = pmod{r}.param;
%         cond(r).pmod(1).poly = pmod{r}.poly;
%         cond(r).pmod(1).name = pmod(r).name{1};
%         cond(r).pmod(1).param = pmod(r).param{1};
%         cond(r).pmod(1).poly = pmod(r).poly{1};
%         cond(r).pmod(2).name = pmod(r).name{2};
%         cond(r).pmod(2).param = pmod(r).param{2};
% %         cond(r).pmod(2).poly = pmod(r).poly{2};
%     end