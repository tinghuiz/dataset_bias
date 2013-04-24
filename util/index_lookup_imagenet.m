function [batch_ind, feat_ind] = index_lookup_imagenet(indices, batch_size)

batch_ind = zeros(numel(indices),1);
feat_ind = zeros(numel(indices),1);
for i = 1 : numel(indices)
    idx = indices(i);
    batch_ind(i) = floor((idx-1)/batch_size) + 1;
    feat_ind(i) = mod(idx, batch_size);
    if feat_ind(i) == 0
        feat_ind(i) = batch_size;
    end
end
