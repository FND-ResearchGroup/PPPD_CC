function [TC,brain,FD] = loadData_SW(functdir, prefix, mask, brain_info)

% Created: Feb 2022, Samantha Weber, University of Bern
% Input: 
%    - functional directory
%    - prefix of functional data
%    - mask
%    - brain_info

% Output: 
%    - TC (time-course) nTimePoints x nVoxels
%    - brain
%    - FD

Tstart = clock;
n_dataset = 0;
%--------------------------------------------------------------------------
   
    % The user selects the data of interest for the group that should be
    % constructed
    Data_OI = char(functdir');
    % Number of subjects (or runs) considered
    n_subjects{n_dataset+1} = size(Data_OI,1);
    
    try
        % We now want to update the FD and TC variables by going through all
        % the subjects to add to the considered group...
        for i = 1:size(Data_OI,1)
            
            disp(['Currently preparing the data from run ',num2str(i),'...']);

            % As before, the "sw" prefix is looked for
            FFiles = cellstr(spm_select('List',fullfile(Data_OI(i,:)),['^' prefix '.*\.' 'nii' '$']));

            % Functional files are read one after the other to build
            % tmp_data
            tmp_data = [];

            for t = 1:length(FFiles)

                tmp1 = spm_vol(fullfile(Data_OI(i,:),FFiles{t}));
                tmp2 = spm_read_vols(tmp1);
                tmp3 = tmp2(:);

                tmp_data = [tmp_data;tmp3(mask{1})'];
            end

            % Z-scoring is performed within the toolbox
            % tmp_data = detrend(tmp_data);
            % tmp_data = zscore(tmp_data);
            tmp_data = (tmp_data-repmat(mean(tmp_data),size(tmp_data,1),1)) ./ repmat(std(tmp_data),size(tmp_data,1),1);
            tmp_data(isnan(tmp_data)) = 0;
            
            % The ready-to-analyse data is put in TC
            TC{n_dataset+1}{i} = tmp_data;
            clear tmp_data

            try
                % Look for the text file with motion parameters (should be the
                % first text file found)
                MFile = cellstr(spm_select('List',fullfile(Data_OI(i,:)),['.*\.' 'txt' '$']));

                % Computes framewise displacement and fills the FD matrix
                % accordingly
                FD{n_dataset+1}(:,i) = CAP_ComputeFD(fullfile(Data_OI(i,:),MFile{1}));
            catch
                FD{n_dataset+1}(:,i) = zeros(length(FFiles),1);
                Log = CAP_AddToLog(Log,'Could not process motion text file; assuming zero movement...');
            end
        end

        % Some commands are run only for the first dataset that we add; we 
        % compute and store the number of voxels and the number of time
        % points, as well as the number of subjects
        if n_dataset == 0
                SubjSize.VOX = size(TC{1}{1},2);
                SubjSize.TP = size(TC{1}{1},1);
        end

        % If we are loading the first dataset, we convert the underlay
        % to the resolution of the functional data for plotting
        if n_dataset == 0

            % The brain variable now contains a good resolution
            % underlay that can directly be overlapped with the
            % functional data
            
            Underlay = load_nii('Underlay.nii');
            Underlay_mat = [Underlay.hdr.hist.srow_x; Underlay.hdr.hist.srow_y; Underlay.hdr.hist.srow_z; 0 0 0 1];
            Underlay_dim = Underlay.hdr.dime.dim;
            Underlay_dim = Underlay_dim(2:4);
            Underlay_info.dim = Underlay_dim;
            Underlay_info.mat = Underlay_mat; 
            load('brain.mat');
            assignin('base','brain', brain);
            brain = brain;
            
            brain = CAP_V2V(brain,Underlay_info.dim,...
                Underlay_info.mat,brain_info{1}.dim,brain_info{1}.mat);
            
        else
            % Also creates the brain_info and mask for the new pop
            mask{n_dataset+1} = mask{1};
            brain_info{n_dataset+1} = spm_vol(fullfile(tmp,FFiles{1}));
            brain_info{n_dataset+1} = brain_info{1};
     end
        
        % We we are loading our final population, then we disable the
        % option to enter more still
        
%         Log = CAP_AddToLog(Log,'Data correctly loaded',...
%             {n_dataset+1},{'Population index'});
        disp('Data correctly loaded');
        % We increment handles.n_dataset
        n_dataset = n_dataset + 1;
        
    catch
        errordlg('Could not load subject population!');
    end
end