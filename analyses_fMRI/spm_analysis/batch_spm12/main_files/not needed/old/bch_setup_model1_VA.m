function [cfg] = bch_setup_model1_VA(cfg)
%--------------------------------------------------------------------------
% BCH_SETUP_MODEL1_EXP creates vectors with onsets, durations and
% parametric modulations to serve as input for your first level model
% specification. This file basically contains your model design! I created
% a different function for each model. Based on the name of the model
% specified by INFO.model1 different functions are called (using 'EVAL').
%
% Below a few of my models are shown as examples. All start out with
% loading the .mat file containing my behavioural vectors. These .mat files
% are created by BCH_GET_BEHAV_EXP. They are highly specific for my
% experiment and most likely you will need to create your own
% BCH_GET_BEHAV_EXP from scratch. After that the onset and duration vectors
% are specified based on the behavioural vectors. Then if applicable the
% parametric modulations are specified. In the end all variables are saved
% in a .mat file starting with the INFO.prefix.cond prefix. The names of
% those variables is very important and can not be changed without
% consequences. The functions BCH_RUN_JOB and EXPAND_JOB depend heavilly on
% these naming conventions. Good luck.
%
% created by Lennart Verhagen, march-2006
% L.Verhagen@fcdonders.ru.nl
% version 2007-11-14
%
% adapted for SPM8 wrapper by Inge Volman, March 2012.
%--------------------------------------------------------------------------
   
subj = cfg.subj;
info_dir = fullfile(cfg.dir.func,cfg.sess,cfg.dir.info.info);

cfg = get_behavioral(cfg,subj);

if ~strcmpi(cfg.model1,'none')
    get_model = ['get_model_',cfg.model1];
    if exist(get_model,'file')
        
        cfg = get_behavioral(cfg,subj);
        
        eval([get_model,'(cfg,info_dir,subj)']);
    else
        warning('BCH:NoModel','This model is not supported yet.');
    end
end
        
    
%==========================================================================
function cfg = get_behavioral(cfg,subj)

%BEHAV.task = cfg.sess(6:end);
BEHAV.task = cfg.sess(1:end);

TR = cfg.preproc.st.TR * 1000;

%% Old logfile
% names of columns: 1=BlockNr, 2=ResInst, 3=BType,4=TrialNr,
% 5=Affect, 6=Colour, 7=Gender, 8=Model, 9=T_Fix, 10=T_FBlck, 11=T_Pict,
% 12=T_PBlck, 13=T_Start, 14=T_End, 15=Resp, 16=Corr, 17=ITI,
% 18=RT (onsets), 19=MT, 20=T_JoyEr (end of instructions of the error), 21=TooLate.

%% New logfile  Auditory AAT
% names of columns: 1=BlockNr, 2=ResInst, 3=TrialNr, 4=Affect
% 5=Gender, 6=Model, 7=T_Fix, 8=T_Voc, 9=T_PBlck, 10=T_Start, 11=T_End,
% 12=Resp, 13=Corr, 14=ITI, 15=RT, 16=MT, 17=T_JoyEr (end of instructions of the error), 18=TooLate.

%logfile_name	= fullfile(cfg.dir.root,subj,cfg.dir.info.log,[subj '_' BEHAV.task '_log.txt']);
%% Adjusted for Auditory AAT
% logfile_name	= fullfile(cfg.dir.root,subj,'func',cfg.sess, cfg.dir.info.log,[subj '_' BEHAV.task '_log.txt']);

%subj changed to [subj(1:3) 'j' subj(5:end)] to remove the hyphen from the subject name and add a j
if length(cfg.subj) == 7
    logfile_name	= fullfile(cfg.dir.root,subj,'func',cfg.sess, cfg.dir.info.log,[[subj(1:3) 'j' subj(6:end)] '_' BEHAV.task '_log.txt']);
elseif length(cfg.subj) == 6
    logfile_name	= fullfile(cfg.dir.root,subj,'func',cfg.sess, cfg.dir.info.log,[[subj(1:3) 'j' subj(5:end)] '_' BEHAV.task '_log.txt']);
    ends

str_trigger     = 'Time of start Experiment:';
str_stop        = '';
[M names start_time] = CropLogfile(logfile_name,str_trigger,str_stop);
block_names = {'BlockNr', 'RepInst', 'Zero3', 'Zero4', 'Zero5', 'beforeIBI', 'InstTime', 'Zero8',...
    'Zero9', 'BlockStart', 'Zero11', 'Zero12','actualIBI', 'InstReadTime', 'Zero15'};

%% adjustment for Auditory AAT: the time from Start time and the instruction of the first block (10 TRs) 
%%  was used for weighting the ME TR = 2320 x 9 

start_time = start_time + (TR*3); %time needed for three echoes

