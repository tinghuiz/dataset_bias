function createFilelist()
inputFolder = 'images';
%files = dir([inputFolder '/*.jpg']);
startidx = 201;
endidx = 2422;
filelist = arrayfun(@(x) [inputFolder '/' num2str(x) '.jpg'], startidx:endidx, 'UniformOutput', false);

save('filelist.mat', 'filelist');
