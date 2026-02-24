function [cfg] = bch_setup_model1_ss44(cfg)
%--------------------------------------------------------------------------

% AT adapted for ss044
%
% created by Lennart Verhagen, march-2006
% L.Verhagen@fcdonders.ru.nl
% version 2007-11-14
%
% adapted for SPM8 wrapper by Inge Volman, March 2012.

%--------------------------------------------------------------------------
   
subj = cfg.subj;
info_dir = fullfile(cfg.dir.func,cfg.sess,cfg.dir.info.info);

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

BEHAV.task = cfg.sess(6:end);

TR = cfg.preproc.st.TR * 1000;
         
% names of columns: 1=BlockNr, 2=ResInst, 3=TrialNr,
% 4=Affect, 5=Gender, 6=Model, 7=T_Fix, 8=T_FBlck, 9=T_Pict,
% 10=T_PBlck, 11=T_Start, 12=T_End, 13=Resp, 14=Corr, 15=ITI,
% 16=RT (onsets), 17=MT, 18=T_JoyEr (end of instructions of the error), 19=TooLate.

%logfile_name	= fullfile(cfg.dir.root,subj,cfg.dir.info.log,[subj '_' BEHAV.task '_log.txt']);
logfile_name	= fullfile(cfg.dir.root,cfg.dir.beh, strcat('subj',subj),cfg.dir.info.log,['subj' subj BEHAV.task '_log.txt']);

str_trigger     = 'Time of start Experiment:';
str_stop        = '';
[M names start_time] = CropLogfile(logfile_name,str_trigger,str_stop);


% find inter block intervals
idx_block	= M(:,strcmp(names,'TrialNr')) == 0;
idx_trial	= M(:,strcmp(names,'TrialNr')) ~= 0;
M_block     = M(idx_block,:);
M           = M(idx_trial,:);

% take out last "completed block" (all too late responses and then stopped exp)
M_block = M_block(1:11,:);
M =  M(1:132,:);


% Do corrections
output = find_strings(names,'T_Fix','T_FBlck','T_Pict','T_PBlck','T_Start','T_End','T_JoyEr','TooLate');
M(:,output) = M(:,output)-start_time;
output = find_strings(names,'T_Fix','T_FBlck','T_Pict','T_PBlck','T_Start','T_End','ITI','RT','MT','T_JoyEr','TooLate');
M(:,output) = M(:,output)./TR;
output = find_strings(names,'Model','T_Fix','T_PBlck');
M_block(:,output) = M_block(:,output)-start_time;
output = find_strings(names,'Model','T_Fix','T_PBlck','Resp','Corr');
M_block(:,output) = M_block(:,output)./TR;

% Get info on the instructions
BEHAV.info_onset=[];
BEHAV.info_dur=[];

for b = 1:size(M_block,1)
    
    % Presentation and duration of block instructions (recorded at T-Fix and Corr).
    BEHAV.info_onset = [BEHAV.info_onset; M_block(b,strcmp(names,'T_Fix'))]; 
    BEHAV.info_dur = [BEHAV.info_dur; M_block(b,strcmp(names,'Corr'))];  
    
    % Loop over the trial in a block
    for t = (12*(b-1))+(1:12); 
        
        % Check for error of joystick not in middle.
        if M(t,strcmp(names,'T_JoyEr')) > 0 
            
            % checks whether joyerr was in first trial of block or  not.
            if M(t,strcmp(names,'TrialNr'))==1
               BEHAV.info_onset = [BEHAV.info_onset; M(t,strcmp(names,'T_Fix'))-M(t,strcmp(names,'T_JoyEr')) + M_block(b,strcmp(names,'T_PBlck'))]; % T-start represents start first ITI of block.
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
    
    kinem_file = load(fullfile(cfg.dir.root,cfg.dir.beh,strcat('subj',subj),cfg.dir.kinem,[strcat('subj', subj) BEHAV.task '_MASKpchip_FILTlp25_MOV_ANA_CFG.mat']));
    % kinem_file.cfg.vars: 1='trlbeg', 2='trlend', 3='trloff', 4='Session', 5='BlockNr',
    % 6='ResInst', 7='TrialNr', 8='Affect', 9='Gender', 10= 'Model',
    % 11='T_Fix', 12='T_FBlck', 13='T_Pict', 14='T_PBlck', 15='T_Start', 16='T_End', 
    % 17='Resp', 18='Corr', 19='ITI', 20='RT', 21='MT', 22='T_JoyEr', 23='TooLate', 
    % 24='rt', 25='mt', 26='mv', 27='pv', 28='tpv', 29='rtpv'. 30='nvc', 31='eposx',
    % 32='pauc', 33='nauc', 34='pmaxpos', 35='nmaxpos', 36='pmaxwinpos', 37='nmaxwinpos'

    kinem_file.cfg.trl = kinem_file.cfg.trl(1:132,:);
    
    M = [M (kinem_file.cfg.trl(:,strcmp(kinem_file.cfg.vars,'rt'))*1000/TR)];
    M = [M (kinem_file.cfg.trl(:,strcmp(kinem_file.cfg.vars,'mt'))*1000/TR)];
    names = [names 'rt' 'mt'];
       
