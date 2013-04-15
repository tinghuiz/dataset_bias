function [feat] = filelist_feature(filelist, imgset, feature, c)
if(~exist('c', 'var'))
  c = conf();
end

p = c.feature_config.(feature);
if(isfield(p, 'dictionary_size'))
  feature_file = sprintf(p.([imgset '_file']), c.cache, p.dictionary_size);
else
	feature_file = sprintf(p.([imgset '_file']), c.cache);
end

if(exist(feature_file, 'file'))
  load(feature_file);
  return;
end

feat = cell(length(filelist), 1);
patch_size.x = 1; patch_size.y = 1;

if(isfield(p, 'dictionary_file'))
  parfor i=1:length(filelist)
    fprintf('Processing filelist (%s, %s): %d of %d\n', imgset, feature, i, length(filelist));
    [~, filename] = fileparts(filelist{i});
    llcFile = [c.cache 'llc_' feature '_' num2str(p.dictionary_size) '/' filename '.mat'];

    if(~exist(llcFile, 'file'))
      info = struct();
      img = imgread(filelist{i}, p);
      [llcfeat, x, y, wid, hgt] = llc_feature(feature, img, c);
      info.x = x; info.y = y; info.wid = wid; info.hgt = hgt;
      parsaveLLC(llcFile, llcfeat, info);
    else
      tmp = load(llcFile);
      llcfeat = tmp.llcfeat;
      info = tmp.info;
    end

    feat{i} = LLC_pooling({llcfeat}, {info}, 0, 0, patch_size, p.pyramid_levels);
  end
else
  parfor i=1:length(filelist)
    fprintf('Processing filelist (%s, %s): %d of %d\n', imgset, feature, i, length(filelist));
    img = imgread(filelist{i}, p);
    feat{i} = extract_feature(feature, img, c);
  end
end

feat = cell2mat(feat);
save(feature_file, 'feat', '-v7.3');
