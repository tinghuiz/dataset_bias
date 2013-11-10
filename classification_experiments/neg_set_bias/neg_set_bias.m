exp_name = 'neg_set_bias';
dataset_list = {'Caltech101', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
feature_list = {'gist', 'sift'};
class_list = {'person', 'bird', 'chair', 'car'};
model_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/cross_dataset/main_results/';
result_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/neg_set_bias/main_results/';
num_run = 3;
num_neg_per_set = 1324; % Limited by the minimum number among all datasets

if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
default_setup;

for r = 1 : num_run
    for f = 1 : length(feature_list)
        % Load the world negative set
        clear world_neg_feat;
        for d = 1 : length(dataset_list)
            fprintf('Loading %s...\n', dataset_list{d});
            if strcmp(dataset_list{d}, 'ILSVRC2012')
                [~, neg_files] = load_data_imagenet(class_list, feature_list{f}, 'train');
                pm = randperm(length(neg_files));
                neg_files = neg_files(pm);
                num_neg_per_file = 50;
                clear neg_feat;
                nload = ceil(num_neg_per_set/num_neg_per_file);
                for i = 1 : nload
                    neg = load(neg_files{i});
                    neg = neg.class_feat;
                    pm = randperm(size(neg,1));
                    if i == nload
                        neg_feat{i} = neg(pm(1:mod(num_neg_per_set, num_neg_per_file)),:);
                    else
                        neg_feat{i} = neg(pm(1:num_neg_per_file),:);
                    end
                end
                neg_feat = double(cell2mat(neg_feat'));
            else
                [train_feat, ~, train_labels, ~] = load_data(dataset_list{d}, class_list, feature_list{f});
                neg_feat = train_feat(train_labels == -1, :);
            end
            pm = randperm(size(neg_feat,1));
            world_neg_feat{d} = neg_feat(pm(1:min([num_neg_per_set, numel(pm)])), :);
        end
        world_neg_feat = cell2mat(world_neg_feat');
        max_neg_set = num_neg_per_set * length(dataset_list);
        if size(world_neg_feat,1) > max_neg_set;
            pm = randperm(size(world_neg_feat,1));
            world_neg_feat = world_neg_feat(pm(1:max_neg_set),:);
        end
        fprintf('size of world negative set: %d\n', size(world_neg_feat,1));
        % Load previously trained models and test on the new test set
        % (positives are the same but the negatives are from the world
        % negative set)
        for d = 1 : length(dataset_list)
            fprintf('Processing %s\n', dataset_list{d});
            for c = 1 : length(class_list)
                model_file = sprintf('%s/cross_dataset_%s_%s_%s_%s.mat', model_dir, dataset_list{d}, dataset_list{d}, feature_list{f}, class_list{c});
                temp = load(model_file);
                model = temp.model;
                ap = temp.ap;
                if strcmp(dataset_list{d}, 'ILSVRC2012')
                    [~, ~, test_feat, test_labels] = load_data_imagenet(class_list{c}, feature_list{f}, 'test');
                else
                    [~, test_feat, ~, test_labels] = load_data(dataset_list{d}, class_list{c}, feature_list{f});
                end
                pos_feat = test_feat(test_labels == 1, :);
                num_neg_test = sum(test_labels == -1);
%                 if num_neg_test > size(world_neg_feat,1)
%                     org_neg
%                     test_feat = [pos_feat; world_neg_feat; ];
%                 else
                    test_feat = [pos_feat; world_neg_feat(1:num_neg_test,:)];
                    test_labels = [ones(size(pos_feat,1),1); -ones(num_neg_test,1)];
%                 end
                [pred_labels, ~, dec_values] = predict(double(test_labels), sparse(test_feat), model, '-b 1');
                new_ap = myAP(dec_values(:, model.Label==1), test_labels, 1);
                drop_percent = (ap - new_ap)/ap;
                result_file = sprintf('%s/%s_%s_%s_r%d', result_dir, dataset_list{d}, feature_list{f}, class_list{c}, r);
                save(result_file, 'ap', 'new_ap', 'drop_percent');
            end
        end
    end
end