param.thumbSize.x = 100;
param.thumbSize.y = 100;

param.numImage.x = 5;
param.numImage.y = 3;

param.imagePadding = 3;
param.goodbadPadding = 50;
param.bboxColor = [1 1 0];
param.bboxWidth = 2;
param.sampleFUnction = 'max';
param.sortOrder = 'descend';



imageSize.x = param.thumbSize.x * param.numImage.x + (param.imagePadding + 1) * param.numImage.x;
imageSize.y = (param.thumbSize.y * param.numImage.y + (param.imagePadding + 1) * param.numImage.y)*2 + param.goodbadPadding;

img = ones(imageSize.y, imageSize.x, 3);

%Output good image
goodColor = [0 0 1];
param.bgColor = goodColor;
goodSize.x = param.thumbSize.x * param.numImage.x + (param.imagePadding + 1) * param.numImage.x;
goodSize.y = param.thumbSize.y * param.numImage.y + (param.imagePadding + 1) * param.numImage.y;
param.dims = goodSize;

startGood.x = 1;
startGood.y = 1;
param.start = startGood;

img = createCollage(img, [], [], param);

%Output bad image
badColor = [1 0 0];
param.bgColor = badColor;
startBad.x = 1;
startBad.y = goodSize.y + param.goodbadPadding;
param.start = startBad;

img = createCollage(img, [], [] , param);

imshow(uint8(img*255));
