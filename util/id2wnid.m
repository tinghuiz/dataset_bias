function wnid = id2wnid(ids, synsets)

wnid = cell(1, numel(ids));
for i = 1 : numel(ids)
    wnid{i} = synsets(ids(i)).WNID;
end



