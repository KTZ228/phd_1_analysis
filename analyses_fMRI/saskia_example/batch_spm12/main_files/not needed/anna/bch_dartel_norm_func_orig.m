
cfg = [];
clear;
dir_root           = [filesep,fullfile('home', 'language', 'anntyb', 'PHD', 'fMRI_subj_wave14')];

subjects            = {'002','003','004', '005','010','012','020','021','025','026','033','036','037','040','042',...
                        '044','045','046','047','051','056','057','058','060', '061','062','065','070',...
                        '072','077','085','088','094','095','098','103','104','106','112','114','115',...
                        '118','119','122','123','124','125','905','942'};  

sessions    = {''};

subjsel = 33;

cfg.dir.root = dir_root;
cfg.prefix.img = '.*\.nii$';  

cfg.prefix.func = 'arf';
cfg.prefix.mean = 'meanrf';

cfg.preproc = 'dartel_norm_func';

cfg.dartel.dir = fullfile(dir_root, 'Dartel_temp');
cfg.dartel.temp = fullfile(cfg.dartel.dir, 'Template_6.nii');
cfg.dartel.flow_prefix = 'u_rc1ss';

data = [];
%% dartel_normalize (.05 smooth) functional images
load(fullfile(cfg.dir.root,cfg.preproc));
 
for s = subjsel
        cfg.subj        = subjects{s};
        disp(['Subject: ' cfg.subj]);
        cfg.dir.func    = fullfile(dir_root,cfg.subj,'func');
        
        cfg.dir.sessions = sessions;
        
        cfg.sess = cfg.dir.sessions{1};


        % fill in name subject/func directory
        matlabbatch{1}.cfg_basicio.cfg_named_dir.dirs = {{cfg.dir.func}};
        % select dartel template
        matlabbatch{3}.spm.tools.dartel.mni_norm.template = {cfg.dartel.temp};                  
        %enter flow field for subj
        dir_flow = fullfile(cfg.dartel.dir, [cfg.dartel.flow_prefix, cfg.subj,'_Template.nii']);
        matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj.flowfield = {dir_flow};             
           
        %select images to be warped
        dir = fullfile(cfg.dir.func, 'preproc','work');
        img_prefix = ['^',cfg.prefix.func,cfg.prefix.img];
        run = cfg_getfile('ExtFPList',dir,img_prefix);
        
        data = [data;run];
        matlabbatch{3}.spm.tools.dartel.mni_norm.data.subj.images = data;    
        
        
        fname = [cfg.preproc '_' cfg.subj '.mat'];
        save(fullfile(cfg.dir.func,fname), 'matlabbatch');
end



