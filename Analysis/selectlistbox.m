function selectlistbox

global subj;                                      % define global variables
global stg;
subj = '-';

fig = uifigure('Position',[100 600 200 300]);     % Create parent figure

txt_subj = uitextarea(fig,...                          % Create text area
    'Position',[20 90 70 22],...
    'Value','-');
txt_stg = uitextarea(fig,...                          % Create text area
    'Position',[110 90 70 22],...
    'Value','-');

lbox_subj = uilistbox(fig,...                          % Create list box
    'Position',[20 120 70 150],...
    'Items',{'W004','W005','W006','W007','W008','W009','W010'},... 
    'ValueChangedFcn', @selected_rat); 

lbox_stg = uilistbox(fig,...                          % Create list box
    'Position',[110 120 70 150],...
    'Items',{'Stage 1','Stage 2','Stage 3','Stage 4','Stage 5','Stage 6'},... 
    'ValueChangedFcn', @selected_stage); 

function selected_rat(src,event)                  % ValueChangedFcn callback
    txt_subj.Value = src.Value;
    subj = src.Value;
    subj = str2num(subj(3:end))+50;                             % Fill global variable
end

function selected_stage(src,event)                  % ValueChangedFcn callback
    txt_stg.Value = src.Value;
    stg = src.Value;
    stg = str2num(stg(end));                             % Fill global variable
end

end