% find inter block intervals
idx_block	= M(:,strcmp(names,'TrialNr')) == 0;
idx_trial	= M(:,strcmp(names,'TrialNr')) ~= 0;
M_block     = M(idx_block,1:15); %the raw data only has 16 columns
M           = M(idx_trial,:);

% Do corrections
output = find_strings(names,'T_Fix','T_FBlck','T_Pict','T_PBlck','T_Start','T_End','T_JoyEr','TooLate');
M(:,output) = M(:,output)-start_time;
output = find_strings(names,'T_Fix','T_FBlck','T_Pict','T_PBlck','T_Start','T_End','ITI','RT','MT','T_JoyEr','TooLate');
M(:,output) = M(:,output)./TR;

% output = find_strings(names,'Model','T_Fix','T_PBlck'); %WHAT IS THIS? Removed by VA

output = find_strings(block_names,'beforeIBI','InstTime','BlockStart'); %Choosing columns with timing data for blocks
M_block(:,output) = M_block(:,output)-start_time;
output = find_strings(block_names,'beforeIBI','InstTime','BlockStart','actualIBI','InstReadTime');
M_block(:,output) = M_block(:,output)./TR;

M_block(1,6) = 0; %before IBI for the first block ends up being a negative number
%% Critical point, remove the first IBI ??

