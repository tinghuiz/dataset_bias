clear
exp_name = 'background_bias';
dataset_list = {'Caltech101', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
class_list = {'person', 'bird', 'chair', 'car'};
feature_list = {'gist', 'sift'};
C = 10;

res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/background_bias/main_results/';
if ~exist(res_dir, 'dir')
    mkdir(res_dir);
end

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
default_setup;

myRandomize;
train_d = randi(length(dataset_list),1);
test_d = randi(length(dataset_list),1);
f = randi(length(feature_list),1);
c = randi(length(class_list),1);


fprintf('Processing: %s_%s_%s_%s\n',dataset_list{train_d},dataset_list{test_d},feature_list{f},class_list{c});

