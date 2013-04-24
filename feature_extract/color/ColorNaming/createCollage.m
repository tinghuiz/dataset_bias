function [img] = createCollage(img, regions, regionScore, param)

dims = param.dims;
start = param.start;

bgColor = reshape(param.bgColor, [1 1 3]);
img(start.y:start.y + dims.y - 1, start.x:start.x + dims.x - 1, :) = repmat(bgColor, [dims.y dims.x]);

currX = start.x + param.imagePadding;
currY = start.y + param.imagePadding;

[sample_score, sample_idx] = eval([param.sampleFunction '(regionScore, [], 2)']);
[~, sort_idx] = sort(sample_score, param.sortOrder);

current_idx = 1;
numImage = param.numImage;
bboxColor = reshape(param.bboxColor, [1 1 3]);
thumbSize = param.thumbSize;
bboxWidth = param.bboxWidth;

for i=1:numImage.x
    currX = start.x + param.imagePadding;
    for j=1:numImage.y
        input_image = param.ids{sort_idx(current_idx)};
        I = imread(input_image);
        curr_region = regions(sample_idx(current_idx));
        wid = size(I, 2);
        hgt = size(I, 1);
        x = round(curr_region.x * wid) : round((curr_region.x + curr_region.wid)*wid);
        y = round(curr_region.y * hgt) : round((curr_region.y + curr_region.hgt)*hgt);
        I(y(1):y(1)+bboxWidth-1, x, :) = repmat(bboxColor, [bboxWidth length(x)]);
        I(y(end)-bboxWidth+1:y(end), x, :) = repmat(bboxColor, [bboxWidth length(x)]);
        I(y, x(1):x(1)+bboxWidth-1, :) = repmat(bboxColor, [length(y) bboxWidth]);
        I(y, x(end)-bboxWidth+1:x(end), :) = repmat(bboxColor, [length(y) bboxWidth]);
        I = imresize(I, [thumbSize.y thumbSize.x]);
        img(currY:currY+thumbSize.y-1, currX:currX+thumbSize.x-1, :) = I;
        
        current_idx = current_idx + 1;
        currY = currY + thumbSize.y + param.imagePadding;
        currX = currX + thumbSize.x + param.imagePadding;
    end
end