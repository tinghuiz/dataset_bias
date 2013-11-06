exp_name = 'neg_set_bias';
dataset_list = {'Caltech101', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
feature_list = {'gist', 'sift'};
class_list = {'person', 'bird', 'chair', 'car'};
result_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/neg_set_bias/main_results/';
num_run = 3;
num_neg_per_set = 3200;

text_file = [result_dir, exp_name, '_results.txt'];
fid = fopen(text_file, 'w');

for f = 1 : length(feature_list)
    fprintf(fid, '%%%% %s %%%%%%%%%%%%%%%%%%%%\n', feature_list{f});
    for c = 1 : length(class_list)
        fprintf(fid, '%% %s\n', class_list{c});
        ap_all = zeros(length(dataset_list),1);
        for d = 1 : length(dataset_list)
            this_ap = zeros(num_run,1);
            for r = 1 : num_run
                result_file = sprintf('%s/%s_%s_%s_r%d', result_dir, dataset_list{d}, feature_list{f}, class_list{c}, r);
                load(result_file);
                this_ap(r) = ap;
            end
            fprintf(fid, '%.1f & ', mean(this_ap)*100);
            ap_all(d) = mean(this_ap)*100;
        end
        fprintf(fid, '%.1f \\\\\n', mean(ap_all));
        
        new_ap_all = zeros(length(dataset_list),1);
        for d = 1 : length(dataset_list)
            this_new_ap = zeros(num_run,1);
            for r = 1 : num_run
                result_file = sprintf('%s/%s_%s_%s_r%d', result_dir, dataset_list{d}, feature_list{f}, class_list{c}, r);
                load(result_file);
                this_new_ap(r) = new_ap;
            end
            fprintf(fid, '%.1f & ', mean(this_new_ap)*100);
            new_ap_all(d) = mean(this_new_ap)*100;
        end
        fprintf(fid, '%.1f \\\\\n', mean(new_ap_all));
        
        drop_percent_all = zeros(length(dataset_list),1);
        for d = 1 : length(dataset_list)
            this_drop_percent = zeros(num_run,1);
            for r = 1 : num_run
                result_file = sprintf('%s/%s_%s_%s_r%d', result_dir, dataset_list{d}, feature_list{f}, class_list{c}, r);
                load(result_file);
                this_drop_percent(r) = drop_percent;
            end
            fprintf(fid, '%2d\\%% & ', round(mean(this_drop_percent)*100));
            drop_percent_all(d) = mean(this_drop_percent)*100;
        end
        fprintf(fid, '%2d\\%% \\\\\n', round((mean(ap_all) - mean(new_ap_all))/mean(ap_all)*100));
    end
end