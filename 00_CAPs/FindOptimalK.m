function [Delta,Fit] = FindOptimalK(CQ,StartVal)

    % Number of parameter cases
    n_params = size(CQ,2);
    
    % Number of K values
    K = size(CQ,1);

    for p = 1:n_params
        
        % tmp_CQ has size (K-StartVal+1) x 1
        tmp_CQ = CQ(StartVal:end,p);
        
        g = fittype('a+b*(1-exp(-c*x))');
        f0 = fit((StartVal:K)',tmp_CQ,g,'StartPoint',[0;1;2/(K-StartVal)]);
        
        Fit(:,p) = f0((StartVal:K)');
        
        Delta(:,p) = tmp_CQ - f0((StartVal:K)');
    end
end