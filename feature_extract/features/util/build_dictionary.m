function [dictionary] = build_dictionary(filelist, feature, c)
if(~exist('c', 'var'))
  c = conf();
end

p = c.feature_config.(feature);
if(~isfield(p, 'dictionary_file'))
  dictionary = [];
  return;
end
p.dictionary_file = sprintf(p.dictionary_file, c.cache, p.dictionary_size);

if(~exist(p.dictionary_file, 'file'))
  perm = randperm(length(filelist));
  descriptors = cell(min(length(filelist), p.num_images), 1);
  num_images = min(length(filelist), p.num_images);
  parfor i=1:num_images
    fprintf('Dictionary learning (%s): %d of %d\n', feature, i, num_images);
    img = imgread(filelist{perm(i)}, p);
    feat = extract_feature(feature, img, c);
    r = randperm(size(feat, 1));
    descriptors{i} = feat(r(1:min(length(r), p.descPerImage)), :);
  end
  descriptors = cell2mat(descriptors);
  ndata = size(descriptors, 1);
  if(ndata>p.num_desc)
    idx = randperm(ndata);
    descriptors = descriptors(idx(1:p.num_desc), :);
  end
  fprintf('Running k-means, dictionary size %d...', p.dictionary_size);
  dictionary = litekmeans(descriptors', p.dictionary_size);
  fprintf('done!\n');
  dictionary = dictionary';
  make_dir(p.dictionary_file);
  fprintf('Saving dictionary: %s\n', p.dictionary_file);
  save(p.dictionary_file, 'dictionary');
else
  load(p.dictionary_file);
end
