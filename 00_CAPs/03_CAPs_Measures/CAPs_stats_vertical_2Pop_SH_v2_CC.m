%% This code extracts you the CAPs measures and saves them in an excel file. 
% To run the statistics on the CAPs measures in R, the data must be in
% vertical shape.

% Inputs:
%       functfold er: Path to subject functional folder 
%
% Outputs:
%       X_flat: 2-dimensional data matrix containing [nVoxels x
%       nTimePoints]
%
% Created: Samantha Weber & Salome Häuselmann

clear; clc;close;
addpath(genpath(pwd));

%% 1. Set parameters
RootPath= 'E:\ConcettiC\PPPD_for_Caps\OriginalData_ForPreprocessing_ForCAPs\AllSubjects_woExcessMov';
CAPsPath = 'E:\ConcettiC\PPPD_for_Caps\CAPs_analysis\28_Newprepro_woExcMo_CAPsSciptBased_Vestibulocerebellum\fromHC_PopMask\k3';
CAPsfile = dir(fullfile(CAPsPath, 'Vestibulocerebellum_Bilat.mat'));
% file_info_PPPD = dir(fullfile(CAPsPath, 'PPPDloaded_K3_AntIns_bi.mat')); 
% file_info_HC = dir(fullfile(CAPsPath, 'HCloaded_K3_AntIns_bi.mat'));  
load(fullfile(CAPsPath,CAPsfile.name),'Outputs');
% load(fullfile(CAPsPath,file_info_PPPD.name),'FD2'); 
% load(fullfile(CAPsPath,file_info_HC.name),'FD1'); 
filename = fullfile(CAPsPath,'ScriptBasedCAPs_Vestibulocerebellum.xlsx');
nTP = 300; %300 volumes per subject

myGroups={'HC','PPPD'};
% load P-codes HC;
filelist=dir(fullfile(RootPath,myGroups{1}, 'P*'));
N_HC=size(filelist,1);
myHC=cell(1,N_HC);
for f=1:N_HC
    myHC{f}=filelist(f).name;
end
clear filelist f

%load P-codes PPPD
filelist=dir(fullfile(RootPath, myGroups{2},'P*'));
N_CD=size(filelist,1);
myCD=cell(1,N_CD);

for f=1:N_CD
    myCD{f}=filelist(f).name;
end
clear filelist f

mySubjects = [myHC,myCD];
N_HC = length(myHC); N_CD = length(myCD); nSubj=N_HC+N_CD; 

%% User needs to specify population index - INPUT
% Use 1 for the population which was chosen as reference for CAPs, 2 for
% the other one
hc_index = 1;
pppd_index = 2;

%% Extract CAPs Measures
% Make sure you read in the data correctly: As the code is now, it takes HC
% as reference population. If used PPPD as reference population you have to
% switch the {1,1} to {1,2} and vice versa. 

%Extract Duration
Duration_HC = Outputs.Metrics.AverageExpressionDuration{1,hc_index}(:,3:end-1); %rows are subjects, columns are states
Duration_HC(isnan(Duration_HC))=0; % replaces any NaN values in the extracted matrices with 0, ensuring there are no missing values.

Duration_PPPD = Outputs.Metrics.AverageExpressionDuration{1,pppd_index}(:,3:end-1); %rows are subjects, columns are states
Duration_PPPD(isnan(Duration_PPPD))=0;

%Extract Entries
Entries_HC = Outputs.Metrics.NumberEntries{1,hc_index}(:,3:end-1);
Entries_HC(isnan(Entries_HC))=0;

Entries_PPPD = Outputs.Metrics.NumberEntries{1,pppd_index}(:,3:end-1);
Entries_PPPD(isnan(Entries_PPPD))=0;

nEntries_HC = sum(Entries_HC,2);

nEntries_PPPD = sum(Entries_PPPD,2);

%Extract Expression Duration
ExpressionDuration_HC = Outputs.Metrics.AverageExpressionDuration{1,hc_index}(:,3:end-1);
ExpressionDuration_HC(isnan(ExpressionDuration_HC))=0;

