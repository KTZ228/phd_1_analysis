function [cfg] = bch_move_jobs(cfg)

%--------------------------------------------------------------------------
% BCH_move_jobs moves all preprocessing jobs to to the job
% directory (these will be deleted from the original directory).
%
% Created by Inge Volman for SPM8 ME wrapper, April 2011
%--------------------------------------------------------------------------
if strcmp(cfg.sess, 'sess_affect') || strcmp(cfg.sess, 'sess_affect1')
     
    orig_dir        = cfg.dir.func;
    jobs_dir     = fullfile(orig_dir,cfg.dir.jobs);
    info_dir     = fullfile(orig_dir,cfg.dir.info);
    if ~exist(jobs_dir,'dir');   mkdir(jobs_dir);    end
    if ~exist(info_dir,'dir');   mkdir(info_dir);    end
    
    % Move jobs
    if ~isempty(dir(fullfile(orig_dir,'realign*.mat')))
        movefile(fullfile(orig_dir,'realign*.mat'),jobs_dir);
    end
    
    if ~isempty(dir(fullfile(orig_dir,'slice*.mat')))
        movefile(fullfile(orig_dir,'slice*.mat'),jobs_dir);
    end
    
    if ~isempty(dir(fullfile(orig_dir,'coreg*.mat')))
        movefile(fullfile(orig_dir,'coreg*.mat'),jobs_dir);
    end
    
    if ~isempty(dir(fullfile(orig_dir,'segment*.mat')))
        movefile(fullfile(orig_dir,'segment*.mat'),jobs_dir);
    end
    
    if ~isempty(dir(fullfile(orig_dir,'norm*.mat')))
        movefile(fullfile(orig_dir,'norm*.mat'),jobs_dir);
    end
    
    if ~isempty(dir(fullfile(orig_dir,'smooth*.mat')))
        movefile(fullfile(orig_dir,'smooth*.mat'),jobs_dir);
    end
    
    % move jpg's with movement info
    if ~isempty(dir(fullfile(orig_dir,'realign*.jpg')))
        movefile(fullfile(orig_dir,'realign*.jpg'),info_dir);
    end
    
    
    
    
end