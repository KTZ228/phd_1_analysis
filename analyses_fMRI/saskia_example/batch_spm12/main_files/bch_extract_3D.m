function [cfg] = bch_extract_3D(cfg)

% Bch_extract_3D extracts 4D nifti's into 3D format, needed for echo
% combination and spike_checking
%
% Written by Saskia Koch, March 2020

direc= fullfile(cfg.dir.func);

img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];

for ee = 1:cfg.me.nechoes
    
    echo_dir = fullfile(direc,[cfg.me.dir_prefix,sprintf('%02d',ee)]);
    run = cfg_getfile('FPList',echo_dir,'any',img_prefix);
    dt = 0; % set to 0 so that output data type is same as input data type
    spm_file_split(run{1});
    delete(run{1});
      
end