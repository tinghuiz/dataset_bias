exp_name = 'cross_dataset_psearch';
dataset_list = {'Caltech101', 'Caltech256', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012'};
class_list = {'person', 'dog', 'bird', 'chair', 'car'};
feature_list = {'gist', 'sift'};
params_c = [0.01 0.1 1 10];

res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/cross_dataset/psearch_results/';
if ~exist(res_dir, 'dir')
    mkdir(res_dir);
end
root_lock_dir = ['/nfs/hn49/tinghuiz/ijcv_bias/sync_locks/' exp_name '/'];
if ~exist(root_lock_dir, 'dir')
    mkdir(root_lock_dir);
end

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
default_setup;

num_comb = length(dataset_list) * length(class_list) * length(feature_list) * length(params_c);

while length(dir([root_lock_dir, 'lock_' exp_name '*'])) < num_comb
    myRandomize;
    d = randi(length(dataset_list),1);
    f = randi(length(feature_list),1);
    c = randi(length(class_list),1);
    p = randi(length(params_c));
    lock = sprintf('%s/lock_%s_%s_%s_%s_%.5f', root_lock_dir, exp_name, dataset_list{d}, feature_list{f}, class_list{c}, params_c(p));
    if mymkdir_dist(lock) == 0
        continue;
    end
    
    fprintf('Processing: %s_%s_%s_%.5f\n',dataset_list{d}, feature_list{f}, class_list{c}, params_c(p));
    
    dataset = dataset_list{d};
    feature = feature_list{f};
    class = class_list{c};
    C = params_c(p);
    
    [train_feat, test_feat, train_labels, test_labels] = load_data(dataset, class, feature);
    if sum(train_labels == 1) == 0 || sum(train_labels == -1) == 0
        fprintf('Label error! No negatives or No positives! %s_%s_%s\n',dataset_list{d}, feature_list{f}, class_list{c});
        continue;
    end
    
    crval_folds = splitTrainVal(train_labels, nfolds);
    for k = 1 : nfolds
        fprintf('fold number: %d/%d\n',k, nfolds);
        this_val = find(crval_folds == k);
        this_train = find(crval_folds ~= k);
        % Ensure that the first training example is positive
        while 1
            if train_labels(this_train(1)) == 1
                break;
            end
            pm = randperm(numel(this_train));
            this_train = this_train(pm);
        end
        model = train(double(train_labels(this_train)'), sparse(train_feat(this_train,:)), ['-s 0 -c ' num2str(C) ' -B 1 -q 1']);
        [~, ~, dec_values] = predict(double(train_labels(this_val)'), sparse(train_feat(this_val,:)), model, '-b 1');
        ap(k) = myAP(dec_values(:, model.Label==1), train_labels(this_val)', 1);
    end
    
    fname = sprintf('%s/%s_%s_%s_%s_%.5f.mat', res_dir, exp_name, dataset_list{d}, feature_list{f}, class_list{c}, params_c(p));
    save(fname, 'ap', 'dataset_list', 'class_list', 'feature_list', 'params_c', 'nfolds', 'd', 'f', 'c', 'p');
end

% Clean up the locks if all jobs are done (FIXME: Not working if "Label error" occurred!)
filesdone = dir([res_dir, exp_name, '*.mat']);
if length(filesdone) == num_comb
    for d = 1 : length(dataset_list)
        for f = 1 : length(feature_list)
            for c = 1 : length(class_list)
                for p = 1 : length(params_c)
                    lock = sprintf('%s/lock_%s_%s_%s_%s_%.5f', root_lock_dir, exp_name, dataset_list{d}, feature_list{f}, class_list{c}, params_c(p));
                    if exist(lock, 'dir')
                        rmdir(lock);
                    end
                end
            end
        end
    end
end