ExpressionDuration_PPPD = Outputs.Metrics.AverageExpressionDuration{1,pppd_index}(:,3:end-1);
ExpressionDuration_PPPD(isnan(ExpressionDuration_PPPD))=0;

%Extract Occurences
Occurences_HC = Outputs.Metrics.Occurrences{1,hc_index}.raw.state(:,1:end-1);
Occurences_HC(isnan(Occurences_HC))=0;

Occurences_PPPD = Outputs.Metrics.Occurrences{1,pppd_index}.raw.state(:,1:end-1);
Occurences_PPPD(isnan(Occurences_PPPD))=0;

%Extract control metrics

notpicked_HC = Outputs.Metrics.Occurrences{1,hc_index}.raw.notpicked(:,1);
notpicked_HC(isnan(notpicked_HC))=0;

scrubbed_HC = Outputs.Metrics.Occurrences{1,hc_index}.raw.scrubbed(:,1);
scrubbed_HC(isnan(scrubbed_HC))=0;
nSelected_HC = nTP -(notpicked_HC + scrubbed_HC);

notpicked_PPPD = Outputs.Metrics.Occurrences{1,pppd_index}.raw.notpicked(:,1);
notpicked_PPPD(isnan(notpicked_PPPD))=0;

scrubbed_PPPD = Outputs.Metrics.Occurrences{1,pppd_index}.raw.scrubbed(:,1);
scrubbed_PPPD(isnan(scrubbed_PPPD))=0;
nSelected_PPPD = nTP -(notpicked_PPPD + scrubbed_PPPD);

PercentageRetainedFrames_HC = Outputs.SpatioTemporalSelection.PercentageRetainedFrames{1,hc_index};
PercentageRetainedFrames_PPPD = Outputs.SpatioTemporalSelection.PercentageRetainedFrames{1,pppd_index};

UnassignedFrames_HC = Outputs.Metrics.Occurrences{1, hc_index}.frac.state(:,4);
UnassignedFrames_PPPD = Outputs.Metrics.Occurrences{1, pppd_index}.frac.state(:,4);

%Extract Resilience
CapResilience_HC = Outputs.Metrics.CAPResilience{1,hc_index};
CapResilience_HC(isnan(CapResilience_HC))=0;

CapResilience_PPPD = Outputs.Metrics.CAPResilience{1,pppd_index};
CapResilience_PPPD(isnan(CapResilience_PPPD))=0;

%Extract Baseline Resilience
BaselineResilience_HC = Outputs.Metrics.BaselineResilience{1,hc_index};
BaselineResilience_HC(isnan(BaselineResilience_HC))=0;

BaselineResilience_PPPD = Outputs.Metrics.BaselineResilience{1,pppd_index};
BaselineResilience_PPPD(isnan(BaselineResilience_PPPD))=0;

%Extract Entries from Baseline
CAPEntriesFromBaseline_HC = Outputs.Metrics.CAPEntriesFromBaseline{1,hc_index};
CAPEntriesFromBaseline_HC(isnan(CAPEntriesFromBaseline_HC))=0;

CAPEntriesFromBaseline_PPPD = Outputs.Metrics.CAPEntriesFromBaseline{1,pppd_index};
CAPEntriesFromBaseline_PPPD(isnan(CAPEntriesFromBaseline_PPPD))=0;

%Extract Exit to Baseline
CAPExitToBaseline_HC = Outputs.Metrics.CAPExitsToBaseline{1,hc_index};
CAPExitToBaseline_HC(isnan(CAPExitToBaseline_HC))=0;

CAPExitToBaseline_PPPD = Outputs.Metrics.CAPExitsToBaseline{1,pppd_index};
CAPExitToBaseline_PPPD(isnan(CAPExitToBaseline_PPPD))=0;

%Extract Transition
Transition_HC = Outputs.Metrics.TransitionProbabilities{1,hc_index}(3:end-1,3:end-1,:);
Transition_HC(isnan(Transition_HC))=0;

Transition_PPPD = Outputs.Metrics.TransitionProbabilities{1,pppd_index}(3:end-1,3:end-1,:);
Transition_PPPD(isnan(Transition_PPPD))=0;

