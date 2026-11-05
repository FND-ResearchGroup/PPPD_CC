% Concatenates populations appropriately for Violin plotting
function M2 = ConcatMat(M,n_pop,n_states,n_subjects,type)

% Creates the data matrix (nan values are used to have the same amount of
% data for each group)
M2 = nan(n_pop*n_states,max(cell2mat(n_subjects)));
%M2 = nan(n_pop*n_states,max((n_subjects)));

for i = 1:n_pop
    
    switch type
        case 'Raw counts'
            
            tmp = M{i}.raw.state(:,1:n_states)';
            
            for j = 1:n_states
                M2(i+(j-1)*n_pop,1:size(tmp,2)) = tmp(j,:);
            end
            
            clear tmp
            
        case 'Normalized counts'

            tmp = M{i}.frac.state(:,1:n_states)';

            for j = 1:n_states
                M2(i+(j-1)*n_pop,1:size(tmp,2)) = tmp(j,:);
            end
            
            clear tmp
            
        case 'Number'

            tmp = M{i}(:,3:3+n_states-1)';

            for j = 1:n_states
                M2(i+(j-1)*n_pop,1:size(tmp,2)) = tmp(j,:);
            end
            
            clear tmp
            
        case 'Duration'
            tmp = DiscardNaN(M{i}(:,3:3+n_states-1))';
            
            for j = 1:n_states
                M2(i+(j-1)*n_pop,1:size(tmp,2)) = tmp(j,:);
            end
            
            clear tmp
            
        case 'Betweenness'
            
            tmp = M{i}';
            
            for j = 1:n_states
                M2(i+(j-1)*n_pop,1:size(tmp,2)) = tmp(j,:);
            end
            
            clear tmp
            
        case 'kin'
            
            tmp = M{i}';
            
            for j = 1:n_states
                M2(i+(j-1)*n_pop,1:size(tmp,2)) = tmp(j,:);
            end
            
            clear tmp
            
        case 'kout'
            
            tmp = M{i}';
            
            for j = 1:n_states
                M2(i+(j-1)*n_pop,1:size(tmp,2)) = tmp(j,:);
            end
            
            clear tmp
            
        case 'Resilience'
            
            tmp = M{i}';
            
            for j = 1:n_states
                M2(i+(j-1)*n_pop,1:size(tmp,2)) = tmp(j,:);
            end
            
            clear tmp
            
        case 'FD'
            tmp = M{i};
            
            for j = 1:n_states
                M2(i+(j-1)*n_pop,1:size(tmp,2)) = tmp(j,:);
            end
    end
end
end