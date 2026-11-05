%% X has dimensions V x T
% V number of voxels
% T number of retained samples
function [U,W,Eigenvals,mu] = ComputePCA(X)

    
    % Mean subtraction
    X2 = X - repmat(mean(X,2),1,size(X,2));
    mu = mean(X,2);
    
    % Standardization
    % X3 = X2./repmat(std(X2,[],2),1,size(X2,2));
    
    %SVD
    [U,Sigma,V] = svd(X2,0);
    
    % Eigenvalues
    % shows amount of variance to be kept
    Eigenvals = Sigma.^2;
    
    % Weights
    % we specify specific amount of components to keep
%     select = diag(Sigma);
%     Sigma2 = select(1:79);
%     W = diag(Sigma2)*V(:,1:79)';
    W = Sigma*V';
end