#!/bin/bash
# Usage:
# cd /project/3025011.02/localite/masks
# /home/affneu/kenvdzee/Documents/phd_1_analysis/acoustic_simulations/localite_setup/transform_MNI_coordinates_to_mask.sh payam_dacc_left_coordinates.nii.gz 48,77,54 48,75,56 48,73,58 41,77,56 41,79,54 41,75,58

reference="$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz"
fslmaths $reference -mul 0 $1

for coordinate_set in "${@:2}"; do
    IFS=',' read x y z <<< "$coordinate_set"
    x=$(printf "%.0f" $x); y=$(printf "%.0f" $y); z=$(printf "%.0f" $z)
    fslmaths $reference -mul 0 -add 1 -roi $x 1 $y 1 $z 1 0 1 tmp
    fslmaths $1 -add tmp $1
done

rm -f tmp.nii.gz