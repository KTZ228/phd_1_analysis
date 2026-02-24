function [cfg] = bch_extract_3D_coherence(cfg)

% Bch_extract_3D extracts 4D nifti's into 3D format, needed for echo
% combination and spike_checking
%
% Written by Saskia Koch, March 2020

smooth_dir = fullfile(cfg.dir.func, '3DSmooth');

img_prefix = ['^','swrf'];

run = cfg_getfile('FPList',smooth_dir,'any',img_prefix);
dt = 0; % set to 0 so that output data type is same as input data type
spm_file_split(run{1});
delete(run{1});