%% Preparation CAPs
% This code must be run before running the CAPs toolbox. 
% Newest version implemented August 2021 by Samantha Weber
% This code uses functions from Dimitri Van De Ville, Jonas Richiardi and Serafeim Loukas

% v1.0 Samantha Weber (June 2021)
% v1.1 Samantha Weber (August 2021)
% v2.0 Samantha Weber (June 2022): adapted WM/CSF regression (blobs) and
% filtering
% Salome Häuselmann (May 2024): modified filterBOLDsignal function.

% 1. Set parameters (subjects, paths, motion)
% 2. Realignment of functional volumes & co-registration of functional data
% to the structural T1 volume. 
% 3. Extraction of average WM and CSF signal as covariate. Linear
%    detrending. Regress out motion and average signal mask of WM and CSF
% 4. Nonlinear warping into MNI space and Smoothing
% 5. High-pass filtering of the BOLD time courses

%!!!! Filtering is done at the end !!!

%Line 191: remove first N scans - INPUT!! Doesn't work

clear; clc
% Necessary: Download SPM12 tool on https://www.fil.ion.ucl.ac.uk/spm/software/download/

%% 1. Set all parameters

% Set paths
% Set filter options
% Names and folders are found independently with the following folder
% structure:
% Datafolder
%   FND
%       > Subject (P*) 
%           > struct
%           > funct
%   HC
%       > Subject (P*) 
%           > struct
%           > funct

f = waitbar(0,'Please wait...');
pause(1)
waitbar(.20,f,'Search paths...');
pause(1)
waitbar(.30,f,'Set paths...');
%Scripts path
scriptsPath = 'C:\Users\ConcettC\Documents\CPP_SH-main\CPP_SH-main\03_MRI\03_CAPs\01_CAPs_Preparation';
addpath (genpath(scriptsPath));
waitbar(.50,f,'Set paths...');
%spm Path
spmPath = 'C:\Users\ConcettC\Documents\Toolboxes\spm12';
addpath (spmPath);
waitbar(.60,f,'Set paths...');
%RootPath
RootPath= 'E:\ConcettiC\PPPD_for_Caps\OriginalData_ForPreprocessing_ForCAPs\AllSubjects_woExcessMov';
%RootPath= '/Users/salomehauselmann/Daten/Analysis/03_MRI/03_Preprocessing_CAPs/CAPs_Preprocessed_Data/neu';
addpath (genpath ('RootPath'));%(3)
waitbar(.70,f,'Set paths...');
waitbar(.80,f,'Set paths...');
% Mask Path
% maskPath=fullfile(scriptsPath,'mymask.nii'); %% MAKE A MASK FOR EACH INDIVIDUAL
masksPath='C:\Users\ConcettC\Documents\CPP_SH-main\CPP_SH-main\03_MRI\03_CAPs\01_CAPs_Preparation\preprocessing\Masks';
addpath (genpath(masksPath));
waitbar(1,f,'Finishing');
pause(.5)
close(f)

%savePath=fullfile(RootPath,'02_Output_Datapreparation_CAPs'); 
%mkdir(savePath);

%% 1. Set parameters
myGroups={'HC','PPPD'};
% load P-codes HC;
filelist=dir(fullfile(RootPath, myGroups{1},'P*'));
N_HC=size(filelist,1);
myHC=cell(1,N_HC);
for f=1:N_HC
    myHC{f}=filelist(f).name;
end
clear filelist f

%load P-codes CPP
filelist=dir(fullfile(RootPath, myGroups{2},'P*'));
N_CD=size(filelist,1);
myCD=cell(1,N_CD);
for f=1:N_CD
    myCD{f}=filelist(f).name;
end
clear filelist f

mySubjects = [myHC,myCD];
N_HC = length(myHC); N_CD = length(myCD); nSubj=N_HC+N_CD;
       
% 
% %load P-codes (no Groups)
% filelist=dir(fullfile(RootPath, 'P*'));
% nSubj=size(filelist,1);
% mySubjects=cell(1,nSubj);
% for f=1:nSubj
%     mySubjects{f}=filelist(f).name;
% end
% clear filelist f

      

%% Define all parameters

filtering='highpass';
nTimePoints=300; %Number of Scans (timepoints)
%How many movement parameters to regress out (6 is recommended)
mvtParams='6';

% Define the folders
%Healthy controls
for i = 1:N_HC
    folders{i} = fullfile(RootPath, myGroups{1},mySubjects{i});
end
%FND patients
for i = N_HC+1:nSubj
    folders{i} = fullfile(RootPath, myGroups{2},mySubjects{i});
end
%No Groups
% for i = 1:nSubj
%     folders{i} = fullfile(RootPath, mySubjects{i});
% end

%1.2 Definition of Filtering parameters
switch filtering
    case 'highpass'    
        band =[0.01 0]; % [LowCutoff_HighPass 0]: high pass filtering
        TR=1.3;
    case 'bandpass'
        band=[0.01 0.08]; % [LowCutoff_HighPass HighCutoff_LowPass]: band pass filtering
        TR=1.3;
end

%% 2. Realignment, Co-Registration, Segmentation
% Additionally, an individual brain mask is created. 

%INPUT:  Functional (f*) and structural (s*) data
%        
%OUTPUT: Motion parameters (6): x-,y-,z- Translation
%                               x-,y-,z- Rotation
%        realigned functional images (rf*)
%        segmented structural images (c*)
%        individual Brain mask (myMask*)