% M_block(:,output) = M_block(:,output)-start_time;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% adjust first IBI onset time to 0 this corresponds to the starting time
%%% (in the auditory AAT you used the first 10 scans for weighting the ME
%%% and these include the first IBI. Setting the onset of the IBI to 0 will
%%% correctly calcualte the first block duration. 

% M_block(1,6) = 0; %this is used only in the baseline model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% output = find_strings(names,'Model','T_Fix','T_PBlck','Resp','Corr');
% M_block(:,output) = M_block(:,outputlength(cfg.subj) == 7)./TR;

% Get info on the instructions
BEHAV.info_onset=[];
BEHAV.info_dur=[];

for b = 1:size(M_block,1)
    
    % Presentation and duration of block instructions (recorded at T-Fix and Corr).
    BEHAV.info_onset = [BEHAV.info_onset; M_block(b,strcmp(block_names,'InstTime'))]; 
    BEHAV.info_dur = [BEHAV.info_dur; M_block(b,strcmp(block_names,'InstReadTime'))];  
   
    
    % Loop over the trial in a block
    for t = (12*(b-1))+(1:12) 
        
        % Check for error of joystick not in middle.
        if M(t,strcmp(names,'T_JoyEr')) > 0 
            
            % checks whether joyerr was in first trial of block or  not.
            if M(t,strcmp(names,'TrialNr'))==1
               BEHAV.info_onset = [BEHAV.info_onset; M(t,strcmp(names,'T_Fix'))-M(t,strcmp(names,'T_JoyEr')) + M_block(b,strcmp(block_names,'BlockStart'))]; % T-start represents start first ITI of block.
               BEHAV.info_dur = [BEHAV.info_dur; M(t,strcmp(names,'ITI')) - 2*(M(t,strcmp(names,'T_Fix'))-M(t,strcmp(names,'T_JoyEr')))]; 
            else
                BEHAV.info_onset = [BEHAV.info_onset; M(t,strcmp(names,'T_Fix'))-M(t,strcmp(names,'T_JoyEr')) + M((t-1),strcmp(names,'T_End'))]; 
                BEHAV.info_dur = [BEHAV.info_dur; M(t,strcmp(names,'ITI')) - 2*(M(t,strcmp(names,'T_Fix'))-M(t,strcmp(names,'T_JoyEr')))];
            end

        end
        
        % Checks for error when subj did not move far enough.
        if M(t,strcmp(names,'TooLate')) > 0
             BEHAV.info_onset = [BEHAV.info_onset; M(t,strcmp(names,'TooLate'))]; 
             BEHAV.info_dur = [BEHAV.info_dur; 1000/TR];
        end

    end

end


%if  any(strcmpi(cfg.model1,{'Resp_Affect6_motregr_info_RT','Resp_Affect6_info_RT','Resp_Affect6_baseline_info_RT'}))
    
    % kinem_file = load(fullfile(cfg.dir.root, subj, cfg.dir.kinem,[subj '_' BEHAV.task '_MASKpchip_FILTlp25_MOV_ANA_CFG.mat']));
   
    %% Adjusted for Auditory AAT: load %% Auditory AAT adjustment: import separate accuracy file
    if length(cfg.subj) == 7
        kinem_file	= load(fullfile(cfg.dir.root, subj,'func',cfg.sess, cfg.dir.kinem,[[subj(1:3) 'j' subj(6:end)] '_' BEHAV.task '_MASKpchip_FILTlp25_MOV_ANA_CFG.mat']));
    elseif length(cfg.subj) == 6
        kinem_file	= load(fullfile(cfg.dir.root, subj,'func',cfg.sess, cfg.dir.kinem,[[subj(1:3) 'j' subj(5:end)] '_' BEHAV.task '_MASKpchip_FILTlp25_MOV_ANA_CFG.mat']));
    end        
    %accuracy_file = load(fullfile(cfg.dir.root, subj,'func',cfg.sess, cfg.dir.kinem,'accuracy.mat'));
    
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if length(cfg.subj) == 7    
        if strcmp(cfg.sess, 'run1')
            run1_file = load(fullfile(cfg.dir.root, subj,'func',cfg.sess, cfg.dir.kinem,[[subj(1:3) 'j' subj(6:end)] '_' BEHAV.task '_MASKpchip_FILTlp25_MOV_ANA_DATA.mat']));
        elseif strcmp(cfg.sess, 'run2')
            run2_file = load(fullfile(cfg.dir.root, subj,'func',cfg.sess, cfg.dir.kinem,[[subj(1:3) 'j' subj(6:end)] '_' BEHAV.task '_MASKpchip_FILTlp25_MOV_ANA_DATA.mat'])); %% only for gender
        end
    elseif length(cfg.subj) == 6
        if strcmp(cfg.sess, 'run1')
            run1_file = load(fullfile(cfg.dir.root, subj,'func',cfg.sess, cfg.dir.kinem,[[subj(1:3) 'j' subj(5:end)] '_' BEHAV.task '_MASKpchip_FILTlp25_MOV_ANA_DATA.mat']));
        elseif strcmp(cfg.sess, 'run2')
            run2_file = load(fullfile(cfg.dir.root, subj,'func',cfg.sess, cfg.dir.kinem,[[subj(1:3) 'j' subj(5:end)] '_' BEHAV.task '_MASKpchip_FILTlp25_MOV_ANA_DATA.mat'])); %% only for gender
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %% Old settings
    % kinem_file.cfg.vars: 1='trlbeg', 2='trlend', 3='trloff', 4='Session', 5='BlockNr',
    % 6='ResInst', 7='BType', 8='TrialNr', 9='Affect', 10='Colour', 11='Gender', 12= 'Model',
    % 13='T_Fix', 14='T_FBlck', 15='T_Pict', 16='T_PBlck', 17='T_Start', 18='T_End', 
    % 19='Resp', 20='Corr', 21='ITI', 22='RT', 23='MT', 24='T_JoyEr', 25='TooLate', 
    % 26='rt', 27='mt', 28='mv', 29='pv', 30='tpv', 31='rtpv'. 32='nvc', 33='eposx',
    % 34='pauc', 35='nauc', 36='pmaxpos', 37='nmaxpos', 38='pmaxwinpos', 39='nmaxwinpos'

    
   %% new settings
    % kinem_file.cfg.vars: 1='trlbeg', 2='trlend', 3='trloff', 4='Session', 5='BlockNr',
    % 6='ResInst', 7='TrialNr', 8='Affect', 9 = 'Gender', 10='Model', 11='T_Fix', 12='T_Voc',
    % 13='T_PBlck', 14='T_Start', 15='T_End', 16='Resp', 17='Corr', 18='ITI', 
    % 19='RT', 20='MT', 21='T_JoyEr', 22='TooLate', 23='rt', 24='mt', 25='mv', 
    % 26='pv', 27='tpv', 28='rtpv', 29='nvc', 30='eposx', 31='pauc'. 32='nauc', 33='pmaxpos',
    % 34='nmaxpos', 35='pmaxwinpos', 36='nmaxwinpos'
    
    %% Auditory AAT adjustment: import separate accuracy file
    
    %accuracy_file = load(fullfile(cfg.dir.root, subj, cfg.dir.kinem,[subj '_' BEHAV.task '_accuracy.mat']));
    
    M = [M (kinem_file.cfg.trl(:,strcmp(kinem_file.cfg.vars,'rt'))*1000/TR)];
    M = [M (kinem_file.cfg.trl(:,strcmp(kinem_file.cfg.vars,'mt'))*1000/TR)];
    names = [names 'rt' 'mt'];
     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PUT THIS BACK IN THE CODE IF NEEDED

% if  strcmp(cfg.sess, 'run1')
% 
% M(:,12) = run1_file.direction;%% replace direction vector Affect task
% M(:,13) = run1_file.correct;%% replace correct vector
% 
% elseif strcmp(cfg.sess, 'run2')
% 
% M(:,12) = run2_file.affect_congruency;
% M(:,13) = run1_file.correct;
% 
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ACCURACY FILE HERE NEEDS TO BE CHANGED
%idx_miss	= (M(:,strcmp(names,'TooLate')) > 0) | (accuracy_file.correct(:) == 0) | isnan(M(:,strcmp(names,'rt'))) ;
%idx_good	= (M(:,strcmp(names,'TooLate')) <= 0) & (accuracy_file.correct(:) == 1) & ~isnan(M(:,strcmp(names,'rt')));
%BEHAV.M_Miss = M(idx_miss,:);-1
%M           = M(idx_good,:);    % the misses are excluded from M.

% old code for finding misses
idx_miss	= (M(:,strcmp(names,'TooLate')) > 0) | (M(:,strcmp(names,'Corr')) == 0) | isnan(M(:,strcmp(names,'rt'))) ;
idx_good	= (M(:,strcmp(names,'TooLate')) <= 0) & (M(:,strcmp(names,'Corr')) == 1) & ~isnan(M(:,strcmp(names,'rt')));
BEHAV.M_Miss = M(idx_miss,:);
M           = M(idx_good,:);    % the misses are excluded from M.


BEHAV.M_Pos = M(M(:,strcmp(names,'Affect'))==1,:);
BEHAV.M_Neg = M(M(:,strcmp(names,'Affect'))==2,:);
BEHAV.M_Happy = BEHAV.M_Pos(BEHAV.M_Pos(:,strcmp(names,'Content')) ==1,:);
BEHAV.M_Fresh = BEHAV.M_Pos(BEHAV.M_Pos(:,strcmp(names,'Content')) ==2,:);
BEHAV.M_Angry = BEHAV.M_Neg(BEHAV.M_Neg(:,strcmp(names,'Content')) ==1,:);
BEHAV.M_Rotten = BEHAV.M_Neg(BEHAV.M_Neg(:,strcmp(names,'Content')) ==2,:);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if  strcmp(cfg.sess, 'run1')
BEHAV.M_ApprH = BEHAV.M_Happy(BEHAV.M_Happy(:,strcmp(names,'Resp')) ==-1,:);
BEHAV.M_ApprA = BEHAV.M_Angry(BEHAV.M_Angry(:,strcmp(names,'Resp')) ==-1,:);
BEHAV.M_AvoidH = BEHAV.M_Happy(BEHAV.M_Happy(:,strcmp(names,'Resp')) ==1,:);
BEHAV.M_AvoidA = BEHAV.M_Angry(BEHAV.M_Angry(:,strcmp(names,'Resp')) ==1,:);
BEHAV.M_ApprF = BEHAV.M_Fresh(BEHAV.M_Fresh(:,strcmp(names,'Resp')) ==-1,:);
BEHAV.M_ApprR = BEHAV.M_Rotten(BEHAV.M_Rotten(:,strcmp(names,'Resp')) ==-1,:);
BEHAV.M_AvoidF = BEHAV.M_Fresh(BEHAV.M_Fresh(:,strcmp(names,'Resp')) ==1,:);
BEHAV.M_AvoidR = BEHAV.M_Rotten(BEHAV.M_Rotten(:,strcmp(names,'Resp')) ==1,:);
elseif strcmp(cfg.sess, 'run2')
BEHAV.M_ApprH = BEHAV.M_Happy(BEHAV.M_Happy(:,strcmp(names,'Resp')) ==-1,:);
BEHAV.M_ApprA = BEHAV.M_Angry(BEHAV.M_Angry(:,strcmp(names,'Resp')) ==-1,:);
BEHAV.M_AvoidH = BEHAV.M_Happy(BEHAV.M_Happy(:,strcmp(names,'Resp')) ==1,:);
BEHAV.M_AvoidA = BEHAV.M_Angry(BEHAV.M_Angry(:,strcmp(names,'Resp')) ==1,:);
BEHAV.M_ApprF = BEHAV.M_Fresh(BEHAV.M_Fresh(:,strcmp(names,'Resp')) ==-1,:);
BEHAV.M_ApprR = BEHAV.M_Rotten(BEHAV.M_Rotten(:,strcmp(names,'Resp')) ==-1,:);
BEHAV.M_AvoidF = BEHAV.M_Fresh(BEHAV.M_Fresh(:,strcmp(names,'Resp')) ==1,:);
BEHAV.M_AvoidR = BEHAV.M_Rotten(BEHAV.M_Rotten(:,strcmp(names,'Resp')) ==1,:);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BEHAV.M_block   = M_block; 
BEHAV.M         = M;
cfg.behav       = BEHAV;
cfg.names       = names;



%% THIS IS THE MODEL!
%----------------------------------------------------
function get_model_FAAT_54Mot_RT (cfg,info_dir,subj)

names = {'ApprH','ApprA','AvoidH','AvoidA','ApprF','ApprR','AvoidF','AvoidR','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Pict'));   %time of presentation avoid angry picture.
onsets{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'T_Pict'));   %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{9} = NaN;
else
    onsets{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Pict'));
end
onsets{10} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.


durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'rt')); % planning time of approach happy trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'rt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'rt')); % planning time of avoid happy trial.
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'rt')); % planning time of avoid angry trial.
durations{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'rt')); % planning time of approach happy trial.
durations{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'rt')); % planning time of approach angry trial.
durations{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'rt')); % planning time of avoid happy trial.
durations{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'rt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{9} = 0;
else
    durations{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'rt'));
    for i = 1:length(durations{9})
        if isnan(durations{9}(i)) 
            durations{9}(i) = 0;
        end
    end
