function [train_feat, test_feat, train_labels, test_labels, train_bbox] = load_data(dataset, class, feature)

default_setup;

load([meta_dir, dataset]);
if strcmp(feature, 'sift')
    featfile = sprintf('%s/%s_%s_%d.mat', feat_dir, dataset, feature, sift_dict_size);
end
if strcmp(feature, 'gist')
    featfile = sprintf('%s/%s_%s.mat', feat_dir, dataset, feature);
end
if strcmp(feature, 'color')
    featfile = sprintf('%s/%s_%s_%d.mat', feat_dir, dataset, feature, color_dict_size);
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

if iscell(class)
    class_all = [];
    for i = 1: length(class)
        class_all = [class_all, class_names.(class{i})];
    end
    class = class_all;
else
    class = class_names.(class);
end

if(check_difficult)
    train_labels = arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(class, y.name)) && strcmp(y.difficult, '0'), x.annotation.object))>0, data.tr);
    test_labels = arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(class, y.name)) && strcmp(y.difficult, '0'), x.annotation.object))>0, data.te);
else
    train_labels = double(arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(class, y.name)), x.annotation.object))>0, data.tr));
    test_labels = double(arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(class, y.name)), x.annotation.object))>0, data.te));
end

for j = 1 : length(train_labels)
    curr_example = data.tr(j).annotation;
    for k = 1 : length(curr_example.object)
        if((isfield(curr_example.object(k), 'difficult') && curr_example.object(k).difficult=='1') || ...
            (isfield(curr_example.object(k), 'crop') && curr_example.object(k).crop=='1')), continue; end
        
    end
end


    
        if(train_labels{j}(k)==1)
          pos(pos_idx).im = fullfile(data{i}.hi, curr_example.folder, curr_example.filename);
          pos(pos_idx).x1 = double(min(curr_example.object(k).polygon.x));
          pos(pos_idx).x2 = double(max(curr_example.object(k).polygon.x));
          pos(pos_idx).y1 = double(min(curr_example.object(k).polygon.y));
          pos(pos_idx).y2 = double(max(curr_example.object(k).polygon.y));
          pos(pos_idx).bias = i;
          
          pos_idx = pos_idx + 1;
        end

% Transform the negative labels to be -1
train_labels = train_labels * 2 - 1;
test_labels = test_labels * 2 - 1;

train_feat = double(train_feat);
test_feat = double(test_feat);
% 
% if strcmp(dataset, 'Caltech256') == true
%     all_valid_class = {'car', 'person', 'dog', 'bird'};
%     all_valid_i = zeros(1, size(train_feat,1));
%     for i = 1 : length(all_valid_class)
%         valid_class = class_names.(all_valid_class{i});
%         this_train_labels = double(arrayfun(@(x) sum(arrayfun(@(y) ~cell_isempty(strfind(valid_class, y.name)), x.annotation.object))>0, data.tr));
%         all_valid_i = all_valid_i | this_train_labels;
%     end
%     neg_i = find(all_valid_i == 0);
%     % Only keep 5000 negative examples (so the AP does not look too
%     % shabby).
%     all_valid_i(neg_i(1:5000)) = 1;
%     train_feat = train_feat(all_valid_i,:);
%     train_labels = train_labels(all_valid_i);
% end