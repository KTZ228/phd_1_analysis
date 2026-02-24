%computes the GM and WM volumes from non-normalized/modulated dartel output files
%AT 2014
 

function [cfg] = bch_VBM_brain_vol(cfg)

%get GM images
if cfg.get_vol == 1
    V = spm_vol(spm_select('ExtFPList',fullfile(cfg.dir.struc,cfg.dartel.seg),cfg.prefix.seg.grey));   %V = spm_vol(spm_select(Inf,'Image'));
    V = V(1);  %just want the first unwarped image - temp solution to loading all c1 files!!
    
    Vols = zeros(numel(V),1);
    for j=1:numel(V),
        tot = 0;
        for i=1:V(1).dim(3),
            img = spm_slice_vol(V(j),spm_matrix(...
                [0 0 i]),V(j).dim(1:2),0);
            img = img(isfinite(img)); % <-- exclude non-finite values
            tot = tot + sum(img(:));
        end;
        voxvol = abs(det(V(j).mat))/100^3; % volume of a voxel, in litres
        Vols(j) = tot*voxvol;
    end
    VM = Vols;

elseif cfg.get_vol == 2 % GM + WM
    V = spm_vol(spm_select('ExtFPList',fullfile(cfg.dir.struc,cfg.dartel.seg),cfg.prefix.seg.grey));
    V = V(1);  %just want the first unwarped image - temp solution to loading all c1 files!!
    
    Vols = zeros(numel(V),1);
    for j=1:numel(V),
        tot = 0;
        for i=1:V(1).dim(3),
            img = spm_slice_vol(V(j),spm_matrix(...
                [0 0 i]),V(j).dim(1:2),0);
            img = img(isfinite(img)); % <-- exclude non-finite values
            tot = tot + sum(img(:));
        end;
        voxvol = abs(det(V(j).mat))/100^3; % volume of a voxel, in litres
        Vols(j) = tot*voxvol;
    end
    VM(:,1) = Vols;

    V= []; Vols = [];
    
    %get WM images
    V = spm_vol(spm_select('ExtFPList',fullfile(cfg.dir.struc,cfg.dartel.seg),cfg.prefix.seg.white));   %V = spm_vol(spm_select(Inf,'Image'));
    V = V(1);  %just want the first unwarped image - temp solution to loading all c1 files!!
    
    Vols = zeros(numel(V),1);
    for j=1:numel(V),
        tot = 0;
        for i=1:V(1).dim(3),
            img = spm_slice_vol(V(j),spm_matrix(...
                [0 0 i]),V(j).dim(1:2),0);
            img = img(isfinite(img)); % <-- exclude non-finite values
            tot = tot + sum(img(:));
        end;
        voxvol = abs(det(V(j).mat))/100^3; % volume of a voxel, in litres
        Vols(j) = tot*voxvol;
    end
    VM(:,2) = Vols;
end

fname = [cfg.preproc '_' cfg.subj '.mat'];
save(fullfile(cfg.dir.vbm, fname),'VM')

end 






%img = spm_slice_vol(V(j),spm_matrix(...  
%                  [0 0 i]),V(j).dim(1:2),0);

%V(j) - selected image volume
%spm_matrix (transformation matrix) - 0 0 i with i being the slice nr to be selected
%V(j).dim(1:2) - the two dimensions of the output image (here: x and y so 256, 256)
%0 - hold - sets the interpolation method for resampling - 0=zero-order hold (nearest neighbor)
%