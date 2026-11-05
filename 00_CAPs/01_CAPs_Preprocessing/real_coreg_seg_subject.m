function matlabbatch = real_coreg_seg_subject(dataDir, run)

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
phase_dir = fullfile(funct_dir, 'b0_2');
if ~exist(phase_dir, 'dir')
    error('Could not find b0/ subfolder');
end

magnitude_dir = fullfile(funct_dir, 'b0_1');
if ~exist(magnitude_dir, 'dir')
    error('Could not find b0/ subfolder');
end

% This is scanner specific.
prisma_dir = which('pm_defaults_Prisma_updmb4_104mat');
if ~exist(prisma_dir, 'file')
    error('Could not find prisma/ subfolder');
end

% Find out where the Tissue Probability Maps (TPMs) of SPM are located
% on your computer.
tpm_dir = fullfile(fileparts(which('spm')), 'tpm');

matlabbatch = {};
Tstart = clock;

%--------------------------------------------------------------------------
% Calculate VDM

    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = cellstr(spm_select('ExtFPList',phase_dir,'^s.*02.nii',1));
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = cellstr(spm_select('ExtFPList',magnitude_dir,'^s.*01.nii',1));
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsfile = cellstr(prisma_dir);
    functfiles = cellstr(spm_select('ExtFPList',funct_dir,'^f.*.nii',1));
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session.epi = functfiles(1);
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 1;
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'session';
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 1;
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.anat = cellstr(spm_select('ExtFPList',struct_dir,'^s.*01.nii',1));
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 0;
    
%--------------------------------------------------------------------------
% Realignment: Motion correction, unwarping and realignment

    matlabbatch{2}.spm.spatial.realignunwarp.data.scans = functfiles; % Load functional files
    matlabbatch{2}.spm.spatial.realignunwarp.data.pmscan(1) = cfg_dep('Calculate VDM: Voxel displacement map (Subj 1, Session 1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','vdmfile', '{}',{1}));
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.sep = 4;
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.rtm = 0;
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.einterp = 2;
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.weight = '';
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.jm = 0;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.sot = [];
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.rem = 1;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.noi = 5;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.mask = 1;
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.prefix = 'r';

