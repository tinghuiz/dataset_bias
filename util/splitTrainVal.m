function all_folds = splitTrainVal(tr_val_labels, nfolds)

pos_ind = find(tr_val_labels == 1);
neg_ind = find(tr_val_labels == -1);

pos_folds = crossvalind('Kfold', numel(pos_ind), nfolds);
neg_folds = crossvalind('Kfold', numel(neg_ind), nfolds);

for k = 1 : nfolds
    all_folds(pos_ind(pos_folds == k)) = k;
    all_folds(neg_ind(neg_folds == k)) = k;
end

% num_val_neg = round(val_perc * numel(neg_ind));
% 
% val_labels = tr_val_labels([pos_ind(1:num_val_pos); neg_ind(1:num_val_neg)]);
% val_feats = tr_val_feats([pos_ind(1:num_val_pos); neg_ind(1:num_val_neg)], :);
% tr_labels = tr_val_labels([pos_ind(num_val_pos+1:end); neg_ind(num_val_neg+1:end)]);
% tr_feats = tr_val_feats([pos_ind(num_val_pos+1:end); neg_ind(num_val_neg+1:end)], :);
% tr_org_ind = [pos_ind(num_val_pos+1:end); neg_ind(num_val_neg+1:end)];
% val_org_ind = [pos_ind(1:num_val_pos); neg_ind(1:num_val_neg)];
% 
% while 1
%     tr_pm = randperm(numel(tr_org_ind));
%     % Ensure that the first training example is positive
%     if tr_labels(tr_pm(1)) == 1
%         break;
%     end
% end
% 
% tr_feats = tr_feats(tr_pm, :);
% tr_labels = tr_labels(tr_pm);
% tr_org_ind = tr_org_ind(tr_pm);
% 
% val_pm = randperm(numel(val_org_ind));
% val_feats = val_feats(val_pm,:);
% val_labels = val_labels(val_pm);
% val_org_ind = val_org_ind(val_pm);