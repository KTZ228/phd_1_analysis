function comp_signal(CINFO)
%--------------------------------------------------------------------------
% COMP_SIGNAL creates regressors with mean signal intensity values for each
% segmented compartment [WhiteMatter (WM), CerebralSpinalFluid (CSF) and
% Out-of-Brain (OOB)] separately for each image. The resulting three
% regressors are saved in a mat file (structure: [WM CSF OOB]). These
% regressors can be used similarly to head motion regressors. Where the
% later can account for head motion effects, the compartment signal
% regressors can be used to account for global signal noise due to changes
% in the magnetic field over time (due to the movement of a conductive body
% - like an arm or hand - through the magnetic field) or other nuisance
% factors. Compartment signals are preferred over global signals as
% inclusion of the later might induce fake BOLD deactivations and a
% reduction in power. The compartment signals do not contain GreyMatter (so
% also no BOLD response) and therefore do not suffer from these ill
% effects.
%
% When using these regressors, you could cite my HBM abstract:
%   Verhagen L, Grol MJ, Dijkerman HC, Toni I. (2006) Studying visually-
%       guided reach to grasp movements in an MR-environment. Human Brain
%       Mapping.
%
% or cite my research paper which describes the methods superficially:
%   Verhagen L, Dijkerman HC, Grol MJ, Toni I (2008) Perceptuo-motor
%       interactions during prehension movements. J Neurosci 28(18):4726-4735 
%
% or wait for the upcoming mehtods paper (a little patience required):
%   Verhagen L, Grol MJ, Dijkerman HC, Toni I. Studying visually-guided
%       reach to grasp movements in an MR-environment. Manuscript in
%       preparation.
%
% FORMAT:   comp_signal(CINFO);
% INPUT:    CINFO       - An structure containing the following fields:
%           imgs        - An array of images to get the compartment signal
%                         of the White Matter (WM), Cerebral Spinal Fluid
%                         (CSF) and Out-of-Brain area (OOB) from.
%           dir.ref     - The directory where the reference for the
%                         segmentation can be found. This is either the mean
%                         or the structural image.
%           dir.segm    - The directory where the segmented images can be found.
%           dir.info    - The directory where the .mat files will be saved.
%           subj        - string containing the subject name. Only used to
%                         give the .mat file and figures the correct name.
%           prefix.img  - string containing the image prefix. Only used to
%                         indicate if .img or .nii files are used.
%           prefix.regr - string containing the output prefix. Only used to
%                         give the .mat file the correct name.
%           OOBmax      - the method to determine the maximum value in the
%                         Out of Brain mask: 1) the 'median', 2) the 'mean'
%                         or 3) the 'max' value of the residual image left
%                         over by the GM, WM and CSF masks.
%           thres.WM    - the threshold of the WM probability mask
%                         (between 0 and 1)
%           thres.CSF   - the threshold of the CSF probability mask
%                         (between 0 and 1)
%           thres.OOB   - the threshold of the OOB probability mask
%                         (between 0 and 1)
%
% created by Lennart Verhagen, 2005-01-25
% L.Verhagen@fcdonders.ru.nl
% adapted to SPM5, 2006-02-02
% version 2008-06-26
%--------------------------------------------------------------------------

pwd_orig = pwd;

%% Sort input and collect using spm_select.m if necessary
%----------------------------------------------------

% prefixes
if isfield(CINFO,'prefix')
    if ~isfield(CINFO.prefix,'img')
        CINFO.prefix.img = '.*\.nii';
    end
    if ~isfield(CINFO.prefix,'regr')
        CINFO.prefix.regr = 'regr';
    end
else
    CINFO.prefix.img = '.*\.nii';
    CINFO.prefix.regr = 'regr';
end

% functional images
if ~isfield(CINFO,'imgs')
    [CINFO.imgs,CINFO.dir.img,fname] = get_dataset(CINFO.prefix.img);
else
    [CINFO.dir.img fname] = fileparts(CINFO.imgs(1,:));
end

% subject name
if ~isfield(CINFO,'imgs')
    if strncmp(fname,'s',1); fname = fname(2:end); end
    if strncmp(fname,'w',1); fname = fname(2:end); end
    if strncmp(fname,'a',1); fname = fname(2:end); end
    if strncmp(fname,'r',1); fname = fname(2:end); end
    char_nr = max(strfind(fname,'_'))-1;
    CINFO.subj = fname(1:char_nr);
end

% reference image, segmented images and info directories
if ~isfield(CINFO.dir,'ref')
    CINFO.dir.ref = get_refdir(CINFO.subj);
end
if ~isfield(CINFO.dir,'segm')
    CINFO.dir.segm = get_segmdir(CINFO.subj);
end
if ~isfield(CINFO.dir,'info')
    CINFO.dir.info = get_infodir(CINFO.subj);
