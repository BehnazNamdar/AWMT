%% بسم الله الرحمن الرحیم

%% Set paths
clear; close; clc;
path = cd;
addpath(genpath([path '\General']));
addpath(genpath(path));

%% Arduino configuration
try
    if ~exist ('a')
        clear a
        a=arduino_config();                                                                                                    
    end
catch
    clear a
    a=arduino_config();
end

%% Defining hot keys
% Escape end experiment
% SPace Pause experiment
% p (q) deliver manual rewards right(left)
% l (a) turn on LED  right(left)
% k (s) turn off LED  right(left)
% v (b) turn on(off) LED center poke
% g play go cue

KbName('UnifyKeyNames');
KbDeviceIndex = [];
escape_key = KbName('ESCAPE');

r_reward_key = KbName('p') ; l_reward_key = KbName('q');
r_led_on_key = KbName('l');  l_led_on_key = KbName('a');
r_led_off_key = KbName('k'); l_led_off_key = KbName('s');

c_led_on_key = KbName('v');  c_led_off_key = KbName('b');
play_go_cue_key = KbName('g');
reset_key = KbName('n');

RestrictKeysForKbCheck([ escape_key, r_reward_key ,...
    l_reward_key , r_led_on_key , r_led_off_key , l_led_on_key ,...
    l_led_off_key , c_led_on_key , c_led_off_key , play_go_cue_key , reset_key ] );

%% Load summary file and subject's parameters

uiopen(strcat(path,'\PWM_Summary','\*.mat'));  % open summary file of the rat
C = who('-regexp' , '_Summary$'); c = C{1};
data = evalin('base',c);
settings.name_subject = getfield(data,'Rat_name');
settings.exp_name = getfield(data,'Experimenter_Name');

%% Settings: Setup Modules
% - basic configs of experiment that may change in every session and across rats
% dialogue input box to get session info
prompt = {'Training Stage:',...
    'Number of blocks in the session :',...
    'The rodent''weight: ',...
    'Left Water Pump Volume:' ,...
    'Right Water Pump Volume:' ,...
    'Drink Time:',...
    'ITI :'};
dlgtitle = 'Session Info';

definput = {'3','15','200','0.15','0.15','3','1'};  % Default values for intial form
opts = 'on';
dims= [1 50];
dlb_answer = inputdlg(prompt,dlgtitle,dims,definput);
settings.Training_Stage = str2double(dlb_answer{1});
data.Current_Stage = str2double(dlb_answer{1});
blocks = str2double(dlb_answer{2});
settings.weight = str2double(dlb_answer{3});
settings.water_vol_l = str2double(dlb_answer{4}) ;
settings.water_vol_r = str2double(dlb_answer{5}) ;
settings.drink_time = str2double(dlb_answer{6}); % sec
settings.iti = str2double(dlb_answer{7}); % sec
settings.session_num = getfield(data, ['Training_Stage',num2str(settings.Training_Stage)],num2str('Next_Session'));

% Main settings - this is set by experimenter according to the protocol
settings.script_edition = 3;
settings.date_time = datetime('now','TimeZone','local','Format','_d_MMM_y_HH_mm');
% settings.num_of_trials_in_block = 10;
settings.time_go_cue = 0.2;  % sec
settings.del_initiation = 0.01;  % sec
settings.time_d1 = 0.25;  % sec
settings.time_d3 = 0.25;  % sec
settings.delayed_reward_time = 1;  % sec
settings.wait_time_for_cpoke = 10; %sec
settings.wait_time_for_spoke = 10; %sec
settings.wait_time_for_2nd_spoke = 10; %sec
settings.wait_time_cpoke_out = 2; % sec
settings.error_iti = 2; % sec

%%%%%%%%%%  Edit after calibration process
% settings.Sound_db = {[60,68];...
%     [68,60];...
%     [68,76];...
%     [76,68];...
%     [76,84];...
%     [84,76];...
%     [84,92];...
%     [92,84]};  % [S_a,S-b]

settings.Sound_db = {[40,100];...
    [100,40];...
    [40,100];...
    [100,40];...
    [120,40];...
    [120,40];...
    [40,150];...
    [150,40]};
%%%%%%%%%%%%%%%%%%
settings.num_of_trials_in_block =size(settings.Sound_db,1);
settings.sound = load(strcat(path, '\General','\sound_param.mat'));
settings.states = {'state0' , 'start next trial';...
    'state1' ,'Center Led On';...
    'state2' , 'Delay1' ; ...
    'state3' , 'Stimulus1';...
    'state4' , 'Delay2';...
    'state5' , 'Stimulus2';...
    'state6' , 'Delay3';...
    'state7' , 'Go Cue';...
    'state8' , 'get ready to collect reward';...
    'state9' , 'Reading Spoke to collect reward';...
    'state10' , 'Reward';...
    'state11' , 'Wait to spokes out';...
    'state12' , 'ITI'};


