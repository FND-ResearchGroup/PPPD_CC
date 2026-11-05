function [X_flat_clean] = filterBOLDsignal_v4(functfolder, mask_path, TR, band)
% Extraction of grey-matter masked BOLD signal

% Inputs:
%       functfolder: Path to subject functional folder 
%
% Outputs:
%       X_flat: 2-dimensional data matrix containing [nVoxels x
%       nTimePoints]
%
% Created: June 2021, Samantha Weber, University of Bern & Serafeim Loukas, EPFL
% April 2024, Very small modifications by Salome Häuselmann (Part 1, Part 3)

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
for iter=1:length(V0i)
    V0(:,:,:,iter)=spm_read_vols(V0i(iter));
end   

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
%
% mask = fullfile(RootPath,'myMask_79x95x79.nii'); %select structural mask %mask = spm_vol(thismask);
% load(fullfile(RootPath, 'mask_data.mat'),'mask_data');
% %Warp mask to MNI Space
% Write c1 to standard space
 matlabbatch{1}.spm.spatial.normalise.write.subj.def = cellstr(spm_select('FPList',mask_path,'^y.*\.nii$'));
 matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {thismask};
 matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                           78 76 85];
 matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
 matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
 matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w'; 
 spm_jobman('run',matlabbatch);
% %spm_jobman('interactive',matlabbatch);
 clear matlabbatch

thismask = fullfile(mask_path,'wmyMask_256x256x176.nii'); %select structural mask %mask = spm_vol(thismask);
thisfile=fullfile(functfolder,V0i(1).fname); %select first functional file
%warning('off');
mask_data=mapVolumeToVolume(thismask,thisfile); %Map strctural mask dimension of realigned functional data

%Safe and write new mask with same dimensions as functional data
thisVol = V0i(1); 
thisVol.fname = 'wmyMask_79x95x79.nii';
cd(mask_path); %safe in struct folder
spm_write_vol(thisVol, mask_data); %write new mask

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

%% 6. Filter the data

% initialize matrix to store results
X_flat_clean = zeros(size(X_flat));

% Filter data
disp('*** Filter the data...');

% %%Filter "all in one"
% X_flat_clean = y_IdealFilter_SW(X_flat,TR,band); % input must be nTimepoints x nTimeSeries = 300 x nVoxels
% 


%% we will work on each voxel "voxel-wise"
assert(size(X_flat,2)==300)
tic
%Either uncomment this: 
%filtered = highpass(X_flat',0.01,1/TR); % see docs: https://fr.mathworks.com/help/signal/ref/highpass.html
% sampling rate in Hz --> 1image/TR
%X_flat_clean = filtered';

%filtered = my_wavelet(X_flat,3,0,5,5);%connectivityDecoding_filtering(X_flat,5,5); % see docs: https://fr.mathworks.com/help/signal/ref/highpass.html
%X_flat_clean = filtered;


% or this: 
filtered = y_IdealFilter_SW_SL(X_flat',TR,band); 
%X_flat_clean = filtered'; 
X_flat_clean = real(filtered'); 

%Plot it
%hold on
plot(X_flat(54936,:)) %plot random voxel
hold on
plot(X_flat_clean(54936,:))
legend('not-filtered','filtered')


%% PART 5: reshape back and save as .nii
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