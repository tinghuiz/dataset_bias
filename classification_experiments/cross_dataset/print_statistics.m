exp_name = 'cross_dataset';
dataset_list = {'Caltech101', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
class_list = {'person', 'car', 'bird', 'chair'};
res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/cross_dataset/main_results/';
res_file = [res_dir, 'stat.txt'];
fid = fopen(res_file, 'w');

for d = 1 : length(dataset_list)
    dataset = dataset_list{d};
    for c = 1 : length(class_list)
        class = class_list{c};
        if strcmp(dataset, 'ILSVRC2012')
            [pos_feat, neg_files, ~, ~] = load_data_imagenet(class, 'gist', 'train');
            neg_count = 0;
            for n = 1 : length(neg_files)
                neg = load(neg_files{n});
                neg_count = neg_count + size(neg.class_feat,1);
            end
            [~, ~, test_feat, test_labels] = load_data_imagenet(class, 'gist', 'test');
            if c == 1
                fprintf(fid, '%s & %d & %d & %d & %d ', dataset, size(pos_feat,1), neg_count, ...
                    sum(test_labels == 1), sum(test_labels == -1));
            else
                fprintf(fid, '& %d & %d & %d & %d ', size(pos_feat,1), neg_count, ...
                    sum(test_labels == 1), sum(test_labels == -1));
            end
        else
            [~, ~, train_labels, ~] = load_data(dataset, class, 'gist');
            [~, ~, ~, test_labels] = load_data(dataset, class, 'gist');
            if c == 1
                fprintf(fid, '%s & %d & %d & %d & %d ', dataset, sum(train_labels==1), sum(train_labels==-1), ...
                    sum(test_labels == 1), sum(test_labels == -1));
            else
                fprintf(fid, '& %d & %d & %d & %d ', sum(train_labels==1), sum(train_labels==-1), ...
                    sum(test_labels == 1), sum(test_labels == -1));
            end
        end
    end
    fprintf(fid, '\\\\\n');
end