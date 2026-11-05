function [seed] = loadseed_SW(functdir, prefix, mask, brain_info, seedName,MasksPath)

% Created: Feb 2022, Samantha Weber, University of Bern
% Input: 
%    - first functional directory
%    - prefix of functional data
%    - information on which mask has been selected

% Output: 
%    - mask 





Tstart = clock;
n_dataset = 0;

Seed = [];
SeedType = 'Average';

% One average map of correlation is computed across subjects and can be
% displayed as a sanity check
AvgSeedMap = [];

%% Seed selection

% Multiselection is on, so that as many as three files can be picked
% % [filename_seed,pathname_seed]=uigetfile({'*.*','All Files'},...
% %   'Select Seed File...','MultiSelect','on');
filename_seed = seedName;
pathname_seed = MasksPath;
% If the user has indeed entered files
if ~isequal(filename_seed,0) || ~isequal(pathname_seed,0)
   
    % In the case in which only one seed file is entered ('char' type),
    % we convert into an array
    if strcmp(class(filename_seed),'char')
        filename_seed = {filename_seed};
    end
    
    % If we enter that statement, it means that we have only one seed type
    % across subjects (that is, no subject-specific data)
    if length(filename_seed) <= 3

        % Number of entered seeds
        n_seed = length(filename_seed);

        for myindex = 1:length(filename_seed)

            disp(['Processing seed number ',num2str(myindex),'...']);
            
            File_seed = fullfile(pathname_seed, filename_seed{myindex});
            
            % The NIFTI file for the seed is read, converted into the
            % proper resolution, masked and made logical
            tmp_seedh = spm_vol(File_seed);
            tmp_seed = spm_read_vols(tmp_seedh);
            
            tmp_seed2 = CAP_V2V(tmp_seed,tmp_seedh.dim,...
            tmp_seedh.mat,brain_info{1}.dim,brain_info{1}.mat);
            
            tmp = tmp_seed2(:);
            tmp = logical(tmp(mask{1}));
            
            %Plot for sanity check
            HeaderInfo = brain_info{1,1};
            HeaderInfo.fname = fullfile(MasksPath,'Seed_SanityCheck.nii');
            spm_write_vol(HeaderInfo,tmp_seed2); % save to target path
            
            % If the file is of suitable dimensions
            if islogical(tmp) && size(tmp,2) == 1 && size(tmp,1) == sum(mask{1})

                % Then we put it in the handles, enable the plotting button, and
                % make the seed selection button green
                seed(:,myindex) = tmp;
                
                %Log = CAP_AddToLog(handles.Log,'Seed chosen',{File_seed},{'Seed file'});
            else
                errordlg('The file you entered appears to be of wrong dimensions...');
                %handles = ClearDataButton_Callback(handles.ClearDataButton, eventdata, handles);
            end

        end
                
        % If we survive all the above, we can see that the seed files are
        % good
        isSeedOK = true;

%         % We also enable to plot the seed results
%         set(handles.PlotSeedButton,'Enable','on');
%         set(handles.PlotSeedButton,'Visible','on');
%         
%         set(handles.SeedButton,'BackgroundColor', [101,140,196]/255);
%         set(handles.SeedButton,'Enable', 'off');
%         set(handles.SeedFreeButton,'Enable', 'off');
% 
%         % We can now go through the next parts of the analysis, so we
%         % enable the related buttons
%         set(handles.TPSelectionButton,'Enable','on');
%         set(handles.SeedMapPushButton,'Enable','on');
%         
%         set(handles.TPSelectionButton,'Visible','on');
%         set(handles.SeedMapPushButton,'Visible','on');
%         
%         % Makes other TP selection utilities visible
%         set(handles.PRadio,'Visible','on');
%         set(handles.TRadio,'Visible','on');
%         set(handles.uibuttongroup7,'Visible','on');
%         set(handles.TText,'Visible','on');
%         set(handles.TMotText,'Visible','on');
%         set(handles.TEdit,'Visible','on');
%         set(handles.TMotEdit,'Visible','on');
%         
%         % We also see the displays for entering seed specifications
%         set(handles.SeedPopup,'Visible','on');
%         
%         handles.Log = CAP_AddToLog(handles.Log,'Correct amount of seeds entered',{handles.n_seed},{'Seed amount'});
%     
        seed_display = zeros(length(seed(:,1)),1);
        
