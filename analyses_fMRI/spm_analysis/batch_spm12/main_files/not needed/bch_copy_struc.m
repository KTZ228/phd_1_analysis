function [cfg] = bch_copy_struc(cfg)
%--------------------------------------------------------------------------
% BCH_COPY_STRUC copies the structural from its original folder
% (struc/orig) to the main structural folder (struc).
% 
% Adapted by Vaibhav Arya. Janurary 2020.
% Copies the files from sub/struc to sub/struc/work

%pwd_orig = pwd;

disp('************ COPYING Structural ************')


%orig_dir = fullfile(cfg.dir.struc,cfg.dir.struc_orig);
orig_dir = fullfile(cfg.dir.struc,'orig');
work_dir = fullfile(cfg.dir.struc,'work');

if ~exist(work_dir, 'dir'); mkdir(work_dir); end

fileSearch = sprintf('*T1*');
inputFiles = dir(fullfile(orig_dir,fileSearch));
fileNames = {inputFiles.name};

for fileN = 1:length(inputFiles)
    
    thisFileName = fileNames{1,fileN};
    inputFullFileName = fullfile(orig_dir, thisFileName);
    
    if contains(thisFileName,'T1w.nii')
        outputBaseFileName = sprintf('s_%s', thisFileName);
        outputFullFileName = fullfile(work_dir, outputBaseFileName);
        copyfile(inputFullFileName, outputFullFileName);
        %spm_file_split(outputFullFileName,strucFolder);
    end

end
%cd(pwd_orig);
