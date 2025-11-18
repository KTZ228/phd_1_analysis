import nibabel as nib
import numpy as np

img = nib.load('/Volumes/project/3025011.02/bids/sub-022/ses-mri01/anat/sub-022_ses-mri01_acq-mprage_T1w.nii.gz')
data = img.get_fdata()
x = 200
y = 300
z = 240
data[x, y, z] = 1240

# Create new image and reset scaling factors
new_img = nib.Nifti1Image(data, img.affine, img.header)
new_img.set_data_dtype(img.get_data_dtype())

# Reset scaling to avoid MATLAB issues
new_img.header['scl_slope'] = 1.0
new_img.header['scl_inter'] = 0.0

nib.save(new_img, '/Volumes/project/3025011.02/bids/sub-022/ses-mri01/anat/sub-022_ses-mri01_acq-mprage_T1w.nii.gz')
print(f'Done: placed voxel value 1240 at ({x}, {y}, {z})')