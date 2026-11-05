function [X_flat_thresh] = ZeroOutNonSig(CAPsPath)

% Inputs:
%       CAPsPath: Path to subject functional folder 
%
% Outputs:
%       X_flat: 2-dimensional data matrix containing [nVoxels x
%       nTimePoints]
%
% Created: June 2021, Samantha Weber, University of Bern & Serafeim Loukas, EPFL

%% PART 1: loading 

% Check if folder exists
if ~exist(CAPsPath, 'dir')
    error('Could not find CAP folder');
end

% Read in functional data
[myListofFiles,dontcare]=spm_select('List', CAPsPath, '^CAP_NIFTI_ZScored.*'); % List of CAPs
cd(CAPsPath)
V0i=spm_vol(myListofFiles);            % load all functional volumes headers

%% PART 2: build 4D
% initialise storage of Matrix (nPixels x nPixels x nSlices x nTimePoints)
V0=zeros(V0i(1).dim(1),V0i(1).dim(2),V0i(1).dim(3),length(V0i),'single');

% store all volumes as 4D matrix
tic
for iter=1:length(V0i)
    V0(:,:,:,iter)=spm_read_vols(V0i(iter));
end   
toc

%% Part 3: Define size of masked data 
% we will zero-out everything that is > -1.04 and > 1.04 (positive and
% negative values that are significant). As image was masked during CAPs
% analysis, it contains already zeros, therefore we create a mask first of
% all non-zero elements. Makes things faster.

V0_size=size(V0);
thisfile=fullfile(CAPsPath,V0i(1).fname); %select first functional file
mask_data = V0(:,:,:,1);

X_flat = zeros(nnz(V0(:,:,:,1)), size(V0,4));

tic
% we will work on each CAP
for vol = 1:size(V0,4)
    % get current 3D CAP (single time-point)
    current_volume = V0(:,:,:,vol);
    % flatten the CAP into a vector - makes life and computations easier
    flat_brain_volume = reshape(current_volume, [1, numel(current_volume)]);
    % mask the flat CAP using the mask, first flatten the mask and make it boolean
    flat_brain_volume_masked = flat_brain_volume(logical(reshape(mask_data, [1, numel(mask_data)])));
    
    if isequal(size(flat_brain_volume_masked,2), nnz(mask_data))== 0
    error('Mask is not same size as brain volume!!');
    end
    
    % store the results
    X_flat(:, vol) = flat_brain_volume_masked';
end
toc

%% 4. Remove values between +1.04 and -1.04
% Images are Z-scored. 

X_flat_thresh_pos = X_flat;
X_flat_thresh_neg = X_flat;

%positive contributions
for c = 1:size(X_flat_thresh_pos,2)
    for i = 1:size(X_flat_thresh_pos,1)
        if (X_flat_thresh_pos(i,c) < 1.04)
        X_flat_thresh_pos(i,c) = 0;
        end
    end
end


%negative contributions
for c = 1:size(X_flat_thresh_neg,2)
    for i = 1:size(X_flat_thresh_neg,1)
        if (X_flat_thresh_neg(i,c) > -1.04)
        X_flat_thresh_neg(i,c) = 0;
        end
    end
end



%% PART 5: reshape back and save as .nii
% the initial mask flattened

% positive contributions
mask_data_flat = reshape(mask_data, [1, numel(mask_data)]); 

for vol = 1:size(X_flat_thresh_pos,2)
    unmasker = zeros(1, numel(mask_data)); % initialize empty array to be used to build the final brain volume
    unmasker(logical(mask_data_flat)) = X_flat_thresh_pos(:,vol)'; % store the thresholded CAP in the right location where the mask existed
        
    final_vol = reshape(unmasker, [V0i(vol).dim]); % reshape to initial dimension
    current_header = V0i(vol); % get header
    current_header.fname= [CAPsPath , '/' , 'thresholded_pos',current_header.fname]; % new filename for MAC
    spm_write_vol(current_header,final_vol); % save to target path
end

% negative contributions

for vol = 1:size(X_flat_thresh_neg,2)
    unmasker = zeros(1, numel(mask_data)); % initialize empty array to be used to build the final brain volume
    unmasker(logical(mask_data_flat)) = X_flat_thresh_neg(:,vol)'; % store the thresholded CAP in the right location where the mask existed
        
    final_vol = reshape(unmasker, [V0i(vol).dim]); % reshape to initial dimension
    current_header = V0i(vol); % get header
    current_header.fname= [CAPsPath , '/' , 'thresholded_neg',current_header.fname]; % new filename for MAC
    spm_write_vol(current_header,final_vol); % save to target path
end


end