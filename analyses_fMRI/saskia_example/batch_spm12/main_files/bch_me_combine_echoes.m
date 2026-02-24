function [cfg] = bch_me_combine_echoes(cfg)

% Created by Pieter Buur, April 2008
%
% 20080421 - pre-allocated memory for data object
%
% Adapted by Inge Volman for SPM8 ME wrapper, august 2010


disp('************ COMBINING ECHOES ************')

%session_dir = fullfile(cfg.dir.func,cfg.dir.preproc.work);
session_dir = fullfile(cfg.dir.func);

% load the data
fn = []; nii_info = struct(); data_flag = 1; %data_flag = 0
for ee=1:cfg.me.nechoes
    echo_dir = fullfile(session_dir,[cfg.me.dir_prefix,sprintf('%02d',ee)]);
    [fn,~] = spm_select('ExtList', echo_dir, '^f.*\.img|^f.*\.nii');
   
    tic
    for vv=1:size(fn,1) %until number of volmes in 4D-file
        tmp = nifti(fullfile(echo_dir,fn(vv,:)));

        data(ee,:,vv) = reshape(numeric(tmp.dat),1,prod(tmp.dat.dim));
        
        % getting some info for writing nii files
        if isempty(fieldnames(nii_info))
            nii_info.mat         = tmp.mat;
            nii_info.mat0        = tmp.mat0;
            nii_info.mat_intent  = tmp.mat_intent;
            nii_info.mat0_intent = tmp.mat0_intent;
            nii_info.Intercept   = tmp.dat.scl_inter;
            nii_info.Slope       = tmp.dat.scl_slope;
            nii_info.dim         = tmp.dat.dim(1:3);
        end
        if ~mod(vv,100), disp(sprintf('loaded %d volumes (of %d) after %.0f s',vv,size(fn,1),toc)); end
    end
    disp(sprintf('volumes for echo %d (of %d) loaded',ee,cfg.me.nechoes));
end


[~,nv,nt] = size(data);
dt  = [spm_type('int16') spm_platform('bigend')];

disp(sprintf('loaded data for subject %s', cfg.subj))

% create mask
mask = make_brainmask(data);

% get one example header
%     tmp = read_mefmri_header([session_dir,INFO.me.dir_prefix,'01']);
%     tmp_nii =

% initialize configuration options
tcfg = [];
tcfg.method = cfg.me.combine_method;

% initialize the data structure
dat = [];
dat.signal = [];
dat.echo_t = cfg.me.echotimes;

% allocate space for extracted bold time-series
src = zeros(nv,nt);
avg = zeros(nv,1);

% loop over voxels
for vv=1:nv
    % select part of the data
    dat.signal = squeeze(data(:,vv,:));
    if (mask(vv)==1)
        % extract the source
        src(vv,:) = extractsource(dat,tcfg);
    else
        % crude hack because who knows what kind of data comes out of
        % extractsource but in this case at least the voxels OUTSIDE
        % the mask will look something like a brain ;-)
        src(vv,:) = mean(dat.signal);
    end
end

disp(sprintf('done combining echoes for subject %s', cfg.subj))

% write combined echo data
for vv=1:size(fn,1)
    
    N = nifti;
    fname = fullfile(session_dir,fn(vv,:));
    fname=char(fname);
    echoloc = strfind(fname,'echo');
    appendtext = ['combined_bold' num2str(vv,'%04.f') '.nii'];
    fname = [fname(1:echoloc-1) appendtext]; 
    N.dat = file_array(fname,nii_info.dim,dt,0,nii_info.Slope,nii_info.Intercept);
    N.mat = nii_info.mat;
    N.mat0 = nii_info.mat0;
    N.mat_intent = nii_info.mat_intent;
    N.mat0_intent = nii_info.mat0_intent;
    N.descrip = cfg.me.combine_method;
    create(N);
    N.dat(:,:,:) = reshape(src(:,vv),nii_info.dim);
    
    if ~mod(vv/N.dat.dim(1)/N.dat.dim(2),N.dat.dim(3)), disp('combined slice %d of %d', vv/N.dat.dim(1)/N.dat.dim(2),N.dat.dim(3)); end
end