%     if strcmp(subj,'1058') % exclude all trials after image 850 (-34 prep scans) due to spikes.
%         idx = M(:,9)>816;
%         M = M(~idx,:);
%     end
%end

% find misses
idx_miss	= (M(:,strcmp(names,'TooLate')) > 0) | (M(:,strcmp(names,'Corr')) == 0) | isnan(M(:,strcmp(names,'rt'))) ;
idx_good	= (M(:,strcmp(names,'TooLate')) <= 0) & (M(:,strcmp(names,'Corr')) == 1) & ~isnan(M(:,strcmp(names,'rt')));
BEHAV.M_Miss = M(idx_miss,:);
M           = M(idx_good,:);    % the misses are excluded from M.

BEHAV.M_Happy = M(M(:,strcmp(names,'Affect'))==1,:);
%BEHAV.M_Neutr = M(M(:,strcmp(names,'Affect'))==2,:);
BEHAV.M_Angry = M(M(:,strcmp(names,'Affect'))==2,:);

BEHAV.M_ApprH = BEHAV.M_Happy(BEHAV.M_Happy(:,strcmp(names,'Resp')) ==-1,:);
%BEHAV.M_ApprN = BEHAV.M_Neutr(BEHAV.M_Neutr(:,strcmp(names,'Resp')) ==-1,:);
BEHAV.M_ApprA = BEHAV.M_Angry(BEHAV.M_Angry(:,strcmp(names,'Resp')) ==-1,:);
BEHAV.M_AvoidH = BEHAV.M_Happy(BEHAV.M_Happy(:,strcmp(names,'Resp')) ==1,:);
%BEHAV.M_AvoidN = BEHAV.M_Neutr(BEHAV.M_Neutr(:,strcmp(names,'Resp')) ==1,:);
BEHAV.M_AvoidA = BEHAV.M_Angry(BEHAV.M_Angry(:,strcmp(names,'Resp')) ==1,:);

BEHAV.M_block   = M_block; 
BEHAV.M         = M;
cfg.behav       = BEHAV;
cfg.names       = names;



%% function - get_model_Resp_Affect6_motregr_info_RT 
%----------------------------------------------------
function get_model_Resp_Affect6_motregr_info_RT (cfg,info_dir,subj)
%AT
names = {'ApprH','ApprA','AvoidH','AvoidA','miss','info'};

onsets{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach happy picture.
onsets{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'T_Pict'));	%time of presentation approach angry picture.
onsets{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'T_Pict'));	%time of presentation avoid happy picture.
onsets{4} = cfg.behav.M_AvoidA(:,strcmp(cfg.names,'T_Pict')); %time of presentation avoid angry picture.
if isempty(cfg.behav.M_Miss)
    onsets{5} = NaN;
else
    onsets{5} = cfg.behav.M_Miss(:,strcmp(cfg.names,'T_Pict'));
end
onsets{6} = cfg.behav.info_onset; %time that block instruction/error message (joy not in middle) was presented.

durations{1} = cfg.behav.M_ApprH(:,strcmp(cfg.names,'rt')); % planning time of approach happy trial.
durations{2} = cfg.behav.M_ApprA(:,strcmp(cfg.names,'rt')); % planning time of approach angry trial.
durations{3} = cfg.behav.M_AvoidH(:,strcmp(cfg.names,'rt')); % planning time of avoid happy trial.
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
