%% Make Population-wise grey matter mask
% Each subject's grey matter segmented image will be normalized. All images
% will be summed up, divided by nSubj and thresholded. 

%% 1. Set all parameters

% Set paths
% Set filter options
% Names and folders are found independently with the following folder
% structure:
% Datafolder
%   CPP
%       > Subject (P*) 
%           > struct
%           > funct
%   HC
%       > Subject (P*) 
%           > struct
%           > funct

%Scripts path
scriptsPath = 'C:\Users\Samantha\Documents\GitHub\CAPs_SW\01_CAPs_Preparation';
addpath (genpath(scriptsPath));
spmPath = 'C:\toolbox\spm12';
addpath (spmPath);
RootPath= 'D:\BioGen_fMRI_Analysis\CAPs\01_Data';
addpath (genpath ('RootPath'));%(3)
spm_jobman('initcfg');

%% 1. Set parameters
myGroups={'HC','CPP'};
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


      

%% Define all parameters

threshold=0.9;
% Define the folders

%Healthy controls
for i = 1:N_HC
    folders{i} = fullfile(RootPath, myGroups{1},mySubjects{i});
end
%CPP patients
for i = N_HC+1:nSubj
    folders{i} = fullfile(RootPath, myGroups{2},mySubjects{i});
end


%% 2. Realignment, Co-Registration, Segmentation
% Additionally, an individual brain mask is created. 

%INPUT:  segmented (mc1*) data
%        
%OUTPUT: Population-wise grey matter mask

for i= 1:nSubj   
    warning('off','MATLAB:dispatcher:nameConflict');
    % Check if last file of function real_coreg_seg subject exists, if yes,
    % the code worked and doesn't need to be repeated
    segPath = fullfile(folders{i}, 'struct');
    segfile = cellstr(spm_select('ExtFPList',segPath,'^c1.*.nii',1));
    
    disp(['Normalizing ' mySubjects{i} ' ...'])

    % Normalize: Write
    % Write c1 to standard space
    matlabbatch{1}.spm.spatial.normalise.write.subj.def = cellstr(spm_select('FPList',segPath,'^y.*\.nii$'));
    matlabbatch{1}.spm.spatial.normalise.write.subj.resample = segfile;
    matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                              78 76 85];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
    matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w'; 
    
    
    matlabbatch{2}.spm.util.imcalc.input = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
    matlabbatch{2}.spm.util.imcalc.output = 'w80_c1.nii';
    matlabbatch{2}.spm.util.imcalc.outdir = {segPath};
    matlabbatch{2}.spm.util.imcalc.expression = 'i1>0.8';
    matlabbatch{2}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    matlabbatch{2}.spm.util.imcalc.options.dmtx = 0;
    matlabbatch{2}.spm.util.imcalc.options.mask = 0;
    matlabbatch{2}.spm.util.imcalc.options.interp = 1;
    matlabbatch{2}.spm.util.imcalc.options.dtype = 4;
    
    spm_jobman('run',matlabbatch);
    clear matlabbatch

end
clear i

segfiles = {};

exp = '((';
for i = 1:nSubj

    if i == nSubj
        exp = [exp, 'i' num2str(i)];
    else
        exp = [exp, 'i' num2str(i) ' + '];
    end
end
exp = [exp, ')/' num2str(nSubj) ')>' num2str(threshold)];

clear i
for i= 1:nSubj   
    warning('off','MATLAB:dispatcher:nameConflict');
    % Check if last file of function real_coreg_seg subject exists, if yes,
    % the code worked and doesn't need to be repeated
    segPath = fullfile(folders{i}, 'struct');
    segfile = cellstr(spm_select('ExtFPList',segPath,'^w80_c1_*.nii',1));
    segfiles{i,1} = segfile{1};
end


% Make mask
    matlabbatch{1}.spm.util.imcalc.input = segfiles;
    matlabbatch{1}.spm.util.imcalc.output = 'GM_Mask_Population.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {RootPath};
    matlabbatch{1}.spm.util.imcalc.expression = exp;
    matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
    matlabbatch{1}.spm.util.imcalc.options.mask = 0;
    matlabbatch{1}.spm.util.imcalc.options.interp = 1;
    matlabbatch{1}.spm.util.imcalc.options.dtype = 4; 
    
    %spm_jobman('interactive',matlabbatch);
    spm_jobman('run',matlabbatch);
    

