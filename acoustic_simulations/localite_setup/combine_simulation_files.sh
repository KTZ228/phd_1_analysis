#! /usr/bin/bash

cd /project/3025011.02/TUS_simulations/planning

echo "subject,condition,min,max" > intensity_in_brain.csv
echo "subject,condition,hemisphere,mean,std" > intensity_in_roi.csv



fslmaths /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-005/final_tissues.nii.gz -thr 1 -uthr 3 -bin final_tissues_binary_sub-005.nii.gz

fslmaths /project/3025011.02/TUS_simulations/planning/target_2_1/sub-005/sub-005_final_isppa_orig_coord_target_2_1_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_2/sub-005/sub-005_final_isppa_orig_coord_target_2_2_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_3/sub-005/sub-005_final_isppa_orig_coord_target_2_3_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_4/sub-005/sub-005_final_isppa_orig_coord_target_2_4_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_5/sub-005/sub-005_final_isppa_orig_coord_target_2_5_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_6/sub-005/sub-005_final_isppa_orig_coord_target_2_6_dc20_strength_3_dense.nii.gz sub-005_dacc_dense.nii.gz
fslmaths sub-005_dacc_dense.nii.gz -mul final_tissues_binary_sub-005.nii.gz sub-005_intensity_in_brain_dense.nii.gz
range=$(fslstats sub-005_intensity_in_brain_dense.nii.gz -R | tr ' ' ',')
echo "sub-005,dense,$range" >> intensity_in_brain.csv

fslmaths sub-005_dacc_dense.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-005/sub-005_payam_dacc_left_mask.nii.gz sub-005_dacc_left_dense.nii.gz
stats=$(fslstats sub-005_dacc_left_dense.nii.gz -M -S | tr ' ' ',')
echo "sub-005,dense,left,$stats" >> intensity_in_roi.csv
fslmaths sub-005_dacc_dense.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-005/sub-005_payam_dacc_right_mask.nii.gz sub-005_dacc_right_dense.nii.gz
stats=$(fslstats sub-005_dacc_right_dense.nii.gz -M -S | tr ' ' ',')
echo "sub-005,dense,right,$stats" >> intensity_in_roi.csv

fslmaths /project/3025011.02/TUS_simulations/planning/target_2_1/sub-005/sub-005_final_isppa_orig_coord_target_2_1_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_2/sub-005/sub-005_final_isppa_orig_coord_target_2_2_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_3/sub-005/sub-005_final_isppa_orig_coord_target_2_3_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_4/sub-005/sub-005_final_isppa_orig_coord_target_2_4_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_5/sub-005/sub-005_final_isppa_orig_coord_target_2_5_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_6/sub-005/sub-005_final_isppa_orig_coord_target_2_6_dc20_strength_3_sparse.nii.gz sub-005_dacc_sparse.nii.gz
fslmaths sub-005_dacc_sparse.nii.gz -mul final_tissues_binary_sub-005.nii.gz sub-005_intensity_in_brain_sparse.nii.gz
range=$(fslstats sub-005_intensity_in_brain_sparse.nii.gz -R | tr ' ' ',')
echo "sub-005,sparse,$range" >> intensity_in_brain.csv

fslmaths sub-005_dacc_sparse.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-005/sub-005_payam_dacc_left_mask.nii.gz sub-005_dacc_left_sparse.nii.gz
stats=$(fslstats sub-005_dacc_left_sparse.nii.gz -M -S | tr ' ' ',')
echo "sub-005,sparse,left,$stats" >> intensity_in_roi.csv
fslmaths sub-005_dacc_sparse.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-005/sub-005_payam_dacc_right_mask.nii.gz sub-005_dacc_right_sparse.nii.gz
stats=$(fslstats sub-005_dacc_right_sparse.nii.gz -M -S | tr ' ' ',')
echo "sub-005,sparse,right,$stats" >> intensity_in_roi.csv

fslmaths target_1_1/sub-005/sub-005_final_isppa_orig_coord_target_1_1_dc20_strength_1_.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-005/sub-005_amygdala_left.nii.gz sub-005_amygdala_left.nii.gz
stats=$(fslstats sub-005_amygdala_left.nii.gz -M -S | tr ' ' ',')
echo "sub-005,amygdala,left,$stats" >> intensity_in_roi.csv
fslmaths target_1_2/sub-005/sub-005_final_isppa_orig_coord_target_1_2_dc20_strength_1_.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-005/sub-005_amygdala_right.nii.gz sub-005_amygdala_right.nii.gz
stats=$(fslstats sub-005_amygdala_right.nii.gz -M -S | tr ' ' ',')
echo "sub-005,amygdala,right,$stats" >> intensity_in_roi.csv



