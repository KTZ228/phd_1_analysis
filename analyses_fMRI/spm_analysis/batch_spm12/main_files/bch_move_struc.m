
function [cfg] = bch_move_struc(cfg)

%--------------------------------------------------------------------------
% BCH_move_struc moves images related to structural to their corresponding
% directories (these will be deleted from the original directory).
%
% Created by Inge Volman for SPM8 ME wrapper, April 2011
%--------------------------------------------------------------------------

work_dir        = cfg.dir.struc;
segment_dir     = fullfile(cfg.dir.struc,cfg.dir.segm);
info_dir        = fullfile(cfg.dir.analysis, cfg.subj, cfg.info.info, '/normalization');

if ~exist(segment_dir,'dir'); mkdir(segment_dir); end
if ~exist(info_dir,'dir'); mkdir(info_dir); end
    
% Move normalization parameters %SPM12
if ~isempty(dir(fullfile(work_dir,'s*_seg8.mat')))
    movefile(fullfile(work_dir,'s*_seg8.mat'),info_dir);
end
if ~isempty(dir(fullfile(work_dir,'y*.nii')))
    movefile(fullfile(work_dir,'y*.nii'),info_dir);
end

if ~isempty(dir(fullfile(work_dir,'ws*.nii')))
    movefile(fullfile(work_dir,'ws*.nii'),segment_dir);
end

% Move segmented structural images in native space
if ~isempty(dir(fullfile(work_dir,'c*.*')))
    movefile(fullfile(work_dir,'c*.*'),segment_dir);
end

% Move segmented structural images in unmodulated normalised space
if ~isempty(dir(fullfile(work_dir,'wc*.*')))
    movefile(fullfile(work_dir,'wc*.*'),segment_dir);
end

% Move segmented structural images in modulated normalised space
if ~isempty(dir(fullfile(work_dir,'mwc*.*')))
    movefile(fullfile(work_dir,'mwc*.*'),segment_dir);
end

if ~isempty(dir(fullfile(work_dir,'wmc*.*')))
    movefile(fullfile(work_dir,'wmc*.*'),segment_dir);
end