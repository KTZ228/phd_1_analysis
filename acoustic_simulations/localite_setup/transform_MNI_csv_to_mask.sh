#!/bin/bash

# Robust version that creates proper binary masks from world coordinates
# Usage: ./transform_subject_coordinates_to_mask_final.sh <output_mask.nii.gz> <subject_anatomical.nii.gz> <coordinates.csv>

if [ "$#" -ne 3 ]; then
    echo "Error: Incorrect number of arguments"
    echo "Usage: $0 <output_mask.nii.gz> <subject_anatomical.nii.gz> <coordinates.csv>"
    exit 1
fi

output_mask="$1"
reference="$2"
csv_file="$3"

# Check if files exist
if [ ! -f "$reference" ]; then
    echo "Error: Reference anatomical file '$reference' not found"
    exit 1
fi

if [ ! -f "$csv_file" ]; then
    echo "Error: CSV file '$csv_file' not found"
    exit 1
fi

echo "Creating mask from coordinates..."
echo "Reference: $reference"
echo "CSV file: $csv_file"
echo "Output: $output_mask"
echo ""

# Create Python script that does proper coordinate conversion and creates binary mask
cat > /tmp/create_mask.py << 'PYTHON_EOF'
import sys
import nibabel as nib
import numpy as np
import csv

ref_file = sys.argv[1]
csv_file = sys.argv[2]
output_file = sys.argv[3]

print("Loading reference image...")
ref_img = nib.load(ref_file)
ref_data = ref_img.get_fdata()
affine = ref_img.affine
inv_affine = np.linalg.inv(affine)

# Create empty mask with same dimensions
mask_data = np.zeros(ref_data.shape, dtype=np.uint8)

print(f"Image dimensions: {mask_data.shape}")
print(f"Voxel size: {ref_img.header.get_zooms()[:3]} mm")
print("")

# Track unique voxels and duplicates
voxel_set = set()
duplicate_count = 0

print("Processing coordinates:")
print("-" * 60)

with open(csv_file, 'r') as f:
    reader = csv.DictReader(f)
    for i, row in enumerate(reader, 1):
        try:
            # Get world coordinates from CSV
            x_mm = float(row['pos_x'])
            y_mm = float(row['pos_y'])
            z_mm = float(row['pos_z'])
            name = row['name'].strip()
            
            # Convert world coordinates to voxel indices using inverse affine
            world_coord = np.array([x_mm, y_mm, z_mm, 1])
            voxel_coord = inv_affine @ world_coord
            
            # Round to nearest voxel
            x_vox = int(np.round(voxel_coord[0]))
            y_vox = int(np.round(voxel_coord[1]))
            z_vox = int(np.round(voxel_coord[2]))
            
            print(f"{i}. {name}")
            print(f"   World:  ({x_mm:7.2f}, {y_mm:7.2f}, {z_mm:7.2f}) mm")
            print(f"   Voxel:  ({x_vox:4d}, {y_vox:4d}, {z_vox:4d})")
            
            # Check if within bounds
            if (0 <= x_vox < mask_data.shape[0] and 
                0 <= y_vox < mask_data.shape[1] and 
                0 <= z_vox < mask_data.shape[2]):
                
                voxel_tuple = (x_vox, y_vox, z_vox)
                
                if voxel_tuple in voxel_set:
                    print(f"   ⚠️  Duplicate voxel location!")
                    duplicate_count += 1
                else:
                    voxel_set.add(voxel_tuple)
                
                # Set voxel to 1 (binary mask)
                mask_data[x_vox, y_vox, z_vox] = 1
                print(f"   ✓ Added")
                
            else:
                print(f"   ✗ Outside bounds {mask_data.shape}")
                
        except Exception as e:
            print(f"   ✗ Error: {e}")
        
        print("")

print("=" * 60)
print(f"Summary:")
print(f"  Total coordinates in CSV: {i}")
print(f"  Unique voxels in mask: {len(voxel_set)}")
print(f"  Duplicate voxel locations: {duplicate_count}")
print(f"  Final mask voxel count: {int(np.sum(mask_data))}")
print("")

if duplicate_count > 0:
    print("⚠️  Note: Some coordinates mapped to the same voxel.")
    print("   This is normal if coordinates are closer than voxel size.")
print("")

# Save as binary mask
mask_img = nib.Nifti1Image(mask_data.astype(np.uint8), affine, ref_img.header)
mask_img.header.set_data_dtype(np.uint8)
nib.save(mask_img, output_file)

print(f"✓ Saved binary mask to: {output_file}")
print("")
print("To visualize:")
print(f"  fsleyes {ref_file} {output_file} -cm red -a 70")
PYTHON_EOF

# Run Python script
if command -v python3 &> /dev/null; then
    python3 /tmp/create_mask.py "$reference" "$csv_file" "$output_mask"
    exit_code=$?
elif command -v python &> /dev/null; then
    python /tmp/create_mask.py "$reference" "$csv_file" "$output_mask"
    exit_code=$?
else
    echo "Error: Python not found"
    rm /tmp/create_mask.py
    exit 1
fi

# Clean up
rm /tmp/create_mask.py

if [ $exit_code -ne 0 ]; then
    echo ""
    echo "Error: Script failed. Make sure nibabel is installed:"
    echo "  pip install nibabel"
    exit 1
fi

exit 0