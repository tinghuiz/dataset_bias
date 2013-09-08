exp_name = 'dataset_value';
dataset_list = {'Caltech101', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
class_list = {'person', 'bird', 'chair', 'car'};
% class_list = {'car'};
feature_list = {'gist', 'sift'};
% feature_list = {'gist'};
npos_list = [3, 5, 10, 20, 50, 100, 200];
num_run = 5;
C_list = [0.1 1 10];

res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/dataset_value/main_results/';
if ~exist(res_dir, 'dir')
    mkdir(res_dir);
end
root_lock_dir = ['/nfs/hn49/tinghuiz/ijcv_bias/sync_locks/' exp_name '/'];
if ~exist(root_lock_dir, 'dir')
    mkdir(root_lock_dir);
end

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
default_setup;

num_comb = length(dataset_list) * length(dataset_list) * length(class_list) * length(feature_list) * length(npos_list);

while length(dir([root_lock_dir, 'lock_' exp_name '*'])) < num_comb
    myRandomize;
    train_d = randi(length(dataset_list),1);
    test_d = randi(length(dataset_list),1);
    f = randi(length(feature_list),1);
    c = randi(length(class_list),1);
        
    lock = sprintf('%s/lock_%s_%s_%s_%s_%s/', root_lock_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
    if mymkdir_dist(lock) == 0
        continue;
    end
    
    fprintf('Processing: %s_%s_%s_%s\n',dataset_list{train_d},dataset_list{test_d},feature_list{f},class_list{c});
    
    feature = feature_list{f};
    class = class_list{c};
    
    train_dataset = dataset_list{train_d};
    test_dataset = dataset_list{test_d};
    
    if (strcmp(train_dataset, 'Caltech256') || strcmp(test_dataset, 'Caltech256')) && strcmp(class, 'chair')
        continue;
    end
    
    if strcmp(test_dataset, 'ILSVRC2012')
        [~, ~, test_feat, test_labels] = load_data_imagenet(class, feature, 'test');
    else
        [~, test_feat, ~, test_labels] = load_data(test_dataset, class, feature);
    end
    
    if strcmp(train_dataset, 'ILSVRC2012') == true
        [all_pos_feat, neg_files, ~, ~] = load_data_imagenet(class_list{c}, feature_list{f}, 'train');
        if size(all_pos_feat,1) > 5000
            pm = randperm(size(all_pos_feat,1));
            all_pos_feat = all_pos_feat(pm(1:5000),:);
        end
        
        ap = zeros(length(npos_list), num_run);
        for p = 1 : length(npos_list)
            for r = 1 : num_run
                fprintf('#pos = %d, r = %d\n', npos_list(p), r);
                pm = randperm(size(all_pos_feat,1));
                all_pos_feat = all_pos_feat(pm,:);
                pos_feat = all_pos_feat(1:npos_list(p), :);
                best_ap = 0;
                for cc = 1 : numel(C_list)
                    C = C_list(cc);
                    rand_neg_mine;
                    [~, ~, dec_values] = predict(double(test_labels'), sparse(test_feat), model, '-b 1');
                    this_ap = myAP(dec_values(:, model.Label==1), test_labels', 1);
                    if this_ap > best_ap
                        best_ap = this_ap;
                    end
                end
                ap(p,r) = best_ap;
            end
        end
    end
    
    if strcmp(train_dataset, 'ILSVRC2012') == false
        [train_feat, ~, train_labels, ~] = load_data(train_dataset, class, feature);
        all_pos_feat = train_feat(train_labels == 1, :);
        neg_feat = train_feat(train_labels == -1, :);
        
        ap = [];
        for p = 1 : length(npos_list)
            for r = 1 : num_run
                fprintf('#pos = %d, r = %d\n', npos_list(p), r);
                pm = randperm(size(all_pos_feat,1));
                all_pos_feat = all_pos_feat(pm,:);
                if size(all_pos_feat, 1) < npos_list(p)
                    fprintf('NOT enough positives!\n');
                    break;
                end
                pos_feat = all_pos_feat(1:npos_list(p),:);
                
                clear train_labels;
                train_labels = [ones(npos_list(p),1); -ones(size(neg_feat,1),1)];
                best_ap = 0;
                for cc = 1 : numel(C_list)
                    model = train(train_labels, sparse([pos_feat; neg_feat]), ['-s 0 -c ' num2str(C_list(cc)) ' -B 1 -q 1']);
                    [~, ~, dec_values] = predict(double(test_labels'), sparse(test_feat), model, '-b 1');
                    this_ap = myAP(dec_values(:, model.Label==1), test_labels', 1);
                    if this_ap > best_ap
                        best_ap = this_ap;
                    end
                end
                ap(p,r) = best_ap;
            end
        end
    end
    
    fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
    save(fname, 'ap', 'dataset_list', 'class_list', 'feature_list', 'npos_list', 'train_d', 'test_d', 'f', 'c');
end