end
durations{10} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
params{7} = {};
params{8} = {};
params{9} = {};
params{10} = {};
% params{7} = {};
% params{8} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');
%==========================================================================

function get_model_FAAT_6Mot_RT (cfg,info_dir,subj)

names = {'ApprH','ApprA','AvoidH','AvoidA','ApprF','ApprR','AvoidF','AvoidR','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
onsets{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{9} = NaN;
else
    onsets{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Pict'));
end
onsets{10} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.


durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'rt')); % planning time of approach happy trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'rt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'rt')); % planning time of avoid happy trial.
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'rt')); % planning time of avoid angry trial.
durations{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'rt')); % planning time of approach happy trial.
durations{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'rt')); % planning time of approach angry trial.
durations{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'rt')); % planning time of avoid happy trial.
durations{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'rt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{9} = 0;
else
    durations{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'rt'));
    for i = 1:length(durations{9})
        if isnan(durations{9}(i)) 
            durations{9}(i) = 0;
        end
    end
end
durations{10} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
params{7} = {};
params{8} = {};
params{9} = {};
params{10} = {};
% params{7} = {};
% params{8} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');
%==========================================================================

function get_model_FAAT_54Mot_MT (cfg,info_dir,subj)

names = {'ApprH','ApprA','AvoidH','AvoidA','ApprF','ApprR','AvoidF','AvoidR','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
onsets{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{9} = NaN;
else
    onsets{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Pict'));
end
onsets{10} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.


durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'mt')); % planning time of approach happy trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'mt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'mt')); % planning time of avoid happy trial.
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'mt')); % planning time of avoid angry trial.
durations{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'mt')); % planning time of approach happy trial.
durations{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'mt')); % planning time of approach angry trial.
durations{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'mt')); % planning time of avoid happy trial.
durations{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'mt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{9} = 0;
else
    durations{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'mt'));
    for i = 1:length(durations{9})
        if isnan(durations{9}(i)) 
            durations{9}(i) = 0;
        end
    end
