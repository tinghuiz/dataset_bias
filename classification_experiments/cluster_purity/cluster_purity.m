exp_name = 'cluster_purity';
dataset_list = {'Caltech101', 'Caltech256', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
feature_list = {'gist', 'sift', 'color'};
num_clusters = [3 7 10 15 20];
num_img = 2000;
num_run = 5;

res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/cluster_purity/main_results/';
if ~exist(res_dir, 'dir')
    mkdir(res_dir);
end

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
default_setup;

for f = 1 : length(feature_list)
    feature = feature_list{f};
    clear imagenet_feat;
    for c = 1 : length(num_clusters)
        for r = 1 : num_run
            clear dataset_feat;
            clear dataset_label;
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
                dataset_label{d} = d*ones(num_img, 1);
            end
            dataset_feat = cell2mat(dataset_feat');
            dataset_label = cell2mat(dataset_label);
            
            % Clustering
            iter = 0;
            while 1
                iter = iter + 1;
                fprintf('Clustering iter %d...\n', iter);
                cluster_label = litekmeans(dataset_feat', num_clusters(c));
                if numel(unique(cluster_label)) == num_clusters(c)
                    break;
                end
            end
            
            % Compute purity of each cluster
            fprintf('Computing clustering purity...\n');
            clear percent_table;
            clear purity;
            for k = 1 : num_clusters(c) % k index clusters
                idx = find(cluster_label == k);
                dlabels = dataset_label(idx);
                for d = 1 : length(dataset_list)
                    curr_cnt = sum(dlabels == d);
                    percent_table(k,d) = curr_cnt/numel(idx);
                end
                %             max_cnt(i) = 0;
                %             max_d(i) = 0;
                %             for d = 1 : length(dataset_list)
                %                 curr_cnt = sum(dlabels == d);
                %                 if curr_cnt > max_cnt(i)
                %                     max_cnt(i) = curr_cnt;
                %                     max_d(i) = d;
                %                 end
                %             end
                %             purity(i) = max_cnt(i)/numel(idx);
            end
            
            for d = 1 : length(dataset_list)
                purity(d) = max(percent_table(:,d));
            end
            
            fname = sprintf('%s/%s_%s_k%d_r%d.mat', res_dir, exp_name, feature, num_clusters(c), r);
            save(fname, 'purity', 'percent_table', 'dataset_list');
        end
    end
end

%% Plot results
colors = cbrewer('qual', 'Set1', 8);
for f = 1 : length(feature_list)
    feature = feature_list{f};
    purity_mean = zeros(length(dataset_list),length(num_clusters));
    purity_std = zeros(length(dataset_list),length(num_clusters));
    for c = 1 : length(num_clusters)
        res = zeros(length(dataset_list), num_run);
        for r = 1 : num_run
            fname = sprintf('%s/%s_%s_k%d_r%d.mat', res_dir, exp_name, feature, num_clusters(c), r);
            load(fname);
            res(:,r) = purity;
        end
        purity_mean(:,c) = mean(res');
        purity_std(:,c) = std(res');
    end
    
    figure(f), hold on; grid on;
    rand_purity = 1/length(dataset_list) * ones(length(num_clusters),1);
    for d = 1 : length(dataset_list)
        h = errorbar(num_clusters, purity_mean(d,:), purity_std(d,:), '-', 'LineWidth', 3);
        set(h, 'Color', colors(d,:));
    end
    h = errorbar(num_clusters, rand_purity, 0*ones(length(num_clusters),1), '--', 'LineWidth', 3);
    set(h, 'Color', 'k');
    xlim([2, 21]);
    ylim([0.1, 0.55]);
    xlabel('Number of clusters', 'FontSize', 24);
    ylabel('Purity', 'FontSize', 24);
    set(gca, 'FontSize', 21);
    if f == 1
        hleg = legend(dataset_list, 'Chance');
        set(hleg, 'FontSize', 11)
    end
    title(feature, 'FontSize', 21)
end