for i= 1:nSubj   
    disp(['***Preprocessing Subject ' num2str(i) ' out of ' num2str(nSubj) ' Subjects...']);
    % Start the preprocessing
    warning('off','MATLAB:dispatcher:nameConflict');
    % Check if last file of function real_coreg_seg subject exists, if yes,
    % the code worked and doesn't need to be repeated
    segPath = fullfile(folders{i}, 'struct');
    segfiles = cellstr(spm_select('ExtFPList',segPath,'^mc.*.nii',1));
    if size(segfiles,1)==3 %there are 3 files of mc*
        disp(['Data of ' mySubjects{i} ' is already realigned and coregistered !'])
    else
        real_coreg_seg_subject(folders{i},1); % 1 = run as code 2 = run
        % interactively -> use this function normally.
        % real_coreg_seg_subject_without_VDM(folders{i},1); % used this function for P167, since the BO field files were corrupted and the VDM calculation was not possibl 
    end
end

clear s

%% 3. Regress out Nuissance: Extraction of Average signal of WM and CSF, motion, detrending)
% Functions used from Serafeim Loukas

% This block uses the function 'RegressOutNuissance'. 
% It takes the segmented files of the white matter (WM) and the cerebrospinal fluid (CSF) and uses it as a mask. 
% The signal of the WM&CSF will be used later as regressors in our Design Matrix together with the motion parameters (rp*.txt)
%
% Further, the BOLD signal is detrended.
% Motion, CSF and WM signal is regressed out

%INPUT: 
%        Segmented WM and CSF files (c2*.nii/c3*.nii)
%        Motion parameters (6): x-,y-,z- Translation
%                               x-,y-,z- Rotation
%OUTPUT: Det_rf* files: detrended, covariates regressed out

for s=1:nSubj  
    disp(['***Extraction of average Signal from Subject ' num2str(s) ' out of ' num2str(nSubj) ' Subjects***']);
    %Define paths and parameters
    structPath=fullfile(folders{s},'struct');
    functPath=fullfile(folders{s},'funct'); 
    Detrend = 1; % 0 or 1 for no or yes
    removeFirstNscans = 0; % remove N first vols
    pre_f='rf'; % slice-timing corrected % realigned volumes will be used
    paths.f = functPath;
    paths.sseg = structPath; 
    
    %% Run the regression
    % Includes extraction of average WM and CSF signal, detrending and GLM
    detfiles = cellstr(spm_select('ExtFPList',functPath,'^Det_.*.nii',1));
    if size(detfiles,1)==nTimePoints
        disp(['Data of ' mySubjects{s} ' is already detrendend and covariates regressed out !'])
    else
        %RegressOutNuissance(paths,pre_f,Detrend,removeFirstNscans,masksPath)%use
        %this for FC analysis
        RegressOutNuissance_GSR(paths,pre_f,Detrend,removeFirstNscans,masksPath) %use for CAPs analysis
        save = 'no';
    end
    
end
%Save intermediate steps
% only save intermediate steps, if a subject is newly processed, otherwise
% it will write it over
switch 'save'
    case'yes'
         save(fullfile(savePath, 'preprocessedTimeseries_detrended_confoundsRegressedOut.mat'));
end

clear s

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4.  Filtering
% This part uses the y_IdealFilter function from DARTEL toolbox. Function
% has been modified in order to add back the mean after filtering

%INPUT: 
%        artefacts regressed out and detrended images (Det_rf*)
%        
%OUTPUT: clean_Det_rf* files: detrended, covariates regressed out, and
%        highpass filtered (using a passband at 0.01Hz)

for s = 1:nSubj
    disp(['***Filtering Subject ' num2str(s) ' out of ' num2str(nSubj) ' Subjects...']);
    structPath=fullfile(folders{s},'struct');
    functPath=fullfile(folders{s},'funct'); 
    cleanfiles = cellstr(spm_select('ExtFPList',functPath,'^clean_Det_.*.nii',1));
    if size(cleanfiles,1)==nTimePoints
            disp(['Data of ' mySubjects{s} ' is already filtered !'])
        else
            filterBOLDsignal_v5(functPath, structPath, TR, band);
    end

end

%Save intermediate steps
% only save intermediate steps, if a subject is newly processed, otherwise
% it will write it over
switch 'save'
    case'yes'
         save(fullfile(savePath, 'preprocessedTimeseries_filtered.mat'));
end

clear s

% NET.addAssembly('System.Speech');
% speaker = System.Speech.Synthesis.SpeechSynthesizer();
% speaker.Rate = 1;
% speaker.Volume = 100;
% speaker.Speak("Hi Samantha, it's me again! Your stupid data is also filtered now! Next time you can do it yourself again!");

%% 5. Warp data into MNI space and smooth the data
% This part normalizes images to MNI standard space and smoothes the images
% with a FWHM of 5mm using spm functions. 

%INPUT:  clean_Det_rf* files
%        
%OUTPUT: wclean_Det_rf*: normalized images
%        s5wclean_Det_rf*: smoothed functional images

for s = 1:nSubj
    
    structPath=fullfile(folders{s},'struct');
    functPath=fullfile(folders{s},'funct'); 
    smoothfiles = cellstr(spm_select('ExtFPList',functPath,'^s5w.*.nii',1));
    
    disp(['***Normalize and smooth subject ' num2str(s) ' out of ' num2str(nSubj) ' subjects...']);
    % Start the preprocessing
    if size(smoothfiles,1)==nTimePoints
        disp(['Data of ' mySubjects{s} ' is already normalized and smoothed !'])
    else
        warning('off','MATLAB:dispatcher:nameConflict');
        norm_smooth(folders{s},1); % 1 = run as code 2 = run interactively
    end
end


 disp('****The Data is preprocessed');

% NET.addAssembly('System.Speech');
% speaker = System.Speech.Synthesis.SpeechSynthesizer();
% speaker.Rate = 1;
% speaker.Volume = 100;
% speaker.Speak("I'm done with the Pre-processing.");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return; 
