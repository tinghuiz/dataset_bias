% TODO: multiclass classification for confusion matrix
exp_name = 'name_that_dataset';
dataset_list = {'Caltech101', 'Caltech256', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
feature_list = {'gist', 'sift', 'color'};
num_train = [10 50 100 500 1000 1500 2000];
% num_train = 2000;
num_test = 1000;
num_run = 5;
C = 1;

res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/name_that_dataset/main_results/multi-class/';
if ~exist(res_dir, 'dir')
    mkdir(res_dir);
end
% root_lock_dir = ['/nfs/hn49/tinghuiz/ijcv_bias/sync_locks/' exp_name '/'];
% warp_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/warp_script/';
% if ~exist(root_lock_dir, 'dir')
%     mkdir(root_lock_dir);
% end

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
default_setup;

for f = 1 : length(feature_list)
    feature = feature_list{f};
    clear imagenet_feat;
    for r = 1 : num_run
        for n = 1 : numel(num_train)
            n_train = num_train(n);
            clear train_feat;
            clear test_feat;
            clear train_label;
            clear test_label;
            for d = 1 : length(dataset_list)
                curr_set = dataset_list{d};
                if strcmp(curr_set, 'ILSVRC2012')
                    if ~exist('imagenet_feat', 'var');
                        feat_dir = [imagenet_feat_dir, feature, '/'];
                        imagenet_feat = load([feat_dir, 'test_set.mat']);
                        imagenet_feat = imagenet_feat.test_feat;
                        imagenet_feat = double(imagenet_feat);
                    end
                    pm = randperm(size(imagenet_feat,1));
                    train_feat{d} = imagenet_feat(pm(1:n_train), :);
                    test_feat{d} = imagenet_feat(pm(n_train+1:n_train+num_test), :);
                    train_label{d} = d*ones(n_train,1);
                    test_label{d} = d*ones(num_test,1);
                else
                    [tr_feat, te_feat, ~, ~] = load_data(curr_set, 'car', feature);
                    tr_pm = randperm(size(tr_feat,1));
                    te_pm = randperm(size(te_feat,1));
                    train_feat{d} = tr_feat(tr_pm(1:n_train),:);
                    test_feat{d} = te_feat(te_pm(1:num_test),:);
                    train_label{d} = d*ones(n_train,1);
                    test_label{d} = d*ones(num_test,1);
                end
            end
            
            train_feat = cell2mat(train_feat');
            train_label = cell2mat(train_label');
            test_feat = cell2mat(test_feat');
            test_label = cell2mat(test_label');
            
            model = train(double(train_label), sparse(train_feat), ['-s 4 -c ' num2str(C) ' -B 1']);
            [class_assign, accuracy, dec_values] = predict(test_label, sparse(test_feat), model);
            accuracy = accuracy(1);
            
            confusion_mat = zeros(length(dataset_list), length(dataset_list));
            for d1 = 1 : length(dataset_list)
                gt_idx = find(test_label == d1);
                for d2 = 1 : length(dataset_list)
                    confusion_mat(d1,d2) = sum(class_assign(gt_idx) == d2);
                end
            end
            
            fname = sprintf('%s/%s_%s_n%d_r%d.mat', res_dir, exp_name, feature, n_train, r);
            save(fname, 'accuracy', 'class_assign', 'test_label', 'confusion_mat');
%             for d = 1 : length(dataset_list)
%                 %         curr_set = dataset_list{d};
%                 neg_idx = setdiff(1:length(dataset_list), d);
%                 pos_train_feat = train_feat{d};
%                 pos_test_feat = test_feat{d};
%                 neg_train_feat = train_feat(neg_idx);
%                 neg_test_feat = test_feat(neg_idx);
%                 neg_train_feat = cell2mat(neg_train_feat');
%                 neg_test_feat = cell2mat(neg_test_feat');
%                 
%                 train_labels = [ones(size(pos_train_feat,1),1); -ones(size(neg_train_feat,1),1)];
%                 test_labels = [ones(size(pos_test_feat,1),1); -ones(size(neg_test_feat,1),1)];
%                 
%                 model = train(double(train_labels), sparse([pos_train_feat; neg_train_feat]), ['-s 0 -c ' num2str(C) ' -B 1']);
%                 [~, acc, dec_values] = predict(test_labels, sparse([pos_test_feat; neg_test_feat]), model, '-b 1');
%                 accuracy = acc(1);
%                 dec_values = dec_values(:, model.Label==1);
%                 [ap, prec, rec] = myAP(dec_values, test_labels, 1);
%                 fname = sprintf('%s/%s_%s_%s_n%d_r%d.mat', res_dir, exp_name, dataset_list{d}, feature, n_train, r);
%                 save(fname, 'ap', 'accuracy');
%             end
        end
    end
end

%% Plot results
clear acc_all;
clear acc_mean;
clear acc_std;
clear conf_mat;
colors = cbrewer('qual', 'Set1', 8);
for f = 1 : length(feature_list)
    feature = feature_list{f};
    for n = 1 : numel(num_train)
        n_train = num_train(n);
        for r = 1 : num_run
            fname = sprintf('%s/%s_%s_n%d_r%d.mat', res_dir, exp_name, feature, n_train, r);
            load(fname);
            acc_all{f}(n,r) = accuracy * 0.01;
            if n == numel(num_train) 
                if r == 1 
                    conf_mat{f} = confusion_mat;
                else
                    conf_mat{f} = conf_mat{f} + confusion_mat;
                end
            end
        end
        acc_mean{f}(n) = mean(acc_all{f}(n,:));
        acc_std{f}(n) = std(acc_all{f}(n,:));
    end
    conf_mat{f} = conf_mat{f}/num_run;
    conf_mat{f} = conf_mat{f}/num_test;
end

% Classification accuracy
figure(1), hold on; grid on;
chance_acc = 1/length(dataset_list) * ones(numel(num_train),1);
h1 = errorbar(num_train, acc_mean{1}, acc_std{1}, '-', 'LineWidth', 5);
h2 = errorbar(num_train, acc_mean{2}, acc_std{2}, '-', 'LineWidth', 5);
h3 = errorbar(num_train, acc_mean{3}, acc_std{3}, '-', 'LineWidth', 5);
h4 = errorbar(num_train, chance_acc, 0*ones(numel(num_train),1), '--', 'LineWidth', 5);

xlim([0, 2100]);
set(h1, 'Color', colors(1,:));
set(h2, 'Color', colors(2,:));
set(h3, 'Color', colors(3,:));
set(h4, 'Color', colors(4,:));
xlabel('Number of training examples per dataset', 'FontSize', 24);
ylabel('Classification accuracy', 'FontSize', 24);
set(gca, 'FontSize', 21);
hleg = legend(feature_list, 'Chance');
set(hleg, 'FontSize', 16)

% Confusion matrix
mat = conf_mat{1};
for i = 2 : length(feature_list)
    mat = mat + conf_mat{f};
end
mat = mat/length(feature_list);
figure(2), draw_cm(mat, dataset_list, length(dataset_list));