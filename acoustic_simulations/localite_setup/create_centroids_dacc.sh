#!/bin/bash

# Function to create a binary mask with single voxels at CSV coordinates
# and output voxel coordinates in MATLAB-parseable format
# Usage: create_voxel_mask <csv_file> <t1_anatomical.nii.gz> <output_mask.nii.gz>
#
# Arguments:
#   csv_file: Path to CSV file with coordinates (format: Generic,pos_x,pos_y,pos_z,name)
#   t1_anatomical: Path to T1 anatomical NIfTI file (reference space)
#   output_mask: Path for output binary mask
#
# Outputs voxel coordinates in format: TARGET_N: x y z

create_voxel_mask() {
    # Check arguments
    if [ $# -lt 3 ]; then
        echo "Usage: create_voxel_mask <csv_file> <t1_anatomical.nii.gz> <output_mask.nii.gz>"
        return 1
    fi
    
    local csv_file="$1"
    local t1_anat="$2"
    local output_mask="$3"
    
    # Check if input files exist
    if [ ! -f "$csv_file" ]; then
        echo "Error: CSV file not found: $csv_file" >&2
        return 1
    fi
    
    if [ ! -f "$t1_anat" ]; then
        echo "Error: T1 anatomical file not found: $t1_anat" >&2
        return 1
    fi
    
    # Check for required commands
    for cmd in fslmaths fslstats std2imgcoord; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: $cmd not found. Please ensure FSL is installed and in your PATH." >&2
            return 1
        fi
    done
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Initialize empty mask (all zeros) with same dimensions as T1
    fslmaths "$t1_anat" -mul 0 "$temp_dir/base_mask.nii.gz" 2>/dev/null
    
    # Start with empty mask for combining
    cp "$temp_dir/base_mask.nii.gz" "$temp_dir/combined.nii.gz"
    
    # Array to store voxel coordinates
    declare -a voxel_coords
    local voxel_num=0
    
    # Read CSV and process each coordinate (skip header)
    while IFS=, read -r generic pos_x pos_y pos_z name; do
        # Skip empty lines
        if [ -z "$pos_x" ]; then
            continue
        fi
        
        voxel_num=$((voxel_num + 1))
        
        # Convert mm coordinates to voxel coordinates
        vox_coords=$(echo "$pos_x $pos_y $pos_z" | std2imgcoord -img "$t1_anat" -std "$t1_anat" -vox)
        read vox_x vox_y vox_z <<< "$vox_coords"
        
        # Round to nearest integer voxel
        vox_x=$(printf "%.0f" $vox_x)
        vox_y=$(printf "%.0f" $vox_y)
        vox_z=$(printf "%.0f" $vox_z)
        
        # Store coordinates
        voxel_coords[$voxel_num]="$vox_x $vox_y $vox_z"
        
        # Create a single voxel at this location
        fslmaths "$temp_dir/base_mask.nii.gz" \
                 -mul 0 \
                 -add 1 \
                 -roi $vox_x 1 $vox_y 1 $vox_z 1 0 1 \
                 "$temp_dir/voxel_${voxel_num}.nii.gz" 2>/dev/null
        
        # Add this voxel to the combined mask
        fslmaths "$temp_dir/combined.nii.gz" \
                 -add "$temp_dir/voxel_${voxel_num}.nii.gz" \
                 "$temp_dir/combined.nii.gz" 2>/dev/null
        
    done < <(tail -n +2 "$csv_file")
    
    # Binarize the final mask (in case any voxels overlap)
    fslmaths "$temp_dir/combined.nii.gz" -bin "$temp_dir/final_mask.nii.gz" 2>/dev/null
    
    # Unzip the output if the requested output doesn't end in .gz
    if [[ "$output_mask" == *.gz ]]; then
        cp "$temp_dir/final_mask.nii.gz" "$output_mask"
    else
        gunzip -c "$temp_dir/final_mask.nii.gz" > "$output_mask"
    fi
    
    # Output voxel coordinates in MATLAB-parseable format
    for ((i=1; i<=voxel_num; i++)); do
        echo "TARGET_${i}: ${voxel_coords[$i]}"
    done
    
    # Get mask statistics (send to stderr so it doesn't interfere with parsing)
    local nvoxels=$(fslstats "$output_mask" -V | awk '{print $1}')
    local volume_mm3=$(fslstats "$output_mask" -V | awk '{print $2}')
    
    echo "MASK_CREATED: $output_mask" >&2
    echo "NUM_VOXELS: $nvoxels" >&2
    echo "VOLUME_MM3: $volume_mm3" >&2
    
    return 0
}

# If script is run directly (not sourced), execute the function with arguments
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    create_voxel_mask "$@"
fi