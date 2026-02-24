function [cfg] = bch_copy_beh(cfg)

% find logfile in bids directory

new_dir =fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg',cfg.dir.beh);
if ~exist(new_dir, 'dir'); mkdir(new_dir); end

subj = cfg.subj;
subjnr = str2num(subj(5:end));

old_logfile = cfg.dir.log;

z = (-1)^subjnr;
if z == -1 % subjnr is odd --> player 1
    pair = round(subjnr/2);
    new_logfile = fullfile(new_dir, ['t' num2str(pair) 'p' num2str(subjnr) '_tcg_ASD_scanning.txt']);
    copyfile(old_logfile, new_logfile)

else % subjnr is even --> player 2
    pair = subjnr/2;
    subjnr_player1 = subjnr-1;
    if  pair == 45  % sub-090 was matched with sub-083
        new_logfile = fullfile(new_dir,'t42p83_tcg_ASD_scanning.txt');
        copyfile(old_logfile, new_logfile)
    elseif pair == 71 % sub-142 was mathced with sub-133 (sub-142 was player 1)
        new_logfile = fullfile(new_dir,'t67p133_tcg_ASD_scanning.txt');
        copyfile(old_logfile, new_logfile)
    else
        new_logfile = fullfile(new_dir, ['t' num2str(pair) 'p' num2str(subjnr_player1) '_tcg_ASD_scanning.txt']);
        copyfile(old_logfile, new_logfile)
    end
end