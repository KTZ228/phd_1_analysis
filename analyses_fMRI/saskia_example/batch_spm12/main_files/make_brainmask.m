function [msk] = make_brainmask(dat)

% MAKE_BRAINMASK
%

if (ndims(dat)==3)
  [ne,nv,nt] = size(dat);
elseif (ndims(dat)==2)
  [nv,nt] = size(dat);
  ne = 1;
else
  error('invalid dat');
end

% allocate space for voxel computations
%crt1 = zeros(nv,1);
%crt2 = zeros(nv,1);
crt3 = zeros(nv,1);
avg = mean(dat(:));
vol = crt3;
if (ne>1)
for i=1:ne
  for j=1:nt
    vol = squeeze(dat(i,:,j));
    %crt1 = crt1 + (vol(:)./mean(vol(:)));
    %crt2 = crt2 + (vol(:)./median(vol(:)));
    crt3 = crt3 + (vol(:)>1.0*avg);
  end
end
else
  for j=1:nt
    vol = squeeze(dat(:,j));
    %crt1 = crt1 + (vol(:)./mean(vol(:)));
    %crt2 = crt2 + (vol(:)./median(vol(:)));
    crt3 = crt3 + (vol(:)>1.0*avg);
  end
end
%crt1 = crt1./(ne*nt);
%crt2 = crt2./(ne*nt);
crt3 = crt3./(ne*nt);

%ii = (crt1<=2.0) | (crt2<=20) | (crt3<1.0);
%ii = (crt1<=2.0) | (crt3<1.0);
ii = (crt3<1.0);
msk = ones(size(vol));
msk(ii) = 0;
