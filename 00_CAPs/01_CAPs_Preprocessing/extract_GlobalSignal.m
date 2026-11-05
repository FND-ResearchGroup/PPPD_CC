function [global_signal] = extract_GlobalSignal(paths,pre_f)

% Build_Voxel_level_56HCP_with_TPM_MNI_GSR_server(path, subject_name, n_subjects)
%%%
%     AUTHOR: SERAFEIM LOUKAS, EPFL, Apr, 2020, Covid-lockdown,
%     working-from-home
% This function takes the 56 HCP data and makes a super GM mask.
% The data are already preprocessed: real, coreg, norm to MNI, nuisance
% regression
%
% path: the path to the directory that contains the subject folders (e.g.
% subjext_001)
%
% v1.0 SERAFEIM LOUKAS, EPFL, JUN 28th, 2019
% Compatible with SPM12 and SPM8. Defaults are based on SPM8
%
%v2.0 SAMANTHA WEBER, July 2022
% adapted for CAPs preprocessing
%

%%
%path_to_nonGSR_outputs = '/media/miplab-nas2/Data/Serafeim_Voxel_HCP_data/voxel_TCS/';
%save_output_to = '/media/miplab-nas2/Data/Serafeim_Voxel_HCP_data/voxel_TCS/GSR_data/';

%runs = {'run_2', 'run_1'};
%runs = {'run_1'};
% n_subjects = 1;
% subject_name = {'P000'};
%for session = 1:size(runs,2)
  %  for i = 1:n_subjects
        %fprintf(1, '\n');
        %fprintf('Working on Subject : %d i.e. %s for run %s.\n', i, subject_name{i});
        %fprintf(1, '\n');
        
        path_to_registered_TPMs = paths.sseg; %path to struct files
        path_to_global_mask = '/Users/samanthaweber/spm12';%path to spm tpm
        path_to_BOLD = paths.f;%path to funct files
        
%         message = 'Starting ...';
%         disp(message);
        
        % load the target functional space
        disp('Looking for valid functional data');
        %Vout_fn = spm_select('FPList' , path_to_BOLD  , [pre_f '.*\.nii$']);
        Vout_fn = spm_select('List',path_to_BOLD,['^' pre_f '.*\.nii$']);
        first_vol_fun = fullfile(path_to_BOLD,Vout_fn(1,:)); %change to 302 to 1 if working with Windows
        h = spm_vol(first_vol_fun);
        target_func_vol_data = spm_read_vols(h);
        
        % the GM mask used for the non-GSR case, the dims are going to be
        %compared to make sure  everything is ok
        %disp('Looking for the previsouly used GM mask');
        %nname = dir(fullfile([path_to_registered_TPMs, '\myMask_79x95x79.nii']));%*final_masked*']);
        %GM_mask_non_GSR = spm_read_vols(spm_vol([path_to_registered_TPMs nname.name]));
    
        %% Construct the GS mask.
        % union of TPMs
        % Load the TPMs (WM,GM,CSF) (these are not in the functional space yet)
        disp('Building whole brain union mask');
        c1_file = dir([path_to_registered_TPMs '/c1*']);
        c2_file = dir([path_to_registered_TPMs '/c2*']);
        c3_file = dir([path_to_registered_TPMs '/c3*']);
        
     
        h.fname = fullfile(path_to_registered_TPMs, 'c1_resliced.nii');
        c1_file=fullfile(path_to_registered_TPMs,c1_file.name);
        tmp1 = mapVolumeToVolume(c1_file,first_vol_fun);
        %spm_write_vol(h, tmp1)

        h.fname = fullfile(path_to_registered_TPMs, 'c2_resliced.nii');
        c2_file=fullfile(path_to_registered_TPMs,c2_file.name);
        tmp2 = mapVolumeToVolume(c2_file,first_vol_fun);
        %spm_write_vol(h, tmp2)

        h.fname = fullfile(path_to_registered_TPMs, 'c3_resliced.nii');
        c3_file=fullfile(path_to_registered_TPMs,c3_file.name);
        tmp3 = mapVolumeToVolume(c3_file,first_vol_fun);
        %spm_write_vol(h, tmp3)

        % Threshold the resliced (now in the func space) TPMs
        tmp1(tmp1<0.10) = 0;
        tmp2(tmp2<0.10) = 0;
        tmp3(tmp3<0.10) = 0;

        % some outside-brain voxels are not 0 so this is needed
        tmp1(~logical(target_func_vol_data)) = 0;
        tmp2(~logical(target_func_vol_data)) = 0;
        tmp3(~logical(target_func_vol_data)) = 0;

        % build the whole brain mask (union of TPMs covering whole brain)
        union_mask = logical(tmp1) | logical(tmp2) | logical(tmp3) ;
        assert(all(size(union_mask) == size(target_func_vol_data)));
        union_mask = union_mask * 1;

        h.fname = fullfile(path_to_registered_TPMs, 'union_mask_GSR.nii');
        spm_write_vol(h, union_mask);
        disp('Whole brain union mask was saved in structural directory');

        
        %% some checks
        if isempty(Vout_fn)
            %fprintf(1, '\n');
            fprintf('!!!!! EMPTY BOLD FOLDER !!!!! ABORT MISSION!');
            %fprintf(1, '\n');
            %continue
        end
        
        %% Extract the timecourse using the new mask (this is in the BOLD space now)
        final_GS_mask = fullfile(path_to_registered_TPMs, 'union_mask_GSR.nii');

        % read the functional volumes 
        disp('Loading the function volumes');
        %Windows: 
        %%Volumes = spm_vol(spm_select('FPList' , path_to_BOLD  , [pre_f '.*\.nii$']));
        %MAC: 
        functfiles = spm_select('List',path_to_BOLD,['^' pre_f '.*\.nii$']);
        for i = 1:size(functfiles,1)%300 CC debugging 17 July 2025
            Volumes(i,:)=(spm_vol(fullfile(path_to_BOLD  , functfiles(i,:))));%read volume
        end
        
        %disp(size(functfiles,1)) % only for debugging CC

        %Continue
        s1dim = Volumes(1).dim(1) * Volumes(1).dim(2) * Volumes(1).dim(3);
        
         % Check that BOLD timepoints are 300 for the current subject ---
