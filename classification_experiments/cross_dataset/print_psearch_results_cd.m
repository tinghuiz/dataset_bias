exp_name = 'cross_dataset_psearch';
dataset_list = {'Caltech101', 'Caltech256', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012'};
class_list = {'person', 'dog', 'bird', 'chair', 'car'};
feature_list = {'gist', 'sift'};
params_c = [0.01 0.1 1 10];
addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
colors = cbrewer('qual', 'Set1', 8);

res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/cross_dataset/psearch_results/';
res_file = [res_dir, exp_name, '_results.txt'];
fid = fopen(res_file, 'w');
% Clean up the locks if all jobs are done
filesdone = dir([res_dir, exp_name, '*.mat']);

for f = 1 : length(feature_list)
    for d = 1 : length(dataset_list)
        clear ap_all;
        figure(1); grid on;
        clf;
        
        exist_class_idx = [];
        for c = 1 : length(class_list)
            file_not_exist = false;
            for p = 1 : length(params_c)
                fname = sprintf('%s/%s_%s_%s_%s_%.5f.mat', res_dir, exp_name, dataset_list{d}, feature_list{f}, class_list{c}, params_c(p));
                if ~exist(fname)
                    file_not_exist = true;
                    break;
                end
                load(fname);
                ap_all(p,:) = ap;
                fprintf(fid, '%s_%s_%s_%.5f: crossval AP = %f\n', dataset_list{d}, feature_list{f}, class_list{c}, params_c(p), mean(ap));
            end
            if file_not_exist == true
                continue;
            end
            exist_class_idx = [exist_class_idx, c];
            mean_ap = mean(ap_all');
            std_ap = std(ap_all');
            h = errorbar(params_c, mean_ap, std_ap, '-', 'LineWidth', 3);hold on;
            set(h, 'Color', colors(c,:));
        end
        xlabel('C', 'FontSize', 18);
        ylabel('Cross validation AP', 'FontSize', 18);
        set(gca, 'FontSize', 18);
        title([dataset_list{d}, ' ', feature_list{f}], 'FontSize', 18);
        leg_class_list = class_list(exist_class_idx);
        hleg = legend(leg_class_list);
        drawnow;
        snapnow;
        fig_file = sprintf('%s/%s_%s_%s.png', res_dir, exp_name, dataset_list{d}, feature_list{f});
        print(gcf,'-dpng',fig_file);
    end
end

