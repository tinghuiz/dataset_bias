dataset_list = {'Caltech101', 'Caltech256', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
class_list = {'person', 'dog', 'bird', 'chair', 'car'};
feature_list = {'gist', 'sift', 'color'};
exp_name = 'cross_dataset';

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));

% Pick a combination that does not have too many workers
while 1
    myRandomize;
    test_d = randi(length(dataset_list),1);
    f = randi(length(feature_list),1);
    c = randi(length(class_list),1);
    
    setup_file = sprintf('%s/neg_mine_setup_%s_$s_%s.mat', exp_name, dataset_list{test_d}, feature_list{f}, class_list{c});
    if exist(setup_file)
        load(setup_file);
        if num_worker < 20
            num_worker = num_worker + 1;
            save(setup_file, 'num_worker', '-append');
            break;
        end
    end
end

% Params to be specified in the setup file:
% max_neg_kept: max number of hard negatives kept for each negative class
% C: SVM parameter
% lock_dir: where parallelization locks are stored
% pos_feat: features of positive training instances
% model: initial model
% neg_files: list of .mat files containing negative training instances
% neg_cache_file: file that contains the current hard-mining cache
% max_mine_iter: max number of mining iterations

% Params to be specified for server alone:
% i_am_server: indicating the server machine

while 1
    mine_iter = mine_iter + 1;
    load(neg_cache_file);
    % Stop mining after certain number of iterations or few new hard
    % negatives are added to cache
    if mine_iter > max_mine_iter || new_cnt < 200
        break;
    end
    % Apply the model to negatives
    while length(dir([lock_dir, 'lock_negmine_file_*'])) < length(neg_files)
        myRandomize;
        f = randi(length(neg_files),1);
        lock = [lock_dir, 'lock_negmine_file_', num2str(f)];
        if mymkdir_dist(lock) == 0
            continue;
        end
        fprintf('Processing: %d/%d\n', f, length(neg_files));
        neg = load(neg_files{f});
        neg = neg.class_feat;
        [~, ~, dec_values] = predict(double(-ones(size(neg,1),1)), sparse(neg), model, '-b 1');
        dec_values = dec_values(:, model.Label==1);
        hard_idx = find(dec_values > -1);
        [~, sort_idx] = sort(dec_values(hard_idx), 'descend');
        hard_idx = hard_idx(sort_idx);
        
        % Remove hard negatives that are already in the cache
        in_cache = ismember(hard_idx, neg_cache{f});
        hard_idx = hard_idx(in_cache == 0);
        
        num_kept = min([numel(hard_idx), max_neg_kept - numel(neg_cache{f})]);
        
        fprintf('Total number of hard examples: %d. Number kept: %d\n', numel(hard_idx), num_kept);
        hard_idx = hard_idx(1:num_kept);
        fname = sprintf('%s/hard_idx_file_%d_iter_%d\n', lock_dir, f, mine_iter);
        save(fname, 'hard_idx', 'num_kept');
    end
    while length(dir([lock_dir, 'hard_idx_file_*'])) < length(neg_files)
        num_undone = length(neg_files) - length(dir([lock_dir, 'hard_idx_file_*']));
        fprintf('Waiting for %d files\n', num_undone);
        pause(5);
    end
    
    % Update the model
    res_model_file = [lock_dir, 'model_', num2str(mine_iter), '.mat'];
    
    if exist(i_am_server, 'var') && i_am_server == true
        fprintf('Clean up the locks...\n');
        for f = 1 : length(neg_files)
            lock = [lock_dir, 'lock_negmine_file_', num2str(f)];
            rmdir(lock);
        end
        fprintf('Updating the model with hard negatives...\n');
        hard_neg_feat = cell(length(neg_files), 1);
        new_cnt = 0;
        for f = 1 : length(neg_files)
            neg = load(neg_files{f});
            hfile = sprintf('%s/hard_idx_file_%d_iter_%d\n', lock_dir, f, mine_iter);
            hidx = load(hfile);
            neg_cache{f} = unique([neg_cache{f}, hidx.hard_idx]);
            hard_neg_feat{f} = neg.class_feat(neg_cache{f},:);
            new_cnt = new_cnt + num_kept; 
        end
        
        hnf = cell2mat(hard_neg_feat');
        train_feat = [pos_feat; hnf];
        train_labels = [ones(size(pos_feat,1),1); -ones(size(hnf,1),1)];
        fprintf('#hard negatives: %d, #new: %d\n', size(hnf,1), new_cnt);
        model = train(double(train_labels), sparse(train_feat), ['-s 0 -c ' num2str(C) ' -B 1 -q 1']);
        
        % Shrink the cache by removing easy negatives
        for f = 1 : length(neg_files)
            fprintf('Shrinking cache: %d/%d\n', f, length(neg_files));
            [~, ~, dec_values] = predict(double(-ones(numel(neg_cache{f}), 1)), sparse(hard_neg_feat{f}), model, '-b 1');
            dec_values = dec_values(:, model.Label==1);
            hard_idx = find(dec_values > -1);
            neg_cache{f} = neg_cache{f}(hard_idx);
        end
        save(neg_cache_file, 'neg_cache', 'new_cnt');
        save(res_model_file, 'model');
    else
        while ~exist(res_model_file);
            fprintf('Waiting for model to be updated by server!\n');
            pause(5);
        end
    end 
end