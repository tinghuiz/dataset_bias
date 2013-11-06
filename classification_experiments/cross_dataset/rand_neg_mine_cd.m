% Randomly sample a negative set, and train together with 70% of the positive set.
% Then evaluate on the rest of the negative set as well as the remaining 30% of 
% the postive set. Keep track of the best performing model along the
% process.

% Split the positives into train and validation sets
npos = size(pos_feat,1);
perm = randperm(npos);
pos_feat = pos_feat(perm,:);

ntrain = round(0.7 * npos);
train_pos = pos_feat(1:ntrain,:);
valid_pos = pos_feat(ntrain+1:end,:);

num_iter = 3;
ap_best = 0;
clear model;
for iter = 1 : num_iter
    fprintf('Random mining iter: %d/%d\n', iter, num_iter);
    rand_neg_feat = zeros(npos, size(pos_feat,2));
    start = 1;
    while start < npos
        % Sample a set
        ff = randi(length(neg_files),1);
        neg = load(neg_files{ff});
        perm = randperm(size(neg.class_feat,1));
        neg.class_feat = neg.class_feat(perm,:);
        % Sample at most 100 examples per set
        this_num = randi(100, 1);
        rand_neg_feat(start:start+this_num-1,:) = neg.class_feat(1:this_num,:);
        start = start + this_num;
    end
    
    train_feat = [train_pos; rand_neg_feat];
    train_labels = [ones(size(train_pos,1),1); -ones(size(rand_neg_feat,1),1)];
    model{iter} = train(double(train_labels), sparse(double(train_feat)), ['-s 0 -c ' num2str(C) ' -B 1']);
    
    % Now evaluate on the validation postive set and the negative set (too
    % time-consuming to evaluate on all. Sample 100 neg sets);
    pos_decval = [valid_pos, ones(size(valid_pos,1),1)] * model{iter}.w';
    perm = randperm(length(neg_files));
    clear neg_decval;
    for ff = 1 : 100
        if mod(ff, 10) == 0
            fprintf('Evaluation progress: %d/100\n', ff);
        end
        neg = load(neg_files{perm(ff)});
        neg = neg.class_feat;
        neg_decval{ff} = [neg, ones(size(neg,1),1)] * model{iter}.w';
    end
    neg_decval = cell2mat(neg_decval'); % FIXME
    
    dec_val = [pos_decval; neg_decval];
    valid_labels = [ones(numel(pos_decval),1); -ones(numel(neg_decval),1)];
    [ap(iter), prec, rec] = myAP(dec_val, valid_labels, 1); 
    if ap(iter) > ap_best
        best_model = model{iter};
        ap_best = ap(iter);
    end
end

model = best_model;