%% Replace 0s with NaNs
% replace 0s with NaNs in a NIFTI file to (potentially) make visualization
% better when using specific softwares like fsleyes or mrview
vol = spm_vol('/Users/loukas/Desktop/CAP_NIFTI_sera_CAP1.nii');

data = spm_read_vols(vol);
data(data==0) = NaN; % exactly 0 is only the background (outside-brain) space

% write new file with new name but same header & affine
vol.fname = '/Users/loukas/Desktop/CAP_NIFTI_sera_CAP1_modified.nii';
spm_write_vol(vol, data)