%script to call function ConsesunsMatrixPlot

RootPath = 'E:\ConcettiC\PPPD_for_Caps\CAPs_analysis\17. New prepro woExcMo CAPs Hippocampus\fromHC\k3';
DataFileName = 'NewPrepro_woExcMo_CAPsHippo_fromHC_k3';
load(strcat(RootPath, '\', DataFileName));

Consensus = HeavyOutputs.KMeansClustering.Consensus; 
K_range = [2 3 4 5 6 7 8 9 10]; 
SavePath = 'E:\ConcettiC\PPPD_for_Caps\CAPs_analysis\17. New prepro woExcMo CAPs Hippocampus\fromHC\Consensus clustering';

fancyName = 'ClustMatrix';

ConsensusMatrixPlot(Consensus, SavePath, fancyName, K_range)