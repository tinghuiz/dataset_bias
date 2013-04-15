addpath(genpath('features'));
addpath(genpath('liblinear-1.91'));

features = {'color_50', 'color_100', 'color_200', 'hog2x2_256', 'hog2x2_1024', 'hog3x3_256', 'hog3x3_1024', 'lbp_1239', 'sift_256', 'sift_1024', 'ssim_256', 'ssim_1024'};
num_splits = 25;
C_value = 1;
c = conf();
num_features = length(features);

load('splits.mat', 'splits');

rank_corr = zeros(num_features, num_splits);
human_corr = zeros(num_features, num_splits);
svm_options = ['-s 12 -p 0.000001 -B 1 -q -c ' num2str(C_value)];
model = cell(num_features, num_splits);
latexTable = cell(1, num_features);

for k=1:num_features
  load(sprintf('%s/train_%s.mat', c.cache, features{k}), 'feat');
  parfor i=1:num_splits
      train_score = splits(i).scores1(splits(i).trainidx);
      test_score = splits(i).scores2(splits(i).testidx);
      
      train_features = feat(splits(i).trainidx, :);
      test_features = feat(splits(i).testidx, :);

      model{k, i} = train(train_score, sparse(train_features), svm_options);
      predict_score = predict(test_score, sparse(test_features), model{k, i});

      rank_corr(k, i) = corr(predict_score, test_score, 'type', 'Spearman');
      human_corr(k, i) = corr(splits(i).scores1(splits(i).testidx), test_score, 'type', 'Spearman');
  end

  fprintf('Feature (%d of %d): %s\n', k, num_features, features{k});
  fprintf('Rank correlation: %f\n', mean(rank_corr(k, :)));
  fprintf('Human correlation: %f\n', mean(human_corr(k, :)));
  latexTable{1, k} = mean(rank_corr(k, :));
end