end

% preferences
if ~isfield(CINFO,'OOBmax')
    CINFO.OOBmax = 'median';
end
if isfield(CINFO,'thres')
    if ~isfield(CINFO.thres,'WM')
        CINFO.thres.WM = 0.5;
    end
    if ~isfield(CINFO.thres,'CSF')
        CINFO.thres.CSF = 0.5;
    end
    if ~isfield(CINFO.thres,'OOB')
        if ~isempty(strfind(CINFO.dir.ref,'str'))
            CINFO.thres.OOB = 0.25;
        else
            CINFO.thres.OOB = 0.5;
        end
    end
else
    CINFO.thres.WM = 0.5;
    CINFO.thres.CSF = 0.5;
    if ~isempty(strfind(CINFO.dir.ref,'str'))
        CINFO.thres.OOB = 0.25;
    else
        CINFO.thres.OOB = 0.5;
    end
end

% comment this line if you don't want to have all those spm progress bars
spm_input(CINFO.subj,'+1','d!','subject')


%% Get compartments and create "Out of Brain" area
%----------------------------------------------------
% Segment the meanEPI into GreyMatter (GM), WhiteMatter (WM), 
% CerebralSpinalFluid (CSF) and Out-Of-Brain (OOB)
CINFO = get_compartments(CINFO);


%% Calculate mean signal of respective compartments
%----------------------------------------------------
% Mask all your EPIs with the segmentations created earlier and calculate
% the different signals over scans.
fprintf('\n   Loading the selected files...');
V = spm_vol(CINFO.imgs);
fprintf(' done');
WM_signal = signal_calc(V,CINFO.compimgs.WM,CINFO.thres.WM,'WM');
CSF_signal = signal_calc(V,CINFO.compimgs.CSF,CINFO.thres.CSF,'CSF');
OOB_signal = signal_calc(V,CINFO.compimgs.OOB,CINFO.thres.OOB,'OOB');


%% Save segment signal regressors
%----------------------------------------------------
% sig = [WM_signal CSF_signal OOB_signal];
% if ~exist(CINFO.dir.info,'dir'); mkdir(CINFO.dir.info); end
% save(fullfile(CINFO.dir.info,[CINFO.prefix.regr,'_sig_',CINFO.subj]),'sig');
% spm('CreateIntWin','off');
% cd(pwd_orig);


sig = [WM_signal CSF_signal OOB_signal];
if ~exist(CINFO.dir.regr,'dir'); mkdir(CINFO.dir.regr); end

if strcmp(CINFO.subj, 'sub-149') || strcmp(CINFO.subj, 'sub-150')
    sig(1:37,:) = []; % remove first 37 volumes for these participants
end

save(fullfile(CINFO.dir.regr,[CINFO.prefix.regr,'_sig_',CINFO.subj]),'sig');
spm('CreateIntWin','off');
cd(pwd_orig);
%==========================================================================



%% Function - get_compartments
%----------------------------------------------------
function CINFO = get_compartments(CINFO)

% I used to prefer the modulated images, now I changed my mind and do not
% use them anymore.
% pfixs = {'rmw','rwm','rw','mw','wm','w',''};  
% rfixs = {'rwm','rwm','rw','wm','wm','w',''};

% Give preference to reslided images, then normalized, then modulated.
pfixs = {'rw','rmw','rwm','w','mw','wm',''};
rfixs = {'rw','rwm','rwm','w','wm','wm',''};

%In SPM12, c3 is GM, c2 is WM,and c1 is CSF
for i = 1:length(pfixs)
    if ~isempty(dir(fullfile(CINFO.dir.segm,[pfixs{i} 'c1*'])))
        GM = fullfile(CINFO.dir.segm,spm_select('List',CINFO.dir.segm,['^',pfixs{i},'c1',CINFO.prefix.img]));
        pfix = pfixs{i}; rfix = rfixs{i};
        break;
    end
end
if ~exist('GM','var')
    GM = spm_select(Inf,'image',['Select the gray matter segment of ',CINFO.subj]);
end

WM  = strrep(GM,[pfix 'c1'],[pfix 'c2']); 
if exist(WM,'file')~=2
    WM = spm_select(Inf,'image',['Select the white matter segment of ',CINFO.subj]);
end

CSF = strrep(GM,[pfix 'c1'],[pfix 'c3']); 
if exist(CSF,'file')~=2
    CSF = spm_select(Inf,'image',['Select the cerebral spinal fluid segment of ',CINFO.subj]);
end

OOB = strrep(GM,[pfix 'c1'],[pfix 'c4']);

