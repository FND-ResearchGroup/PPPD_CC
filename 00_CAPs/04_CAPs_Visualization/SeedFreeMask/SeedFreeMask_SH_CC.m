%% Create a seed-free mask

% v1.0 Salome Häuselmann (April 2024)
% Change the seed and the name of the output file accordingly. 

clear; clc


%% 1. Set all parameters

spmPath = 'C:\Users\ConcettC\Documents\Toolboxes\spm12';
addpath (spmPath);
toolboxPath = 'C:\Users\ConcettC\Documents\Toolboxes\TbCAPs-master';
addpath (toolboxPath);
scriptPath = 'C:\Users\ConcettC\Documents\03_CAPs_Scripts_Salome\04_CAPs_Visualization';
addpath(genpath(scriptPath));
AtlasPath='C:\Users\ConcettC\Documents\03_CAPs_Scripts_Salome\Atlases\Yeo';
addpath (genpath(AtlasPath));
SeedPath = 'E:\ConcettiC\PPPD_for_Caps\Seeds_for_CAPs';
addpath(genpath(SeedPath));
savePath = 'E:\ConcettiC\PPPD_for_Caps\CAPs_analysis\24_Newprepro_woExcMo_CAPsScriptBased_Hippocampus';
addpath(genpath(savePath));

% Read in atlas 
atlasFile=fullfile(AtlasPath,'Yeo2011_17Networks_MNI152_1mm_LiberalMask.nii');
AV0i=spm_vol(atlasFile); % Load the NIfTI file        
% Read in Seed 
seedFileName = 'Hippocampus_Bilat.nii';
seedFile=fullfile(strcat(SeedPath, '.\', seedFileName));
SV0i=spm_vol(seedFile); % Load the NIfTI file


%% 2. build 3D of Atlas & Seed
% initialise storage of Matrix (nPixels x nPixels x nSlices)
AV0=zeros(AV0i(1).dim(1),AV0i(1).dim(2),AV0i(1).dim(3),length(AV0i),'single');

% store Atlas as 3D volume
AV0(:,:,:)=spm_read_vols(AV0i);


% Coregister Seed Mask to Atlas -> Reslice 
matlabbatch{1}.spm.spatial.coreg.write.ref = {atlasFile};
matlabbatch{1}.spm.spatial.coreg.write.source = {seedFile};
matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 4;
matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';

spm('defaults', 'FMRI');
spm_jobman('run', matlabbatch);

%Alternative create mask manually with tha MarsBaR Toolbox
%Create .mat file of the of the Seed Mask: Build ROI -> Chose Seed Mask
%-> Maintain as binary image: yes -> Apply function to image: no -> .mat
%file of seed mask is created.
%Save seed-mask in the dimension of a refrence space: Export ROI(s) to
%image -> chose new .mat file -> Space for ROI image from image -> chose
%Yeo Atlas (or other reference image) -> save seed mask within the new
%space.


% Load the resliced seed file
rSeedFile = fullfile(strcat(SeedPath,'.\r', seedFileName));
rSV0i = spm_vol(rSeedFile);
% initialise storage of Matrix (nPixels x nPixels x nSlices)
rSV0=zeros(rSV0i(1).dim(1),rSV0i(1).dim(2),rSV0i(1).dim(3),length(rSV0i),'single');
% store Seed as 3D volume
rSV0(:,:,:)=spm_read_vols(rSV0i);

%% 3. Create a new seed-free mask

seed_free_mask = AV0; % Initialize with the atlas

% Find voxels in the seed mask and set corresponding voxels in the atlas to 0
seed_voxels = rSV0(:) == 1;
seed_free_mask(seed_voxels) = 0;

%% 4. Save the seed-free mask

% Define the output file path
outputFile = fullfile(strcat(savePath, '.\Yeo_', seedFileName(1:end-4), '_Removed.nii'));

% Create a new NIfTI header based on the first volume of the atlas
new_header = AV0i(1);
new_header.fname = outputFile;

% Write the seed-free mask to a NIfTI file using the new header
spm_write_vol(new_header, seed_free_mask);

% Delete the rSeed.nii file that is not needed anymore.
delete(strcat(rSeedFile)); % Deletes the resliced file from disk
