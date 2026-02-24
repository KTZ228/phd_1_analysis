function [cfg] = bch_check_motion(cfg)
%--------------------------------------------------------------------------
% BCH_CHECK_MOTION loads the realignment parameters from the 'rp_*.txt'
% file. From those vectors a few parameters are calculated, plotted and
% saved for each session and if applicable also over all sessions combined.
%
%   11. Maximum translation relative to minimum translation (mm)
%       a.  Along the XYZ-axes separately
%       b.  In Euclidian distance (real distance, XYZ-axes combined)
%   12. Maximum translation relative to first scan of session (mm)
%       a.  XYZ-axes separately
%       b.  Euclidian distance
%   13. Maximum translation relative to prior scan (mm)
%       a.  XYZ-axes separately
%       b.  Euclidian distance
%   14. Mean translation per scan (mm/scan)
%       a.  XYZ-axes separately
%       b.  Euclidian distance
%   For session number 2 and higher
%   15. Translation between the last scan of the prior session and the
%       first scan of the current session (mm)
%       a.  XYZ-axes separately
%       b.  Euclidian distance
%
%   21. Maximum rotation relative to minimum rotation (deg*1000)
%       a.  pitch, roll and jaw separately
%       b.  Euclidian rotation
%   22. Maximum rotation relative to first scan of session (deg*1000)
%       a.  pitch, roll and jaw separately
%       b.  Euclidian rotation
%   23. Maximum rotation relative to prior scan (deg*1000)
%       a.  pitch, roll and jaw separately
%       b.  Euclidian rotation
%   24. Mean rotation per scan ((deg*1000)/scan)
%       a.  pitch, roll and jaw separately
%       b.  Euclidian rotation
%   For session number 2 and higher
%   25. Rotation between the last scan of the prior session and the
%       first scan of the current session (deg*1000)
%       a.  pitch, roll and jaw separately
%       b.  Euclidian rotation
%
% created by Lennart Verhagen, march-2006
% L.Verhagen@fcdonders.ru.nl
% version 2007-11-14
%
%--------------------------------------------------------------------------

pwd_orig = pwd;

subj = cfg.subj;

mov_dir = fullfile(cfg.dir.preproc, cfg.subj,'ses-tcg/mri',cfg.dir.mov);

% clear the files before starting
print_str{1} = '';
print_str{2} = '';

motionfile = dir(fullfile(mov_dir,'rp_*.txt'));
fid = fopen(fullfile(mov_dir,motionfile(1).name),'r');
rp = fscanf(fid,' %e %e %e %e %e %e',[6,inf])';
fclose(fid);

regr_dir = fullfile(cfg.dir.preproc, cfg.subj, 'ses-tcg/mri', cfg.dir.regr);
if ~exist(regr_dir,'dir'); mkdir(regr_dir); end

% save rp in .mat file
if strcmp(subj, 'sub-149') || strcmp(subj,'sub-150')
    rp(1:37,:)= []; % remove first 37 volumes
end

save(fullfile(regr_dir,[cfg.prefix.regr,'_rp_',subj]),'rp');

    % loop over the two types of head motion: translation and rotation
for t = 1:2
    
    if t == 1
        p = rp(:,1:3);
    elseif t == 2
        p = rp(:,4:6);
    end
    
    % calculate the parameters
    pr = repmat(p(1,:),size(p,1),1);
    pA = p(1:end-1,:);
    pB = p(2:end,:);
    pf = sqrt( sum ( (p-pr).^2, 2) );
    pp = sqrt( sum ( (pB-pA).^2, 2) );
    
    % axes separately
    max_min{t}{1}   = max(p)-min(p);
    max_first{t}{1} = max(abs(p-pr));
    max_prior{t}{1} = max(abs(pB-pA));
    mean_scan{t}{1} = mean(abs(pB-pA));
    
    % Euclidian distance / rotation
    max_first{t}{2} = max(pf);
    max_prior{t}{2} = max(pp);
    mean_scan{t}{2} = mean(pp);
    
    str = '';
    str = [str sprintf('\nHead Motion report - Subject %s',subj)];
    
    % Translation
    if t == 1
        str = [str sprintf('\n\n    Translation:')];
        str = [str sprintf('\n\tMaximum - relative to minimum (mm):')];
        str = [str sprintf('\n\t\tXYZ:\t%0.2f  %0.2f  %0.2f',max_min{t}{1})];
        str = [str sprintf('\n\t\tEuclid:\t%0.2f (same as relative to first scan)',max_first{t}{2})];
        str = [str sprintf('\n\tMaximum - relative to first scan (mm):')];
        str = [str sprintf('\n\t\tXYZ:\t%0.2f  %0.2f  %0.2f',max_first{t}{1})];
        str = [str sprintf('\n\t\tEuclid:\t%0.2f',max_first{t}{2})];
        str = [str sprintf('\n\tMaximum - relative to prior scan (mm):')];
        str = [str sprintf('\n\t\tXYZ:\t%0.2f  %0.2f  %0.2f',max_prior{t}{1})];
        str = [str sprintf('\n\t\tEuclid:\t%0.2f',max_prior{t}{2})];
        str = [str sprintf('\n\tMean - per scan (mm/scan):')];
        str = [str sprintf('\n\t\tXYZ:\t%0.2f  %0.2f  %0.2f',mean_scan{t}{1})];
        str = [str sprintf('\n\t\tEuclid:\t%0.2f',mean_scan{t}{2})];

        % save report
        fid = fopen(fullfile(mov_dir,sprintf('check_head_motion_translation_%s.txt',subj)),'a');
        fprintf(fid,str);
        fclose(fid);
        
   % Rotation
    elseif t == 2
        str = [str sprintf('\n\n    Rotation:')];
        str = [str sprintf('\n\tMaximum - relative to minimum (deg*1000):')];
        str = [str sprintf('\n\t\tPRY:\t%0.2f  %0.2f  %0.2f',max_min{t}{1}*1000)];
        str = [str sprintf('\n\t\tEuclid:\t%0.2f (same as relative to first scan)',max_first{t}{2}*1000)];
        str = [str sprintf('\n\tMaximum - relative to first scan (deg*1000):')];
        str = [str sprintf('\n\t\tPRY:\t%0.2f  %0.2f  %0.2f',max_first{t}{1}*1000)];
        str = [str sprintf('\n\t\tEuclid:\t%0.2f',max_first{t}{2}*1000)];
        str = [str sprintf('\n\tMaximum - relative to prior scan (deg*1000):')];
        str = [str sprintf('\n\t\tPRY:\t%0.2f  %0.2f  %0.2f',max_prior{t}{1}*1000)];
        str = [str sprintf('\n\t\tEuclid:\t%0.2f',max_prior{t}{2}*1000)];
        str = [str sprintf('\n\tMean - per scan ((deg*1000)/scan):')];
        str = [str sprintf('\n\t\tPRY:\t%0.2f  %0.2f  %0.2f',mean_scan{t}{1}*1000)];
        str = [str sprintf('\n\t\tEuclid:\t%0.2f',mean_scan{t}{2}*1000)];

        % save report      
        fid = fopen(fullfile(mov_dir,sprintf('check_head_motion_rotation_%s.txt',subj)),'a');
        fprintf(fid,str);
        fclose(fid);

    end
end

cd(pwd_orig);
%==========================================================================