fslmaths /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-022/final_tissues.nii.gz -thr 1 -uthr 3 -bin final_tissues_binary_sub-022.nii.gz

fslmaths /project/3025011.02/TUS_simulations/planning/target_2_1/sub-022/sub-022_final_isppa_orig_coord_target_2_1_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_2/sub-022/sub-022_final_isppa_orig_coord_target_2_2_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_3/sub-022/sub-022_final_isppa_orig_coord_target_2_3_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_4/sub-022/sub-022_final_isppa_orig_coord_target_2_4_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_5/sub-022/sub-022_final_isppa_orig_coord_target_2_5_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_6/sub-022/sub-022_final_isppa_orig_coord_target_2_6_dc20_strength_3_dense.nii.gz sub-022_dacc_dense.nii.gz
fslmaths sub-022_dacc_dense.nii.gz -mul final_tissues_binary_sub-022.nii.gz sub-022_intensity_in_brain_dense.nii.gz
range=$(fslstats sub-022_intensity_in_brain_dense.nii.gz -R | tr ' ' ',')
echo "sub-022,dense,$range" >> intensity_in_brain.csv

fslmaths sub-022_dacc_dense.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-022/sub-022_payam_dacc_left_mask.nii.gz sub-022_dacc_left_dense.nii.gz
stats=$(fslstats sub-022_dacc_left_dense.nii.gz -M -S | tr ' ' ',')
echo "sub-022,dense,left,$stats" >> intensity_in_roi.csv
fslmaths sub-022_dacc_dense.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-022/sub-022_payam_dacc_right_mask.nii.gz sub-022_dacc_right_dense.nii.gz
stats=$(fslstats sub-022_dacc_right_dense.nii.gz -M -S | tr ' ' ',')
echo "sub-022,dense,right,$stats" >> intensity_in_roi.csv

fslmaths /project/3025011.02/TUS_simulations/planning/target_2_1/sub-022/sub-022_final_isppa_orig_coord_target_2_1_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_2/sub-022/sub-022_final_isppa_orig_coord_target_2_2_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_3/sub-022/sub-022_final_isppa_orig_coord_target_2_3_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_4/sub-022/sub-022_final_isppa_orig_coord_target_2_4_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_5/sub-022/sub-022_final_isppa_orig_coord_target_2_5_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_6/sub-022/sub-022_final_isppa_orig_coord_target_2_6_dc20_strength_3_sparse.nii.gz sub-022_dacc_sparse.nii.gz
fslmaths sub-022_dacc_sparse.nii.gz -mul final_tissues_binary_sub-022.nii.gz sub-022_intensity_in_brain_sparse.nii.gz
range=$(fslstats sub-022_intensity_in_brain_sparse.nii.gz -R | tr ' ' ',')
echo "sub-022,sparse,$range" >> intensity_in_brain.csv

fslmaths sub-022_dacc_sparse.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-022/sub-022_payam_dacc_left_mask.nii.gz sub-022_dacc_left_sparse.nii.gz
stats=$(fslstats sub-022_dacc_left_sparse.nii.gz -M -S | tr ' ' ',')
echo "sub-022,sparse,left,$stats" >> intensity_in_roi.csv
fslmaths sub-022_dacc_sparse.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-022/sub-022_payam_dacc_right_mask.nii.gz sub-022_dacc_right_sparse.nii.gz
stats=$(fslstats sub-022_dacc_right_sparse.nii.gz -M -S | tr ' ' ',')
echo "sub-022,sparse,right,$stats" >> intensity_in_roi.csv

fslmaths target_1_1/sub-022/sub-022_final_isppa_orig_coord_target_1_1_dc20_strength_1_.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-022/sub-022_amygdala_left.nii.gz sub-022_amygdala_left.nii.gz
stats=$(fslstats sub-022_amygdala_left.nii.gz -M -S | tr ' ' ',')
echo "sub-022,amygdala,left,$stats" >> intensity_in_roi.csv
fslmaths target_1_2/sub-022/sub-022_final_isppa_orig_coord_target_1_2_dc20_strength_1_.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-022/sub-022_amygdala_right.nii.gz sub-022_amygdala_right.nii.gz
stats=$(fslstats sub-022_amygdala_right.nii.gz -M -S | tr ' ' ',')
echo "sub-022,amygdala,right,$stats" >> intensity_in_roi.csv



