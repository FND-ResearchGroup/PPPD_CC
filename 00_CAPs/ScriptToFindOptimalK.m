%Script to find optimal K based on Thomas Bolton fit function
clear all; close all; clc

%% 1. Load data
CAPsPath = 'E:\ConcettiC\PPPD_for_Caps\CAPs_analysis\Run1_Feb2025\CAPs_rTPJ_2pop_Ap5\K3';
CAPsfile = dir(fullfile(CAPsPath, 'CAPs_rTPJ_2pop_Ap5_k3.mat'));

OutputFilename = 'CAPs_rTPJ_2pop_Ap5_k3_OptimalKFromFit'; 

load(fullfile(CAPsPath,CAPsfile.name),'Outputs');

%% 2. Use function
CQ = Outputs.KMeansClustering.ConsensusQuality; 
StartVal = 2;

[Delta,Fit] = FindOptimalK(CQ,StartVal);

%I want to find the biggest delta, first I need to avg across subjects

AvgDelta = mean(Delta, 2); 
OptimalK = find(AvgDelta(2:end) == max(AvgDelta(2:end))) +1; % find which K is optimal (apart from K=2 because we are not interested in K=2)

%% 3. Store output

writematrix(OptimalK, strcat(CAPsPath, '.\',OutputFilename, '.txt'));