%% plot weight
% date_ = datetime(W001_Summary.weight(:,2),'InputFormat','_d_MMM_y_HH_mm');
% weight = str2double(W001_Summary.weight(:,1));
% figure(1)
% plot(date_,weight, 'b--o')
% title(strcat(settings.name_subject,' weight figure'));
%
% KbWait(-1);
% close


%% Experimental setup modules

% Next version: not required by user; program will calculate it.
settings.blocks = blocks;
settings.trial_num = settings.num_of_trials_in_block * ...
    settings.blocks;

% "side led on" table for Stage 1
if settings.Training_Stage ==1
    [side_led , choice] = side_led_table(...
        settings.blocks,...
        settings.num_of_trials_in_block);
end

pre_tri_resp = -1;
% function for d2 duration
if settings.Training_Stage > 1
    time_d2 = delay2_duration(...
        settings.Training_Stage,...
        settings.del_initiation,...
        settings.blocks,...
        data.Training_Stage3.Last_Keep_C_Poke_Duration,...
        settings.num_of_trials_in_block,...
        pre_tri_resp);
end

%  S_a , S_b db pairs function
if settings.Training_Stage > 3
    [sound_db_s_a,sound_db_s_b,choice] = sound_db_table(...
        settings.Sound_db,...
        settings.blocks,...
        settings.num_of_trials_in_block);
end