%         CC commented out for preprocessing without first 3 scans
        if size(Volumes,1) ~= 300
            msg = 'Error occurred. The number of timepoints is not 300';
            error(msg)
        end

        %% Read the new union mask
        disp('Loading the union mask');
        GS_masked = spm_read_vols(spm_vol(final_GS_mask));
        brainmask_masked = logical(GS_masked);
        brainmask_masked = reshape(brainmask_masked, [1,s1dim]); %flatten

        %% store results (initialize an empty matrix)
        V_masked = zeros(length(Volumes),nnz(brainmask_masked));
        
        %% Iterate over all volumes (timepoints) and extract whole brain voxel
        % timecourses (based on the GS mask)
        disp('Extract whole brain voxel time-courses');
        for ii = 1:length(Volumes)
            % vectorize/flatten/ravel the functional volume into a vector
            Vprime =  reshape(spm_read_vols(Volumes(ii)), [1,s1dim]);
            Vprime(isnan(Vprime)) = 0;
            Vprime(Vprime < 0) = 0;
            
            V_masked(ii,:) = Vprime(brainmask_masked);
            
            if mod(ii,100) == 0
               disp(ii)
            end
        end
        
        %% estimate the GS (average across all voxels)
        global_signal = mean(V_masked,2);
        %plot(global_signal)
        
%         %% Load non-GSR data and do the GSR regression
%         disp('Load non-GSR data and do the GSR regression');
%         TCS_no_GSR_path = [path_to_nonGSR_outputs 'GM_voxel_wise' '_' subject_name{i} '_' '.csv'];
%         TCS_no_GSR_data = readtable('GM_voxel_wise_subj_588565_run_1.csv');
%         TCS_no_GSR_data = table2array(TCS_no_GSR_data);
%         % check that csv loading was successful
%         assert(size(TCS_no_GSR_data,2) == nnz(GM_mask_non_GSR))
%         
%         
        %% the GSR using a GLM
%         disp('Performing GSR using the average whole brain signal');
        % demean global signal
        global_signal = global_signal - mean(global_signal);
%         % add constant to design matrix
%         X_glm = [ones(size(TCS_no_GSR_data,1),1) global_signal];
%         
%         TCS_GSRed_data_res = zeros(size(TCS_no_GSR_data));
%         TCS_GSRed_data_with_mean = zeros(size(TCS_no_GSR_data));
%         
%         % for each voxel, do GSR regression
%         for whole_vox=1:size(TCS_no_GSR_data,2)
%             % current time-course, non-GSR-ed
%             Y = TCS_no_GSR_data(:,whole_vox);
%             % keep mean to put it back
%             Y_mean = mean(Y);
%             [b,bint,r] = regress(Y,X_glm);
%             TCS_GSRed_data_res(:,whole_vox) = r; % store only residuals
%             TCS_GSRed_data_with_mean(:,whole_vox) = r + Y_mean; % store only residuals+ mean before glm  
%         end
        
        % Save the run-specific subject-specific voxel timecourses in a
        % .csv file. Shape is [Nt, Ns]
%         disp('Saving GSRed GM time-courses');
%         csvwrite( [save_output_to 'GSR_GM_voxel_wise' '_' subject_name{i} '_' runs{session} '.csv'] , TCS_GSRed_data_with_mean)
%         csvwrite( [save_output_to 'GSR_GM_voxel_wise' '_' subject_name{i} '_' runs{session} '_resid_only.csv'] , TCS_GSRed_data_res)
% 
%         fprintf('Run %d ,Subject : %d - %s  is finished.\n', session, i, subject_name{i});
%         
%     
  %  end
%end
%return
    

end