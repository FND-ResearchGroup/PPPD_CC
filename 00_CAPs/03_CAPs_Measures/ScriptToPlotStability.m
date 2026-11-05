% Script using the use the function ComputeClusteringQuality to get PAC
% values and to then plot the stability, ie 1-PAC

clear all; close all; clc

%% Define parameters and inputs

CAPsPath = 'E:\ConcettiC\PPPD_for_Caps\CAPs_analysis\11. New prepro CAPs Precuneus Bilat\from HC\k3';
DataFileName = 'NewPrepro_CAPs_PrecuneusBilat_fromHC_k3.mat';
load(strcat(CAPsPath, '\', DataFileName));
SaveFolder = 'E:\ConcettiC\PPPD_for_Caps\CAPs_analysis\11. New prepro CAPs Precuneus Bilat\from HC\Consensus clustering';

Consensus = HeavyOutputs.KMeansClustering.Consensus; 
K_range = 2:10;

%% Extract PAC values

[CDF,Lorena] = ComputeClusteringQuality(Consensus,K_range);
PAC = Lorena;
 
%% Visualise the "1-PAC"

CCPlot = figure;
ax1 = axes(CCPlot);
%set(CCPlot,'Visible','on');
tmp_plot = bar(2:K_range(end),1-PAC);
xlabel(get(tmp_plot(1),'Parent'),'Cluster number K');
ylabel(get(tmp_plot(1),'Parent'),'Stability');
xlim(get(tmp_plot(1),'Parent'),[2-0.6,K_range(end)+0.6]);
ylim(get(tmp_plot(1),'Parent'),[0,1]);
set(get(tmp_plot(1),'Parent'),'Box','off');
custom_cm = cbrewer('seq','Reds',25);
colormap(CCPlot,custom_cm(6:25,:));

%% Save figure

%saveas (gcf, 'Stability.fig');
filename = fullfile(SaveFolder, 'Stability');
fig = gcf;
saveas(fig, strcat(filename, '.jpg'));
saveas(fig, strcat(filename, '.fig'));
close all; 