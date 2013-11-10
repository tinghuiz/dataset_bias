% allDatasets = {'Caltech101', 'Caltech256', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
allDatasets = {'ILSVRC2012'};
% allDatasets = {'Caltech256'};
datasetFolder = '/nfs/hn49/tinghuiz/ijcv_bias/datasetStore/';
cacheFolder = 'cache/';
feature = 'color';
dict_size = 1024;
split_size = 50000;

clear trainlists
clear testlists
for d = 1 : length(allDatasets)
    trainlists{d} = [];
    testlists{d} = [];
    currset = allDatasets{d};
    load(fullfile(datasetFolder, [currset '.mat']));
    if(strcmp(currset, 'PASCAL2007') || strcmp(currset, 'PASCAL2012'))
        check_difficult = 1;
    else
        check_difficult = 0;
    end
%     [tmp,hname] = unix('hostname');
%     if ~strcmp(hname(end-3:end-1), 'edu')
%         data.hi = '/lustre/tinghuiz/datasets/ILSVRC_2012/';
%     end
    noTrainObjects = find(arrayfun(@(x) ~isfield(x.annotation, 'object'), data.tr));
    for i=1:length(noTrainObjects), data.tr(noTrainObjects(i)).annotation.object = []; end
    
    noTestObjects = find(arrayfun(@(x) ~isfield(x.annotation, 'object'), data.te));
    for i=1:length(noTestObjects), data.te(noTestObjects(i)).annotation.object = []; end
    
    tr_split = cell(1, split_size);
    si = 0;
    for i = 1 : length(data.tr)
        si = si + 1;
        tr_split{si} = fullfile(data.hi, data.tr(i).annotation.folder, data.tr(i).annotation.filename);
        if si == split_size || i == length(data.tr)
            si = 0;
            emp = cellfun(@isempty,tr_split);
            tr_split(emp) = [];
            trainlists{d} = [trainlists{d}, tr_split];
            tr_split = cell(1, split_size);
            fprintf('Processing train set of %s: %d/%d\n', currset, i, length(data.tr));
        end        
    end 
    
    for i = 1 : length(data.te)
        if ~mod(i,1000) fprintf('Processing test set of %s: %d/%d\n', currset, i, length(data.te));end
        testlists{d}{i} = fullfile(data.hi, data.te(i).annotation.folder, data.te(i).annotation.filename);
    end
end
data.hi
fprintf('Start feature extraction...\n');
addpath(genpath(pwd));
names = allDatasets;
c = conf(cacheFolder);
c.cores = 0;
c.batch_size = 500;
c.feature_config.color.dictionary_size = dict_size;
c.feature_config.color.grid_spacing = 6;
c.feature_config.color.patch_sizes = [8 16 24];
c.feature_config.color.maxsize = 400;

datasets_feature(names, trainlists, testlists, feature, c);
save([feature, '_', num2str(dict_size) '_config.mat'], 'c'); % save this variable because its useful for file reading later
