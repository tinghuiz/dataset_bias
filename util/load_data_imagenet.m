function [pos_feat, neg_files, test_feat, test_labels] = load_data_imagenet(class, feature, imgset)

default_setup;

load([meta_dir, 'ILSVRC2012.mat'], 'class_names');
class = class_names.(class);

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
    test_labels = double(arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(class, y.class)), x.annotation.object))>0, test_anno));
    pos_feat = [];
    neg_files = [];
end

