function [Atlas_flat_thresh] = maskAtlas(CAPsPath,thisCAP, AtlasPath, thisAtlas,nRois,s, K)

% Inputs:
%       CAPsPath: Path to CAPs
%
% Outputs:
%       Overlay_thresholded_CAP*.nii: Yeo atlas thresholded based on those
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

% Read in atlas 
[myAtlas]=spm_select('List', 'FYeo_SeedRemoved.nii'); 
[myAtlas]=spm_select('List', thisAtlas); 

%[myAtlas]=spm_select('List', 'Yeo2011*.nii');
AV0i=spm_vol(myAtlas);            % load atlas

%% PART 2: build 3D
% initialise storage of Matrix (nPixels x nPixels x nSlices)
AV0=zeros(AV0i(1).dim(1),AV0i(1).dim(2),AV0i(1).dim(3),length(AV0i),'single');

% store Atlas as 3D volume
AV0(:,:,:)=spm_read_vols(AV0i);

% initialise storage of Matrix (nPixels x nPixels x nSlices)
V0=zeros(V0i(1).dim(1),V0i(1).dim(2),V0i(1).dim(3),length(V0i),'single');

% store CAPs as 3D matrix
V0(:,:,:)=spm_read_vols(V0i);

%% Part 3: Define size of masked data 
% Our mask data is the thresholded CAPs, as it shows from which parts we
% have to select the atlas regions and sum them up. 

AV0_size=size(AV0);
mask_data = V0(:,:,:);
Atlas_flat = zeros(nnz(V0(:,:,:)), size(V0,4));

% get atlas
current_atlas = AV0(:,:,:);
% flatten the atlas into a vector - makes life and computations easier
flat_atlas_volume = reshape(current_atlas, [1, numel(current_atlas)]);
% mask the flat atlas using the mask, first flatten the mask and make it boolean
flat_atlas_volume_masked = flat_atlas_volume(logical(reshape(mask_data, [1, numel(mask_data)])));

%Safety check
if isequal(size(flat_atlas_volume_masked,2), nnz(mask_data))== 0
error('Mask is not same size as brain volume!!');
end

% store the results
Atlas_flat(:) = flat_atlas_volume_masked';


%% PART 5: reshape back and save as .nii
% the initial mask flattened
mask_data_flat = reshape(mask_data, [1, numel(mask_data)]); 

unmasker = zeros(1, numel(mask_data)); % initialize empty array to be used to build the final brain volume
unmasker(logical(mask_data_flat)) = Atlas_flat(:)'; % store the thresholded CAP in the right location where the mask existed

final_vol = reshape(unmasker, [AV0i.dim]); % reshape to initial dimension
current_header = AV0i; % get header
current_header.fname= [CAPsPath , '\' , 'Overlay_thresholded' thisCAP(end-8:end)]; % new filename for WINDOWS
%current_header.fname= [CAPsPath , '/' , 'Overlay_' myListofFiles(1:15) thisCAP(end-8:end)]; % new filename for MAC
spm_write_vol(current_header,final_vol); % save to target path


%% 6. Extract atlas details

disp('* Extract atlas details...');

% Find number of non-zero elements (overlay)
voxels_tot = nnz(V0); %total non-zero voxels in CAP
Rois_tot = zeros(nRois,1); %place-holder

FAi=spm_vol(current_header.fname); % read functional atlas header
FA=spm_read_vols(FAi); % read in functional atlas
[x1,x2,x3]=ndgrid(1:FAi.dim(1),1:FAi.dim(2),1:FAi.dim(3));  %  FAi is the header of the functional atlas

for al=1:nRois  %  al: atlas label
    idx=find(round(FA,1)==al);            %  find voxels that have this label
    Rois_tot(al,1) = length(idx); %save the numbers of voxels
end

%%Rois_tot = Rois_tot - Rois_tot_Seed;
% calculate the number of non-assigned voxels (those that do not overlap
% with atlas and save in position 18. 

% Rois_tot(nRois+1,1) = voxels_tot - sum(Rois_tot(1:17,1));


%% 6. Plot cake-graph
labels = {'VisCen','VisPer','SomMotA','SomMotB','DorsAttnA','DorsAttnB','Sal/VenAttnA','Sal/VenAttnB',...
        'LimbicA','LimbicB','ContA','ContB - ECN','ContC','TempPar','DefaultA - DMN','DefaultB','DefaultC','Non-Network'};
    

%Pie plot
% Graph displays are stored in a common tmp_sfrac cell array
%tmp_sfrac = figure;    

% The pie charts for each cluster are created

custom_cm = cbrewer2('Spectral',18);
%custom_cm = cbrewer2('GnBu',18);

disp([myListofFiles(12:15) thisCAP(end-8:end-4)]);
%position = [2 8 14 4 10 16 6 1 7 13 3 9 15 5]; %for 7
%subplot(3,6,position(s))% nrows, ncols, nPlots for 7

if K == 4
position = [2 4 6 8 1 3 5 7 ]; %for 4
subplot(K,2,position(s))% nrows, ncols, nPlots for 4
elseif K == 3
position = [2 4 6 1 3 5]; %for 3
subplot(K,2,position(s))% nrows, ncols, nPlots for 3
end

%position = [2 4 6 8 10 1 3 5 7 9]; %for 5
%subplot(5,2,position(s))% nrows, ncols, nPlots for 5

%s = input(prompt);

%subplot(6,1,position(s))% nrows, ncols, nPlots for 3

% Pie charts
Rois_tot = Rois_tot + 1;% so that whole legend will be shown.
pie(Rois_tot);
%colormap(tmp_sfrac,(custom_cm));
colormap((custom_cm));
set(gca,'FontSize',12)
disp(['Numbers of voxels: ' num2str(sum(Rois_tot))]);

if s == 6 %5;
        Lgnd = legend(labels, 'fontsize',12);
        Lgnd.Position(1) = 0.85;%0.8;
        Lgnd.Position(2) = 0.5;
end

%if s == 2
%if position(s) == 2
     %title('Negative contributions','fontsize',12);
% elseif position(s) == 4
%         title('Negative contributions','fontsize',12);
% elseif s == 3
%         title('Negative contributions','fontsize',12);
 % elseif s == 4
 %         title('Negative contributions','fontsize',12);
 % elseif s == 5
 %         title('Negative contributions','fontsize',12);
%  elseif position(s) == 6
%               title('Negative contributions','fontsize',12);
%elseif position(s) == 1
        %title('Positive contributions','fontsize',12);
% elseif position(s) == 3
%         title('Positive contributions','fontsize',12);
% elseif position(s) == 5
%         title('Positive contributions','fontsize',12);
% else
%             title('Positive contributions','fontsize',12);
%end
% % 
%  saveas(gcf,fullfile(CAPsPath,['CAP_Cake_Yeo_all' myListofFiles(12:15) thisCAP(end-8:end) '.fig']));
%  saveas(gcf,fullfile(CAPsPath,['CAP_Cake_Yeo_all' myListofFiles(12:15) thisCAP(end-8:end) '.jpg']));

%close;


end