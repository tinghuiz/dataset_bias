cache_size = max([size(pos_feat,1), 2000]);
max_mine_iter = 1;
mine_iter = 1;

neg_cache.feat = zeros(cache_size, size(pos_feat,2));
neg_cache.cnt = 0;
neg_cache.cls_ind = [];
neg_cache.img_ind = [];

last_f = 0;
while 1
    % Apply the model to negatives
    for f = last_f+1 : length(neg_files)
        fprintf('Processing: %d/%d\n', f, length(neg_files));
        neg = load(neg_files{f});
        neg = neg.class_feat;
%         [~, ~, ~] = predict(double(-ones(size(neg,1),1)), sparse(double(neg)), model, '-b 1');
%         dec_values = dec_values(:, model.Label==1);
        dec_values = [neg, ones(size(neg,1),1)] * model.w';
        hard_idx = find(dec_values >= -1);
        pm = randperm(numel(hard_idx));
        hard_idx = hard_idx(pm);
%         [~, sort_idx] = sort(dec_values(hard_idx), 'descend');
%         hard_idx = hard_idx(sort_idx);
        
        % Remove hard negatives that are already in the cache
        exist_idx = find(neg_cache.cls_ind == f);
        in_cache = ismember(hard_idx, neg_cache.img_ind(exist_idx));
        hard_idx = hard_idx(in_cache == 0);
        
        num_kept = min([numel(hard_idx), cache_size - numel(neg_cache.cls_ind)]);
        if num_kept > 20
            num_kept = 20;
        end
        
        fprintf('#hard negatives: %d. #in cache: %d. #kept: %d\n', numel(hard_idx), numel(exist_idx), num_kept);
        hard_idx = hard_idx(1:num_kept);
        cnt = neg_cache.cnt;
        neg_cache.feat(cnt+1:cnt+numel(hard_idx),:) = neg(hard_idx,:);
        neg_cache.cls_ind = [neg_cache.cls_ind; f*ones(numel(hard_idx),1)];
        neg_cache.img_ind = [neg_cache.img_ind; hard_idx];
        neg_cache.cnt = neg_cache.cnt + numel(hard_idx);
        
        if neg_cache.cnt >= cache_size
            break;
        end
    end
    last_f = f;
    if last_f == length(neg_files)
        mine_iter = mine_iter + 1;
        last_f = 0;
    end
    
    % Update the model
    fprintf('Updating the model with hard negatives... last_f = %d, mine_iter = %d\n', last_f, mine_iter);
    hard_neg_feat = neg_cache.feat(1:neg_cache.cnt, :);
    remainder = size(pos_feat,1) - neg_cache.cnt;
    if remainder > 0
        neg_feat = [hard_neg_feat; rand_neg_feat(1:remainder,:)];
    else
        neg_feat = hard_neg_feat;
    end
    
    train_feat = [pos_feat; neg_feat];
    train_labels = [ones(size(pos_feat,1),1); -ones(size(neg_feat,1),1)];
    fprintf('#hard negatives: %d\n', size(hard_neg_feat,1));
    model = train(double(train_labels), sparse(double(train_feat)), ['-s 0 -c ' num2str(C) ' -B 1 -q 1']);
    
    % Shrink the cache by removing easy negatives
%     [~, ~, dec_values] = predict(double(-ones(neg_cache.cnt, 1)), sparse(double(hard_neg_feat)), model, '-b 1');
%     dec_values = dec_values(:, model.Label==1);
    dec_values = [hard_neg_feat, ones(size(hard_neg_feat,1),1)] * model.w';
    
    hard_idx = find(dec_values >= -1);
%     min_to_keep = floor(0.5 * neg_cache.cnt); % Keep at least half of the previous hard negatives set
%     if numel(hard_idx) < min_to_keep
%         [~, sort_idx] = sort(dec_values, 'descend');
%         hard_end = find(dec_values(sort_idx) == min(dec_values(hard_idx)));
%         hard_idx = [hard_idx; sort_idx(hard_end+1:min_to_keep - numel(hard_idx) + hard_end)]; 
%     end
    tmp_feat = neg_cache.feat(hard_idx,:);
    neg_cache.cls_ind = neg_cache.cls_ind(hard_idx);
    neg_cache.img_ind = neg_cache.img_ind(hard_idx);
    neg_cache.cnt = numel(hard_idx);
    neg_cache.feat = tmp_feat;
    neg_cache.feat = [neg_cache.feat; zeros(cache_size - neg_cache.cnt, size(pos_feat,2))];
    
    % Stop mining after certain number of iterations or no new hard
    % negatives can be added to cache
    if mine_iter > max_mine_iter || neg_cache.cnt >= cache_size
        break;
    end
    
    [~, ~, dec_values] = predict(double(test_labels'), sparse(test_feat), model, '-b 1');
        ap = myAP(dec_values(:, model.Label==1), test_labels', 1);
        fprintf('#neg kept after mining: %d, test ap = %f\n', numel(hard_idx), ap);
end