end
durations{10} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
params{7} = {};
params{8} = {};
params{9} = {};
params{10} = {};
% params{7} = {};
% params{8} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');
%==========================================================================

function get_model_FAAT_6Mot_MT (cfg,info_dir,subj)

names = {'ApprH','ApprA','AvoidH','AvoidA','ApprF','ApprR','AvoidF','AvoidR','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
onsets{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{9} = NaN;
else
    onsets{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Pict'));
end
onsets{10} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.


durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'mt')); % planning time of approach happy trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'mt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'mt')); % planning time of avoid happy trial.
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'mt')); % planning time of avoid angry trial.
durations{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'mt')); % planning time of approach happy trial.
durations{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'mt')); % planning time of approach angry trial.
durations{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'mt')); % planning time of avoid happy trial.
durations{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'mt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{9} = 0;
else
    durations{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'mt'));
    for i = 1:length(durations{9})
        if isnan(durations{9}(i)) 
            durations{9}(i) = 0;
        end
    end
end
durations{10} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
params{7} = {};
params{8} = {};
params{9} = {};
params{10} = {};
% params{7} = {};
% params{8} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');
%==========================================================================

function get_model_FAAT_54Mot_RT_MT (cfg,info_dir,subj)

names = {'ApprH','ApprA','AvoidH','AvoidA','ApprF','ApprR','AvoidF','AvoidR','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
onsets{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{9} = NaN;
else
    onsets{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Pict'));
end
onsets{10} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.


durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'rt')) + cfg.behav.M_ApprH(:,strcmp(cfg.names,'mt')); % planning time of approach happy trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'rt')) + cfg.behav.M_ApprA(:,strcmp(cfg.names,'mt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'rt')) + cfg.behav.M_AvoidH(:,strcmp(cfg.names,'mt')); % planning time of avoid happy trial.
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'rt')) + cfg.behav.M_AvoiH(:,strcmp(cfg.names,'mt')); % planning time of avoid angry trial.
durations{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'rt')) + cfg.behav.M_ApprF(:,strcmp(cfg.names,'mt')); % planning time of approach happy trial.
durations{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'rt')) + cfg.behav.M_ApprR(:,strcmp(cfg.names,'mt')); % planning time of approach angry trial.
durations{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'rt')) + cfg.behav.M_AvoidF(:,strcmp(cfg.names,'mt')); % planning time of avoid happy trial.
durations{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'rt')) + cfg.behav.M_AvoidR(:,strcmp(cfg.names,'mt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{9} = 0;
else
    durations{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'rt')) + cfg.behav.M_Miss(:,strcmp(cfg.names,'mt'));
    for i = 1:length(durations{9})
        if isnan(durations{9}(i)) 
            durations{9}(i) = 0;
        end
    end
end
durations{10} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
params{7} = {};
params{8} = {};
params{9} = {};
params{10} = {};
% params{7} = {};
% params{8} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');
%==========================================================================

function get_model_FAAT_6Mot_RT_MT (cfg,info_dir,subj)

names = {'ApprH','ApprA','AvoidH','AvoidA','ApprF','ApprR','AvoidF','AvoidR','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
onsets{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{9} = NaN;
else
    onsets{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Pict'));
end
onsets{10} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.


durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'rt')) + cfg.behav.M_ApprH(:,strcmp(cfg.names,'mt')); % planning time of approach happy trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'rt')) + cfg.behav.M_ApprA(:,strcmp(cfg.names,'mt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'rt')) + cfg.behav.M_AvoidH(:,strcmp(cfg.names,'mt')); % planning time of avoid happy trial.
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'rt')) + cfg.behav.M_AvoiH(:,strcmp(cfg.names,'mt')); % planning time of avoid angry trial.
durations{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'rt')) + cfg.behav.M_ApprF(:,strcmp(cfg.names,'mt')); % planning time of approach happy trial.
durations{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'rt')) + cfg.behav.M_ApprR(:,strcmp(cfg.names,'mt')); % planning time of approach angry trial.
durations{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'rt')) + cfg.behav.M_AvoidF(:,strcmp(cfg.names,'mt')); % planning time of avoid happy trial.
durations{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'rt')) + cfg.behav.M_AvoidR(:,strcmp(cfg.names,'mt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{9} = 0;
else
    durations{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'rt')) + cfg.behav.M_Miss(:,strcmp(cfg.names,'mt'));
    for i = 1:length(durations{9})
        if isnan(durations{9}(i)) 
            durations{9}(i) = 0;
        end
    end
end
durations{10} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
params{7} = {};
params{8} = {};
params{9} = {};
params{10} = {};
% params{7} = {};
% params{8} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');
%==========================================================================


function get_model_Resp_Tasks4_motregr_info_RT (cfg,info_dir,subj)

names = {'ApprH','ApprA','AvoidH','AvoidA','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
onsets{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{9} = NaN;
else
    onsets{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Pict'));
end
onsets{10} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.


durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'rt')); % planning time of approach happy trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'rt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'rt')); % planning time of avoid happy trial.
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'rt')); % planning time of avoid angry trial.
durations{5} = cfg.behav.M_ApprF(:,strcmp(cfg.names,'rt')); % planning time of approach happy trial.
durations{6} = cfg.behav.M_ApprR(:,strcmp(cfg.names,'rt')); % planning time of approach angry trial.
durations{7} = cfg.behav.M_AvoidF(:,strcmp(cfg.names,'rt')); % planning time of avoid happy trial.
durations{8} = cfg.behav.M_AvoidR(:,strcmp(cfg.names,'rt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{9} = 0;
else
    durations{9} = cfg.behav.M_Miss(:,strcmp(cfg.names,'rt'));
    for i = 1:length(durations{9})
        if isnan(durations{9}(i)) 
            durations{9}(i) = 0;
        end
    end
end
durations{10} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
params{7} = {};
params{8} = {};
params{9} = {};
params{10} = {};
% params{7} = {};
% params{8} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');
%==========================================================================

%% function - get_model_Resp_Affect6_motregr_baseline_info_RT % less mov regressors and IBI as baseline..
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function get_model_Resp_Affect6_motregr_baseline_info_RT (cfg,info_dir,subj)

names = {'ApprH','ApprA','AvoidH','AvoidA','miss','info','IBI'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Voc'));	%time of presentation approach happy picture.
%onsets{2} = cfg.behav.M_ApprN(:,strcmp(cfg.names,'T_Voc'));	%time of presentation approach neutral picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Voc'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Voc'));	%time of presentation avoid happy picture.
%onsets{5} = cfg.behav.M_AvoidN(:,strcmp(cfg.names,'T_Voc'));	%time of presentation avoid neutral picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Voc')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss) %errors
    onsets{5} = NaN;
else
    onsets{5} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Voc'));
end
onsets{6} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.
onsets{7} = cfg.behav.M_block(:,strcmp(cfg.names,'Model')); 

durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'rt')); % planning time of approach happy trial.
%durations{2} = cfg.behav.M_ApprN(:,strcmp(cfg.names,'rt')); % planning time of approach neutral trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'rt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'rt')); % planning time of avoid happy trial.
%durations{5} = cfg.behav.M_AvoidN(:,strcmp(cfg.names,'rt'));	% planning time of avoid neutral trial.
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'rt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{5} = 0;
else
    durations{5} = cfg.behav.M_Miss(:,strcmp(cfg.names,'rt'));
    for i = 1:length(durations{5})
        if isnan(durations{5}(i)) 
            durations{5}(i) = 0;
        end
    end
