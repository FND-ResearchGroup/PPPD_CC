%% CALCULATE OVERLAP CAP AND YEO ATLAS

% v1.0 Samantha Weber (May 2023)
% v2.0 Salome Häuselmann (October 2024)
% Adapt name of Seed-free mask that should be used (e.g.
% Yeo_AmygdalaRemoved.nii)
% Function maskAtlas should be adapted, that you do not have to change it
% manually dependent on the input. -> CC done
 

clear; clc
% Necessary: Download SPM12 tool on https://www.fil.ion.ucl.ac.uk/spm/software/download/

%% 1. Set all parameters

CAPsPath = 'E:\ConcettiC\PPPD_for_Caps\CAPs_analysis\24_Newprepro_woExcMo_CAPsScriptBased_Hippocampus\fromHC_PopMask\K3\ScriptBasedCAPs_HippocampusBilat';
K = 3; %specify number of CAPs !!!
spmPath = 'C:\Users\ConcettC\Documents\Toolboxes\spm12';
addpath (spmPath);
scriptPath = 'C:\Users\ConcettC\Documents\03_CAPs_Scripts_Salome\04_CAPs_Visualization\OverlapAtlas';
addpath(genpath(scriptPath));
AtlasPath='C:\Users\ConcettC\Documents\03_CAPs_Scripts_Salome\Atlases\Yeo';
addpath (genpath(AtlasPath));
MaskPath = 'E:\ConcettiC\PPPD_for_Caps\CAPs_analysis\24_Newprepro_woExcMo_CAPsScriptBased_Hippocampus';
addpath(genpath(MaskPath));
SeedFreeMaskName = 'Yeo_Hippocampus_Bilat_Removed.nii'; 

%% 1. Set parameters
atlas = 'Yeo' ; %choose between:  'AAL', 'Shirer', 'Hammers', 'Yeo'

% Set the atlas
switch atlas
    case 'AAL'
        nRois=90; %ROI = region of interest
        atlasFile='AAL116_correctLR.nii';
    case 'Shirer'
        nRois = 90;
        atlasFile='ShirerAtlas.nii';
    case 'Hammers'
        nRois=83;
        atlasFile='Hammers_mith_atlas_n30r83_SPM5.nii';
    case 'Brainnetome'
        nRois=246;
        atlasFile='BN_Atlas_246_1mm.nii';
    case 'HCP-ICA'
        nRois=32;
        atlasFile='networks.nii';
    case 'Yeo'
        nRois = 17;
        atlasFile = 'Yeo2011_17Networks_MNI152_1mm_LiberalMask.nii';
end

thisAtlas = fullfile(MaskPath, SeedFreeMaskName);

%% 2.  Zero-Out Non-Significant volumes in CAP
% This part uses the y_IdealFilter function from DARTEL toolbox. Function
% has been modified in order to add back the mean after filtering

%INPUT: 
%        Nifti Files of CAPs. 
%        
%OUTPUT: thresholded_CAP* files: only keep values > 1.04 or < -1.04

ZeroOutNonSig(CAPsPath);

CAP_file=dir(fullfile(CAPsPath,'thresholded*.nii')); 

tmp_sfrac = figure('units','normalized','outerposition',[0 0 1 1]);    

for s = 1:size(CAP_file,1)
    
    thisCAP=fullfile(CAPsPath,CAP_file(s).name);
    if s == 1
        % Convert Yeo atlas to functional/CAP atlas
        convert_atlas_VK(thisCAP,thisAtlas,strcat('F', SeedFreeMaskName),nRois); %VK 
    end
    thisAtlas= fullfile(CAPsPath, strcat('F', SeedFreeMaskName)); 
    maskAtlas(CAPsPath,thisCAP, AtlasPath, thisAtlas, nRois,s,K);

end

saveas(gcf,fullfile(CAPsPath,'CAP_Cake_Yeo_all.jpg'));
saveas(gcf,fullfile(CAPsPath,'CAP_Cake_Yeo_all.svg'));


