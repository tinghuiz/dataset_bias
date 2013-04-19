exp_name = 'cross_dataset';
dataset_list = {'Caltech101', 'Caltech256', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012'};
class_list = {'person', 'dog', 'bird', 'chair', 'car'};
feature_list = {'gist', 'sift'};
C = 1;

res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/cross_dataset/main_results/';
if ~exist(res_dir, 'dir')
    mkdir(res_dir);
end
root_lock_dir = ['/nfs/hn49/tinghuiz/ijcv_bias/sync_locks/' exp_name '/'];
if ~exist(root_lock_dir, 'dir')
    mkdir(root_lock_dir);
end

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
default_setup;

num_comb = length(dataset_list) * length(dataset_list) * length(class_list) * length(feature_list);

while length(dir([root_lock_dir, 'lock_' exp_name '*'])) < num_comb
    myRandomize;
    train_d = randi(length(dataset_list),1);
    test_d = randi(length(dataset_list),1);
    f = randi(length(feature_list),1);
    c = randi(length(class_list),1);
    lock = sprintf('%s/lock_%s_%s_%s_%s_%s', root_lock_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
    if mymkdir_dist(lock) == 0
        continue;
    end
    
    fprintf('Processing: %s_%s_%s_%s\n',dataset_list{train_d},dataset_list{test_d},feature_list{f},class_list{c});
    
    feature = feature_list{f};
    class = class_list{c};
    
    train_dataset = dataset_list{train_d};
    test_dataset = dataset_list{test_d};
    [train_feat, ~, train_labels, ~] = load_data(train_dataset, class, feature);
    [~, test_feat, ~, test_labels] = load_data(test_dataset, class, feature);
    
    % Ensure that the first training example is positive
    while 1
        if train_labels(1) == 1
            break;
        end
        pm = randperm(numel(train_labels));
        train_labels = train_labels(pm);
    end
    train_feat = train_feat(pm,:);
    
    if sum(train_labels == 1) == 0 || sum(train_labels == -1) == 0 || sum(test_labels == 1) == 0 || sum(test_labels == -1) == 0
        fprintf('Label error! %s_%s_%s_%s\n',dataset_list{train_d},dataset_list{test_d},feature_list{f},class_list{c});
        continue;
    end
    
    model = train(double(train_labels'), sparse(train_feat), ['-s 0 -c ' num2str(C) ' -B 1 -q 1']);
    [~, ~, dec_values] = predict(double(test_labels'), sparse(test_feat), model, '-b 1');
    ap = myAP(dec_values(:, model.Label==1), test_labels', 1);

    fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
    save(fname, 'ap', 'model', 'dataset_list', 'class_list', 'feature_list', 'train_d', 'test_d', 'f', 'c');
end


% for train_d = 1 : length(dataset_list)
%     for test_d = 1 : length(dataset_list)
%         for f = 1 : length(feature_list)
%             for c = 1 : length(class_list)
%                 fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
%                 lock = sprintf('%s/lock_%s_%s_%s_%s_%s', root_lock_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
%                 if ~exist(fname) && exist(lock, 'dir')
%                     rmdir(lock);
%                 end
%             end
%         end
%     end
% end