% If the OOB-image is created later than the GM, WM and CSF images it is
% assumed to be up to date and accurate so no new image is created.
do_OOB = true;
if exist(OOB,'file')
    GM_file = dir(GM);
    WM_file = dir(WM);
    CSF_file = dir(CSF);
    OOB_file = dir(OOB);
    if datenum(OOB_file(1).date) >= datenum(GM_file(1).date) && ...
       datenum(OOB_file(1).date) >= datenum(WM_file(1).date) && ...
       datenum(OOB_file(1).date) >= datenum(CSF_file(1).date)
        do_OOB = false;
    end   
end

% if no up to date OOB-image could be found, a new one is created.
if do_OOB
    fprintf('\n   Creating Out-of-Brain mask from the mean image...');
    ref_image = strrep(GM,[pfix 'c1'],rfix);
    ref_image = strrep(ref_image,CINFO.dir.segm,CINFO.dir.ref);
    
    % If a unmodulated normalised image is requested, but does not exist,
    % try a modulated normalised image.
    if exist(ref_image,'file')~=2 && strcmpi(rfix,'w')
        ref_image = strrep(GM,[pfix 'c1'],'wm');
        ref_image = strrep(ref_image,CINFO.dir.segm,CINFO.dir.ref);
    end
    
    % If the modularisation and the normalisation are done in reverse order
    % for the reference image, switch the rfix.
    if exist(ref_image,'file')~=2 && (strcmpi(rfix,'wm') || strcmpi(rfix,'mw'))
        ref_image = strrep(GM,[pfix 'c1'],rfix([2 1]));
        ref_image = strrep(ref_image,CINFO.dir.segm,CINFO.dir.ref);
    end
    
    % If a resliced image is requested, but does not exist, try a
    % non-reslided image.
    if exist(ref_image,'file')~=2 && strcmpi(rfix(1),'r')
        ref_image = strrep(GM,[pfix 'c1'],rfix(2:end));
        ref_image = strrep(ref_image,CINFO.dir.segm,CINFO.dir.ref);
    end
    
    % Okay, I give up.
    if exist(ref_image,'file')~=2
        ref_image = spm_select(Inf,'image',['Select the reference (mean or structural) image  of ',CINFO.subj]);
    end
    
    % Reslice if the reference and GM images do not have equal dimensions.
    V = spm_vol(GM);
    Vref = spm_vol(ref_image);
    if ~isequal(V.mat,Vref.mat)
        voxdim = spm_imatrix(V.mat);
        voxdim = voxdim(7:9);
        ref_image = resize_img(ref_image,voxdim,world_bb(V));
    end
    
    CINFO.compimgs.ref = ref_image;
    CINFO.compimgs.GM = GM;
    CINFO.compimgs.WM = WM;
    CINFO.compimgs.CSF = CSF;
    CINFO.compimgs.OOB = OOB;
    
    create_OOB(CINFO);
    fprintf(' done');
else
    fprintf('\n   Up to date Out-of-Brain mask already exists');
end

% If the reference images are not in the same space as the functional
% images (for instance, when the reference images are based on structural
% images) they are first resliced to map directly onto the functional
% images.
V = spm_vol(CINFO.imgs(1,:));
Q = [GM;WM;CSF;OOB];
Vcomp = spm_vol(Q);
if ~isequal(V(1).mat,Vcomp(1).mat)
    fprintf('\n   Resizing the compartments to the functional images...');
    voxdim = spm_imatrix(V(1).mat);
    voxdim = voxdim(7:9);
    rcomp = resize_img(Q,voxdim,world_bb(V(1)));
    GM = rcomp(1,:);
    WM = rcomp(2,:);
    CSF = rcomp(3,:);
    OOB = rcomp(4,:);
    fprintf(' done');
end

CINFO.compimgs.GM = GM;
CINFO.compimgs.WM = WM;
CINFO.compimgs.CSF = CSF;
CINFO.compimgs.OOB = OOB;
%==========================================================================


%% Function - create_OOB
%----------------------------------------------------
function create_OOB(CINFO)

% select voxels where the reference image is not GM, WM, nor CSF.
[OOB_dir, OOB_file, OOB_ext] = fileparts(CINFO.compimgs.OOB);
imcalc = struct( ...
    'input', {{CINFO.compimgs.ref; CINFO.compimgs.GM; CINFO.compimgs.WM; CINFO.compimgs.CSF}}, ...
    'output', [OOB_file OOB_ext], ...
    'outdir', {{OOB_dir}}, ...
    'expression', 'i1.*( (i2==0) & (i3==0) & (i4==0) )', ...
    'options', struct( ...
        'dmtx', 0, ...
        'mask', 0, ...
        'interp', 2, ...
        'dtype', 4));
    
jobs{1}.util{1}.imcalc = imcalc;
spm_jobman('run',jobs);

