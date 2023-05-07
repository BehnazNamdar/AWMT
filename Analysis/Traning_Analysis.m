%% Analysis

%% clear workspace
clear ; clc; close ;

%% load 
[file, path_ ] = uigetfile;
load([path_ file]);

%% Define initials 

% edit missed trials from 0 to nan
all_data([all_data(:,10) == 1] & [all_data(:,6) == 0],6)  = nan ; 

global subj;
global stg;
selectlistbox;                          % Select subject and stage to plot its data 

ind_stg  = all_data(:,10)== stg;
ind_subj = all_data(:,1) == subj;
ses_num  = unique(all_data(ind_stg , 2));

ttl = struct();
smpl = struct();

switch stg

    case 1
        
% All the rats
var = all_data(ind_stg , :);
for ses = 1 : length(ses_num)   
    var_ses = var(var(:,2) == ses_num(ses) , :) ;   
    ttl(ses).session    = ses ; 
    ttl(ses).num_subj   = numel(unique(var_ses(:,1)));
    ttl(ses).num_trials = size(var_ses,1);
    ttl(ses).perf_tr    = sum(var_ses(:,7) == var_ses(:,6) ) / size(var_ses,1);
    ttl(ses).missed     = sum(isnan(var_ses(:,6))) / size(var_ses,1);
    ttl(ses).false_     = sum((var_ses(:,7) ~= var_ses(:,6)) & ~isnan(var_ses(:,6))) / size(var_ses,1);
    ttl(ses).perf_r     = sum(var_ses(:,8) == 1 & var_ses(:,7) == 1 ) / sum(var_ses(:,7) == 1 & ~isnan(var_ses(:,6)));
    ttl(ses).perf_l     = sum(var_ses(:,8) == 1 & var_ses(:,7) == -1 ) / sum(var_ses(:,7) == -1 & ~isnan(var_ses(:,6)));
end


% Sample rat

    var = all_data(ind_subj & ind_stg , :);
    for ses = 1 : length(ses_num)    
        var_ses = var(var(:,2) == ses_num(ses) , :) ; 
        smpl(ses).session    = ses ; 
        smpl(ses).num_trials = size(var_ses,1);
        smpl(ses).perf_tr    = sum(var_ses(:,7) == var_ses(:,6) ) / size(var_ses,1);
        smpl(ses).missed     = sum(isnan(var_ses(:,6))) / size(var_ses,1);
        smpl(ses).false_     = sum((var_ses(:,7) ~= var_ses(:,6)) & ~isnan(var_ses(:,6))) / size(var_ses,1);
        smpl(ses).perf_r     = sum(var_ses(:,8) == 1 & var_ses(:,7) == 1 ) / sum(var_ses(:,7) == 1 & ~isnan(var_ses(:,6))) ;
        smpl(ses).perf_l     = sum(var_ses(:,8) == 1 & var_ses(:,7) == -1) / sum(var_ses(:,7) == -1 & ~isnan(var_ses(:,6)));
    end        
    case 2 

% error_typ = answer1: 
%           nan : nothing, skip it
%           -1  : poked left side
%           1   : poked right side
%           3   : break during fixation 
%           5   : missed reward 
%           4   : missed fixation 
%           0   : ???
        
% All the rats
var = all_data(ind_stg , :);
for ses = 1 : length(ses_num)   
    var_ses = var(var(:,2) == ses_num(ses) , :) ;   
    ttl(ses).session    = ses ; 
    ttl(ses).num_subj   = numel(unique(var_ses(:,1)));
    ttl(ses).num_trials = size(var_ses,1);
    ttl(ses).missed_fix = sum(var_ses(:,6) == 4) / size(var_ses,1);
    ttl(ses).brk_fix    = sum(var_ses(:,6) == 3) / (size(var_ses,1) - sum(var_ses(:,6) == 4));    
    ttl(ses).missed_rwd = sum(var_ses(:,6) == 5) / (size(var_ses,1) - sum(var_ses(:,6) == 4)- sum(var_ses(:,6) == 3));
    ttl(ses).tru        = sum(var_ses(:,8) == 1) / size(var_ses,1);
    ttl(ses).tru_r      = sum(var_ses(:,6) == 1) / sum(var_ses(:,8) == 1);
    ttl(ses).tru_l      = sum(var_ses(:,6) == -1)/ sum(var_ses(:,8) == 1);
end  
        
% sample rat 