end
durations{6} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).
durations{7} = cfg.behav.M_block(:,strcmp(cfg.names,'Resp'));


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
params{7} = {};
% params{8} = {};
% params{9} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');
%==========================================================================


%% function - get_model_Resp_Affect6_motregr_info_MT % regressors from Rick..
%----------------------------------------------------
function get_model_Resp_Affect6_motregr_info_MT (cfg,info_dir,subj)

names = {'ApprH','ApprA','AvoidH','AvoidA','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Voc')) + cfg.behav.M_ApprH(:,strcmp(cfg.names,'rt'));	%time of presentation approach happy picture.
%onsets{2} = cfg.behav.M_ApprN(:,strcmp(cfg.names,'T_Voc')) + cfg.behav.M_ApprN(:,strcmp(cfg.names,'rt'));	%time of presentation approach neutral picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Voc')) + cfg.behav.M_ApprA(:,strcmp(cfg.names,'rt'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Voc')) + cfg.behav.M_AvoidH(:,strcmp(cfg.names,'rt'));	%time of presentation avoid happy picture.
%onsets{5} = cfg.behav.M_AvoidN(:,strcmp(cfg.names,'T_Voc')) + cfg.behav.M_AvoidN(:,strcmp(cfg.names,'rt'));	%time of presentation avoid neutral picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Voc')) + cfg.behav.M_AvoidA(:,strcmp(cfg.names,'rt')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{5} = NaN;
else
    onsets{5} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Voc')) + cfg.behav.M_Miss(:,strcmp(cfg.names,'rt'));
    for i = 1:length(onsets{5})
        if isnan(onsets{5}(i)) 
            onsets{5}(i) = cfg.behav.M_Miss(i,strcmp(cfg.names,'T_Voc'));
        end
    end
