%% CALCULATE OVERLAP CAP AND YEO ATLAS

% v1.0 Samantha Weber (May 2023)
% Take care! Inside of function maskAtlas, you should sometimes change
% things manually depending on your input. 
% I was too lazy to programm it beautiful. Sorry for that. 

clear; %clc
% Necessary: Download SPM12 tool on https://www.fil.ion.ucl.ac.uk/spm/software/download/

%% 1. Set all parameters
CAPsPath = '/Volumes/T7_Samantha/BioGen_fMRI_Analysis/CAPs/03_SaveData/PCA_CAPs_Final/TwoPop_Final_Insula_Population/TwoPopulation_PCA_Final';
CAPsPath2= '/Volumes/T7_Samantha/BioGen_fMRI_Analysis/CAPs/03_SaveData/PCA_CAPs_Final/Revisions_FNDReference/TwoPop_Final_INSULA_FND_Population/TwoPopulation_PCA_Final';
spmPath = '/Users/samanthaweber/spm12';
addpath (spmPath);
scriptPath = '/Users/samanthaweber/Documents/GitHub/CAPs_SW/07_Reviews';
addpath(genpath(scriptPath));
% % AtlasPath='/Volumes/T7_Samantha/BioGen_fMRI_Analysis/Codes/Atlases';
% % addpath (genpath(AtlasPath));
% % MaskPath = '/Users/samanthaweber/Documents/GitHub/CAPs_SW/03_CAPs_Analysis/DefaultData';
% % addpath(genpath(MaskPath));
% % thisMask = 'GM_Mask_Population.nii';
% % 
% % %% 1. Set parameters
% % %thisCAP= 'CAP_NIFTI_ZScored_TwoPopulation_PCA_Final_CAP1.nii';
% % atlas = 'Yeo' ; %choose between:  'AAL', 'Shirer', 'Hammers', 'Yeo'
% % nRois = 17;
% % atlasFile = 'FYeo_SeedRemoved.nii';
% % 
% % thisAtlas=fullfile(CAPsPath,atlasFile);


%atlasing_CAPs()

%% 2.  Zero-Out Non-Significant volumes in CAP
% This part uses the y_IdealFilter function from DARTEL toolbox. Function
% has been modified in order to add back the mean after filtering

%INPUT: 
%        Nifti Files of CAPs. 
%        
%OUTPUT: thresholded_CAP* files: only keep values > 1.04 or < -1.04
% % 
% % ZeroOutNonSig(CAPsPath);
% % 
% % % First find out how many voxels are in seed (to remove that later). A
% % % structural atlas mask first has to be done using MakeAALMaskOverlap.m
% % 
% % 
% % SeedPath = '/Users/samanthaweber/Documents/GitHub/CAPs_SW/03_CAPs_Analysis/Masks_AAL';
% % Seed_file=dir(fullfile(SeedPath,'Amygdala_mask.nii'));   
% % thisSeed=fullfile(SeedPath,Seed_file.name);



% Now we calculate the amount of overlap, by subtracting the seed. 

CAP_file=dir(fullfile(CAPsPath,'thresholded*.nii')); 
CAP2_file=dir(fullfile(CAPsPath2,'thresholded*.nii'));
% Fi=spm_vol(CAP_file(1).name); %get dimensions


tmp_sfrac = figure;    
cd(CAPsPath);
for s = 1:size(CAP_file,1)
    
    thisCAP=fullfile(CAPsPath,CAP_file(s).name);
    thisCAP2=fullfile(CAPsPath2,CAP2_file(s).name);

    if s == 1
        % Convert Yeo atlas to functional/CAP atlas
%         convert_atlas_VK(thisCAP,thisAtlas,'FYeo.nii',nRois); %VK
%         cd(SeedPath);
%         VOut = mapVolumeToVolume(thisSeed,thisCAP);
%         %convert_atlas_VK(thisCAP,thisSeed,'FYeo_Seed.nii',nRois); %VK
%         Fi.fname= [SeedPath , '/' , 'Overlay_Seed.nii']; % new filename for MAC
%         spm_write_vol(Fi,VOut); % save to target path
    end
%     Rois_tot_Seed = maskAtlas2Seed(CAPsPath,thisCAP, SeedPath,thisSeed, nRois);
    maskCAP(CAPsPath,thisCAP,CAPsPath2, thisCAP2,  s);

end

    