%         set(handles.CheckS1POS,'Visible','on');
%         set(handles.CheckS1NEG,'Visible','on');
%         CheckS1POS_Callback(handles.CheckS1POS,eventdata,handles);
%         
%         set(handles.Seed1Text,'Visible','on');
%         
%         set(handles.SeedPlusText,'Visible','on');
%         set(handles.SeedMinusText,'Visible','on');
        
        % If there are more than one seed, then we allow the popup button to be
        % changed for a more complex seed use choice
        if n_seed > 1
%             set(handles.SeedPopup,'Enable','on');
%             set(handles.SeedPopup,'Value',2);
            SeedType = 'Union';
            
            % We also update the circles in the seed illustration
%             rectangle('Position',[12 -10 6 8],'Curvature',[0.8 0.8],'Parent',FancyCircles);
%             rectangle('Position',[11 -5 8 4],'Curvature',[0.8 0.8],'EdgeColor','none','FaceColor','w','Parent',FancyCircles);
%             
            % We fill seed_display with one scalar value across seed voxels
            % per seed (to have different colors plotted in the seed choice
            % graph
            useless_vector = [0.25,0.75,1];
            
            for se = 1:n_seed
                seed_display = seed_display + useless_vector(se)*seed(:,se);
            end
            
%             set(handles.S_SEED1,'Visible','on');
%             set(handles.S_SEED2,'Visible','on');
%             
%             set(handles.CheckS2POS,'Visible','on');
%             set(handles.CheckS2NEG,'Visible','on');
%             CheckS2POS_Callback(handles.CheckS2POS,eventdata,handles);
%             
%             set(handles.Seed2Text,'Visible','on');
        
            % Same for 3 seeds
            if n_seed > 2
%                 set(handles.CheckS3POS,'Visible','on');
%                 set(handles.CheckS3NEG,'Visible','on');
%                 CheckS3POS_Callback(handles.CheckS3POS,eventdata,handles);
%                 
%                 set(handles.Seed3Text,'Visible','on');
                
%                 rectangle('Position',[32 -10 6 8],'Curvature',[0.8 0.8],'Parent',FancyCircles);
%                 rectangle('Position',[31 -5 8 4],'Curvature',[0.8 0.8],'EdgeColor','none','FaceColor','w','Parent',FancyCircles);
%                 
%                 set(handles.S_SEED3,'Visible','on');
            end
         
        % Entered if we have just one seed
        else
            % We make the text legends visible and colours accordingly
%             set(handles.S_SEED1,'Visible','on');
%             set(handles.S_SEED1,'ForegroundColor',[103,0,31]/255);
%             
%             set(handles.SeedPopup,'Enable','off');
%             set(handles.SeedPopup,'Value',1);
            SeedType = 'Average';
            
            seed_display = seed;
            
%             set(handles.CheckS1POS,'Visible','on');
%             set(handles.CheckS1NEG,'Visible','on');
        end
        
%         rectangle('Position',[0 0 10 10],'Curvature',[1 1],'FaceColor',[150,48,48]/255,'EdgeColor','none','Parent',FancyCircles);
%         
%         if n_seed > 1
%             rectangle('Position',[20 0 10 10],'Curvature',[1 1],'FaceColor',[150,48,48]/255,'EdgeColor','none','Parent',FancyCircles);
%             
%             if n_seed > 2
%                 rectangle('Position',[40 0 10 10],'Curvature',[1 1],'FaceColor',[150,48,48]/255,'EdgeColor','none','Parent',FancyCircles);
%             end
%         end
    else
        errordlg('Problem with the amount of seed files entered !');
%         handles = ClearDataButton_Callback(handles.ClearDataButton, eventdata, handles);
    end
    
%     % Updates the limits of the plot
%     switch n_seed
%         case 1
%             set(handles.FancyCircles,'xlim',[-10 10]);
%             set(handles.FancyCircles,'ylim',[-10 10]);
%         case 2
%             set(handles.FancyCircles,'xlim',[-10 30]);
%             set(handles.FancyCircles,'ylim',[-10 30]);
%         case 3
%             set(handles.FancyCircles,'xlim',[-10 50]);
%             set(handles.FancyCircles,'ylim',[-10 50]);
%     end
    
else
    errordlg('You did not enter a seed file !');
%     handles = ClearDataButton_Callback(handles.ClearDataButton, eventdata, handles);
end
end       
