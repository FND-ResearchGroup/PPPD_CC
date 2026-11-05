function [X_flat_clean] = filterBOLDsignal_v2(functfolder, mask_path, TR, band)
% Extraction of grey-matter masked BOLD signal

% Inputs:
%       functfolder: Path to subject functional folder 
%
% Outputs:
%       X_flat: 2-dimensional data matrix containing [nVoxels x
%       nTimePoints]
%
% Created: June 2021, Samantha Weber, University of Bern & Serafeim Loukas, EPFL

%% PART 1: loading 

% Check if folder exists
if ~exist(functfolder, 'dir')
    error('Could not find functional folder');
end

% Read in functional data
[myListofFiles,dontcare]=spm_select('List', functfolder, '^Det_.*'); % make list of all functional volumes
cd(functfolder)
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

%% PART 3: extract signals (whole image)
% uncomment if you want to work with whole brain image
% V0_size=size(V0);
% X_flat = zeros(prod(V0_size(1:3)), size(V0,4)); % size = image voxels (including background !) x time-points
% voxel_counter=1;
% tic
% for z = 1:size(V0,3)
%     for y = 1:size(V0,2)
%         for x = 1:size(V0,1)
%             X_flat(voxel_counter,:) = squeeze(V0(x,y,z,:))';
%             voxel_counter = voxel_counter + 1;
%         end
%     end
% end
% toc


%% Part 3: Write structural Mask into functional mask
V0_size=size(V0);
%Write mask into same dimensions as functional data
thismask = fullfile(mask_path,'myMask_256x256x176.nii'); %select structural mask %mask = spm_vol(thismask);
thisfile=fullfile(functfolder,V0i(1).fname); %select first functional file
mask_data=mapVolumeToVolume(thismask,thisfile); %Map strctural mask dimension of realigned functional data

%Safe and write new mask with same dimensions as functional data
thisVol = V0i(1); 
thisVol.fname = 'myMask_104x104x60.nii';
cd(mask_path); %safe in struct folder
%spm_write_vol(thisVol, mask_data); %write new mask

%mask_data = spm_read_vols(mask);
% sanity check i.e. same mask size as the brain vols
if isequal(size(mask_data), V0_size(1:3))== 0
    error('Mask is not same size as brain volume!!');
end

%% PART 4: Realistic case: extract signals using a brain mask !
% the extracted data will be signals from voxels that are WITHIN the brain
% (i.e. non negative elements of the mask)
% thus, the dimension is  nnz(mask_data) = 219381
% in other words, we have 219381 voxels in the brain.

% initialize matrix to store results
X_flat = zeros(nnz(mask_data), size(V0,4));

tic
% we will work on each volume
for vol = 1:size(V0,4)
    % get current 3D brain volume (single time-point)
    current_volume = V0(:,:,:,vol);
    % flatten the volume into a vector - makes life and computations easier
    flat_brain_volume = reshape(current_volume, [1, numel(current_volume)]);
    % mask the flat brain volume using the mask, first flatten the mask and make it boolean
    flat_brain_volume_masked = flat_brain_volume(logical(reshape(mask_data, [1, numel(mask_data)])));
    
    if isequal(size(flat_brain_volume_masked,2), nnz(mask_data))== 0
    error('Mask is not same size as brain volume!!');
    end
    % Note: "size(flat_brain_volume_masked,2)" should be = to
    % "nnz(mask_data)"
    
    % store the results
    X_flat(:, vol) = flat_brain_volume_masked';
end
toc

%% 5. Filter the data

% initialize matrix to store results
X_flat_clean = zeros(size(X_flat));

% Filter data
disp('*** Filter the data...');

% %%Filter "all in one"
% X_flat_clean = y_IdealFilter_SW(X_flat,TR,band); % input must be nTimepoints x nTimeSeries = 300 x nVoxels
% 
% hold on
% plot(X_flat_clean(:,5783)) %plot random voxel
% hold on
% plot(X_flat(:,5783))
% legend('filtered','not-filtered')

%% we will work on each voxel "voxel-wise"
assert(size(X_flat,2)==300)
% for voxel = 1:size(X_flat,2)
%     current_voxel_BOLD = X_flat(:,voxel); % this is the BOLD signal of voxel i 
%     
%     if voxel == 1; assert(size(X_flat(:,1),1) == 300); end % each voxel time-series has lenght 300 (timepoints)
%     
%     %filtered = highpass(current_voxel_BOLD,0.01,fs); % see docs: https://fr.mathworks.com/help/signal/ref/highpass.html
%     filtered = y_IdealFilter_SW(current_voxel_BOLD,TR,band);  %high-pass, as requested input for y_IdealFilter to high-passfilter data
%     X_flat_clean(:,voxel) = filtered;
% end

filtered = y_IdealFilter_SW_SL(X_flat',TR,band); 
X_flat_clean = real(filtered'); 
%save('2d.mat', 'X_flat_clean')

%% PART 6: reshape back and save as .nii
% the initial mask flattened
mask_data_flat = reshape(mask_data, [1, numel(mask_data)]); 

assert(size(X_flat_clean,2)==300)
% we will work on each volume
for vol = 1:size(X_flat_clean,2)
    unmasker = zeros(1, numel(mask_data)); % initialize empty array to be used to build the final brain volume
    unmasker(logical(mask_data_flat)) = X_flat_clean(:,vol); % store the clean data in the right location where the mask existed
    
    %if vol == 1; assert(size(X_flat_clean(:,vol),1) == 156802); end % each flat volume is a vector with length 156802
    
    final_vol = reshape(unmasker, [V0i(vol).dim]); % reshape to initial dimension
    current_header = V0i(vol); % get header
    %current_header.fname= [functfolder , '\' , 'clean_',current_header.fname]; % new filename for WINDOWS
    current_header.fname= [functfolder , '/' , 'clean_',current_header.fname]; % new filename for MAC
    spm_write_vol(current_header,final_vol); % save to target path
end


end