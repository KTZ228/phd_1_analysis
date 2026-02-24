function [cfg] = bch_move_beh(cfg)
%--------------------------------------------------------------------------
% BCH_move_func moves all the functional images to their corresponding
% directories (these will be deleted from original directory).
%
% Created by Inge Volman for SPM8 ME wrapper, April 2011
%--------------------------------------------------------------------------

%% create new subject number with subj-xx format

loc = strfind(string(cfg.subj), '-');
subj_nr = str2double(cfg.subj(loc+1:end));

if subj_nr < 10
    subj_name = sprintf('subj0%d', subj_nr);
else
    subj_name = sprintf('subj%d',subj_nr);
end


for ss = 1:length(cfg.sess.names)
%     orig_dir = fullfile(cfg.dir.func,cfg.sess.names{ss},cfg.dir.preproc.work);
    orig_dir = fullfile(cfg.dir.beh,subj_name);
    %beh_dir = fullfile(cfg.dir.func,cfg.sess.names{ss},'behavioural');
    
    beh_dir     = fullfile(cfg.dir.func,cfg.sess.names{ss},cfg.dir.preproc.beh);
    
    if ~exist(beh_dir,'dir');       mkdir(beh_dir); end
    
    
    %fileSearch = sprintf('*subj-%d*',str2double(cfg.subj));
    inputFiles = dir(orig_dir);
    fileNames = {inputFiles.name};
    
    for files = 1:length(fileNames)
        
        thisFileName = fileNames{1,files};
        inputFullFileName = fullfile(orig_dir, thisFileName);
        
        if strcmp({'AA'},fileNames(1,files))
            copyfile(inputFullFileName, fullfile(beh_dir, 'AA'));
        end
        if strcmp({'raw'},fileNames(1,files))
            copyfile(inputFullFileName, fullfile(beh_dir, 'raw'));
        end
    end
   
end