%--------------------------------------------------------------------------
% Slice timing correction
%     matlabbatch{3}.spm.temporal.st.scans{1}(1) = cfg_dep('Realign & Unwarp: Unwarped Images (Sess 1)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{1}, '.','uwrfiles'));
%     matlabbatch{3}.spm.temporal.st.nslices = 60;
%     matlabbatch{3}.spm.temporal.st.tr = 1.3;
%     matlabbatch{3}.spm.temporal.st.ta = 0;
%     matlabbatch{3}.spm.temporal.st.so = [0 0.6825 0.085 0.7675 0.17 0.8525 0.255 0.9375 0.3425 1.025 0.4275 1.11 0.5125 1.195 0.5975 0 0.6825 0.085 0.7675 0.17 0.8525 0.255 0.9375 0.3425 1.025 0.4275 1.11 0.5125 1.195 0.5975 0 0.6825 0.085 0.7675 0.17 0.8525 0.255 0.9375 0.3425 1.025 0.4275 1.11 0.5125 1.195 0.5975 0 0.6825 0.085 0.7675 0.17 0.8525 0.255 0.9375 0.3425 1.025 0.4275 1.11 0.5125 1.195 0.5975];
%     matlabbatch{3}.spm.temporal.st.refslice = 30;
%     matlabbatch{3}.spm.temporal.st.prefix = 'a';

%--------------------------------------------------------------------------
% Segmentation
    matlabbatch{3}.spm.spatial.preproc.channel.vols = cellstr(spm_select('ExtFPList',struct_dir,'^s.*01.nii',1));
    matlabbatch{3}.spm.spatial.preproc.channel.biasreg = 0.001;
    matlabbatch{3}.spm.spatial.preproc.channel.biasfwhm = 60;
    matlabbatch{3}.spm.spatial.preproc.channel.write = [0 1];
    matlabbatch{3}.spm.spatial.preproc.tissue(1).tpm = {fullfile(tpm_dir,'TPM.nii,1')};
    matlabbatch{3}.spm.spatial.preproc.tissue(1).ngaus = 1;
    matlabbatch{3}.spm.spatial.preproc.tissue(1).native = [1 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(1).warped = [0 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(2).tpm = {fullfile(tpm_dir,'TPM.nii,2')};
    matlabbatch{3}.spm.spatial.preproc.tissue(2).ngaus = 1;
    matlabbatch{3}.spm.spatial.preproc.tissue(2).native = [1 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(2).warped = [0 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(3).tpm = {fullfile(tpm_dir,'TPM.nii,3')};
    matlabbatch{3}.spm.spatial.preproc.tissue(3).ngaus = 2;
    matlabbatch{3}.spm.spatial.preproc.tissue(3).native = [1 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(3).warped = [0 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(4).tpm = {fullfile(tpm_dir,'TPM.nii,4')};
    matlabbatch{3}.spm.spatial.preproc.tissue(4).ngaus = 3;
    matlabbatch{3}.spm.spatial.preproc.tissue(4).native = [0 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(4).warped = [0 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(5).tpm = {fullfile(tpm_dir,'TPM.nii,5')};
    matlabbatch{3}.spm.spatial.preproc.tissue(5).ngaus = 4;
    matlabbatch{3}.spm.spatial.preproc.tissue(5).native = [0 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(5).warped = [0 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(6).tpm = {fullfile(tpm_dir,'TPM.nii,6')};
    matlabbatch{3}.spm.spatial.preproc.tissue(6).ngaus = 2;
    matlabbatch{3}.spm.spatial.preproc.tissue(6).native = [0 0];
    matlabbatch{3}.spm.spatial.preproc.tissue(6).warped = [0 0];
    matlabbatch{3}.spm.spatial.preproc.warp.mrf = 1;
    matlabbatch{3}.spm.spatial.preproc.warp.cleanup = 1;
    matlabbatch{3}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
    matlabbatch{3}.spm.spatial.preproc.warp.affreg = 'mni';
    matlabbatch{3}.spm.spatial.preproc.warp.fwhm = 0;
    matlabbatch{3}.spm.spatial.preproc.warp.samp = 3;
    matlabbatch{3}.spm.spatial.preproc.warp.write = [1 1];

%--------------------------------------------------------------------------
% Image Calculation

    matlabbatch{4}.spm.util.imcalc.input(1) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));
    matlabbatch{4}.spm.util.imcalc.input(2) = cfg_dep('Segment: c1 Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{1}, '.','c', '()',{':'}));
    matlabbatch{4}.spm.util.imcalc.input(3) = cfg_dep('Segment: c2 Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{2}, '.','c', '()',{':'}));
    matlabbatch{4}.spm.util.imcalc.output = 'SkullStrippedT1';
    matlabbatch{4}.spm.util.imcalc.outdir = {struct_dir};
    matlabbatch{4}.spm.util.imcalc.expression = 'i1.*((i2+i3)>0.05)';
    matlabbatch{4}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    matlabbatch{4}.spm.util.imcalc.options.dmtx = 0;
    matlabbatch{4}.spm.util.imcalc.options.mask = 0;
    matlabbatch{4}.spm.util.imcalc.options.interp = 1;
    matlabbatch{4}.spm.util.imcalc.options.dtype = 4;
    
%--------------------------------------------------------------------------
% Co-Registration: Estimate (mean functional -> skstruct [bias corrected])

    matlabbatch{5}.spm.spatial.coreg.estimate.ref(1) = cfg_dep('Realign & Unwarp: Unwarped Mean Image', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','meanuwr'));
    matlabbatch{5}.spm.spatial.coreg.estimate.source(1) = cfg_dep('Image Calculator: ImCalc Computed Image: SkullStrippedT1', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
    matlabbatch{5}.spm.spatial.coreg.estimate.other = {''};
    matlabbatch{5}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
    matlabbatch{5}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
    matlabbatch{5}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{5}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

%--------------------------------------------------------------------------
% Create Brain Mask: Smooth segmented images of GM, WM, CSF

    matlabbatch{6}.spm.spatial.smooth.data(1) = cfg_dep('Segment: c1 Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{1}, '.','c', '()',{':'}));
    matlabbatch{6}.spm.spatial.smooth.data(2) = cfg_dep('Segment: c2 Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{2}, '.','c', '()',{':'}));
    matlabbatch{6}.spm.spatial.smooth.data(3) = cfg_dep('Segment: c3 Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{3}, '.','c', '()',{':'}));
    matlabbatch{6}.spm.spatial.smooth.fwhm = [2 2 2];
    matlabbatch{6}.spm.spatial.smooth.dtype = 0;
    matlabbatch{6}.spm.spatial.smooth.im = 0;
    matlabbatch{6}.spm.spatial.smooth.prefix = 'm';

%--------------------------------------------------------------------------
% Create Brain Mask: Calculate binary mask

    matlabbatch{7}.spm.util.imcalc.input(1) = cfg_dep('Smooth: Smoothed Images', substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
    matlabbatch{7}.spm.util.imcalc.output = 'myMask_256x256x176.nii';
    matlabbatch{7}.spm.util.imcalc.outdir = {struct_dir};
    matlabbatch{7}.spm.util.imcalc.expression = '(i1+i2+i3)>0';
    matlabbatch{7}.spm.util.imcalc.var = struct('name', {}, 'value', {});
    matlabbatch{7}.spm.util.imcalc.options.dmtx = 0;
    matlabbatch{7}.spm.util.imcalc.options.mask = 0;
    matlabbatch{7}.spm.util.imcalc.options.interp = 1;
    matlabbatch{7}.spm.util.imcalc.options.dtype = 4;

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
disp(['** DONE REALIGNMENT AND CO-REGISTRATION. Total time: ' num2str(Ttotal/60,'%3.1f') ' min.']);
