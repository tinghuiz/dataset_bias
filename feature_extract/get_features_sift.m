% allDatasets = {'ILSVRC2012', 'LabelMeSpain', 'PASCAL2007', 'SUN', 'Caltech101', 'Caltech256', 'PASCAL2012'};
allDatasets = {'ILSVRC2012'};
% allDatasets = {'Caltech101'};
datasetFolder = '/nfs/hn49/tinghuiz/ijcv_bias/datasetStore/';
cacheFolder = '/nfs/hn49/tinghuiz/ijcv_bias/feature_extract/cache/';
feature = 'sift';
dict_size = 1024;

clear trainlists
clear testlists
for d = 1 : length(allDatasets)
    currset = allDatasets{d};
    load(fullfile(datasetFolder, [currset '.mat']));
    if(strcmp(currset, 'PASCAL2007') || strcmp(currset, 'PASCAL2012'))
        check_difficult = 1;
    else
        check_difficult = 0;
    end
    noTrainObjects = find(arrayfun(@(x) ~isfield(x.annotation, 'object'), data.tr));
    for i=1:length(noTrainObjects), data.tr(noTrainObjects(i)).annotation.object = []; end
    
    noTestObjects = find(arrayfun(@(x) ~isfield(x.annotation, 'object'), data.te));
    for i=1:length(noTestObjects), data.te(noTestObjects(i)).annotation.object = []; end
    
    for i = 1 : length(data.tr)
        if ~mod(i,1000) fprintf('Processing train set of %s: %d/%d\n', currset, i, length(data.tr));end
        trainlists{d}{i} = fullfile(data.hi, data.tr(i).annotation.folder, data.tr(i).annotation.filename);
    end
    for i = 1 : length(data.te)
        if ~mod(i,1000) fprintf('Processing test set of %s: %d/%d\n', currset, i, length(data.te));end
        testlists{d}{i} = fullfile(data.hi, data.te(i).annotation.folder, data.te(i).annotation.filename);
    end
end

fprintf('Start feature extraction...\n');
addpath(genpath(pwd));
names = allDatasets;
c = conf(cacheFolder);
c.cores = 0;
c.batch_size = 20;
c.feature_config.sift.dictionary_size = dict_size;
c.feature_config.sift.grid_spacing = 6;
c.feature_config.sift.patch_sizes = [8 16 24];
c.feature_config.sift.maxsize = 400;

datasets_feature(names, trainlists, testlists, feature, c);
save([feature, '_', num2str(dict_size) '_config.mat'], 'c'); % save this variable because its useful for file reading later