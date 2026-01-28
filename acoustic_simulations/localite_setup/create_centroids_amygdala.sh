#!/bin/bash

# Script to create a binary mask with voxels at the centroids of two input masks
# Usage: ./create_centroid_mask.sh <mask1> <mask2> <output_file>

if [ $# -ne 3 ]; then
    echo "Usage: $0 <mask1> <mask2> <output_file>"
    echo "Example: $0 mask1.nii.gz mask2.nii.gz /path/to/output/centroids.nii"
    exit 1
fi

mask1=$1
mask2=$2
output=$3

# Check if input files exist
if [ ! -f "$mask1" ]; then
    echo "Error: $mask1 not found"
    exit 1
fi

if [ ! -f "$mask2" ]; then
    echo "Error: $mask2 not found"
    exit 1
fi

# Create output directory if it doesn't exist
output_dir=$(dirname "$output")
mkdir -p "$output_dir"

# Get centroids and convert to integers
centroid1=($(fslstats "$mask1" -C | awk '{print int($1), int($2), int($3)}'))
centroid2=($(fslstats "$mask2" -C | awk '{print int($1), int($2), int($3)}'))

# Correct y-axis and z-axis height on coordinates
centroid1[1]=$((centroid1[1] + 2))
centroid2[1]=$((centroid2[1] + 2))
centroid1[2]=$((centroid1[2] + 2))
centroid2[2]=$((centroid2[2] + 2))

# Output centroids in MATLAB-friendly format
echo "CENTROID1: ${centroid1[0]} ${centroid1[1]} ${centroid1[2]}"
echo "CENTROID2: ${centroid2[0]} ${centroid2[1]} ${centroid2[2]}"

# Create temporary files
temp_empty=$(mktemp -u).nii.gz
temp_point1=$(mktemp -u).nii.gz
temp_point2=$(mktemp -u).nii.gz
temp_output=$(mktemp -u).nii.gz

# Create empty image with same header as mask1
fslmaths "$mask1" -mul 0 "$temp_empty"

# Create point at centroid 1
fslmaths "$temp_empty" -mul 0 -add 1 -roi ${centroid1[0]} 1 ${centroid1[1]} 1 ${centroid1[2]} 1 0 1 "$temp_point1"

# Create point at centroid 2
fslmaths "$temp_empty" -mul 0 -add 1 -roi ${centroid2[0]} 1 ${centroid2[1]} 1 ${centroid2[2]} 1 0 1 "$temp_point2"

# Combine both points
fslmaths "$temp_point1" -add "$temp_point2" -bin "$temp_output"

# Unzip the output file
gunzip -c "$temp_output" > "$output"

# Clean up temporary files
rm -f "$temp_empty" "$temp_point1" "$temp_point2" "$temp_output"