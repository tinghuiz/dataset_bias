dataset = 'PASCAL2012';
dict_size = 1024;
feature = 'sift';
feat_dir = '/nfs/hn49/tinghuiz/ijcv_bias/feature_extract/cache/';
meta_dir = '/nfs/ladoga_no_backups/users/tinghuiz/eccv12/datasetStore/';
res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/feature_extract/final_features/';

addpath(genpath(pwd));
load([feature '_config_' num2str(dict_size)]);
train_feat = load_features(feature, 'train', c, dataset);
test_feat = load_features(feature, 'test', c, dataset);

save(sprintf('%s/%s_%s_%d.mat', res_dir, dataset, feature, dict_size), 'train_feat', 'test_feat', '-v7.3');