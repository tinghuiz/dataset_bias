feature = feature_list{f};
class = class_list{c};

train_dataset = dataset_list{train_d};
test_dataset = dataset_list{test_d};

if strcmp(train_dataset, 'ILSVRC2012')
    [pos_feat, neg_files, ~, ~] = load_data_imagenet(class_list{c}, feature_list{f}, 'train');
    if size(pos_feat,1) > 5000
        pm = randperm(size(pos_feat,1));
        pos_feat = pos_feat(pm(1:5000),:);
    end
    neg_cache = cell(length(neg_files),1);
    max_mine_iter = 2;
    max_neg_kept = 50;
    new_cnt = 9999;
    i_am_server = true;
    % Initialize a model with a random negative set
    neg_cnt = 0;
    set = 0;
    clear rand_neg_feat;
    while neg_cnt < size(pos_feat,1)
        n = randi(length(neg_files),1);
        neg = load(neg_files{n});
        set = set + 1;
        neg_cnt = neg_cnt + size(neg.class_feat,1);
        rand_neg_feat{set} = neg.class_feat;
    end
    rand_neg_feat = cell2mat(rand_neg_feat');
    pm = randperm(size(rand_neg_feat,1));
    rand_neg_feat = rand_neg_feat(pm,:);
    train_feat = [pos_feat; rand_neg_feat];
    train_labels = [ones(size(pos_feat,1),1); -ones(size(rand_neg_feat,1),1)];
    model = train(double(train_labels), sparse(double(train_feat)), ['-s 0 -c ' num2str(C) ' -B 1']);
    [~, ~, dec_values] = predict(train_labels, sparse(double(train_feat)), model, '-b 1');
    %         model = libsvmtrain(double(train_labels), sparse(double(train_feat)), ['-t 0 -c ' num2str(C)]);
    %          [~, ~, dec_values] = libsvmpredict(train_labels, sparse(double(train_feat)), model);
    dec_values = dec_values(:, model.Label==1);
    [ap, prec, rec] = myAP(dec_values, train_labels, 1);
    if strcmp(test_dataset, 'ILSVRC2012')
        [~, ~, test_feat, test_labels] = load_data_imagenet(class_list{c}, feature_list{f}, 'test');
    else
        [~, test_feat, ~, test_labels] = load_data(test_dataset, class, feature);
    end
    if sum(train_labels == 1) == 0 || sum(train_labels == -1) == 0 || sum(test_labels == 1) == 0 || sum(test_labels == -1) == 0
        fprintf('Label error! %s_%s_%s_%s\n',dataset_list{train_d},dataset_list{test_d},feature_list{f},class_list{c});
        continue;
    end
    mine_iter = 0;
    rand_neg_mine_cd;
    [~, ~, dec_values] = predict(double(test_labels'), sparse(test_feat), model, '-b 1');
    ap = myAP(dec_values(:, model.Label==1), test_labels', 1);
    fprintf('AP = %f, num_pos_train = %d, num_neg_train = %d, num_pos_test = %d, num_neg_test = %d\n', ap, sum(train_labels == 1), sum(train_labels == -1), sum(test_labels == 1), sum(test_labels == -1));
    fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
    save(fname, 'ap', 'model', 'dataset_list', 'class_list', 'feature_list', 'train_d', 'test_d', 'f', 'c');
else
    [train_feat, ~, train_labels, ~] = load_data(train_dataset, class, feature);
    if strcmp(test_dataset, 'ILSVRC2012')
        [~, ~, test_feat, test_labels] = load_data_imagenet(class_list{c}, feature_list{f}, 'test');
    else
        [~, test_feat, ~, test_labels] = load_data(test_dataset, class, feature);
    end
    
    % Ensure that the first training example is positive
    while 1
        if train_labels(1) == 1
            break;
        end
        pm = randperm(numel(train_labels));
        train_labels = train_labels(pm);
        train_feat = train_feat(pm,:);
    end
    
    model = train(double(train_labels'), sparse(train_feat), ['-s 0 -c ' num2str(C) ' -B 1 -q 1']);
    [pred_labels, ~, dec_values] = predict(double(test_labels'), sparse(test_feat), model, '-b 1');
    ap = myAP(dec_values(:, model.Label==1), test_labels', 1);
    fprintf('AP = %f, num_pos_train = %d, num_neg_train = %d, num_pos_test = %d, num_neg_test = %d\n', ap, sum(train_labels == 1), sum(train_labels == -1), sum(test_labels == 1), sum(test_labels == -1));
    fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
    if exist(fname, 'file')
        previous_result = load(fname);
        if previous_result.ap < ap
            save(fname, 'ap', 'model', 'dataset_list', 'class_list', 'feature_list', 'train_d', 'test_d', 'f', 'c');
        end
    else
        save(fname, 'ap', 'model', 'dataset_list', 'class_list', 'feature_list', 'train_d', 'test_d', 'f', 'c');
    end
end