var = all_data(ind_subj & ind_stg , :);
for ses = 1 : length(ses_num)   
    var_ses = var(var(:,2) == ses_num(ses) , :) ;   
    smpl(ses).session    = ses ; 
    smpl(ses).num_trials = size(var_ses,1);
    smpl(ses).missed_fix = sum(var_ses(:,6) == 4) / size(var_ses,1);
    smpl(ses).brk_fix    = sum(var_ses(:,6) == 3) / (size(var_ses,1) - sum(var_ses(:,6) == 4));    
    smpl(ses).missed_rwd = sum(var_ses(:,6) == 5) / (size(var_ses,1) - sum(var_ses(:,6) == 4)- sum(var_ses(:,6) == 3));
    smpl(ses).tru        = sum(var_ses(:,8) == 1) / size(var_ses,1);
    smpl(ses).tru_r      = sum(var_ses(:,6) == 1) / sum(var_ses(:,8) == 1);
    smpl(ses).tru_l      = sum(var_ses(:,6) == -1)/ sum(var_ses(:,8) == 1);
end 

%% stage 3 
    case 3 
% All the rats
var = all_data(ind_stg , :);        
for ses = 1 : length(ses_num)   
    var_ses = var(var(:,2) == ses_num(ses) , :) ;   
    ttl(ses).session    = ses ; 
    ttl(ses).num_subj   = numel(unique(var_ses(:,1)));
    ttl(ses).num_trials = size(var_ses,1);
    ttl(ses).missed_fix = sum(var_ses(:,6) == 4) / size(var_ses,1);
    ttl(ses).brk_fix    = sum(var_ses(:,6) == 3) / (size(var_ses,1) - sum(var_ses(:,6) == 4));    
    ttl(ses).missed_rwd = sum(var_ses(:,6) == 5) / (size(var_ses,1) - sum(var_ses(:,6) == 4)- sum(var_ses(:,6) == 3));
    ttl(ses).tru        = sum(var_ses(:,8) == 1) / size(var_ses,1);
    ttl(ses).tru_r      = sum(var_ses(:,6) == 1) / sum(var_ses(:,8) == 1);
    ttl(ses).tru_l      = sum(var_ses(:,6) == -1)/ sum(var_ses(:,8) == 1);
end  
        
% sample rat 
var = all_data(ind_subj & ind_stg , :);
for ses = 1 : length(ses_num)   
    var_ses = var(var(:,2) == ses_num(ses) , :) ;   
    smpl(ses).session    = ses ; 
    smpl(ses).num_trials = size(var_ses,1);
    smpl(ses).missed_fix = sum(var_ses(:,6) == 4) / size(var_ses,1);
    smpl(ses).brk_fix    = sum(var_ses(:,6) == 3) / (size(var_ses,1) - sum(var_ses(:,6) == 4));    
    smpl(ses).missed_rwd = sum(var_ses(:,6) == 5) / (size(var_ses,1) - sum(var_ses(:,6) == 4)- sum(var_ses(:,6) == 3));
    smpl(ses).tru        = sum(var_ses(:,8) == 1) / size(var_ses,1);
    smpl(ses).tru_r      = sum(var_ses(:,6) == 1) / sum(var_ses(:,8) == 1);
    smpl(ses).tru_l      = sum(var_ses(:,6) == -1)/ sum(var_ses(:,8) == 1);
end 


% All the rats- delay time 
tdly = struct();
var = all_data(ind_stg , :);        
for ii = 1 : length(var)
  tdly(ii).session = var(ii,2); 
  tdly(ii).trial   = var(ii,3);
  tdly(ii).deley   = var(ii,9);      
end 

% sample rat- delay time
dly = struct();
var = all_data(ind_subj & ind_stg , :);
for ii = 1 : length(var)
  dly(ii).session  = var(ii,2); 
  dly(ii).trial    = var(ii,3);
  dly(ii).deley    = var(ii,9);      
end 

end

%% Plot 

switch stg 
    case 1 
     % all rats
    plot([ttl.session],[ttl.perf_tr],...
         [ttl.session],[ttl.false_] ,...
         [ttl.session],[ttl.missed]);

    plot([ttl.session],[ttl.perf_tr],...
         [ttl.session],[ttl.perf_r] ,...
         [ttl.session],[ttl.perf_l]);
     % sample rat 
    plot([smpl.session],[smpl.perf_tr],...
         [smpl.session],[smpl.false_] ,...
         [smpl.session],[smpl.missed]);

    plot([smpl.session],[smpl.perf_tr],...
         [smpl.session],[smpl.perf_r] ,...
         [smpl.session],[smpl.perf_l]);
    
    case 2
     % all rats
    bar([ttl.session],[ttl.missed_fix],...
        [ttl.session],[ttl.brk_fix] ,...
        [ttl.session],[ttl.missed_rwd]); 
    bar([ttl.session],[ttl.missed_fix],'stacked');
     
     
     
     % sample rat  
     
     
     
     
    case 3 
        
        
        
     
end







%% stage 1
pref=[];
for id =54:60
ind_h=(all_data(:,1)==id&all_data(:,10)==2);
var_h= all_data(ind_h,:);
id=id-53;
pref(id)= sum(var_h(:,6)==var_h(:,7))/size(var_h,1);
end


