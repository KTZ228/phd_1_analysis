#!/bin/bash

# Script to create a binary mask with voxels at the midpoints of two coordinate pairs
# Usage: ./create_centroids_from_coords.sh <x1> <y1> <z1> <x2> <y2> <z2> <x3> <y3> <z3> <x4> <y4> <z4> <reference_image> <output_file>

if [ $# -ne 14 ]; then
    echo "Usage: $0 <x1> <y1> <z1> <x2> <y2> <z2> <x3> <y3> <z3> <x4> <y4> <z4> <reference_image> <output_file>"
    echo "Example: $0 87 164 135 105 171 205 134 165 136 120 175 205 reference.nii.gz /path/to/output/centroids.nii"
    echo ""
    echo "Arguments:"
    echo "  x1, y1, z1: Coordinates for first point of first pair"
    echo "  x2, y2, z2: Coordinates for second point of first pair"
    echo "  x3, y3, z3: Coordinates for first point of second pair"
    echo "  x4, y4, z4: Coordinates for second point of second pair"
    echo "  reference_image: NIfTI file to use as template for dimensions and header"
    echo "  output_file: Path to output mask file"
    echo ""
    echo "The script will:"
    echo "  - Calculate midpoint 1 between (x1,y1,z1) and (x2,y2,z2)"
    echo "  - Calculate midpoint 2 between (x3,y3,z3) and (x4,y4,z4)"
    echo "  - Create a binary mask with voxels at both midpoints"
    exit 1
fi

# Parse input coordinates
x1=$1
y1=$2
z1=$3
x2=$4
y2=$5
z2=$6
x3=$7
y3=$8
z3=$9
x4=${10}
y4=${11}
z4=${12}
reference=${13}
output=${14}

# Check if reference image exists
if [ ! -f "$reference" ]; then
    echo "Error: Reference image $reference not found"
    exit 1
fi

# Create output directory if it doesn't exist
output_dir=$(dirname "$output")
mkdir -p "$output_dir"

# Calculate midpoint 1 (between point 1 and point 2)
mid1_x=$(echo "scale=0; ($x1 + $x2) / 2" | bc)
mid1_y=$(echo "scale=0; ($y1 + $y2) / 2" | bc)
mid1_z=$(echo "scale=0; ($z1 + $z2) / 2" | bc)

# Calculate midpoint 2 (between point 3 and point 4)
mid2_x=$(echo "scale=0; ($x3 + $x4) / 2" | bc)
mid2_y=$(echo "scale=0; ($y3 + $y4) / 2" | bc)
mid2_z=$(echo "scale=0; ($z3 + $z4) / 2" | bc)

# Output coordinates in MATLAB-friendly format
echo "CENTROID1: $mid1_x $mid1_y $mid1_z"
echo "CENTROID2: $mid2_x $mid2_y $mid2_z"

# Create temporary files
temp_empty=$(mktemp -u).nii.gz
temp_point1=$(mktemp -u).nii.gz
temp_point2=$(mktemp -u).nii.gz
temp_output=$(mktemp -u).nii.gz

# Create empty image with same header as reference
fslmaths "$reference" -mul 0 "$temp_empty"

# Create point at midpoint 1
fslmaths "$temp_empty" -mul 0 -add 1 -roi $mid1_x 1 $mid1_y 1 $mid1_z 1 0 1 "$temp_point1"

# Create point at midpoint 2
fslmaths "$temp_empty" -mul 0 -add 1 -roi $mid2_x 1 $mid2_y 1 $mid2_z 1 0 1 "$temp_point2"

# Combine both points into a temporary compressed file
fslmaths "$temp_point1" -add "$temp_point2" -bin "$temp_output"

# Unzip to create the final uncompressed .nii file
gunzip -c "$temp_output" > "$output"

# Clean up temporary files
rm -f "$temp_empty" "$temp_point1" "$temp_point2" "$temp_output"

echo "Binary mask created successfully: $output"