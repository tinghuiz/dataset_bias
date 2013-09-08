exp_name = 'dataset_value';
dataset_list = {'Caltech101', 'SUN', 'LabelMeSpain', 'PASCAL2007', 'PASCAL2012', 'ILSVRC2012'};
class_list = {'person', 'bird', 'chair', 'car'};
feature_list = {'gist', 'sift'};
npos_list = [5, 10, 20, 40, 80, 160, 320, 640];
num_run = 3;

addpath(genpath('/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/util'));
default_setup;
root_lock_dir = ['/nfs/hn49/tinghuiz/ijcv_bias/sync_locks/' exp_name '/'];
res_dir = '/nfs/hn49/tinghuiz/ijcv_bias/dataset_bias/classification_experiments/dataset_value/main_results/';
%
% for f = 1 : length(feature_list)
% 	for c = 1 : length(class_list)
% 		fprintf('%%%% %s\n', class_list{c});
% 		for test_d = 1 : length(dataset_list)
% 			for train_d = 1 : length(dataset_list)
% 				self_fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{test_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
% 				if ~exist(self_fname, 'file')
% 					lock = sprintf('%s/lock_%s_%s_%s_%s_%s/', root_lock_dir, exp_name, dataset_list{test_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
% 					if exist(lock, 'dir')
% 						rmdir(lock);
% 					end
% 					continue;
% 				end
% 				self_result = load(self_fname);
% 				self_map = mean(self_result.ap');
% 				self_stdev = std(self_result.ap');
% 				other_fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
% 				if ~exist(other_fname, 'file')
% 					lock = sprintf('%s/lock_%s_%s_%s_%s_%s/', root_lock_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
% 					if exist(lock, 'dir')
% 						rmdir(lock);
% 					end
% 					continue;
% 				end
% 				other_result = load(other_fname);
% 				other_map = mean(other_result.ap');
% 				other_stdev = std(other_result.ap');
% 				pol = polyfit(other_map, npos_list(1:numel(other_map)), 1);
% 				if train_d == test_d
% 					fprintf('1 %s & ', dataset_list{train_d});
% 					continue;
% 				end
% 				worth = zeros(numel(self_map),1);
% 				for s = 1 : min([numel(self_map), numel(other_map)])
% 					num_other_pos = polyval(pol, self_map(s));
% 					worth(s) = npos_list(s)/num_other_pos;
% 				end
% 				fprintf('%.2f %s & ', mean(worth), dataset_list{test_d});
% 			end
% 			fprintf('\\\\\n')
% 		end
% 	end
% end

colors = cbrewer('qual', 'Set1', 8);
for f = 1 : 1
    for c = 4 : 4
        fprintf('%%%% %s\n', class_list{c});
        for test_d = 1 : length(dataset_list)
            self_fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{test_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
            if ~exist(self_fname, 'file')
                lock = sprintf('%s/lock_%s_%s_%s_%s_%s/', root_lock_dir, exp_name, dataset_list{test_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
                if exist(lock, 'dir')
                    rmdir(lock);
                end
                continue;
            end
            self_result = load(self_fname);
            self_map = mean(self_result.ap');
            self_stdev = std(self_result.ap')/4;
            figure(test_d), clf, hold on, grid on;
            for train_d = 1 : length(dataset_list)
                other_fname = sprintf('%s/%s_%s_%s_%s_%s.mat', res_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
                if ~exist(other_fname, 'file')
                    lock = sprintf('%s/lock_%s_%s_%s_%s_%s/', root_lock_dir, exp_name, dataset_list{train_d}, dataset_list{test_d}, feature_list{f}, class_list{c});
                    if exist(lock, 'dir')
                        rmdir(lock);
                    end
                    continue;
                end
                other_result = load(other_fname);
                other_map = mean(other_result.ap');
                other_stdev = std(other_result.ap');
                if train_d == test_d
                    h = errorbar(npos_list(1:numel(self_map)), self_map, self_stdev, '-', 'LineWidth', 4);
                else
                    h = errorbar(npos_list(1:numel(other_map)), other_map, 0*other_stdev, '-', 'LineWidth', 2);
                end
                set(h, 'Color', colors(train_d,:));
            end
            xlabel('Training examples', 'FontSize', 24);
            ylabel('AP', 'FontSize', 24);
            xlim([1, 645]);
            set(gca, 'FontSize', 21);
            hleg = legend(dataset_list);
            set(hleg, 'FontSize', 11);
        end
    end
end