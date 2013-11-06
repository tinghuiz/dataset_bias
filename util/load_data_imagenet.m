function [pos_feat, neg_files, test_feat, test_labels] = load_data_imagenet(class, feature, imgset)

default_setup;

load([meta_dir, 'ILSVRC2012.mat'], 'class_names');
if iscell(class)
    class_all = [];
    for i = 1: length(class)
        class_all = [class_all, class_names.(class{i})];
    end
    class = class_all;
else
    class = class_names.(class);
end

feat_dir = [imagenet_feat_dir, feature, '/'];

if strcmp(imgset, 'train')
    train_feat_files = dir([feat_dir, 'n*.mat']);
    neg_cnt = 0;
    pos_cnt = 0;
    for i = 1 : length(train_feat_files)
        if cell_isempty(strfind(class, train_feat_files(i).name(1:end-4)))
            neg_cnt = neg_cnt + 1;
            neg_files{neg_cnt} = [feat_dir, train_feat_files(i).name];
        else
            if pos_cnt > max_pos_synsets
                continue
            end
            pos_cnt = pos_cnt + 1;
            tmp = load([feat_dir, train_feat_files(i).name], 'class_feat');
            pos_feat{pos_cnt} = tmp.class_feat;
        end
        
    end
    
    pos_feat = cell2mat(pos_feat');
    test_feat = [];
    test_labels = [];
end

if strcmp(imgset, 'test')
    test_set_file = [feat_dir, 'test_set.mat'];
    load(test_set_file);
    all_valid_class = {'car', 'person', 'dog', 'bird', 'chair'};
    all_valid_i = zeros(1, size(test_feat,1));
    for i = 1 : length(all_valid_class)
        valid_class = class_names.(all_valid_class{i});
        this_test_labels = double(arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(valid_class, y.class)), x.annotation.object))>0, test_anno));
        all_valid_i = all_valid_i | this_test_labels;
    end
    neg_i = find(all_valid_i == 0);
    % Only keep 5000 negative examples (so the AP does not look too
    % shabby).
    all_valid_i(neg_i(1:5000)) = 1;
    test_labels = double(arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(class, y.class)), x.annotation.object))>0, test_anno));
    test_labels = test_labels * 2 - 1;
    test_feat = double(test_feat);
    pos_feat = [];
    neg_files = [];
    test_labels = test_labels(all_valid_i);
    test_feat = test_feat(all_valid_i, :);
end

