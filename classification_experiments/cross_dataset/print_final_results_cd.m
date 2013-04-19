exp_name = 'cross_dataset';
dataset_list = {'Caltech101', 'Caltech256', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
class_list = {'person', 'dog', 'bird', 'chair', 'car'};
feature_list = {'gist', 'sift'};

res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/cross_dataset/main_results/';
res_file = [res_dir, exp_name, '_results.txt'];
fid = fopen(res_file, 'w');

for f = 1 : length(feature_list)
    fprintf(fid, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n');
    fprintf(fid, '%% Feature = %s\n', feature_list{f});
    for c = 1 : length(class_list)
        fprintf(fid, '%%%s\n', class_list{c});
        for train_d = 1 : length(dataset_list)
            fprintf(fid, '%s & ', dataset_list{train_d});
            maxap = 0;
            selfap = [];
            otherap = [];
            for test_d = 1 : length(dataset_list)
                fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
                if ~exist(fname)
                    continue;
                end
                load(fname, 'ap');
                if ap > maxap
                    maxap = ap;
                end
                if test_d == train_d
                    selfap = ap;
                else
                    otherap = [otherap, ap];
                end
            end
            for test_d = 1 : length(dataset_list)
                fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
                if ~exist(fname)
                    fprintf(fid, '-- & ');
                    continue;
                end
                load(fname, 'ap');
                if ap == maxap
                    fprintf(fid, '\\mathbf{%.1f} & ', ap*100);
                else
                    fprintf(fid, '%.1f & ', ap*100);
                end
            end
            if ~isempty(selfap)
                percent_drop = (selfap - mean(otherap))/selfap;
                fprintf(fid, '%.1f & %.1f & %2d%% ', selfap*100, mean(otherap)*100, round(percent_drop*100));
            else
                fprintf(fid, '-- & -- & -- ');
            end
            fprintf(fid, '\\\\\n');
        end
        fprintf(fid, '\n');
    end
end