end
onsets{6} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.

durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'mt')); % planning time of approach happy trial.
%durations{2} = cfg.behav.M_ApprN(:,strcmp(cfg.names,'mt')); % planning time of approach neutral trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'mt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'mt')); % planning time of avoid happy trial.
%durations{5} = cfg.behav.M_AvoidN(:,strcmp(cfg.names,'mt'));	% planning time of avoid neutral trial.
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'mt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{5} = 0;
else
    durations{5} = cfg.behav.M_Miss(:,strcmp(cfg.names,'mt'));
    for i = 1:length(durations{5})
        if isnan(durations{5}(i)) 
            durations{5}(i) = 0;
        end
    end
end
durations{6} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
% params{7} = {};
% params{8} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');
%==========================================================================

function get_model_Resp_Affect6_motregr_RT_MT (cfg,info_dir,subj) % Added for the Auditory AAT: time from voc onset to end movement

names = {'ApprH','ApprA','AvoidH','AvoidA','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Voc'));	%time of presentation approach happy picture.
%onsets{2} = cfg.behav.M_ApprN(:,strcmp(cfg.names,'T_Voc'));	%time of presentation approach neutral picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Voc'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Voc'));	%time of presentation avoid happy picture.
%onsets{5} = cfg.behav.M_AvoidN(:,strcmp(cfg.names,'T_Voc'));	%time of presentation avoid neutral picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Voc')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{5} = NaN;
else
    onsets{5} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Voc'));
end
onsets{6} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.


durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'rt')) + cfg.behav.M_ApprH(:,strcmp(cfg.names,'mt')); % time from Voc onset to end movement
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'rt')) + cfg.behav.M_ApprA(:,strcmp(cfg.names,'mt')); 
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'rt')) + cfg.behav.M_AvoidH(:,strcmp(cfg.names,'mt')); 
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'rt')) + cfg.behav.M_AvoidA(:,strcmp(cfg.names,'mt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{5} = 0;
else
    durations{5} = cfg.behav.M_Miss(:,strcmp(cfg.names,'rt')) + cfg.behav.M_Miss(:,strcmp(cfg.names,'mt'));
    for i = 1:length(durations{5})
        if isnan(durations{5}(i)) 
            durations{5}(i) = 0;
        end
    end
end
durations{6} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
% params{7} = {};
% params{8} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');

%% function - get_model_Resp_Affect6_info_RT % less mov regressors..
%----------------------------------------------------
function get_model_Resp_Affect6_info_RT (cfg,info_dir,subj)

names = {'ApprH','ApprA','AvoidH','AvoidA','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Voc'));	%time of presentation approach happy picture.
%onsets{2} = cfg.behav.M_ApprN(:,strcmp(cfg.names,'T_Voc'));	%time of presentation approach neutral picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Voc'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Voc'));	%time of presentation avoid happy picture.
%onsets{5} = cfg.behav.M_AvoidN(:,strcmp(cfg.names,'T_Voc'));	%time of presentation avoid neutral picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Voc')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{5} = NaN;
else
    onsets{5} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Voc'));
