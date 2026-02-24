function bch_betas_level1(cfg)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% initialize marsbar
marsbar('on');

% roi_files = fullfile(cfg.dir.apfc, cfg.maskname);
roi_files = '/project/3025003.01/bids/derivatives/second-level/October2021/KnownNovel_canon/rSTG_58_-3_0_roi.mat';
con_images = {'con_0001.nii','con_0002.nii'};

for j = 1:length(con_images)
    
    %P = spm_get(Inf,'*.nii','Select images');
    %work = fullfile(cfg.dir.root, cfg.subj, cfg.dir.ana, cfg.model1,con_face_img_nrs(j));
    work = fullfile('/project/3025003.01/bids/derivatives/fmri_preproc/sub-001/first_level_baseline',con_images(j));
    P(j,:) = char(work);
end

rois = maroi('load_cell', roi_files);  % make maroi ROI objects
mY = get_marsy_SK(rois{:}, P, 'mean');  % extract data into marsy data object % 'mean' VA


y = summary_data(mY); % get summary time course(s)

region_no = 1;
voxel_data = region_data(y, region_no);
% voxel_data = voxel_data{1};
% voxel_xyz  = xyz(y, region_no, 'mm');

%% getting voxel data from the mars object
% to select the region for which we want data
% In this case there's only one region
% region_no = 1;
% 
% % marbs bar default code | change later
% y = get_marsy(rois{:}, P, 'mean');
% 
% % Help yourself to information
% voxel_data = region_data(y, region_no);
% voxel_data = voxel_data{1};
% voxel_xyz  = xyz(y, region_no, 'mm');

%% create file with betas
fileID = fopen('betas_face_level1_new.txt', 'a');
if cfg.subj == string(cfg.subjnames(1))
    fprintf(fileID,'Subj\tCong_Face_Beta\tIncong_Face_Beta\n');
end
fprintf(fileID,'%s\t%f\t%f\n',cfg.subj,y(1), y(2));
fclose(fileID);

for j = 1:length(con_food_img_nrs)
    
    %P = spm_get(Inf,'*.nii','Select images');
    work = fullfile(cfg.dir.root, cfg.subj, cfg.dir.ana, cfg.model1,con_food_img_nrs(j));
    P(j,:) = char(work);
end

rois = maroi('load_cell', roi_files);  % make maroi ROI objects
mY = get_marsy(rois{:}, P, 'eigen1');  % extract data into marsy data object % 'mean' VA
y = summary_data(mY); % get summary time course(s)

fileID = fopen('betas_food_level1_new.txt', 'a');
if cfg.subj == string(cfg.subjnames(1))
    fprintf(fileID,'Subj\tCong_Food_Beta\tIncong_Food_Beta\n');
end
fprintf(fileID,'%s\t%f\t%f\n',cfg.subj,y(1), y(2));
fclose(fileID);

end

% 
% con_food_img_nrs = {'con_0014.nii' ,'con_0015.nii'};
% con_face_img_nrs = {'con_0012.nii' ,'con_0013.nii'};

