function [cfg] = bch_calc_mask(cfg)

% Reinoud Kaldewaij 2017

load(fullfile(cfg.dir.root,cfg.preproc));

struc_prefix = ['^',cfg.prefix.struc,cfg.prefix.img];
matlabbatch{1}.spm.util.imcalc.input = cfg_getfile('FPList',cfg.dir.struc,'any',struc_prefix);

matlabbatch{1}.spm.util.imcalc.output = [cfg.dir.struc,'/explicit_mask'];

fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(cfg.dir.func,fname), 'matlabbatch');
