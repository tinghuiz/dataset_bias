exp_name = 'cluster_purity';
dataset_list = {'Caltech101', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
% feature_list = {'gist', 'sift', 'color'};
feature_list = {'color'};
num_clusters = [3 7 10 20 40 80];
num_img = 2000;
num_run = 5;
num_chance_run = 50;
res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/cluster_purity/main_results/';

if ~exist(res_dir, 'dir')
    mkdir(res_dir);
end

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
default_setup;

% Get chance performance
chance_purity_mean = zeros(1,length(num_clusters));
chance_purity_std = zeros(1,length(num_clusters));
for c = 1 : length(num_clusters)    
    normalized_purity = zeros(1, num_chance_run);
    for r = 1 : num_chance_run
        clear dataset_labels;
        for d = 1 : length(dataset_list)
            curr_set = dataset_list{d};
            dataset_labels{d} = d*ones(num_img, 1);
        end
        dataset_labels = cell2mat(dataset_labels');
        % Randomly assign a cluster label to each data point
        cluster_labels = randi([1, num_clusters(c)], numel(dataset_labels),1);
        purity = zeros(num_clusters(c),1);
        percent_table = zeros(num_clusters(c), length(dataset_list));
        cluster_size = zeros(num_clusters(c), 1);
        for k = 1 : num_clusters(c) % k index clusters
            idx = find(cluster_labels == k);
            dlabels = dataset_labels(idx);
            for d = 1 : length(dataset_list)
                curr_cnt = sum(dlabels == d);
                percent_table(k,d) = curr_cnt/numel(idx);
            end
            purity(k) = max(percent_table(k,:));
            cluster_size(k) = numel(idx);
        end
%         mean_purity = mean(purity);
        normalized_purity(r) = sum(purity.*(cluster_size/sum(cluster_size)));
%         fprintf('#clusters = %d, run = %d, norm_purity = %f\n', num_clusters(c), r, normalized_mean_purity);
    end
    chance_purity_mean(c) = mean(normalized_purity);
    chance_purity_std(c) = std(normalized_purity);
end


for f = 1 : length(feature_list)
    feature = feature_list{f};
    clear imagenet_feat;
    for c = 1 : length(num_clusters)
        for r = 1 : num_run
            clear dataset_feat;
            clear dataset_labels;
            fprintf('Loading features...\n');
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
                    dataset_feat{d} = imagenet_feat(pm(1:num_img), :);
                else
                    [tr_feat, ~, ~, ~] = load_data(curr_set, 'car', feature);
                    tr_pm = randperm(size(tr_feat,1));
                    dataset_feat{d} = tr_feat(tr_pm(1:num_img),:);
                end
                dataset_labels{d} = d*ones(num_img, 1);
            end
            dataset_feat = cell2mat(dataset_feat');
            dataset_labels = cell2mat(dataset_labels');
            
            % Clustering
            iter = 0;
            while 1
                iter = iter + 1;
                fprintf('Clustering iter %d...\n', iter);
                cluster_labels = litekmeans(dataset_feat', num_clusters(c));
                if numel(unique(cluster_labels)) == num_clusters(c)
                    break;
                end
            end
            
            % Compute purity of each cluster
            fprintf('Computing clustering purity...\n');
            
            purity = zeros(num_clusters(c),1);
            percent_table = zeros(num_clusters(c), length(dataset_list));
            cluster_size = zeros(num_clusters(c), 1);
            for k = 1 : num_clusters(c) % k index clusters
                idx = find(cluster_labels == k);
                dlabels = dataset_labels(idx);
                for d = 1 : length(dataset_list)
                    curr_cnt = sum(dlabels == d);
                    percent_table(k,d) = curr_cnt/numel(idx);
                end
                purity(k) = max(percent_table(k,:));
                cluster_size(k) = numel(idx);
            end
%             mean_purity = mean(purity);
%             normalized_mean_purity = mean(purity.*(cluster_size/size(dataset_feat,1)));
            fname = sprintf('%s/%s_%s_k%d_r%d.mat', res_dir, exp_name, feature, num_clusters(c), r);
            save(fname, 'purity', 'percent_table', 'cluster_size');
        end
    end
end

%% Plot results
colors = cbrewer('qual', 'Set1', 8);
figure(1), hold on; grid on;
for f = 1 : length(feature_list)
    feature = feature_list{f};
    purity_mean = zeros(1,length(num_clusters));
    purity_std = zeros(1,length(num_clusters));
    for c = 1 : length(num_clusters)
        res = zeros(1, num_run);
        for r = 1 : num_run
            fname = sprintf('%s/%s_%s_k%d_r%d.mat', res_dir, exp_name, feature, num_clusters(c), r);
            load(fname);
            res(r) = sum(purity.*(cluster_size/sum(cluster_size)));
        end
        purity_mean(c) = mean(res);
        purity_std(c) = std(res);
    end
    h = errorbar(num_clusters, purity_mean, purity_std, '-', 'LineWidth', 3);
    set(h, 'Color', colors(f,:));
end

% rand_purity = 1/length(dataset_list) * ones(1, length(num_clusters));
h = errorbar(num_clusters, chance_purity_mean, chance_purity_std, '--', 'LineWidth', 3);
set(h, 'Color', 'k');
hleg = legend(feature_list, 'Chance');
set(hleg, 'FontSize', 11)
xlim([2, 81]);
ylim([0, 0.7]);
xlabel('Number of clusters', 'FontSize', 24);
ylabel('Purity', 'FontSize', 24);
set(gca, 'FontSize', 21);
