function [cfg] = bch_plot_mov(cfg)

%% This function plots and saves the movement parameters created by the realignment
%% estimation.

rp = [];
for ss = 1:length(cfg.dir.sessions)
direc{ss} = fullfile(cfg.dir.func,cfg.dir.sessions{ss},cfg.dir.preproc.work,cfg.me.estecho);
rp_file = dir(fullfile(direc{ss},'rp_*.txt'));
rp_file = load(fullfile(direc{ss},rp_file.name));
rp = [rp;rp_file];
end

figure_name_transl = ['realign regr translation: subject - ' cfg.subj];
figure_name_rot = ['realign regr rotation: subject - ' cfg.subj];
         
h = figure(2); clf; plot(rp(:,1),'b');
hold on
plot(rp(:,2),'r');
plot(rp(:,3),'g');
title({'realignment regressors translation: x (blue), y (red), z (green)',['subject - ' cfg.subj],'Order of sessions - affect, colour'},'FontSize',14);
saveas(h, fullfile(cfg.dir.func,['realign_regr_transl_' cfg.subj]),'jpg');

h = figure(3); clf; plot(rp(:,4),'b');
hold on
plot(rp(:,5),'r');
plot(rp(:,6),'g');
title({'realignment regressors rotation: x (blue), y (red), z (green)',['subject - ' cfg.subj],'Order of sessions - affect, colour'},'FontSize',14);
saveas(h, fullfile(cfg.dir.func,['realign_regr_rotation_' cfg.subj]),'jpg');


end


