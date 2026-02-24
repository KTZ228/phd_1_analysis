function TotalReadoutTime = a_get_TotalReadoutTime(dicomfile)

%get the read out time from a DICOM file
%
% - this is used for Calculate VDM in SPM
% - input: a EPI dicom fle
% - output: Total EPI readout time in ms (as to be entered in SPM)
%
% based on following formula:
%   EffectiveEchoSpacing = 1/[BWPPPE * ReconMatrixPE]
%   TotalReadoutTime = EffectiveEchoSpacing * (ReconMatrixPE) = ReconMatrixPE/[BWPPPE * ReconMatrixPE] = 1/BWPPE
%   See: https://bids.neuroimaging.io/bids_spec.pdf
%
% LdV 2019

%read in file
fname = 'project/3023001.04/raw/sub-003/ses-mri01/009-fieldmap/02231_1.3.12.2.1107.5.2.43.67027.2020012210101716374496679.IMA';
dcminfo=dicominfo(dicomfile);
dcminfo=dicominfo(fname);

%calculate BandwidthPerPixelPhaseEncode (BWPPE)
BWPPE=typecast(int8(dcminfo.Private_0019_1028),'double');
%BWPPE=typecast(int8(dcminfo.PixelBandwidth),'double');
BWPPE = dcminfo.Private_0019_1028;
MatrixSizePhase = dcminfo.AcquisitionMatrix(4);

1/(BWPPE * double(MatrixSizePhase))

%calculate read out time
TotalReadoutTime = (1/BWPPE)*1000;