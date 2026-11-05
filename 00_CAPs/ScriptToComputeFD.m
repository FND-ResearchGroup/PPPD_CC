%Script to calculate framewise displacement using function CAP_ComputeFD

%% Define parameters

clear all; close all; clc

RootPath= 'E:\ConcettiC\PPPD_for_Caps\OriginalData_ForPreprocessing_ForCAPs\AllSubjects';

OutputFilename = 'FramewiseDisplacement_AllSubj'; 
SavePath = 'E:\ConcettiC\PPPD_for_Caps\OriginalData_ForPreprocessing_ForCAPs';

myGroups={'HC','PPPD'};

%% Load P codes
% load P-codes group 1; 
% %-->> or load previously saved subjects lists and do not run
% % these 2 subsections
filelist=dir(fullfile(RootPath,myGroups{1}, 'P*'));
N_Group1=size(filelist,1);
myGroup1=cell(1,N_Group1);
for f=1:N_Group1 
    myGroup1{f}=filelist(f).name;
end
clear filelist f

%load P-codes group2
filelist=dir(fullfile(RootPath, myGroups{2},'P*'));
N_Group2=size(filelist,1);
myGroup2=cell(1,N_Group2);
for f=1:N_Group2
    myGroup2{f}=filelist(f).name;
end
clear filelist f

N_Group1 = length(myGroup1); N_Group2 = length(myGroup2); nSubj=N_Group1+N_Group2; 

%CC: Add group tags to P codes and put them vertically
myGroup1 = [repmat(myGroups(1),N_Group1,1) transpose(myGroup1)];
myGroup2 = [repmat(myGroups(2),N_Group2,1) transpose(myGroup2)];
mySubjects = [myGroup1;myGroup2];

%% Define input folders
NameFunctFolder = 'funct';
mySubj = {myGroup1, myGroup2};
N_Groups = [N_Group1, N_Group2];
for gr = 1:2
    for subj =1:N_Groups(1,gr)
        InputDirsFunct(gr,subj) = strcat(RootPath, '\', myGroups{1,gr}, '\', mySubj{1,gr}(subj,2), '\', NameFunctFolder);
    end
end

%% Load rp file for each subject and compute FD

for gr = 1:2
    for subj =1:N_Groups(1,gr)
        folderPath = InputDirsFunct(gr,subj);
        fullPath = fullfile(folderPath, 'rp_*.txt');
        % Get list of files matching pattern "rp_*.txt"
        files = dir(fullPath{1,1});
        
        if ~isempty(files)
            filePath = fullfile(folderPath, files(1).name);
%             % Load the file - assuming it's a text file with numeric data
%             data = load(filePath);
            
            % Calculate FD using function
            [FD{gr,subj}] = CAP_ComputeFD(filePath{1,1});

            %Apply threshold: find if subject has more than 40% frames with more
            %than 0.5 mm FD
            FD_Threshold = 0.5;
            nVols = 300;
            FrameNum_Threshold = 0.4 * nVols;
            OverFDThreshold{gr,subj} = FD{gr,subj} > FD_Threshold;
            NumFramesOverFDThreshold{gr,subj} = sum(OverFDThreshold{gr,subj});
        else
            fprintf('No matching file found in folder: %s\n', folderPath);
        end
    end
end

for subj = 1: N_Group1
    OverFrameNumThreshold_Group1(1,subj) = sum(OverFDThreshold{1,subj}) > FrameNum_Threshold;
end
clear subj
for subj = 1: N_Group2
    OverFrameNumThreshold_Group2(1,subj) = sum(OverFDThreshold{2,subj}) > FrameNum_Threshold;
end
clear subj
%% Save output

%make a csv with P codes, group info, FD values, and threshold evaluations
OverFrameNumThreshold_Vert = num2cell(double([transpose(OverFrameNumThreshold_Group1);  transpose(OverFrameNumThreshold_Group2)]));
FDAboveThresh = [mySubjects, OverFrameNumThreshold_Vert];
cd(SavePath); 
writecell(FDAboveThresh, 'FDAboveThresh.csv');
save("FD.mat", "FD");