%Extract Number of excluded frames (based on FD)
ScrubbedActiveFrames_HC = Outputs.SpatioTemporalSelection.Indices{1, hc_index}.scrubbedandactive;
ScrubbedActiveFrames_HC(isnan(ScrubbedActiveFrames_HC))=0;
ScrubbedActiveFrames_HC = sum(ScrubbedActiveFrames_HC, 1);
ExcludedFrames_HC = ScrubbedActiveFrames_HC.';  % Transpose

ScrubbedActiveFrames_PPPD = Outputs.SpatioTemporalSelection.Indices{1, pppd_index}.scrubbedandactive;
ScrubbedActiveFrames_PPPD(isnan(ScrubbedActiveFrames_PPPD))=0;
ScrubbedActiveFrames_PPPD = sum(ScrubbedActiveFrames_PPPD, 1);
ExcludedFrames_PPPD = ScrubbedActiveFrames_PPPD.';  % Transpose

%Extract Number of selected frames
SelectedFrames_HC = Outputs.SpatioTemporalSelection.Indices{1, hc_index}.kept.active;
SelectedFrames_HC(isnan(SelectedFrames_HC))=0;
SelectedFrames_HC = sum(SelectedFrames_HC, 1);
SelectedFrames_HC = SelectedFrames_HC.';  % Transpose

SelectedFrames_PPPD = Outputs.SpatioTemporalSelection.Indices{1, pppd_index}.kept.active;
SelectedFrames_PPPD(isnan(SelectedFrames_PPPD))=0;
SelectedFrames_PPPD = sum(SelectedFrames_PPPD, 1);
SelectedFrames_PPPD = SelectedFrames_PPPD.';  % Transpose

%Extract Number of retained frames (absolute)
RetainedFrames_HC = Outputs.SpatioTemporalSelection.RetainedFramesPerSeed{1, hc_index};
RetainedFrames_HC(isnan(RetainedFrames_HC))=0;
RetainedFrames_HC = sum(RetainedFrames_HC, 1);
RetainedFrames_HC = RetainedFrames_HC.';  % Transpose

RetainedFrames_PPPD = Outputs.SpatioTemporalSelection.RetainedFramesPerSeed{1, pppd_index};  
RetainedFrames_PPPD(isnan(RetainedFrames_PPPD))=0;
RetainedFrames_PPPD = sum(RetainedFrames_PPPD, 1);
RetainedFrames_PPPD = RetainedFrames_PPPD.';  % Transpose

%Extract Number of retained frames (percentage)
RelativeRetainedFrames_HC = Outputs.SpatioTemporalSelection.PercentageRetainedFrames{1, hc_index};
RelativeRetainedFrames_HC(isnan(RelativeRetainedFrames_HC))=0;
RelativeRetainedFrames_HC = RelativeRetainedFrames_HC.';  % Transpose

RelativeRetainedFrames_PPPD = Outputs.SpatioTemporalSelection.PercentageRetainedFrames{1, pppd_index};  
RelativeRetainedFrames_PPPD(isnan(RelativeRetainedFrames_PPPD))=0;
RelativeRetainedFrames_PPPD = RelativeRetainedFrames_PPPD.';  % Transpose


%% Define Number of States

nStates = size(Occurences_HC,2);
namesStates = {};
namesSubj = {};

