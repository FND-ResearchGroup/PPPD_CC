function [] = maskCAP(CAPsPath,thisCAP, CAPsPath2, thisCAP2,s)

% Inputs:
%       CAPsPath: Path to CAPs
%
% Outputs:
%       Overlay_thresholded_CAP*.nii: CAP2 thresholded based on those
%       voxels remaining significant in CAP
%
% Created: May 2023, Samantha Weber, Inselspital Bern



%% PART 1: loading 

% Check if folder exists
if ~exist(CAPsPath, 'dir')
    error('Could not find CAP folder');
end

% Read in CAP
[myListofFiles]=spm_select('List', thisCAP); % List of CAPs
cd(CAPsPath)
V0i=spm_vol(myListofFiles);            % load CAPs header

cd(CAPsPath2);
% Read in CAP2 
[myCAP2]=spm_select('List', thisCAP2); 
%[myCAP2]=spm_select('List', 'Yeo2011*.nii');
CAP2V0i=spm_vol(myCAP2);            % load CAP2

%% PART 2: build 3D
% initialise storage of Matrix (nPixels x nPixels x nSlices)
CAP2V0=zeros(CAP2V0i(1).dim(1),CAP2V0i(1).dim(2),CAP2V0i(1).dim(3),length(CAP2V0i),'single');

% store CAP2 as 3D volume
CAP2V0(:,:,:)=spm_read_vols(CAP2V0i);

cd(CAPsPath);
% initialise storage of Matrix (nPixels x nPixels x nSlices)
V0=zeros(V0i(1).dim(1),V0i(1).dim(2),V0i(1).dim(3),length(V0i),'single');

% store CAPs as 3D matrix
V0(:,:,:)=spm_read_vols(V0i);

% Load Mask
MaskPath = '/Users/samanthaweber/Documents/GitHub/CAPs_SW/03_CAPs_Analysis/DefaultData';
[myMask] = spm_select('List','/Users/samanthaweber/Documents/GitHub/CAPs_SW/03_CAPs_Analysis/DefaultData/GM_Mask_Population.nii');
cd(MaskPath);
Mask = spm_vol(myMask);
% initialise storage of Mask (nPixels x nPixels x nSlices)
MaskV0=zeros(Mask(1).dim(1),Mask(1).dim(2),Mask(1).dim(3),length(Mask),'single');

% store CAP2 as 3D volume
MaskV0(:,:,:)=spm_read_vols(Mask);

MaskV0_size=size(MaskV0);
mask_data = MaskV0(:,:,:);
Mask_flat = zeros(nnz(MaskV0(:,:,:)), size(MaskV0,4));

% get atlas
current_mask = MaskV0(:,:,:);
% flatten the atlas into a vector - makes life and computations easier
flat_mask_volume = reshape(current_mask, [1, numel(current_mask)]);
% mask the flat atlas using the mask, first flatten the mask and make it boolean
flat_mask_volume_masked = flat_mask_volume(logical(reshape(mask_data, [1, numel(mask_data)])));

% store the results
Mask_flat(:) = flat_mask_volume_masked';

% initialize matrix to store results
cd(CAPsPath);
flat_CAP1_volume = zeros(nnz(mask_data), size(MaskV0,4));

% we will work on each volume
for vol = 1:size(MaskV0,4)
    % get current 3D brain volume (single time-point)
    current_volume = V0(:,:,:,vol);
    % flatten the volume into a vector - makes life and computations easier
    flat_brain_volume = reshape(current_volume, [1, numel(current_volume)]);
    % mask the flat brain volume using the mask, first flatten the mask and make it boolean
    flat_brain_volume_masked = flat_brain_volume(logical(reshape(mask_data, [1, numel(mask_data)])));
    
    if isequal(size(flat_brain_volume_masked,2), nnz(mask_data))== 0
    error('Mask is not same size as brain volume!!');
    end
    % Note: "size(flat_brain_volume_masked,2)" should be = to
    % "nnz(mask_data)"
    
    % store the results
    flat_CAP1_volume(:, vol) = flat_brain_volume_masked';
end
clear flat_brain_volume_masked current_volume flat_brain_volume

flat_CAP2_volume = zeros(nnz(mask_data), size(MaskV0,4));

% we will work on each volume
for vol = 1:size(MaskV0,4)
    % get current 3D brain volume (single time-point)
    current_volume = CAP2V0(:,:,:,vol);
    % flatten the volume into a vector - makes life and computations easier
    flat_brain_volume = reshape(current_volume, [1, numel(current_volume)]);
    % mask the flat brain volume using the mask, first flatten the mask and make it boolean
    flat_brain_volume_masked = flat_brain_volume(logical(reshape(mask_data, [1, numel(mask_data)])));
    
    if isequal(size(flat_brain_volume_masked,2), nnz(mask_data))== 0
    error('Mask is not same size as brain volume!!');
    end
    % Note: "size(flat_brain_volume_masked,2)" should be = to
    % "nnz(mask_data)"
    
    % store the results
    flat_CAP2_volume(:, vol) = flat_brain_volume_masked';
