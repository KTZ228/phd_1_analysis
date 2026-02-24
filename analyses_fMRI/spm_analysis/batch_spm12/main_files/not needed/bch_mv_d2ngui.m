function [cfg] = bch_mv_d2ngui(cfg)
%--------------------------------------------------------------------------
% BCH_MV_d2ngui moves the images created by the D2NGUI function to a data
% structure recognized by this batch. In effect it moves the new functional
% images to an orig directory and the new prepimages to a info/dummies
% directory. Enjoy.
%
% created by Lennart Verhagen, march-2006
% L.Verhagen@fcdonders.ru.nl
% version 2007-11-14
%
% adapted by Inge Volman, august-2010
% works with SPM8 batch.
%--------------------------------------------------------------------------


if cfg.me.medata == true
    
    me.d2nsess = char(cfg.me.d2nsessions(~cellfun(@isempty,regexp(cfg.me.d2nsessions,cfg.sess))));
    
    filesep_pos = strfind(cfg.sess, filesep);
    if isempty(filesep_pos)
        session_topdirs = '';
        session_name    = me.d2nsess;
    else
        session_topdirs = me.d2nsess(1:filesep_pos(end)-1);
        session_name    = me.d2nsess(filesep_pos(end)+1:end);
    end
    
    for ee = 1:cfg.me.nechoes
        %orig_d2ngui_dir  = fullfile(cfg.dir.func,session_topdirs,[session_name,cfg.me.dir_prefix,sprintf('%02d', ee)]);
        orig_d2ngui_dir  = fullfile(cfg.dir.func,session_topdirs,[cfg.me.dir_prefix,sprintf('%02d', ee)]);
        dummy_d2ngui_dir = fullfile(orig_d2ngui_dir,'prepscans');
        orig_dir = fullfile(cfg.dir.func,cfg.sess,cfg.dir.orig,[cfg.me.dir_prefix,sprintf('%02d', ee)]);
        dummy_dir = fullfile(orig_dir,cfg.dir.info.dummy);
        
        if ~exist(orig_dir,'dir'); mkdir(orig_dir); end
        if ~exist(dummy_dir,'dir'); mkdir(dummy_dir); end
        
        if exist(dummy_d2ngui_dir,'dir') && ~strcmpi(dummy_d2ngui_dir,dummy_dir)
            movefile(fullfile(dummy_d2ngui_dir,[cfg.prefix.func,'*.*']),dummy_dir);
            rmdir(dummy_d2ngui_dir,'s');
        end
        if length(dir(fullfile(orig_d2ngui_dir,[cfg.prefix.func,'*.*']))) && ~strcmpi(orig_d2ngui_dir,orig_dir)
            movefile(fullfile(orig_d2ngui_dir,[cfg.prefix.func,'*.*']),orig_dir);
            rmdir(orig_d2ngui_dir,'s');
        end
    end
    
else
    
    orig_d2ngui_dir = fullfile(cfg.dir.func,cfg.sess);
    dummy_d2ngui_dir = fullfile(cfg.dir.func,cfg.sess,'prepscans');
    orig_dir = fullfile(cfg.dir.func,cfg.sess,cfg.dir.orig);
    dummy_dir = fullfile(cfg.dir.func,cfg.sess,cfg.dir.info.dummy);
    if ~exist(orig_dir,'dir'); mkdir(orig_dir); end
    if ~exist(dummy_dir,'dir'); mkdir(dummy_dir); end
    
    if length(dir(fullfile(orig_d2ngui_dir,[cfg.prefix.func,'*.*']))) && ~strcmpi(orig_d2ngui_dir,orig_dir)
        movefile(fullfile(orig_d2ngui_dir,[cfg.prefix.func,'*.*']),orig_dir);
    end
    if exist(dummy_d2ngui_dir,'dir') && ~strcmpi(dummy_d2ngui_dir,dummy_dir)
        movefile(fullfile(dummy_d2ngui_dir,[cfg.prefix.func,'*.*']),dummy_dir);
        rmdir(dummy_d2ngui_dir,'s');
    end
    
end % end ME / non ME if
                  
