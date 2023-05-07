%% pre_proccessing

% Set paths
clear; close; clc;
% for windows 
% path_ = 'F:\Rodent PWM\Matlab Code\data_set';
% for my mac
path_ = '/Users/behnaz/Documents/cognitive science/Rodent PWM/Matlab Code/data_set';


all_data = [];
% Get a list of all files and folders in the directory
dir_contents = dir(path_);

% Loop through the contents of the directory
for i = 1 : length(dir_contents)
    item = dir_contents(i);

    % If the item is a folder, load its contents
    if ~strcmp(item.name, '.') && ~strcmp(item.name, '..') && ~strcmp(item.name, '.DS_Store')
        var_= split(item.name,'_'); var_ = var_{5};

        stage_id= str2num(var_);
        subfolder_path = fullfile(path_, item.name);
        subfolder_contents = dir(subfolder_path);
        for si = 1 : length(subfolder_contents)
            item_subdir = subfolder_contents(si);
            rat_id = str2num(item_subdir.name(3:end))+50;
            if ~strcmp(item_subdir.name, '.') && ~strcmp(item_subdir.name, '..') && ~strcmp(item_subdir.name, '.DS_Store')

                subfile_path = fullfile(subfolder_path, item_subdir.name);
                subfile_contents = dir(subfile_path);
                for wi = 1 : length(subfile_contents)
                    item_file = subfile_contents(wi);
                    
                    if ~strcmp(item_file.name, '.') && ~strcmp(item_file.name, '..') && ~strcmp(item_file.name, '...')
                        load(fullfile(subfile_path, item_file.name));     % load file
                        var_= split(item_file.name,'_'); 
                        session_id = str2num(var_{3}(4:end));             % Extract session number
                        var_h = []; 
                        resp=[]; choice=[];hit=[];
 
                        resp = [tempo_mat.answer1];
                        choice = [tempo_mat.choice];
                        hit = [tempo_mat.hit];
                        
                        trial_num = size(resp,1)*size(resp,2);%settings.trial_num;                   % Extract trial number 
                        id_trials = ones(trial_num,1);                     % Create lenght index  
                        sa = nan * id_trials ; sb = nan * id_trials;      % Create lenght index  for S1 and S2 
                        delay = nan * id_trials ;
                        
                        % Fill S1 and S2 
                        if isfield(tempo_mat,'sound_db_s_a');  sa = tempo_mat.sound_db_s_a;   end
                        if isfield(tempo_mat,'sound_db_s_b');  sb = tempo_mat.sound_db_s_b;   end
                       
                        resp = [tempo_mat.answer1];
                        choice = [tempo_mat.choice];
                        hit = [tempo_mat.hit];
                        if isfield(tempo_mat, 'time_d2'); delay = [tempo_mat.time_d2] ; end
                        
                        var_h = [rat_id * id_trials ,session_id * id_trials , (1:trial_num)', ...
                            sa , sb , resp(:), choice(:), hit(:) , delay(:) ,stage_id * id_trials];  % Fill matrix of the session data
                        

                        all_data = [all_data ; var_h] ;                   % concatinate sessions' data
                        clear tempo_mat;
                        clear settings;
                    end
                end
            end
        end
    end
end

% save data
d = date;
% for windows
% save(['F:\Rodent PWM\Matlab Code\Analysis\data\data_',d,'.mat'],"all_data")
% for mac
save(['/Users/behnaz/Documents/cognitive science/Rodent PWM/Matlab Code/Analysis/data/data_',d,'.mat'],"all_data")


