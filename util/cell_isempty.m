function flag = cell_isempty(input)

flag = true;
for i = 1 : length(input)
    if ~isempty(input{i})
        flag = false;
        break;
    end
end