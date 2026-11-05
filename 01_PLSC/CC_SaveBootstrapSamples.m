%Script to save bootstrap samples

%load results file
load('F:\CC_PLSC_Analysis\PLSC output\PLSC_woMissingValues_noAUCi_NVI_onlyOcc_nPerm5000_nBoot5000 - inspect\myPLS_behavior_norm2-2_res.mat')

%% Output folder
output_dir = 'F:\CC_PLSC_Analysis\PLSC output\PLSC_woMissingValues_noAUCi_NVI_onlyOcc_nPerm5000_nBoot5000 - inspect';

%% Number of significant components

NumL = 2;

%% SALIENCES

for LC = 1:NumL
    
    %behavioral
    behav_sal_boot = squeeze(res.boot_results.Ub_vect(:,LC,:));
    % Result: B x P

    file_name = fullfile(output_dir,...
        sprintf('LC%d_BehavSaliences_BootstrapSamples.csv',LC));

    writematrix(behav_sal_boot,file_name);

    %imaging
    img_sal_boot = squeeze(res.boot_results.Vb_vect(:,LC,:));
    % Result: B x P

    file_name = fullfile(output_dir,...
        sprintf('LC%d_ImgSaliences_BootstrapSamples.csv',LC));

    writematrix(img_sal_boot,file_name);

end

%% LOADINGS

for LC = 1:NumL

    %behavioral
    behav_load_boot = squeeze(res.boot_results.LC_behav_loadings_boot(:,LC,:));
    % Result: B x P

    file_name = fullfile(output_dir,...
        sprintf('LC%d_BehavLoadings_BootstrapSamples.csv',LC));

    writematrix(behav_load_boot,file_name);

    %imaging
    img_load_boot = squeeze(res.boot_results.LC_img_loadings_boot(:,LC,:));
    % Result: B x P

    file_name = fullfile(output_dir,...
        sprintf('LC%d_ImgLoadings_BootstrapSamples.csv',LC));

    writematrix(img_load_boot,file_name);

end

