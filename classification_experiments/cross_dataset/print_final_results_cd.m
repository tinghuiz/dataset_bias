exp_name = 'cross_dataset';
dataset_list = {'Caltech101', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
class_list = {'person', 'dog', 'bird', 'chair', 'car'};
feature_list = {'gist', 'sift', 'color'};

res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/cross_dataset/main_results/';
res_file = [res_dir, exp_name, '_results.txt'];
fid = fopen(res_file, 'w');

for f = 1 : length(feature_list)
    fprintf(fid, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n');
    fprintf(fid, '%% Feature = %s\n', feature_list{f});
    for c = 1 : length(class_list)
        fprintf(fid, '%%%s\n', class_list{c});
        ap_table = -ones(length(dataset_list), length(dataset_list));
        for test_d = 1 : length(dataset_list)
            fprintf(fid, '& & %s & ', dataset_list{test_d});
            for train_d = 1 : length(dataset_list)
                fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
                if ~exist(fname)
                    fprintf(fid, '-- & ');
                    continue;
                end
                load(fname, 'ap');
                ap_table(test_d, train_d) = ap;
                if train_d == test_d
                    fprintf(fid, '$\\mathbf{%.1f}$ & ', ap*100);
                else
                    fprintf(fid, '%.1f & ', ap*100);
                end
            end
            self_ap = ap_table(test_d, test_d);
            if self_ap ~= -1
                row_other_idx = setdiff(1:length(dataset_list), test_d);
                bad_idx = find(ap_table(test_d,:) == -1);
                row_other_idx = setdiff(row_other_idx, bad_idx);
                row_other_ap = ap_table(test_d, row_other_idx);
                percent_drop = (self_ap - mean(row_other_ap))/self_ap;
                fprintf(fid, '%.1f & %.1f & %2d\\%% ', self_ap*100, mean(row_other_ap)*100, round(percent_drop*100));
            else
                fprintf(fid, '-- & -- & -- ');
            end
            fprintf(fid, '\\\\\n');
        end
        
%         self_all = [];
%         mean_all = [];
%         
%         fprintf(fid, 'Mean others & ');
%         for test_d = 1 : length(dataset_list)
%             if ap_table(test_d, test_d) == -1
%                 fprintf(fid, '-- & ');
%                 continue;
%             end
%             col_other_idx = setdiff(1:length(dataset_list), test_d);
%             bad_idx = find(ap_table(:,test_d) == -1);
%             col_other_idx = setdiff(col_other_idx, bad_idx);
%             col_other_ap = ap_table(col_other_idx, test_d);
%             fprintf(fid, '%.1f & ', mean(col_other_ap)*100);
%             mean_all = [mean_all, mean(col_other_ap)*100];
%             self_all = [self_all, ap_table(test_d, test_d)*100];
%         end
%         
%         mma = mean(mean_all);
%         msa = mean(self_all);
%         percent_drop = (msa - mma)/msa;
%         fprintf(fid, '%.1f & %.1f & %2d%% ', msa, mma, round(percent_drop*100));
%         
        fprintf(fid, '\\\\\n');
        fprintf(fid, '\n');     
    end
end