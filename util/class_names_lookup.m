meta_dir = '/nfs/hn49/tinghuiz/ijcv_bias/datasetStore/';

%% LabelMeSpain
clear class_names
class_names.car = {'car'};
class_names.chair = {'chair'};
class_names.person = {'person'};
class_names.dog = {'dog'};
class_names.bird = {'bird'};
save([meta_dir, 'LabelMeSpain.mat'], 'class_names', '-append');

%% SUN
clear class_names
class_names.car = {'car'};
class_names.chair = {'chair'};
class_names.person = {'person'};
class_names.dog = {'dog'};
class_names.bird = {'bird'};
save([meta_dir, 'SUN.mat'], 'class_names', '-append');

%% Caltech101
clear class_names
class_names.car = {'car_side'};
class_names.chair = {'chair'};
class_names.person = {'faces_2', 'faces_3'};
class_names.bird = {'bird', 'ibis'};
class_names.dog = {'dalmatian'};
save([meta_dir, 'Caltech101.mat'], 'class_names', '-append');

%% Caltech256
clear class_names
class_names.car = {'car-side-101'};
class_names.chair = {''};
class_names.person = {'people'};
class_names.bird = {'cormorant', 'goose', 'hummingbird', 'ibis', 'ostrich', 'swan', 'duck', 'owl'};
class_names.dog = {'dog'};
save([meta_dir, 'Caltech256.mat'], 'class_names', '-append');

%% PASCAL2007
clear class_names
class_names.car = {'pascal_car'};
class_names.chair = {'pascal_chair'};
class_names.person = {'pascal_person'};
class_names.dog = {'pascal_dog'};
class_names.bird = {'pascal_bird'};
save([meta_dir, 'PASCAL2007.mat'], 'class_names', '-append');

%% PASCAL2012
clear class_names
class_names.car = {'pascal_car'};
class_names.chair = {'pascal_chair'};
class_names.person = {'pascal_person'};
class_names.dog = {'pascal_dog'};
class_names.bird = {'pascal_bird'};
save([meta_dir, 'PASCAL2012.mat'], 'class_names', '-append');
