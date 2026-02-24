function [cfg] = bch_bids_organize(cfg)
%BCH_BIDS_ORGANIZE Arranges the bids structured files

if cfg.me.medata == true
    nechoes = cfg.me.nechoes;
else nechoes = 1;
end

%% Structural T1-weighted scans
orig_file = cfg.dir.struc;

work_dir = fullfile(cfg.dir.analysis, cfg.subj);
strucFolder = sprintf('%s/', work_dir,cfg.ses.TCG,'mri/anat'); % move structural scan to same session as funcitonal mri images
if ~exist(strucFolder, 'dir'); mkdir(strucFolder); end

copyfile(orig_file, strucFolder)

%% Functional files
orig_dir = cfg.dir.func;

work_dir = fullfile(cfg.dir.analysis, cfg.subj);
funcFolder = sprintf('%s/', work_dir,cfg.ses.TCG,'mri/func');
if ~exist(funcFolder, 'dir'); mkdir(funcFolder); end

for ee = 1:nechoes

    echoFolder = sprintf('%s/E0%d',funcFolder,ee);
    if ~exist(echoFolder, 'dir'); mkdir(echoFolder); end

    % only copies and renames nifti files (ignores .json files)
    fileSearch = sprintf('*echo-%d*',ee);
    inputFiles = dir(fullfile(orig_dir,fileSearch));
    fileNames = {inputFiles.name};

    for fileN = 1:length(inputFiles)

        thisFileName = fileNames{1,fileN};
        inputFullFileName = fullfile(orig_dir,thisFileName);
        outputFullFileName = fullfile(echoFolder,['f',thisFileName]);

        if  contains(thisFileName,'bold.nii')
            if isempty(cfg.run.TCG)
                copyfile(inputFullFileName, outputFullFileName);
            elseif contains(thisFileName, cfg.run.TCG)
                copyfile(inputFullFileName, outputFullFileName);
            end
        end
    end
end

%% repeating the same process for fieldmap files
orig_dir = cfg.dir.fmap;

work_dir = fullfile(cfg.dir.analysis, cfg.subj);
fmapFolder = sprintf('%s/', work_dir,cfg.ses.TCG,'mri/fmap'); % move fieldmap to same session as functional mri images
if ~exist(fmapFolder, 'dir'); mkdir(fmapFolder); end

fileSearch = sprintf('*.nii');
inputFiles = dir(fullfile(orig_dir,fileSearch));
fileNames = {inputFiles.name};

for fileN = 1:length(inputFiles)

    thisFileName = fileNames{1,fileN};
    inputFullFileName = fullfile(orig_dir,thisFileName);
    outputFullFileName = fullfile(fmapFolder,['fieldmap_',thisFileName]);

    if  contains(thisFileName,'magnitude1.nii') || contains(thisFileName,'magnitude2.nii') || contains(thisFileName,'phasediff.nii')
        if isempty(cfg.run.fmap)
            copyfile(inputFullFileName, outputFullFileName);
        elseif contains(thisFileName, cfg.run.fmap)
            copyfile(inputFullFileName, outputFullFileName);
        end
    end
end