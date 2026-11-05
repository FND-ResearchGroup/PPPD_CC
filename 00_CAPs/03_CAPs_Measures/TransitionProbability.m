%% This code extracts the Transition Probability (CAPs measures) and saves the values in an excel file
% SW & SH
clear; clc;close;
addpath(genpath(pwd));

%% Load Data
RootPath= '/Users/salomehauselmann/Daten/Analysis/03_MRI/03_CAPs/03_CAPs/whole_sample';
CAPsPath = '/Users/salomehauselmann/Daten/Analysis/03_MRI/03_CAPs/03_CAPs/whole_sample/Two_Pop_PCA_ref_HC_GSR_PopulationMask_SH/AntIns_bi/K3_AntIns_bi_30_25';
CAPsfile = dir(fullfile(CAPsPath, 'K3_AntIns_bi_30_25.mat'));
load(fullfile(CAPsPath,CAPsfile.name),'Outputs');
filename1 = fullfile(CAPsPath,'z_TransitionProbability_HC_CPP.xlsx.xlsx');
filename2 = fullfile(CAPsPath,'raw_TransitionProbability_HC_CPP.xlsx.xlsx');

%% Set parameters
myGroups={'HC','CPP'};
% load P-codes HC;
filelist=dir(fullfile(RootPath,myGroups{1}, 'P*'));
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
mySubjects = mySubjects'; % Convert subject IDs to a column cell array
N_HC = length(myHC); N_CD = length(myCD);

%% Transition Probability

%Extract Transition Probability
Transition_HC_raw = Outputs.Metrics.TransitionProbabilities{1,1}; %rows are subjects, columns are states
Transition_HC_raw(isnan(Transition_HC_raw))=0;
Transition_HC = Transition_HC_raw(3:end-1,3:end-1,:);
Transition_HC_raw = Transition_HC_raw(3:end-1,3:end-1,:);

%Fisher Z transform
for s=1:N_HC
    thisTM=Transition_HC(:,:,s);
    myNewTM=jFisherRtoZtransform(thisTM);
    Transition_HC_fisherZ(:,:,s)=myNewTM; 
end

Transition_CPP_raw = Outputs.Metrics.TransitionProbabilities{1,2}; %rows are subjects, columns are states
Transition_CPP_raw(isnan(Transition_CPP_raw))=0;
Transition_CPP = Transition_CPP_raw(3:end-1,3:end-1,:);
Transition_CPP_raw = Transition_CPP_raw(3:end-1,3:end-1,:);

%Fisher Z transform
for s=1:N_CD
    thisTM=Transition_CPP(:,:,s);
    myNewTM=jFisherRtoZtransform(thisTM);
    Transition_CPP_fisherZ(:,:,s)=myNewTM; 
end

for i = 1:N_HC
    my2DTM_HC(:,i) = reshape(Transition_HC(:,:,i)',[],1); % convert matrix to column vector
end

for i = 1:N_CD
    my2DTM_CPP(:,i) = reshape(Transition_CPP(:,:,i)',[],1); % convert matrix to column vector
end

my2DTM = [my2DTM_HC';my2DTM_CPP'];

for i = 1:N_HC
    my2DTM_HC_raw(:,i) = reshape(Transition_HC_raw(:,:,i)',[],1); % convert matrix to column vector
end

for i = 1:N_CD
    my2DTM_CPP_raw(:,i) = reshape(Transition_CPP_raw(:,:,i)',[],1); % convert matrix to column vector
end

my2DTM_raw = [my2DTM_HC_raw';my2DTM_CPP_raw'];

%% Saving Data in an Excel Sheet

header = {'p_code','1_1','1_2','1_3','2_1','2_2','2_3','3_1','3_2','3_3'};

% Convert transition matrix to cell
my2DTM_cells = num2cell(my2DTM); % each row corresponds to a subject

% Combine everything into final table
FinalTM = [header; [mySubjects, my2DTM_cells]];

% Write to Excel
writecell(FinalTM, filename1, 'Sheet', 'TP');

% Convert transition matrix to cell
my2DTM_cells_raw = num2cell(my2DTM_raw); % each row corresponds to a subject

% Combine everything into final table
FinalTM_raw = [header; [mySubjects, my2DTM_cells_raw]];

% Write to Excel
writecell(FinalTM_raw, filename2, 'Sheet', 'TP');