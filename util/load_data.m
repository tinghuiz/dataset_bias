function [train_feat, test_feat, train_labels, test_labels] = load_data(dataset, class, feature)

default_setup;

load([meta_dir, dataset]);
if strcmp(feature, 'sift')
    featfile = sprintf('%s/%s_%s_%d.mat', feat_dir, dataset, feature, sift_dict_size);
end
if strcmp(feature, 'gist')
    featfile = sprintf('%s/%s_%s.mat', feat_dir, dataset, feature);
end

load(featfile);
if(strcmp(dataset, 'PASCAL2007') || strcmp(dataset, 'PASCAL2012'))
    check_difficult = 1;
else
    check_difficult = 0;
end
noTrainObjects = find(arrayfun(@(x) ~isfield(x.annotation, 'object'), data.tr));
for i=1:length(noTrainObjects), data.tr(noTrainObjects(i)).annotation.object = []; end

noTestObjects = find(arrayfun(@(x) ~isfield(x.annotation, 'object'), data.te));
for i=1:length(noTestObjects), data.te(noTestObjects(i)).annotation.object = []; end

class = class_names.(class);

if(check_difficult)
    train_labels = arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(class, y.name)) && strcmp(y.difficult, '0'), x.annotation.object))>0, data.tr);
    test_labels = arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(class, y.name)) && strcmp(y.difficult, '0'), x.annotation.object))>0, data.te);
else
    train_labels = double(arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(class, y.name)), x.annotation.object))>0, data.tr));
    test_labels = double(arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(class, y.name)), x.annotation.object))>0, data.te));
end

% Transform the negative labels to be -1
train_labels = train_labels * 2 - 1;
test_labels = test_labels * 2 - 1;

train_feat = double(train_feat);
test_feat = double(test_feat);