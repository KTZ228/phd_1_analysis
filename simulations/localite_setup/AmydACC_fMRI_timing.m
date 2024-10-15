%%

statistical_map_name = 'stats_uncorr_thresholded.nii';

statistical_map = niftiread(statistical_map_name);
info = niftiinfo(statistical_map_name);
mask = niftiread('t1_OUTCxLR4xa_mask.nii');
left_mask = niftiread('left_mask.nii.gz');
right_mask = niftiread('right_mask.nii.gz');

masked_statistical_map = mask .* statistical_map;
niftiwrite(masked_statistical_map, 'masked_statistical_map.nii', info);