end
onsets{6} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.

durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'rt')); % planning time of approach happy trial.
%durations{2} = cfg.behav.M_ApprN(:,strcmp(cfg.names,'rt')); % planning time of approach neutral trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'rt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'rt')); % planning time of avoid happy trial.
%durations{5} = cfg.behav.M_AvoidN(:,strcmp(cfg.names,'rt'));	% planning time of avoid neutral trial.
durations{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'rt')); % planning time of avoid angry trial.
if isempty(cfg.behav.M_Miss)
    durations{5} = 0;
else
    durations{5} = cfg.behav.M_Miss(:,strcmp(cfg.names,'rt'));
    for i = 1:length(durations{5})
        if isnan(durations{5}(i)) 
            durations{5}(i) = 0;
        end
    end
end
durations{6} = cfg.behav.info_dur; % duration of presentation of block instruction/error message (joy not in middle).


params{1} = {};
params{2} = {};
params{3} = {};
params{4} = {};
params{5} = {};
params{6} = {};
% params{7} = {};
% params{8} = {};

pmod.name = 'none';
pmod.params = params;
pmod.poly = [];

save (fullfile(info_dir,[cfg.prefix.cond,subj,cfg.behav.task]),'names','onsets','durations','pmod');
%==========================================================================


%% function - CropLogfile
%--------------------------------------------------------------------------
function [M names trigger_time exp_dur] = CropLogfile(fname,str_trigger,str_stop)

fid = fopen(fname,'r');
F = fread(fid);
S = char(F');
fclose(fid);

i = max(strfind(S,str_trigger));
if isempty(i)
    warning('KMD:NoTrigStr','The trigger string is not found in the logfile.');
    i = 1;
else
    i = i + length(str_trigger);
end

trig_on = false;
trig_off = false;
while ~trig_on || ~trig_off
    if ~trig_on && isstrprop(S(i),'digit');
        trig_on = true;
        idx_on = i;
    elseif trig_on && ~isstrprop(S(i),'digit');
        trig_off = true;
        idx_off = i-1;
    end
    i = i + 1;
end
trigger_time = str2double(S(idx_on:idx_off));
if isempty(trigger_time)
	trigger_time = -1;
end

while ~isstrprop(S(i),'alphanum')
	i = i + 1;
end

n = 1;
names_off = false;
while ~names_off
    idx_on = i;
    while ~strcmp(S(i),char(10)) && ~strcmp(S(i),char(13)) && ~strcmp(S(i),char(9))
        i = i + 1;
    end
    idx_off = i - 1;
    names{1,n} = S(idx_on:idx_off);
    n = n + 1;
    
    while strcmp(S(i),char(9))
        i = i + 1;
    end
    if strcmp(S(i),char(10)) || strcmp(S(i),char(13))
        names_off = true;
    end
end

while ( strcmp(S(i),char(10)) || strcmp(S(i),char(13)) ) && ~isstrprop(S(i+1),'digit')
    i = i + 1;
end
idx_on = i+1;

exp_dur = -1;
if isempty(str_stop)
    idx_off = length(S);
else

    i = max(strfind(S,str_stop));
    
    if isempty(i)
        warning('KMD:NoStopStr','The stop string is not found in the logfile.');
        idx_off = length(S);
        KMD.info.experiment.duration = NaN;
    else
        j = i + length(str_stop);

        while ~isstrprop(S(i),'digit')
            i = i - 1;
        end
        idx_off = i;

        stop_on = false;
        stop_off = false;
        while ~stop_on || ~stop_off
            if stop_on && j > length(S)
                stop_off = true;
                jdx_off = j-1;
            elseif ~stop_on && isstrprop(S(j),'digit');
                stop_on = true;
                jdx_on = j;
            elseif stop_on && ~isstrprop(S(j),'digit');
                stop_off = true;
                jdx_off = j-1;
            end
            j = j + 1;
        end
        if trigger_time >= 0
            exp_dur = (str2double(S(jdx_on:jdx_off)) - trigger_time)/1000;
        end
        
    end
    
end

[fdir fname ext] = fileparts(fname);
trials_fname = ['trials_',fname,ext];
fid = fopen(trials_fname,'w');
fwrite(fid,S(idx_on:idx_off));
fclose(fid);
M = dlmread(trials_fname,'\t');
delete(trials_fname);
while ~any(M(:,end))
    M = M(:,1:end-1);
end
%==========================================================================


%% function find_strings looks for multiple strings simultanously in a longer string.
%--------------------------------------------------------------------------
function output = find_strings(names,varargin)
str = sprintf('%s|',varargin{:});
str = str(1:end-1);
output = ~cellfun(@isempty,(regexp(names,str)));

%%