% path for save dataset
path_save_data = strcat('\data_set\data_set_training_stage_',...
    num2str(settings.Training_Stage),...
    '\',settings.name_subject,'\');



%% Main task

% Main task - Initiation
escap_order = 0;
sl_poke_state = 0;
sr_poke_state = 0;
c_poke_state = 0;

session_start = tic;
%% For on Blocks
for nblk = 1 : settings.blocks  % defining blocks for plot online plots

    tempo_mat(nblk).block_num = nblk ;
    tempo_mat(nblk).rt      = nan(1,settings.num_of_trials_in_block);
    tempo_mat(nblk).answer1 = nan(1,settings.num_of_trials_in_block);
    tempo_mat(nblk).hit     = nan(1,settings.num_of_trials_in_block);
    tempo_mat(nblk).fixation_time = nan(1,settings.num_of_trials_in_block);
    tempo_mat(nblk).s1_time = nan(1,settings.num_of_trials_in_block);
    tempo_mat(nblk).trial_end_time = nan(1,settings.num_of_trials_in_block);
    tempo_mat(nblk).s2_time = nan(1,settings.num_of_trials_in_block);
    tempo_mat(nblk).go_cue_time = nan(1,settings.num_of_trials_in_block);
    tempo_mat(nblk).cpoke_out_time = nan(1,settings.num_of_trials_in_block);
    tempo_mat(nblk).side_poke_time = nan(1,settings.num_of_trials_in_block);

    switch settings.Training_Stage
        case 1
            tempo_mat(nblk).choice = choice(nblk,:);
            tempo_mat(nblk).side_led = side_led(nblk,:);

        case 2
            tempo_mat(nblk).choice = nan(1,settings.num_of_trials_in_block);
            tempo_mat(nblk).time_d2 = time_d2(nblk,:);


        case 3
            tempo_mat(nblk).choice = nan(1,settings.num_of_trials_in_block);
            tempo_mat(nblk).time_d2 = time_d2(nblk,:);

        case 4
            tempo_mat(nblk).choice = choice(nblk,:);
            tempo_mat(nblk).time_d2 = time_d2(nblk,:);
            tempo_mat(nblk).sound_db_s_a =  sound_db_s_a(nblk,:);
            tempo_mat(nblk).sound_db_s_b =  sound_db_s_b(nblk,:);
            tempo_mat(nblk).answer2 = nan(1,settings.num_of_trials_in_block);

        case 5
            tempo_mat(nblk).choice = choice(nblk,:);
            tempo_mat(nblk).time_d2 = time_d2(nblk,:);
            tempo_mat(nblk).sound_db_s_a =  sound_db_s_a(nblk,:);
            tempo_mat(nblk).sound_db_s_b =  sound_db_s_b(nblk,:);
            tempo_mat(nblk).answer2 = nan(1,settings.num_of_trials_in_block);

        case 6
            tempo_mat(nblk).choice = choice(nblk,:);
            tempo_mat(nblk).time_d2 = time_d2(nblk,:);
            tempo_mat(nblk).sound_db_s_a =  sound_db_s_a(nblk,:);
            tempo_mat(nblk).sound_db_s_b =  sound_db_s_b(nblk,:);
    end

    %% Loop on Trials
    for trii = 1 : settings.num_of_trials_in_block

        if  escap_order
            break;
        end

        %         sprintf('start trial: block number: %d , trial number: %d',nblk,trii)
        %% State 0
        % ------------------------------------------------------------
        %             state 0 : "start next trial"
        % ------------------------------------------------------------

        % getting ready for next trial
        state = 0; trial_end = 1; d2_change = 1;FlushEvents();
        tempo_mat(nblk).trial_start_time(trii) = toc(session_start);

        trial_start = tic;
        while trial_end
           
            c_poke_state = read_cpoke(a);
            WaitSecs(0.1);
            [sl_poke_state,sr_poke_state] = read_spoke(a);

                % ------------------------------------------------------------
                %             Stage 1: preliminalty stage 
                % ------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if (settings.Training_Stage == 1 && state == 0)
                tempo_mat(nblk).num_tr(trii) = trii;

                led_drive(a ,num2str(tempo_mat(nblk).side_led(trii) ) , 1)                
                state = 9;
                t_elapsed = toc(trial_start);
                tempo_mat(nblk).fixation_time(trii) = t_elapsed;

            elseif (settings.Training_Stage == 1 && state == 9 )...
                    && (sum([sl_poke_state,sr_poke_state]) == 1 ...
                    && toc(trial_start)- t_elapsed <=  settings.wait_time_for_spoke)

                led_drive(a ,num2str(tempo_mat(nblk).side_led(trii) ) , 0)
                tempo_mat(nblk).rt(trii) = toc(trial_start) - t_elapsed ;
                tempo_mat(nblk).side_poke_time(trii) = toc(trial_start);

                if sl_poke_state == 1
                    tempo_mat(nblk).answer1(trii) = -1; %left

                    if tempo_mat(nblk).answer1(trii) == tempo_mat(nblk).choice(trii)
                        tempo_mat(nblk).hit(trii) = 1; % true response
                        water_vol = settings.water_vol_l;
                    else
                        tempo_mat(nblk).hit(trii) = 0; % false response
                    end

                elseif sr_poke_state == 1
                    tempo_mat(nblk).answer1(trii) = 1; %right

                    if tempo_mat(nblk).answer1(trii) == tempo_mat(nblk).choice(trii)
                        tempo_mat(nblk).hit(trii) = 1; % true response
                        water_vol = settings.water_vol_r;
                    else
                        tempo_mat(nblk).hit(trii) = 0; % false response
                    end
                end

                t_elapsed = toc(trial_start);
                state = 10;


            elseif (settings.Training_Stage == 1 && state == 9) ...
                    && (sum([sl_poke_state,sr_poke_state]) == 0 ...
                    && toc(trial_start)- t_elapsed >  settings.wait_time_for_spoke)

                led_drive(a ,num2str(tempo_mat(nblk).side_led(trii) ) , 0)
                t_elapsed = toc(trial_start);
                state = 12;

%   End of stage 1 codes 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                % ------------------------------------------------------------
                %             Stage : Main task from stage 2 up 6 
                % ------------------------------------------------------------
  %% State 1

                % ------------------------------------------------------------
                %             state 1 : "Center poke"
                % ------------------------------------------------------------

            elseif (settings.Training_Stage > 1 && state == 0)             % State 0 to state 1  "Center Led On"

                tempo_mat(nblk).num_tr(trii) = trii;               
            
                led_drive(a, 'c' , 1);                                     % turn on one C_led
                state = 1;
                t_elapsed = toc(trial_start);
                tempo_mat(nblk).fixation_time(trii) = t_elapsed;
              
                % ------------------------------------------------------------
                %             state 1 : "Hold Center poke"
                % ------------------------------------------------------------

            elseif (settings.Training_Stage == 2 && state == 1) ...        % Stage 2          
                    && (c_poke_state == 1 ...
                    && ((toc(trial_start)- t_elapsed) <= settings.wait_time_for_cpoke)) 
                    

                led_drive(a, 'c' , 0);
                state = 7;
                t_elapsed = toc(trial_start);
                tempo_mat(nblk).fixation_poke(trii) = t_elapsed;

            elseif (settings.Training_Stage == 3 && state == 1) ...        % Stage 3                     
                    && (c_poke_state == 1 ...
                    &&((toc(trial_start)- t_elapsed) <= settings.wait_time_for_cpoke)) 
                  
                t_elapsed = toc(trial_start);
                led_drive(a, 'c' , 0);
                state = 4;

            elseif (settings.Training_Stage > 3 && state == 1) ...         % Stages 4 5 6                            
                      && (c_poke_state == 1 ...
                      && ((toc(trial_start)- t_elapsed) <= settings.wait_time_for_cpoke))
                  
                led_drive(a, 'c' , 0);
                state = 2;             

                % ------------------------------------------------------------
                %             state 2 : "wait time before S1"
                % ------------------------------------------------------------
        
            elseif (state == 2) ...                                       % Delay before S1 for Stages 4 5 6   
                    && (c_poke_state == 1 ...
                    && ((toc(trial_start) - t_elapsed) >= settings.time_d1)) ...                                        % State 2
                                        

                t_elapsed = toc(trial_start);
                state = 3;                      

           elseif (state > 1 && state < 8) ...                             % Break poke during delay state 2 to state 8
                    && c_poke_state == 0

                state = 12 ;
                t_elapsed= toc(trial_start);
                tempo_mat(nblk).answer1(trii) = 3;                         % play error  sound
                [w , sample_rate] = sound_interface('Tone', settings.sound.sound_param , 'violation_sound' );
                sound(w,sample_rate);  

                % ------------------------------------------------------------
                %             state 3 : present"S1"
                % ------------------------------------------------------------

            elseif (state == 3 && c_poke_state == 1)                       % S1 presentation
                
                state = 3.5;
                t_elapsed= toc(trial_start);
                tempo_mat(nblk).s1_time(trii) = t_elapsed;

                settings.sound.sound_param.S_one_sound.Vol = tempo_mat(nblk).sound_db_s_a (trii)/10000;
                [w , sample_rate] = sound_interface('WhiteNoise', settings.sound.sound_param , 'S_one_sound');
                sound(w,sample_rate);                                      % play sound one
                
            elseif (state == 3.5 && c_poke_state == 1)...                  % end S1 presentation 
                    && ((toc(trial_start)-t_elapsed) <= settings.sound.sound_param.S_one_sound.Dur1)
                
                state = 4;
                t_elapsed= toc(trial_start);
            
                % ------------------------------------------------------------
                %             state 4 : "Delay of task"
                % ------------------------------------------------------------              

            elseif (settings.Training_Stage == 3 && state == 4)&&(d2_change)         % Increase Delay in stage 3                                  % Delay between S1 and S2
                   d2_change =0;
                if nblk > 1
                    if trii == 1
                        if tempo_mat(nblk-1).hit(end)== 1
                            tempo_mat(nblk).time_d2(trii) = tempo_mat(nblk-1).time_d2(end) + ...
                                settings.del_initiation +  abs(normrnd(0.01 , 0.01));
                        else
                            tempo_mat(nblk).time_d2(trii) = tempo_mat(nblk-1).time_d2(end);
                        end
                    else
                        if tempo_mat(nblk).hit(trii-1)== 1
                            tempo_mat(nblk).time_d2(trii) = tempo_mat(nblk).time_d2(trii-1) + ...
                                settings.del_initiation + abs(normrnd(0.01 , 0.01));

                        else
                            tempo_mat(nblk).time_d2(trii) = tempo_mat(nblk).time_d2(trii-1);
                        end
                    end
                    end


            elseif (settings.Training_Stage == 3 && state == 4) ...        % Delay in stage 3                 
                    && (c_poke_state == 1 ...
                    && (toc(trial_start)- t_elapsed >=  tempo_mat(nblk).time_d2(trii)))

                t_elapsed= toc(trial_start);
                state = 7;

            elseif ( settings.Training_Stage > 3 && state == 4) ...        % Delay in stage 4 5 6        
                    && (c_poke_state == 1 ...
                    && (toc(trial_start)-t_elapsed >=  tempo_mat(nblk).time_d2(trii)))

                t_elapsed= toc(trial_start);
                state = 5;

                % ------------------------------------------------------------
                %             state 5 : "Stimulus2"
                % ------------------------------------------------------------
                
            elseif (state == 5 && c_poke_state == 1)                       % State 5: S2 presentation

                t_elapsed = toc(trial_start);
                tempo_mat(nblk).s2_time(trii) = t_elapsed;
                state = 5.5;

                settings.sound.sound_param.S_two_sound.Vol = tempo_mat(nblk).sound_db_s_b (trii)/10000;              
                [w , sample_rate] = sound_interface('WhiteNoise', settings.sound.sound_param , 'S_two_sound'  );
                sound(w,sample_rate);                                      % play sound Two

            elseif (state == 5.5  && c_poke_state == 1) ...                % end S1 presentation 
                     && (toc(trial_start)-t_elapsed) >=  settings.sound.sound_param.S_two_sound.Dur1

                t_elapsed = toc(trial_start);
                state = 6;

                % ------------------------------------------------------------
                %             state 6 : "wait time after S2"
                % ------------------------------------------------------------
        
            elseif (state == 6 && c_poke_state == 1) ...                   % State 6
                    && (toc(trial_start)-t_elapsed) >=  settings.time_d3

                t_elapsed= toc(trial_start);
                state = 7;              

                % ------------------------------------------------------------
                %             state 7 : "Go Cue"
                % ------------------------------------------------------------

            elseif (state == 7 && c_poke_state == 1)...                    % State 7                    
                    && (toc(trial_start)- t_elapsed) >=  settings.sound.sound_param.go_sound.Dur1

                t_elapsed= toc(trial_start);
                tempo_mat(nblk).go_cue_time(trii) = t_elapsed;        
                state = 8;

                [w , sample_rate] = sound_interface('Tone', settings.sound.sound_param , 'go_sound'  );
                sound(w,sample_rate);                                      % play go cue sound
    
               
                % ------------------------------------------------------------
                % state 8:"get ready to collect reward "
                % ------------------------------------------------------------
              
            elseif (state == 8 && c_poke_state == 0 ) ...                  % State 8:  get ready to collect reward
                    && ((toc(trial_start) - t_elapsed) <= settings.wait_time_cpoke_out)
               
                state = 9;
                tempo_mat(nblk).cpoke_out_time(trii) = toc(trial_start);

                % ------------------------------------------------------------
                %         state 9 : "Reading side pokes to collect reward"
                % ------------------------------------------------------------
            
            elseif ( settings.Training_Stage > 1 && state == 9 ) ...         % State 9
                    && (sum([sl_poke_state,sr_poke_state]) == 1 ...
                    && ((toc(trial_start)- t_elapsed) <=  settings.wait_time_for_spoke)) 

                tempo_mat(nblk).rt(trii) =  toc(trial_start) - t_elapsed ;
                tempo_mat(nblk).side_poke_time(trii) =  toc(trial_start);

                if sl_poke_state == 1
                    tempo_mat(nblk).answer1(trii) = -1; %left

                    %filling up choice array for stages 2 and 3
                    if settings.Training_Stage == 2 || settings.Training_Stage == 3
                        tempo_mat(nblk).choice(trii) = tempo_mat(nblk).answer1(trii);
                    end

                    if tempo_mat(nblk).answer1(trii) == tempo_mat(nblk).choice(trii)
                        tempo_mat(nblk).hit(trii) = 1; % true response
                        water_vol = settings.water_vol_l;
                    else
                        tempo_mat(nblk).hit(trii) = 0; % false response

                    end
                elseif sr_poke_state == 1
                    tempo_mat(nblk).answer1(trii) = 1; %right

                    %filling up choice array for stages 2 and 3
                    if settings.Training_Stage == 2 || settings.Training_Stage == 3
                        tempo_mat(nblk).choice(trii) = tempo_mat(nblk).answer1(trii);
                    end

                    if tempo_mat(nblk).answer1(trii) == tempo_mat(nblk).choice(trii)
                        tempo_mat(nblk).hit(trii) = 1; % true response
                        water_vol = settings.water_vol_r;
                    else
                        tempo_mat(nblk).hit(trii) = 0; % false response
                    end
                end

                t_elapsed= toc(trial_start);
                state = 10;

                % ------------------------------------------------------------
                %         state 10 : "Reward"
                % ------------------------------------------------------------
 
            elseif state == 10 && tempo_mat(nblk).hit(trii) == 1           % State 10: correct choice 
                
                t_elapsed = toc(trial_start);
                state = 11;

                beep = MakeBeep(500,0.2,48000);
                sound(beep*0.1,48000);                                         % Play reward Beep
                water_drive(a ,num2str(tempo_mat(nblk).choice(trii)) ,water_vol);
                WaitSecs(settings.drink_time(end));
                         
            elseif state == 10 &&  tempo_mat(nblk).hit(trii) == 0          % State 10: For error trial 
                   
                switch settings.Training_Stage
                    case 1                                                 % stage 1 NoReward 
                        state = 12 ;
                    case 4                                                 % stage 4 ImmediateReward
                        if ((toc(trial_start)- t_elapsed) <=  settings.wait_time_for_2nd_spoke ...
                                &&(toc(trial_start)- t_elapsed) >=  settings.wait_time_cpoke_out) ...
                                && (sum([sl_poke_state,sr_poke_state]) == 1)
                            tempo_mat(nblk).rt(trii) =  toc(trial_start) - t_elapsed;

                            if sl_poke_state == 1

                                tempo_mat(nblk).answer2(trii) = -1; %left

                            elseif sr_poke_state == 1

                                tempo_mat(nblk).answer2(trii) = 1; %right

                            end

                            if tempo_mat(nblk).answer2(trii) == tempo_mat(nblk).choice(trii)

                                tempo_mat(nblk).hit(trii) = 1; % true response
                                %                             tempo_mat(jj).trial_type(ii) = '?';  %%%%%%%%%

                            else
                                tempo_mat(nblk).hit(trii) = 0; % false response
                                state = 12 ;
                                t_elapsed= toc(trial_start);
                            end
                        end
                    case 5                                                 % stage 5 DelayedReward
                        if ((toc(trial_start)- t_elapsed) <=  settings.wait_time_for_2nd_spoke ...
                                &&(toc(trial_start)- t_elapsed) >=  settings.wait_time_cpoke_out) ...
                                && (sum([sl_poke_state,sr_poke_state]) == 1)
                            tempo_mat(nblk).rt(trii) =  toc(trial_start) - t_elapsed;

                            if sl_poke_state == 1
                                tempo_mat(nblk).answer2(trii) = -1; %left
                            elseif sr_poke_state == 1
                                tempo_mat(nblk).answer2(trii) = 1; %right
                            end
                            if tempo_mat(nblk).answer2(trii) == tempo_mat(nblk).choice(trii)
                                tempo_mat(nblk).hit(trii) = 1; % true response
                                WaitSecs(settings.delayed_reward_time);
                            else; tempo_mat(nblk).hit(trii) = 0; % false response
                                state = 12 ;
                                t_elapsed= toc(trial_start);
                            end

                        end
                    case 6                                                 % stage 6 NoReward
                        state = 12 ;
                        t_elapsed= toc(trial_start);

                end
        

                %%%%%%%%%%%          calculate total reward   %%%%%%%%%
                % as a function , to save data in summary.mat file


                %% State 11


                % ------------------------------------------------------------
                %         state 11 : "wait to Spoke out"
                % ------------------------------------------------------------


            elseif state == 11 &&  ...
                    sum([sl_poke_state,sr_poke_state]) == 0

                state = 12;
                t_elapsed = toc(trial_start);


            elseif (state == 9 ...                                          % state 9 , side pokes out , passed time more than waiting time ----
                    && (toc(trial_start)- t_elapsed) > settings.wait_time_for_spoke) ...
                    && sum([sl_poke_state,sr_poke_state]) == 0
                tempo_mat(nblk).hit(trii) = 0 ;
                state = 12 ;
                t_elapsed= toc(trial_start);
                tempo_mat(nblk).answer1(trii) = 5;                         % play error  sound
                [w , sample_rate] = sound_interface('Tone', settings.sound.sound_param , 'violation_sound' );
                sound(w,sample_rate);  

            elseif (state == 8 ...
                    && settings.Training_Stage > 1) ...
                    && ((toc(trial_start) - t_elapsed) >  settings.wait_time_cpoke_out...
                    &&  c_poke_state == 1 )
                tempo_mat(nblk).hit(trii) = 0 ;
                state = 12 ;
                t_elapsed= toc(trial_start);


            elseif state == 1 ...
                    &&  ((toc(trial_start)- t_elapsed) >  settings.wait_time_for_cpoke ...
                    && (c_poke_state == 0 && sum([sl_poke_state,sr_poke_state]) == 0))



                % turn off one led
                led_drive(a, 'c' , 0);
                tempo_mat(nblk).answer1(trii) = 4;                         % play error  sound
                [w , sample_rate] = sound_interface('Tone', settings.sound.sound_param , 'violation_sound' );
                sound(w,sample_rate);  
               
                state = 12 ;
                t_elapsed = toc(trial_start);

                %% State 12

                % ------------------------------------------------------------
                %         state 12 :   Finish trials
                % ------------------------------------------------------------

            elseif (state == 12 && (c_poke_state == 0))...                 %  Finish trials    
                     &&  ((toc(trial_start)- t_elapsed > settings.iti) ...                   
                    && sum([sl_poke_state,sr_poke_state]) == 0)

                tempo_mat(nblk).trial_end_time(trii) =  toc(trial_start);
                trial_end = 0;  
                sprintf('finish trial: block number: %d , trial number: %d , result: %d, Cchoise: %d'...
                    ,nblk,trii, tempo_mat(nblk).answer1(trii), tempo_mat(nblk).choice(trii))


            end


                % ------------------------------------------------------------
                %         Hot keys
                % ------------------------------------------------------------
                
           %% Defining hot keys

              % Key press check for manual mediating during running experiment

              % Escape end experiment
              % SPace Pause experiment
              % p (q) deliver manual rewards right(left)
              % l (a) turn on LED  right(left)
              % k (s) turn off LED  right(left)
              % v (b) turn on(off) LED center poke
              % g play go cue
            
            [keyIsDown,secs, keyCode] = KbCheck(-1);
            if keyIsDown

                pressedKey = find(keyCode);
                if keyCode(escape_key)
                    escap_order =1;
                    break;
                elseif keyCode(r_reward_key)
                    beep = MakeBeep(500,0.2,48000);
                    sound(beep*0.1,48000);                                 % Play reward Beep
                    water_drive(a ,'1' , settings.water_vol_r );
                elseif keyCode(l_reward_key)
                    beep = MakeBeep(500,0.2,48000);
                    sound(beep*0.1,48000);                                 % Play reward Beep
                    water_drive(a ,'-1' , settings.water_vol_l );
                elseif keyCode(r_led_on_key)
                    led_drive(a, '1' , 1);
                elseif keyCode(r_led_off_key)
                    led_drive(a, '1' , 0);
                elseif keyCode(l_led_on_key)
                    led_drive(a, '-1' , 1);
                elseif keyCode(l_led_off_key)
                    led_drive(a, '-1' , 0);
                elseif keyCode(c_led_on_key)
                    led_drive(a, 'c' , 1);
                elseif keyCode(c_led_off_key)
                    led_drive(a, 'c' , 0);
                elseif keyCode(reset_key)
                    trial_end = 0;
                elseif keyCode(play_go_cue_key)                            % Play go cue
                    [w , sample_rate] = sound_interface('Tone', settings.sound.sound_param , 'go_sound'  );
                    sound(w,sample_rate);
                end
                FlushEvents();
            end

        end
        
        
            

    end

    %% plot
    %     % ------------------------------------------------------------
    %     %                          PLOTTING
    %     % ------------------------------------------------------------
    %
    %     %%% **********
    %     % plot Bias Towards a poke side
    %     figure(1)
    %
    %     x = [1: settings.num_of_trials_in_block];
    %     y = tempo_mat(jj).answer1;
    %     subplot(3,1,1)
    %     plot(x,y,'r--*');
    %     title('Bias Towards a poke side')
    %     xlabel('trial')
    %     ylabel('left(-1) ,  right(1)')
    %
    %     %%% **********
    %     % Plot Overall Performance
    %
    % %     z = tempo_mat(2).trial_type;
    % %     subplot(3,1,2)
    % %     title('Plot Overall Performance')
    % %     bar( z )
    %
    %
    %
    %     %%% **********
    %     % Plot cpoke duration
    %
    %     if settings.Training_Stage == 3
    %         q = tempo_mat(jj).time_d2(tempo_mat(jj).hit(:) == 1 );
    %     end
    %     subplot(3,1,3)
    %     plot(x,q,'b--*');
    %     title('Plot cpoke duration')
    %
    %
    %
    %   save(strcat(path, '\current_experiment\tempo.mat') , 'tempo_mat');

    %%     Change Settings of next block of experiment

    %     % ------------------------------------------------------------
    %     %          Change Settings of next block of experiment
    %     % ------------------------------------------------------------
    %
    %     change_vol = strcat('volume of water drive, left = ' ,...
    %         tempo_mat(jj).vol_of_water_drive_l(end),'and right = ',tempo_mat(jj).vol_of_water_drive_r(end)',...
    %         'Do you want to change them?( Enter 0 for No', ...
    %         'l to change left one and r to change right one','s');
    %     if change_vol == 'l'
    %         settings.vol_of_water_drive_l = input('Enter volume of left water drive', 's');
    %     elseif change_vol == 'r'
    %         settings.vol_of_water_drive_r = input('Enter volume of right water drive', 's');
    %     end


    if  escap_order
        break;
    end

    %% save
    % save dataset


    save(strcat(path, path_save_data,...
        settings.name_subject,...
        '_Stg',num2str(settings.Training_Stage),...
        '_Ses',num2str(settings.session_num),...
        '_',settings.exp_name,...
        string(settings.date_time),...
        '.mat'),'tempo_mat','settings');

end
session_end = toc(trial_start);



% rmdir('current_experiment' , 's');


%%% ********
% save final figure

%% update Summary.mat file

% ------------------------------------------------------------
%                    update Summary.mat file
% ------------------------------------------------------------

data.Previous_Session = datetime('now','TimeZone','local','Format','_d_MMM_y_HH_mm'); % this session actually
if ~isfield(data,'weight')
    data.weight=[];
end
data.weight = [data.weight; [settings.weight,string(settings.date_time)]];
% data.Current_Stage = 1;
switch data.Current_Stage
    case 1
        data.Training_Stage1.Next_Session = settings.session_num + 1;
        data.Training_Stage1.Number_of_sessions_Actual = settings.session_num;
        data.Training_Stage1.Remained_Sessions = ...
            data.Training_Stage1.Number_of_sessions_Predicted...
            - data.Training_Stage1.Number_of_sessions_Actual;
        data.Training_Stage1.Number_of_trials_Actual = ...
            data.Training_Stage1.Number_of_trials_Actual...
            + length([tempo_mat.num_tr]);
        data.Training_Stage1.Remained_Trials = ....
            data.Training_Stage1.Number_of_trials_Predicted ...
            - data.Training_Stage1.Number_of_trials_Actual;
    case 2
        data.Training_Stage2.Next_Session = settings.session_num + 1;
        data.Training_Stage2.Number_of_sessions_Actual = settings.session_num;
        data.Training_Stage2.Remained_Sessions = ...
            data.Training_Stage2.Number_of_sessions_Predicted...
            - data.Training_Stage2.Number_of_sessions_Actual;
        data.Training_Stage2.Number_of_trials_Actual = ...
            data.Training_Stage2.Number_of_trials_Actual...
            + length([tempo_mat.num_tr]);
        data.Training_Stage2.Remained_Trials = ....
            data.Training_Stage2.Number_of_trials_Predicted ...
            - data.Training_Stage2.Number_of_trials_Actual;
    case 3
        data.Training_Stage3.Next_Session = settings.session_num + 1;
        data.Training_Stage3.Number_of_sessions_Actual = settings.session_num;
        data.Training_Stage3.Remained_Sessions = ...
            data.Training_Stage3.Number_of_sessions_Predicted...
            - data.Training_Stage3.Number_of_sessions_Actual;
        data.Training_Stage3.Number_of_trials_Actual = ...
            data.Training_Stage3.Number_of_trials_Actual...
            + length([tempo_mat.num_tr]);
        data.Training_Stage3.Remained_Trials = ....
            data.Training_Stage3.Number_of_trials_Predicted ...
            - data.Training_Stage3.Number_of_trials_Actual;
        data.Training_Stage3.Last_Keep_C_Poke_Duration = ...
            tempo_mat(end).time_d2(end);
    case 4
        data.Training_Stage4.Next_Session = settings.session_num + 1;
        data.Training_Stage4.Number_of_sessions_Actual = settings.session_num;
        data.Training_Stage4.Remained_Sessions = ...
            data.Training_Stage4.Number_of_sessions_Predicted...
            - data.Training_Stage4.Number_of_sessions_Actual;
        data.Training_Stage4.Number_of_trials_Actual = ...
            data.Training_Stage4.Number_of_trials_Actual...
            + length([tempo_mat.num_tr]);
        data.Training_Stage4.Remained_Trials = ....
            data.Training_Stage4.Number_of_trials_Predicted ...
            - data.Training_Stage4.Number_of_trials_Actual;
    case 5
        data.Training_Stage5.Next_Session = settings.session_num + 1;
        data.Training_Stage5.Number_of_sessions_Actual = settings.session_num;
        data.Training_Stage5.Remained_Sessions = ...
            data.Training_Stage5.Number_of_sessions_Predicted...
            - data.Training_Stage5.Number_of_sessions_Actual;
        data.Training_Stage5.Number_of_trials_Actual = ...
            data.Training_Stage5.Number_of_trials_Actual...
            + length([tempo_mat.num_tr]);
        data.Training_Stage5.Remained_Trials = ....
            data.Training_Stage5.Number_of_trials_Predicted ...
            - data.Training_Stage5.Number_of_trials_Actual;
    case 6
        data.Training_Stage6.Next_Session = settings.session_num + 1;
        data.Training_Stage6.Number_of_sessions_Actual = settings.session_num;
        data.Training_Stage6.Remained_Sessions = ...
            data.Training_Stage6.Number_of_sessions_Predicted...
            - data.Training_Stage6.Number_of_sessions_Actual;
        data.Training_Stage6.Number_of_trials_Actual = ...
            data.Training_Stage6.Number_of_trials_Actual...
            + length([tempo_mat.num_tr]);
        data.Training_Stage6.Remained_Trials = ....
            data.Training_Stage6.Number_of_trials_Predicted ...
            - data.Training_Stage6.Number_of_trials_Actual;
end

data_name = strcat(settings.name_subject,'_Summary');
eval(strcat(data_name,' = data;'));
data_name_=strcat(settings.name_subject,'_Summary');
save(strcat(path,'\PWM_Summary\' ,settings.name_subject,'_Summary.mat'),data_name_);


%
%???????
% delete [path , '\current_experiment\tempo.mat
% rmdir current_experiment tempo.mat
