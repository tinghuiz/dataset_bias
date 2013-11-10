dataset = 'ILSVRC2012';
feature = 'color';
dict_size = 1024;
feat_dir = '/nfs/hn49/tinghuiz/ijcv_bias/feature_extract/cache/';
meta_dir = '/nfs/hn49/tinghuiz/ijcv_bias/datasetStore/';
res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/feature_extract/final_features/';

addpath(genpath(pwd));
addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
if strcmp(feature, 'sift')
    load([feature '_config_' num2str(dict_size), '.mat']);
end
if strcmp(feature, 'gist')
    load([feature '_config.mat']);
end
if strcmp(feature, 'color')
    load([feature '_config_' num2str(dict_size), '.mat']);
end

if strcmp(dataset, 'ILSVRC2012')
    lock_dir = ['/nfs/hn49/tinghuiz/ijcv_bias/sync_locks/assemble/'];
    if ~exist(lock_dir, 'dir')
        mkdir(lock_dir);
    end
    ilsvrc_meta_file = '/nfs/ladoga_no_backups/users/tinghuiz/datasets/ILSVRC_2012/ILSVRC2012_devkit_t12/data/meta.mat';
    cache_folder = [c.cache '/' dataset '/'];
    p = c.feature_config.(feature);
    if(isfield(p, 'dictionary_size'))
        train_feature_file = sprintf(p.train_file, cache_folder, p.dictionary_size);
    else
        train_feature_file = sprintf(p.train_file, cache_folder);
    end
    load(train_feature_file);
    load([meta_dir, 'ILSVRC2012.mat']);
    load(ilsvrc_meta_file);
    temp = load(batch_files{1});
    batch_size = length(temp.info);
    
    while length(dir([lock_dir, 'lock_assemble_synset_*'])) < 1000
        myRandomize;
        s = randi(1000, 1);
        lock = [lock_dir, 'lock_assemble_synset_' num2str(s)];
        if mymkdir_dist(lock) == 0
            continue;
        end
        fprintf('Processing: %d/1000\n', s);
        curr_class = synsets(s).WNID;
        tic
        train_labels = double(arrayfun(@(x) sum(arrayfun(@(y) ~isempty(strfind(curr_class, y.class)), x.annotation.object))>0, data.tr));
        toc
        ind = find(train_labels == 1);
        [batch_ind, feat_ind] = index_lookup_imagenet(ind, batch_size);
        
        uni_batch_ind = unique(batch_ind);
        clear batch_feat;
        for b = 1 : numel(uni_batch_ind)
            bfile = batch_files{uni_batch_ind(b)};
            if ~exist(bfile)
                batch_feat{b} = [];
            else
                load(bfile);
                batch_feat{b} = poolfeat(feat_ind(batch_ind == uni_batch_ind(b)), :);
            end
        end
        class_feat = cell2mat(batch_feat');
        class_anno = data.tr(ind);
        class_hi = data.hi;
        save([res_dir, '/ILSVRC2012/' feature, '/' curr_class, '.mat'], 'class_feat', 'class_anno', 'class_hi');
    end
    
    if mymkdir_dist([lock_dir, 'lock_assemble_person_and_test'])
        fprintf('Processing: person and test set\n');
        s = 1072;
        curr_class = synsets(s).WNID;
        tic
        train_labels = double(arrayfun(@(x) sum(arrayfun(@(y) ~isempty(strfind(curr_class, y.class)), x.annotation.object))>0, data.tr));
        toc
        ind = find(train_labels == 1);
        [batch_ind, feat_ind] = index_lookup_imagenet(ind, batch_size);
        
        uni_batch_ind = unique(batch_ind);
        clear batch_feat;
        for b = 1 : numel(uni_batch_ind)
            load( batch_files{uni_batch_ind(b)});
            batch_feat{b} = poolfeat(feat_ind(batch_ind == uni_batch_ind(b)), :);
        end
        class_feat = cell2mat(batch_feat');
        class_anno = data.tr(ind);
        class_hi = data.hi;
        save([res_dir, '/ILSVRC2012/' feature, '/' curr_class, '.mat'], 'class_feat', 'class_anno', 'class_hi');
        test_feat = load_features(feature, 'test', c, dataset);
        test_anno = data.te;
        test_hi = data.hi;
        save([res_dir, '/ILSVRC2012/' feature, '/test_set.mat'], 'test_feat', 'test_anno', 'test_hi', '-v7.3');
    end
else
    train_feat = load_features(feature, 'train', c, dataset);
    test_feat = load_features(feature, 'test', c, dataset);
    if strcmp(feature, 'sift')
        save(sprintf('%s/%s_%s_%d.mat', res_dir, dataset, feature, dict_size), 'train_feat', 'test_feat', '-v7.3');
    end
    if strcmp(feature, 'color')
        save(sprintf('%s/%s_%s_%d.mat', res_dir, dataset, feature, dict_size), 'train_feat', 'test_feat');
    end
    
    if strcmp(feature, 'gist')
        save(sprintf('%s/%s_%s.mat', res_dir, dataset, feature), 'train_feat', 'test_feat');
    end
end