% calculate maximum allowed value (median of all intensities)
V = spm_vol(CINFO.compimgs.OOB);
%[n,x,t] = histvol(V,100);
t = [];
for z = 1:V.dim(3)
    img = spm_slice_vol(V,spm_matrix([0 0 z]),V.dim(1:2),0);
    msk = find(isfinite(img) & img~=0);
	t   = [t reshape(img(msk),1,numel(img(msk)))];
end

switch lower(CINFO.OOBmax)
    case 'median'
        OOB_max = median(t);
    case 'mean'
        OOB_max = mean(t);
    case 'max'
        OOB_max = max(t);
end

% invert the image (lower intensity means greater probability that the
% voxel is OOB) and select only voxels above zero and below the OOB_max
imcalc = struct( ...
    'input', {{CINFO.compimgs.OOB}}, ...
    'output', [OOB_file OOB_ext], ...
    'outdir', {{OOB_dir}}, ...
    'expression', sprintf('(1-(i1./%d)).*(i1<%d & i1>0)',OOB_max,OOB_max), ...
    'options', struct( ...
        'dmtx', 0, ...
        'mask', 0, ...
        'interp', 2, ...
        'dtype', 4));
    
jobs{1}.util{1}.imcalc = imcalc;
spm_jobman('run',jobs);
%==========================================================================


%% Function - signal_calc
%----------------------------------------------------
function sig = signal_calc(V,mask,thres,maskname)
% Integrate the values in an segmented image.
if nargin < 4
    maskname = 'compartment';
end    
    
fprintf('\n   %s: Calculating signal per image...',maskname);

% saving thresholded mask image
[mask_dir, mask_file, mask_ext] = fileparts(mask);
imcalc = struct( ...
    'input', {{mask}}, ...
    'output', [maskname '_thresholded_mask' mask_ext], ...
    'outdir', {{mask_dir}}, ...
    'expression', sprintf('i1>%0.2f',thres), ...
    'options', struct( ...
        'dmtx', 0, ...
        'mask', 0, ...
        'interp', 2, ...
        'dtype', 4));
    
jobs{1}.util{1}.imcalc = imcalc;
spm_jobman('run',jobs);

fprintf(' done');

Vmask = spm_vol(mask);

fprintf('\n   %s: Calculating signal per image...',maskname);

f = sprintf('img.*(mask>%0.2f);',thres);

sig = zeros(length(V),1);
vox = zeros(length(V),1);
spm_progress_bar('Init',length(sig),'calc signal','images completed');
fprintf('\n1    ');
for i = 1:length(sig)
    for z = 1:V(i).dim(3)
        img   = spm_slice_vol(V(i),...
            spm_matrix([0 0 z]),V(i).dim(1:2),0);
        mask = spm_slice_vol(Vmask,...
            spm_matrix([0 0 z]),Vmask.dim(1:2),0);
        img = eval(f);
        sig(i) = sig(i) + sum(img(:));
        vox(i) = vox(i) + sum(length(find(img(:)>0)));
    end
    %sig(i) = sig(i)/prod(V(i).dim(1:3));
    sig(i) = sig(i)/vox(i);
    spm_progress_bar('Set',i);
    fprintf('.');
    if rem(i,50)==0
        fprintf('\n');
        fprintf('%d ',i);
        if i < 10; fprintf(' '); end
        if i < 100; fprintf(' '); end
        if i < 1000; fprintf(' '); end
    end
end
spm_progress_bar('Clear');
fprintf('\n');

%==========================================================================



%% Function - get_dataset
%----------------------------------------------------
function [imgs,img_dir,fname] = get_dataset(prefix)
fprintf('\n   Selecting the images...');

prefix = ['^w',prefix];
imgs = cellstr(spm_select(Inf,'image','Select images...','',pwd,prefix));
for i = 1:length(imgs)
    imgs{i} = imgs{i}(1:end-2);
end
[img_dir fname] = fileparts(imgs{1});
imgs = char(imgs);

cd(img_dir);
fprintf(' done');
%==========================================================================


%% Function - get_infodir
%----------------------------------------------------
function info_dir = get_infodir(subject_name)
fprintf('\n   Selecting the destination directory...');
info_dir = spm_select(1,'dir',['Select the destination directory of ',subject_name]);
fprintf(' done');
%==========================================================================


%% Function - get_refdir
%----------------------------------------------------
function ref_dir = get_refdir(subject_name)
fprintf('\n   Selecting the reference image (mean or struct) directory...');
ref_dir = spm_select(1,'dir',['Select reference image (mean or struct) directory of ',subject_name]);
fprintf(' done');
%==========================================================================


%% Function - get_segmdir
%----------------------------------------------------
function segm_dir = get_segmdir(subject_name)
fprintf('\n   Selecting the segmented images directory...');
segm_dir = spm_select(1,'dir',['Select segmented images directory of ',subject_name]);
fprintf(' done');
%==========================================================================