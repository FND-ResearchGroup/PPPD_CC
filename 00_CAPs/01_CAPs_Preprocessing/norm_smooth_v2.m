function matlabbatch = norm_smooth_v2(dataDir, run)

% matlabbatch = preproc_subject(dataDir, run)
% Performs / sets up a preprocessing pipeline.
%
% Inputs:
%       dataDir: Path to subject data folder (must contain structural/ and
%                 functional/ subfolders)
%       run:      if 0 -> just create struct [default]
%                 if 1 -> run directly
%                 if 2 -> run interactively (open Batch editor with analysis)
%
% Outputs:
%       matlabbatch: batch containing information about analysis.
%
% Created: Oct 2018, Jakob Heinzle, Translational Neuromodeling Unit, IBT
% University and ETH Zurich
% Adapted: June 2021, Samantha Weber, University of Bern

if nargin < 2
    run = 0;
end

% Check whether data folder exists.
if ~exist(dataDir, 'dir')
    error('Could not find specified data folder');
end
% Check whether subfolders exist.
struct_dir = fullfile(dataDir, 'struct');
if ~exist(struct_dir, 'dir')
    error('Could not find structural/ subfolder');
end
funct_dir = fullfile(dataDir, 'funct');
if ~exist(funct_dir, 'dir')
    error('Could not find functional/ subfolder');
end

% Find out where the Tissue Probability Maps (TPMs) of SPM are located
% on your computer.
tpm_dir = fullfile(fileparts(which('spm')), 'tpm');

matlabbatch = {};
Tstart = clock;

%--------------------------------------------------------------------------
% Load functional files
    functfiles = cellstr(spm_select('ExtFPList',funct_dir,'^Det_rf.*.nii',1));
    
%--------------------------------------------------------------------------
% Normalize: Write

    % Write functionals to standard space
    matlabbatch{1}.spm.spatial.normalise.write.subj.def = cellstr(spm_select('FPList',struct_dir,'^y.*\.nii$'));
    matlabbatch{1}.spm.spatial.normalise.write.subj.resample = functfiles;
    matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                              78 76 85];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
    matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
    matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';

%--------------------------------------------------------------------------
% Smoothing: functional volumes
    matlabbatch{2}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
    matlabbatch{2}.spm.spatial.smooth.fwhm = [5 5 5];
    matlabbatch{2}.spm.spatial.smooth.dtype = 0;
    matlabbatch{2}.spm.spatial.smooth.im = 0;
    matlabbatch{2}.spm.spatial.smooth.prefix = 's5';

%--------------------------------------------------------------------------
% Start spm

if run == 2
    spm_jobman('initcfg');
    spm_jobman('interactive',matlabbatch);
elseif run == 1
    spm_jobman('initcfg');
    spm_jobman('run',matlabbatch);
end

Ttotal=etime(clock, Tstart);
disp(['** DONE SMOOTHING AND NORMALIZATION. Total time: ' num2str(Ttotal/60,'%3.1f') ' min.']);