end



%% Part 3: Define size of masked data 
% % Our mask data is the thresholded CAPs, as it shows from which parts we
% % have to select the CAP2 regions and sum them up. 
% 
% CAP2V0_size=size(CAP2V0);
% mask_data1 = V0(:,:,:);
% mask_data2 = CAP2V0(:,:,:);
% 
% %CAP1_flat = zeros(nnz(V0(:,:,:)), size(V0,4));
% %CAP2_flat = zeros(nnz(CAP2V0(:,:,:)), size(CAP2V0,4));
% 
% % get CAP2
% current_CAP1 = V0(:,:,:);
% % flatten the CAP2 into a vector - makes life and computations easier
% flat_CAP1_volume = reshape(current_CAP1, [1, numel(current_CAP1)]);
% 
% 
% % get CAP2
% current_CAP2 = CAP2V0(:,:,:);
% % flatten the CAP2 into a vector - makes life and computations easier
% flat_CAP2_volume = reshape(current_CAP2, [1, numel(current_CAP2)]);


% store the results
CAP2_flat(:) = zeros(length(flat_CAP2_volume),1);
for i = 1:length(flat_CAP2_volume)
   if flat_CAP2_volume(i) == 0
       CAP2_flat(i) = 0;
   else
       CAP2_flat(i)=1;
   end
    
end

% store the results
CAP1_flat(:) = zeros(length(flat_CAP1_volume),1);
for i = 1:length(flat_CAP2_volume)
   if flat_CAP1_volume(i) == 0
       CAP1_flat(i) = 0;
   else
       CAP1_flat(i)=1;
   end
    
end


%Find overlaps
overlap = 0;
CAP1_only = 0;
CAP2_only = 0;
OverlapImage = zeros(length(CAP1_flat),1);

for v = 1:length(CAP1_flat)
%     if CAP1_flat(v) && CAP2_flat(v) == 0
%         overlap = overlap + 1;
%         OverlapImage(v) = 1;
    if CAP1_flat(v) && CAP2_flat(v) == 1
        overlap = overlap +1;
        OverlapImage(v) = 1;
    elseif CAP1_flat(v) == 1 && CAP2_flat(v) == 0
        CAP1_only = CAP1_only + 1;
        OverlapImage(v) = 0.5;
    elseif CAP1_flat(v) == 0 && CAP2_flat(v) == 1
        CAP2_only = CAP2_only + 1;
        OverlapImage(v) = 0;
    end 
end

totalOverlap = [overlap; CAP1_only; CAP2_only];
totalOverlap = totalOverlap + 1;

%% PART 5: reshape back and save as .nii
% the initial mask flattened
mask_data_flat = reshape(mask_data, [1, numel(mask_data)]); 

unmasker = zeros(1, numel(mask_data)); % initialize empty array to be used to build the final brain volume
unmasker(logical(mask_data_flat)) = OverlapImage(:)'; % store the thresholded CAP in the right location where the mask existed

final_vol = reshape(unmasker, [V0i.dim]); % reshape to initial dimension

current_header = V0i; % get header
%current_header.fname= [CAPsPath , '\' , 'Overlay_thresholded' thisCAP(end-8:end)]; % new filename for WINDOWS
current_header.fname= [CAPsPath , '/' , 'Overlap_' myListofFiles(1:15) thisCAP(end-8:end)]; % new filename for MAC
spm_write_vol(current_header,final_vol); % save to target path




%% 6. Plot cake-graph
labels = {'Overlap','CAP HC','CAP whole population'};

%Pie plot
% Graph displays are stored in a common tmp_sfrac cell array  

% The pie charts for each cluster are created

custom_cm = cbrewer2('Greys',3);
%custom_cm = cbrewer2('GnBu',18);

%subplot(4,2,position(s))% nrows, ncols, nPlots
% Pie charts
pie(totalOverlap);
%colormap(tmp_sfrac,(custom_cm));
colormap(flipud(custom_cm));
set(gca,'FontSize',12)

disp(['This CAP: ' myListofFiles]);
Lgnd = legend(labels, 'fontsize',12);
Lgnd.Position(1) = 0.8;
Lgnd.Position(2) = 0.5;

% if s == 1 
%     title('Negative contributions','fontsize',12);
% elseif s == 2
%         title('Negative contributions','fontsize',12);
% elseif s == 3
%         title('Negative contributions','fontsize',12);
% elseif s == 4
%         title('Negative contributions','fontsize',12);
% % elseif s == 5
% %         title('Negative contributions','fontsize',12);
% % elseif s == 6
% %         title('Negative contributions','fontsize',12);
% else
%             title('Positive contributions','fontsize',12);
% end
% 
% saveas(gcf,fullfile(CAPsPath,['CAP_Cake_Yeo' myListofFiles(12:15) thisCAP(end-8:end) '.fig']));
% saveas(gcf,fullfile(CAPsPath,['CAP_Cake_Yeo' myListofFiles(12:15) thisCAP(end-8:end) '.jpg']));

close;




end