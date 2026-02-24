function [cfg] = bch_plot_movparam(cfg)

%% This function plots and saves the movement parameters created by the realignment
%% estimation.

rp = [];
direc = cfg.dir.func;
rp_file = dir(fullfile(direc, '/rp_*.txt'));
rp_file = load(fullfile(direc,rp_file.name));
rp = [rp;rp_file];

figure_name_transl = ['Translation: subject - ' cfg.subj];
figure_name_rot = ['Rotation: subject - ' cfg.subj];
         
h = figure(2); clf; plot(rp(:,1),'b');
hold on
plot(rp(:,2),'r');
plot(rp(:,3),'g');
xlim([1 length(rp)]);

mov_dir = fullfile(char(cfg.dir.analysis),char(cfg.subj),cfg.info.info, 'movement');
if ~exist(mov_dir,'dir'); mkdir(mov_dir); end

title({'realignment translation: x (blue), y (red), z (green)' char(cfg.subj)},'FontSize',12);
saveas(h, fullfile(mov_dir,['translation_' char(cfg.subj)]),'jpg');

h = figure(3); clf; plot(rp(:,4),'b');
hold on
plot(rp(:,5),'r');
plot(rp(:,6),'g');
xlim([1 length(rp)]);
title({'realignment rotation: x (blue), y (red), z (green)' char(cfg.subj)},'FontSize',12);
saveas(h, fullfile(mov_dir,['rotation_' char(cfg.subj)]),'jpg');

close(figure(2)); close(figure(3));

end