clear
exp_name = 'cross_dataset';
dataset_list = {'Caltech101', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
class_list = {'person', 'bird', 'chair', 'car'};
feature_list = {'gist', 'sift'};
C = 10;

res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/cross_dataset/main_results/';
if ~exist(res_dir, 'dir')
    mkdir(res_dir);
end
root_lock_dir = ['/nfs/hn49/tinghuiz/ijcv_bias/sync_locks/' exp_name '/'];
warp_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/warp_script/';
if ~exist(root_lock_dir, 'dir')
    mkdir(root_lock_dir);
end

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
default_setup;

num_comb = length(dataset_list) * length(dataset_list) * length(class_list) * length(feature_list);

% while length(dir([root_lock_dir, 'lock_' exp_name '*'])) < num_comb
    myRandomize;
    train_d = randi(length(dataset_list),1);
    test_d = randi(length(dataset_list),1);
    f = randi(length(feature_list),1);
    c = randi(length(class_list),1);
    train_d = 6;
    test_d = 6;
    f = 1;
    c= 1;
    
    lock = sprintf('%s/lock_%s_%s_%s_%s_%s/', root_lock_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
%     if mymkdir_dist(lock) == 0
%         continue;
%     end

    fprintf('Processing: %s_%s_%s_%s\n',dataset_list{train_d},dataset_list{test_d},feature_list{f},class_list{c});
    
    feature = feature_list{f};
    class = class_list{c};
    
    train_dataset = dataset_list{train_d};
    test_dataset = dataset_list{test_d};
    
    if strcmp(train_dataset, 'ILSVRC2012')
        lock_dir = lock;
%         num_worker = 0;
        [pos_feat, neg_files, ~, ~] = load_data_imagenet(class_list{c}, feature_list{f}, 'train');
%         if size(pos_feat,1) > 5000
%            pm = randperm(size(pos_feat,1));
%            pos_feat = pos_feat(pm(1:5000),:);
%         end
        neg_cache = cell(length(neg_files),1);
        % Initialize a model with a random negative set
        neg_cnt = 0;
        set = 0;
        clear rand_neg_feat;
        while neg_cnt < size(pos_feat,1)
            n = randi(length(neg_files),1);
            neg = load(neg_files{n});
            set = set + 1;
            neg_cnt = neg_cnt + size(neg.class_feat,1);
            rand_neg_feat{set} = neg.class_feat;
        end
        rand_neg_feat = cell2mat(rand_neg_feat');
        pm = randperm(size(rand_neg_feat,1));
        rand_neg_feat = rand_neg_feat(pm,:);
        train_feat = [pos_feat; rand_neg_feat];
        train_labels = [ones(size(pos_feat,1),1); -ones(size(rand_neg_feat,1),1)];
        model = train(double(train_labels), sparse(double(train_feat)), ['-s 0 -c ' num2str(C) ' -B 1']);
        [~, ~, dec_values] = predict(train_labels, sparse(double(train_feat)), model, '-b 1');
%         model = libsvmtrain(double(train_labels), sparse(double(train_feat)), ['-t 0 -c ' num2str(C)]);
%          [~, ~, dec_values] = libsvmpredict(train_labels, sparse(double(train_feat)), model);
        dec_values = dec_values(:, model.Label==1);
        [ap, prec, rec] = myAP(dec_values, train_labels, 1); 
        if strcmp(test_dataset, 'ILSVRC2012')
            [~, ~, test_feat, test_labels] = load_data_imagenet(class_list{c}, feature_list{f}, 'test');
        else
            [~, test_feat, ~, test_labels] = load_data(test_dataset, class, feature);
        end
        if sum(train_labels == 1) == 0 || sum(train_labels == -1) == 0 || sum(test_labels == 1) == 0 || sum(test_labels == -1) == 0
            fprintf('Label error! %s_%s_%s_%s\n',dataset_list{train_d},dataset_list{test_d},feature_list{f},class_list{c});
            continue;
        end
%         num_worker = 0;
        mine_iter = 0;
%         neg_cache_file = [lock_dir, 'neg_cache.mat'];
%         save(neg_cache_file,clear 'neg_cache', 'new_cnt');
%         setup_file = sprintf('neg_mine_setup_%s_%s_%s.mat', dataset_list{test_d}, feature_list{f}, class_list{c});
%         save(setup_file, 'C', 'max_neg_kept', 'lock_dir', 'model', 'neg_files', 'neg_cache_file', 'max_mine_iter', 'num_worker');
%         
%         curr_dir = pwd;
%         cd(warp_dir);
%         system('./warp_starter.h hard_neg_mining 20 2');
%         cd(curr_dir);
        hard_neg_mining;
%         [~, test_feat, ~, test_labels] = load_data(test_dataset, class, feature);
%         rand_neg_mine_cd;
        [~, ~, dec_values] = predict(double(test_labels'), sparse(test_feat), model, '-b 1');
        ap = myAP(dec_values(:, model.Label==1), test_labels', 1);
        fprintf('AP = %f, num_pos_train = %d, num_neg_train = %d, num_pos_test = %d, num_neg_test = %d\n', ap, sum(train_labels == 1), sum(train_labels == -1), sum(test_labels == 1), sum(test_labels == -1));
        fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
        save(fname, 'ap', 'model', 'dataset_list', 'class_list', 'feature_list', 'train_d', 'test_d', 'f', 'c');
    else
        [train_feat, ~, train_labels, ~] = load_data(train_dataset, class, feature);
        if strcmp(test_dataset, 'ILSVRC2012')
            [~, ~, test_feat, test_labels] = load_data_imagenet(class_list{c}, feature_list{f}, 'test');
        else
            [~, test_feat, ~, test_labels] = load_data(test_dataset, class, feature);
        end

        if sum(train_labels == 1) == 0 || sum(train_labels == -1) == 0 || sum(test_labels == 1) == 0 || sum(test_labels == -1) == 0
            fprintf('Label error! %s_%s_%s_%s\n',dataset_list{train_d},dataset_list{test_d},feature_list{f},class_list{c});
            continue;
        end
        
        % Ensure that the first training example is positive
        while 1
            if train_labels(1) == 1
                break;
            end
            pm = randperm(numel(train_labels));
            train_labels = train_labels(pm);
            train_feat = train_feat(pm,:);
        end
        
        model = train(double(train_labels'), sparse(train_feat), ['-s 0 -c ' num2str(C) ' -B 1 -q 1']);
        [pred_labels, ~, dec_values] = predict(double(test_labels'), sparse(test_feat), model, '-b 1');
        ap = myAP(dec_values(:, model.Label==1), test_labels', 1);
        fprintf('AP = %f, num_pos_train = %d, num_neg_train = %d, num_pos_test = %d, num_neg_test = %d\n', ap, sum(train_labels == 1), sum(train_labels == -1), sum(test_labels == 1), sum(test_labels == -1));
        fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
        if exist(fname, 'file')
            previous_result = load(fname);
            if previous_result.ap < ap
                save(fname, 'ap', 'model', 'dataset_list', 'class_list', 'feature_list', 'train_d', 'test_d', 'f', 'c');
            end
        else
            save(fname, 'ap', 'model', 'dataset_list', 'class_list', 'feature_list', 'train_d', 'test_d', 'f', 'c');
        end
    end
    
% end

% for train_d = 1 : length(dataset_list)
% train_d = 6;
%     for test_d = 1 : length(dataset_list)
%         for f = 1 : length(feature_list)
%             for c = 1 : length(class_list)
%                 fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
%                 lock = sprintf('%s/lock_%s_%s_%s_%s_%s', root_lock_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
%                 rmdir(lock, 's');
% %                 if exist(fname, 'file')
% %                     load(fname);
% %                     if isnan(ap)
% %                         fprintf('NAN: %s\n', fname);
% %                         delete(fname);
% %                     end
% %                 end
% %                 if ~exist(fname, 'file') && exist(lock, 'dir')
% %                     fprintf('%s\n', lock);
% %                     rmdir(lock, 's');
% %                 end
%                 
%             end
%         end
%     end
% % end
