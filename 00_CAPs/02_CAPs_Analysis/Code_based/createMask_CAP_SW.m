function [mask, brain_info] = createMask_CAP_SW(functdir, prefix, selectMask)

% Created: Feb 2022, Samantha Weber, University of Bern
% Input: 
%    - first functional directory
%    - prefix of functional data
%    - information on which mask has been selected

% Output: 
%    - mask 

Tstart = clock;

%--------------------------------------------------------------------------
    ToMask = functdir{1};
    n_datasets = 0;
    
    % Current file path
    tmp = ToMask(1,:);

    % Selects all the functional files that match our criteria
    % (prefix 's5w' meaning MNI space data)
    FFiles = cellstr(spm_select('List',fullfile(tmp),['^' prefix '.*\.' 'nii' '$']));

    % We read the header of the first one to get the data
    % resolution
    try
        brain_info{n_datasets+1} = spm_vol(fullfile(tmp,FFiles{1}));

        switch selectMask
            
            %GM
            case 'GM'
               a = spm_vol(fullfile('.','DefaultData','Default_mask.nii'));
            % Whole-brain
            case 'Whole-brain'
               a = spm_vol(fullfile('.','DefaultData','BrainMask.nii'));
            % White matter
            case 'WM'
               a = spm_vol(fullfile('.','DefaultData','WhiteMask.nii'));
            % CSF
            case 'CSF'
               a = spm_vol(fullfile('.','DefaultData','CerebroMask.nii'));
            case 'Population'
               a = spm_vol(fullfile('.','DefaultData','GM_Mask_Population.nii'));
        end
        
        b = spm_read_vols(a);
        b(b < 0.9) = 0;
        b(b >= 0.9) = 1;

        maskf = CAP_V2V(b,a.dim,a.mat,brain_info{n_datasets+1}.dim,brain_info{n_datasets+1}.mat);
        
        %Plot for sanity check
        %HeaderInfo = brain_info{1,1};
        %HeaderInfo.fname = 'GM_SanityCheck.nii';
        %spm_write_vol(HeaderInfo,maskf); % save to target path
        
        % Filling accordingly
        mask{n_datasets+1} = logical(maskf(:));
    catch
        errordlg('Error in attempting to create  !');
    end
Ttotal=etime(clock, Tstart);
disp(['** MASK SELECTED. Total time: ' num2str(Ttotal/60,'%3.1f') ' min.']);