%CAPs header
for i = 1:nStates
    for s = 1:nSubj
        thisState{s,1} = ['CAP ' num2str(i)];
    end
        namesStates = [namesStates; thisState];
        namesSubj = [namesSubj; mySubjects'];
end
clear thisState i s

header = {'ID','State','value'};

%Baseline header

for s = 1:nSubj
    namesBaseline{s,1} = 'Baseline';
end
namesSubj_Baseline = mySubjects';

clear  s

%Control header

for k = 1:nSubj
    namesControl{k,1} = 'Control';
end
namesSubj_Control = mySubjects';

clear  k


%% Merge it all together to export to excel
% Output will be an excel file in columns

% Duration
Duration =[];
for i = 1:nStates
    thisDuration = [num2cell(Duration_HC(:,i)); num2cell(Duration_PPPD(:,i))];
    Duration = [Duration; thisDuration];
end
Duration = [header; namesSubj namesStates Duration];
clear i thisDuration

% Entries
Entries = [];
for i = 1:nStates
    thisEntry = [num2cell(Entries_HC(:,i)); num2cell(Entries_PPPD(:,i))];
    Entries = [Entries; thisEntry];
end
Entries = [header; namesSubj namesStates Entries];
clear i thisEntry

% % Relative Entries (compared to total entries)
% Rel_Ent_raw = [Entries_HC; Entries_PPPD];
% total = [nEntries_HC; nEntries_PPPD];
% RelativeEntries = [];
% for i =1:nStates
%     for s = 1:nSubj
%         thisRelativeEntries(s,1) = (Rel_Ent_raw(s,i)/total(s,1));
%     end
%     RelativeEntries = [RelativeEntries; num2cell(thisRelativeEntries)];
% end
% clear thisRelOccurence s
% RelativeEntries_final = [header; namesSubj namesStates RelativeEntries];
% clear i

% Relative Entries (compared to RetainedFrames)
Rel_Ent_raw = [Entries_HC; Entries_PPPD];
total = [nEntries_HC; nEntries_PPPD];
nSelected = [nSelected_HC; nSelected_PPPD];
RelativeEntries = [];
for i =1:nStates
    for s = 1:nSubj
        thisRelativeEntries(s,1) = (Rel_Ent_raw(s,i)/nSelected(s,1));
    end
    RelativeEntries = [RelativeEntries; num2cell(thisRelativeEntries)];
end
clear thisRelOccurence s
RelativeEntries_final = [header; namesSubj namesStates RelativeEntries];
clear i

% Average Expression Duration
ExpressionDuration = [];
for i = 1:nStates
    thisExpressionDuration = [num2cell(ExpressionDuration_HC(:,i)); num2cell(ExpressionDuration_PPPD(:,i))];
    ExpressionDuration = [ExpressionDuration; thisExpressionDuration];
end
ExpressionDuration = [header; namesSubj namesStates ExpressionDuration];
clear i thisExpressionDuration

% Occurence
Occurence =[];
for i = 1:nStates
    thisOccurence = [num2cell(Occurences_HC(:,i)); num2cell(Occurences_PPPD(:,i))];
    Occurence = [Occurence; thisOccurence];
end
Occurence = [header; namesSubj namesStates Occurence];
clear i thisOccurence


% Relative Occurence
Rel_Occ_raw = [Occurences_HC; Occurences_PPPD];
nSelected = [nSelected_HC; nSelected_PPPD];
RelativeOccurence = [];
for i =1:nStates
    for s = 1:nSubj
        thisRelOccurence(s,1) = (Rel_Occ_raw(s,i)/nSelected(s,1));
    end
    RelativeOccurence = [RelativeOccurence; num2cell(thisRelOccurence)];
end
clear thisRelOccurence s
RelativeOccurence_final = [header; namesSubj namesStates RelativeOccurence];
clear i  


%Resilience
CapResilience =[];
for i = 1:nStates
    thisCapResilience = [num2cell(CapResilience_HC(:,i)); num2cell(CapResilience_PPPD(:,i))];
    CapResilience = [CapResilience; thisCapResilience];
end
CapResilience = [header; namesSubj namesStates CapResilience];
clear i thisCapResilience

%Baseline Resilience
BaselineResilience =[];
%for i = 1:nStates
    thisBaselineResilience = [num2cell(BaselineResilience_HC); num2cell(BaselineResilience_PPPD)];
    BaselineResilience = [BaselineResilience; thisBaselineResilience];
%end
BaselineResilience = [header; namesSubj_Baseline namesBaseline BaselineResilience];
clear i thisBaselineResilience

%EntriesFrom Baseline
CapEntriesBaseline =[];
for i = 1:nStates
    thisCapEntriesBaseline = [num2cell(CAPEntriesFromBaseline_HC(:,i)); num2cell(CAPEntriesFromBaseline_PPPD(:,i))];
    CapEntriesBaseline = [CapEntriesBaseline; thisCapEntriesBaseline];
end
CapEntriesBaseline = [header; namesSubj namesStates CapEntriesBaseline];
clear i thisCapEntriesBaseline

%Exits to Baseline
CapExitsBaseline =[];
for i = 1:nStates
    thisCapExitsBaseline = [num2cell(CAPExitToBaseline_HC(:,i)); num2cell(CAPExitToBaseline_PPPD(:,i))];
    CapExitsBaseline = [CapExitsBaseline; thisCapExitsBaseline];
end
CapExitsBaseline = [header; namesSubj namesStates CapExitsBaseline];
clear i thisCapExitsBaseline

%Transition probabilities - take mean across subjects

Transition_HC = [num2cell(mean(Transition_HC,3))];
Transition_PPPD = [num2cell(mean(Transition_PPPD,3))];

% Number of excluded frames (based on FD)
ExcludedFrames =[];
thisExcludedFrames = [num2cell(ExcludedFrames_HC); num2cell(ExcludedFrames_PPPD)];
ExcludedFrames = [ExcludedFrames; thisExcludedFrames];

ExcludedFrames = [header; namesSubj_Control namesControl ExcludedFrames];

% Number of selected frames
SelectedFrames =[];
thisSelectedFrames = [num2cell(SelectedFrames_HC); num2cell(SelectedFrames_PPPD)];
SelectedFrames = [SelectedFrames; thisSelectedFrames];

SelectedFrames = [header; namesSubj_Control namesControl SelectedFrames];

% Retained-frames (absolut)
RetainedFrames =[];
thisRetainedFrames = [num2cell(RetainedFrames_HC); num2cell(RetainedFrames_PPPD)];
RetainedFrames = [RetainedFrames; thisRetainedFrames];

RetainedFrames = [header; namesSubj_Control namesControl RetainedFrames];

% Relative Retained-frames 
RelRetainedFrames =[];
thisRelRetainedFrames = [num2cell(RelativeRetainedFrames_HC); num2cell(RelativeRetainedFrames_PPPD)];
RelRetainedFrames = [RelRetainedFrames; thisRelRetainedFrames];

RelRetainedFrames = [header; namesSubj_Control namesControl RelRetainedFrames];

% Other control metrics
PercentageRetainedFrames = vertcat(PercentageRetainedFrames_HC', PercentageRetainedFrames_PPPD'); 
PercentageRetainedFrames = ['PercentageRetainedFrames' ;num2cell(PercentageRetainedFrames)];

UnassignedFrames = vertcat(UnassignedFrames_HC, UnassignedFrames_PPPD);
UnassignedFrames = ['UnassignedFrames' ;num2cell(UnassignedFrames)];

nSelected = ['nSelected' ; num2cell(nSelected)];

%% Write it to excel
% Write excel file
writecell(Duration,filename,'Sheet','Duration');
writecell(Occurence, filename,'Sheet','Occurence');
writecell(RelativeOccurence_final,filename,'Sheet','RelativeOccurence');
writecell(Entries,filename,'Sheet','Entries');
writecell(RelativeEntries_final,filename,'Sheet','RelativeEntries');
writecell(CapResilience, filename,'Sheet','CapResilience');
writecell(BaselineResilience,filename,'Sheet','BaselineResilience');
writecell(ExpressionDuration,filename,'Sheet','ExpressionDuration');
writecell(CapEntriesBaseline, filename,'Sheet','EntriesFromBaseline');
writecell(CapExitsBaseline, filename,'Sheet','ExitsToBaseline');
writecell(Transition_HC,filename,'Sheet','Transition_HC');
writecell(Transition_PPPD, filename,'Sheet','Transition_PPPD');
writecell(ExcludedFrames, filename,'Sheet','ExcludedFrames');
writecell(SelectedFrames, filename,'Sheet','SelectedFrames');
writecell(RetainedFrames, filename,'Sheet','RetainedFrames');
writecell(RelRetainedFrames, filename,'Sheet','RelRetainedFrames');

writecell(PercentageRetainedFrames, filename,'Sheet','PercentageRetainedFrames');
writecell(UnassignedFrames, filename,'Sheet','UnassignedFrames');
writecell(nSelected, filename,'Sheet','nSelected');