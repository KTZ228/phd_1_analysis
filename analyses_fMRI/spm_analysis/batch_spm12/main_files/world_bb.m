function bb = world_bb(V)
% world-bb -- get bounding box in world (mm) coordinates
% see resize_img.m for instructions.

d = V.dim(1:3);
% corners in voxel-space
c = [ 1    1    1    1
    1    1    d(3) 1
    1    d(2) 1    1
    1    d(2) d(3) 1
    d(1) 1    1    1
    d(1) 1    d(3) 1
    d(1) d(2) 1    1
    d(1) d(2) d(3) 1 ]';
% corners in world-space
tc = V.mat(1:3,1:4)*c;
% reflect in x if required
if spm_flip_analyze_images; tc(1,:) = -tc(1,:); end;

% bounding box (world) min and max
mn = min(tc,[],2)';
mx = max(tc,[],2)';
bb = [mn; mx];