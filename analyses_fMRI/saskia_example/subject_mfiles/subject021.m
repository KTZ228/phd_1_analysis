%% subject
subj.id             = '21';
subj.sub            = 'sub-021';
subj.gender         = 'male';
subj.group_online   = 'control';
subj.group_tcg      = 'control';

% pair
subj.player1        = 'sub-021';
subj.p1id           = '21';
subj.pair           = '11';

%% main folders
subj.tcgdir         = '/project/3025003.01/bids/';

%% structural
subj.T1             = [subj.tcgdir subj.sub '/ses-mri01/mri/anat/' subj.sub '_ses-mri01_T1w.nii'];
subj.T1_ses         = 'ses-mri01';
subj.R1             = [subj.tcgdir subj.sub '/ses-mri01/mri/anat/' subj.sub '_ses-mri01_inv-1_MP2RAGE.nii']; 
subj.R1_ses         = 'ses-mri01';

%% online study
subj.room           = [subj.tcgdir subj.sub '/ses-online/room000460'];
subj.online         = 1;

%% fieldmaps
subj.fmap           = [subj.tcgdir subj.sub '/ses-mri01/mri/fmap/' ];% for functional scans
subj.ses_fmap       = 'ses-mri01';
subj.fmaprun        = [];
%subj.B1             = % for MP2RAGE (R1)

%% TCG data
subj.tcglog          = [subj.tcgdir subj.player1 '/ses-mri01/beh/t' subj.pair 'p' subj.p1id '_tcg_ASD_scanning.txt'];
%subj.tcgeye         = [subj.tcgdir 'synergy/raw/' subj.sub '/eye/t' subj.pair 'p' subj.id '.asc'];
subj.tcgfmri         = [subj.tcgdir subj.sub '/ses-mri01/mri/func/' ];
subj.tcgrun          = [];
subj.ses_tcg         = 'ses-tcg';

%[subj.tcgdir 'synergy/bids/derivatives/fmri_preproc/' subj.sub '/func/3DSmooth'];
%subj.tcgregr        = [subj.tcgdir 'synergy/bids/derivatives/fmri_preproc/' subj.sub '/info/regressors/'];

%% INFORMATION