fslmaths /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-037/final_tissues.nii.gz -thr 1 -uthr 3 -bin final_tissues_binary_sub-037.nii.gz

fslmaths /project/3025011.02/TUS_simulations/planning/target_2_1/sub-037/sub-037_final_isppa_orig_coord_target_2_1_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_2/sub-037/sub-037_final_isppa_orig_coord_target_2_2_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_3/sub-037/sub-037_final_isppa_orig_coord_target_2_3_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_4/sub-037/sub-037_final_isppa_orig_coord_target_2_4_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_5/sub-037/sub-037_final_isppa_orig_coord_target_2_5_dc20_strength_3_dense.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_6/sub-037/sub-037_final_isppa_orig_coord_target_2_6_dc20_strength_3_dense.nii.gz sub-037_dacc_dense.nii.gz
fslmaths sub-037_dacc_dense.nii.gz -mul final_tissues_binary_sub-037.nii.gz sub-037_intensity_in_brain_dense.nii.gz
range=$(fslstats sub-037_intensity_in_brain_dense.nii.gz -R | tr ' ' ',')
echo "sub-037,dense,$range" >> intensity_in_brain.csv

fslmaths sub-037_dacc_dense.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-037/sub-037_payam_dacc_left_mask.nii.gz sub-037_dacc_left_dense.nii.gz
stats=$(fslstats sub-037_dacc_left_dense.nii.gz -M -S | tr ' ' ',')
echo "sub-037,dense,left,$stats" >> intensity_in_roi.csv
fslmaths sub-037_dacc_dense.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-037/sub-037_payam_dacc_right_mask.nii.gz sub-037_dacc_right_dense.nii.gz
stats=$(fslstats sub-037_dacc_right_dense.nii.gz -M -S | tr ' ' ',')
echo "sub-037,dense,right,$stats" >> intensity_in_roi.csv

fslmaths /project/3025011.02/TUS_simulations/planning/target_2_1/sub-037/sub-037_final_isppa_orig_coord_target_2_1_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_2/sub-037/sub-037_final_isppa_orig_coord_target_2_2_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_3/sub-037/sub-037_final_isppa_orig_coord_target_2_3_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_4/sub-037/sub-037_final_isppa_orig_coord_target_2_4_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_5/sub-037/sub-037_final_isppa_orig_coord_target_2_5_dc20_strength_3_sparse.nii.gz -add /project/3025011.02/TUS_simulations/planning/target_2_6/sub-037/sub-037_final_isppa_orig_coord_target_2_6_dc20_strength_3_sparse.nii.gz sub-037_dacc_sparse.nii.gz
fslmaths sub-037_dacc_sparse.nii.gz -mul final_tissues_binary_sub-037.nii.gz sub-037_intensity_in_brain_sparse.nii.gz
range=$(fslstats sub-037_intensity_in_brain_sparse.nii.gz -R | tr ' ' ',')
echo "sub-037,sparse,$range" >> intensity_in_brain.csv

fslmaths sub-037_dacc_sparse.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-037/sub-037_payam_dacc_left_mask.nii.gz sub-037_dacc_left_sparse.nii.gz
stats=$(fslstats sub-037_dacc_left_sparse.nii.gz -M -S | tr ' ' ',')
echo "sub-037,sparse,left,$stats" >> intensity_in_roi.csv
fslmaths sub-037_dacc_sparse.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-037/sub-037_payam_dacc_right_mask.nii.gz sub-037_dacc_right_sparse.nii.gz
stats=$(fslstats sub-037_dacc_right_sparse.nii.gz -M -S | tr ' ' ',')
echo "sub-037,sparse,right,$stats" >> intensity_in_roi.csv

fslmaths target_1_1/sub-037/sub-037_final_isppa_orig_coord_target_1_1_dc20_strength_1_.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-037/sub-037_amygdala_left.nii.gz sub-037_amygdala_left.nii.gz
stats=$(fslstats sub-037_amygdala_left.nii.gz -M -S | tr ' ' ',')
echo "sub-037,amygdala,left,$stats" >> intensity_in_roi.csv
fslmaths target_1_2/sub-037/sub-037_final_isppa_orig_coord_target_1_2_dc20_strength_1_.nii.gz -mul /project/3025011.02/TUS_simulations/segmentation_data/m2m_sub-037/sub-037_amygdala_right.nii.gz sub-037_amygdala_right.nii.gz
stats=$(fslstats sub-037_amygdala_right.nii.gz -M -S | tr ' ' ',')
echo "sub-037,amygdala,right,$stats" >> intensity_in_roi.csv