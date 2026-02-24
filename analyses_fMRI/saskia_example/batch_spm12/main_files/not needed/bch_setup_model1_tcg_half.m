function [cfg] = bch_setup_model1_tcg(cfg)
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
% Version 2007-11-14
%
% adapted for SPM8 wrapper by Inge Volman, March 2012.
% ATyb June 2013
%--------------------------------------------------------------------------
subj = cfg.subj;
cfg = preproc_taskregressors(cfg,subj);

%==========================================================================

function cfg = preproc_taskregressors(cfg,subj)

% read logile
subjnr = str2num(subj(5:end));

z = (-1)^subjnr;
if z == -1 % subjnr is odd --> player 1
    pair = round(subjnr/2);
    if  pair == 67 % sub-133 was player 2 (screens were reversed)
        player = 2;
        data = read_logfile_tcg_fMRI(fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg',cfg.dir.beh,['t' num2str(pair) 'p' num2str(subjnr) '_tcg_ASD_scanning.txt']));
    else
        player = 1;
        data = read_logfile_tcg_fMRI(fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg',cfg.dir.beh,['t' num2str(pair) 'p' num2str(subjnr) '_tcg_ASD_scanning.txt']));
    end
else % subjnr = even --> player 2
    pair = subjnr/2;
    if  pair == 45 % sub-090 was matched with sub-083
        data = read_logfile_tcg_fMRI(fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg',cfg.dir.beh,'t42p83_tcg_ASD_scanning.txt'));
        player = 2;
    elseif pair == 71 % sub-142 was matched with sub-133
        player = 1;   % sub-142 was player 1 (screens were reversed)
        data = read_logfile_tcg_fMRI(fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg',cfg.dir.beh,'t67p133_tcg_ASD_scanning.txt'));
    else
        player = 2;
        subjnr_player1 = subjnr-1;
        data = read_logfile_tcg_fMRI(fullfile(cfg.dir.preproc,cfg.subj,'ses-tcg',cfg.dir.beh,['t' num2str(pair) 'p' num2str(subjnr_player1) '_tcg_ASD_scanning.txt']));
    end
end

% event names
names = {'Planning as Sender Known trials','Planning as Sender Novel trials','Observing as Receiver Known trials',...
  'Observing as Receiver Novel trials', 'Role assignment & Token assignment',...
  'Moving as Sender','Waiting as Sender','Observing as Sender',...
  'Waiting as Receiver','Planning as Receiver','Moving as Receiver',...
  'Positive Feedback','Negative Feedback'};

% event onsets and durations
if player == 1 % PrismaFit, player 1 started as sender

    % get scanner onset
    if pair == 67 % sub-133 roles were reversed, this was player 1 and was scanned on prisma
        pulse = cell2mat(struct2cell(data.prisma(1)));
    elseif subjnr == 149 % first two trials excluded due to mirrored screens
        first_pulse = cell2mat(struct2cell(data.prisma(1)));
        first_scan = 37*1.5;
        pulse = first_pulse+first_scan;
    else
        pulse = cell2mat(struct2cell(data.prismafit(1)));
    end

    % novel and known trials for sender and receiver roles
    known_indx_sender=find(data.trial(1:2:94,2)==1); % known trials as a sender
    novel_indx_sender=find(data.trial(1:2:94,2)==2); % novel trials as a sender
    known_indx_receiver=find(data.trial(2:2:94,2)==1); % known trials as a receiver
    novel_indx_receiver=find(data.trial(2:2:94,2)==2); % novel trials as a receiver
    
    % planning as a sender
    senderPlan = [data.event(1:2:94).goalconfiguration]-pulse; % onsets
    dur_senderPlan = [data.event(1:2:94).senderstart]-[data.event(1:2:94).goalconfiguration]; % durations
    
    % planning as a sender - known trials
    onsets{1} = senderPlan(known_indx_sender); % onsets - known trials
    durations{1} = dur_senderPlan(known_indx_sender); % durations - known trials;

    % planning as a sender - novel trials - first half
    onsets{2} = senderPlan(novel_indx_sender); % onsets - novel trials (first half)
    durations{2} = dur_senderPlan(novel_indx_sender)/2; % durations - novel trials (first half)

    % planning as a sender - novel trials - second half
    onsets{3} = senderPlan(novel_indx_sender) + (dur_senderPlan(novel_indx_sender)/2); % onsets - novel trials (second half)
    durations{3} = dur_senderPlan(novel_indx_sender)/2; % durations - novel trials (second half)
   
    % observig as a receiver
    receiverObserv = [data.event(2:2:94).senderstart]-pulse; % observing as a receiver (sender moving)
    dur_receiverObserv = [data.event(2:2:94).senderend]-[data.event(2:2:94).senderstart];

    % observing as a receiver - known trials
    onsets{4} = receiverObserv(known_indx_receiver); % onsets - known trials
    durations{4} = dur_receiverObserv(known_indx_receiver); % durations - known trials

    % observing as a receiver - novel trials - first half
    onsets{5} = receiverObserv(novel_indx_receiver); % onsets - novel trials (first half)
    durations{5} = dur_receiverObserv(novel_indx_receiver)/2; % durations - novel trials (first half)
 
    % observing as a receiver - novel trials - second half
    onsets{6} = receiverObserv(novel_indx_receiver) + (dur_receiverObserv(novel_indx_receiver)/2); % onsets - novel trials (second half)
    durations{6} = dur_receiverObserv(novel_indx_receiver)/2; % durations - novel trials (second half)
    
    % events of non-interest
    onsets{7} = [data.event(1:1:94).roleassignment]-pulse; % role & token assignment (ITI)

    onsets{8} = [data.event(1:2:94).senderstart]-pulse; % moving as a sender
    onsets{9} = [data.event(1:2:94).senderend]-pulse; % waiting as a sender (receiver planning)
    onsets{10} = [data.event(1:2:94).receiverstart]-pulse; % observing as a sender (receiver moving)

    onsets{11} = [data.event(2:2:94).goalconfiguration]-pulse; % waiting as a receiver (sender planning)
    onsets{12} = [data.event(2:2:94).senderend]-pulse; % planning as a receiver
    onsets{13} = [data.event(2:2:94).receiverstart]-pulse; % moving as a receiver

    onsets{14} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{15} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback

    onsets{16} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{17} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback

    % durations of non-interest
    durations{7} = [data.event(1:1:94).goalconfiguration]-[data.event(1:1:94).roleassignment]; % role assignment (ITI) & token assignment

    durations{8} = [data.event(1:2:94).senderend]-[data.event(1:2:94).senderstart]; % moving as a sender
    durations{9} = [data.event(1:2:94).receiverstart]-[data.event(1:2:94).senderend]; % waiting as a sender (receiver planning)
    durations{10} = [data.event(1:2:94).receiverend]-[data.event(1:2:94).receiverstart]; % observing as a sender (receiver moving)

    durations{11} = [data.event(2:2:94).senderstart]-[data.event(2:2:94).goalconfiguration]; % waiting as a receiver (sender planning)
    durations{12} = [data.event(2:2:94).receiverstart]-[data.event(2:2:94).senderend]; % planning as a receiver
    durations{13} = [data.event(2:2:94).receiverend]-[data.event(2:2:94).receiverstart]; % moving as a receiver

    durations{14} = .5;
    durations{15} = .5;
    
elseif player == 2 % Prisma, player 2 started as receiver
    
    if pair == 71 % sub-141 roles were reversed, this was player 1 and was scanned on prisma
        pulse = cell2mat(struct2cell(data.prismafit(1)));
     elseif subjnr == 150 % first two trials excluded due to mirrored screens
        first_pulse = cell2mat(struct2cell(data.prisma(1)));
        first_scan = 37*1.5;
        pulse = first_pulse+first_scan;
    else
        pulse = cell2mat(struct2cell(data.prisma(1)));
    end

    % novel and known trials for sender and receiver roles
    known_indx_sender=find(data.trial(2:2:94,2)==1); % known trials as a sender
    novel_indx_sender=find(data.trial(2:2:94,2)==2); % novel trials as a sender
    known_indx_receiver=find(data.trial(1:2:94,2)==1); % known trials as a receiver
    novel_indx_receiver=find(data.trial(1:2:94,2)==2); % novel trials as a receiver
    
    % planning as a sender
    senderPlan = [data.event(2:2:94).goalconfiguration]-pulse; % onsets
    dur_senderPlan = [data.event(2:2:94).senderstart]-[data.event(2:2:94).goalconfiguration]; % durations
    
    % planning as a sender - known trials
    onsets{1} = senderPlan(known_indx_sender); % onsets - known trials
    durations{1} = dur_senderPlan(known_indx_sender); % durations - known trials;

    % planning as a sender - novel trials - first half
    onsets{2} = senderPlan(novel_indx_sender); % onsets - novel trials (first half)
    durations{2} = dur_senderPlan(novel_indx_sender)/2; % durations - novel trials (first half)

    % planning as a sender - novel trials - second half
    onsets{3} = senderPlan(novel_indx_sender) + (dur_senderPlan(novel_indx_sender)/2); % onsets - novel trials (second half)
    durations{3} = dur_senderPlan(novel_indx_sender)/2; % durations - novel trials (second half)
   
    % observig as a receiver
    receiverObserv = [data.event(1:2:94).senderstart]-pulse; % observing as a receiver (sender moving)
    dur_receiverObserv = [data.event(1:2:94).senderend]-[data.event(1:2:94).senderstart];

    % observing as a receiver - known trials
    onsets{4} = receiverObserv(known_indx_receiver); % onsets - known trials
    durations{4} = dur_receiverObserv(known_indx_receiver); % durations - known trials

    % observing as a receiver - novel trials - first half
    onsets{5} = receiverObserv(novel_indx_receiver); % onsets - novel trials (first half)
    durations{5} = dur_receiverObserv(novel_indx_receiver)/2; % durations - novel trials (first half)
 
    % observing as a receiver - novel trials - second half
    onsets{6} = receiverObserv(novel_indx_receiver) + (dur_receiverObserv(novel_indx_receiver)/2); % onsets - novel trials (second half)
    durations{6} = dur_receiverObserv(novel_indx_receiver)/2; % durations - novel trials (second half)   

    % events of non-interest
    onsets{7} = [data.event(1:1:94).roleassignment]-pulse; % role assignment (ITI) & token assignment

    onsets{8} = [data.event(2:2:94).senderstart]-pulse; % moving as a sender
    onsets{9} = [data.event(2:2:94).senderend]-pulse; % waiting as a sender (receiver planning)
    onsets{10} = [data.event(2:2:94).receiverstart]-pulse; % observing as a sender (receiver moving)

    onsets{11} = [data.event(1:2:94).goalconfiguration]-pulse; % waiting as a receiver (sender planning)
    onsets{12} = [data.event(1:2:94).senderend]-pulse; % planning as a receiver
    onsets{13} = [data.event(1:2:94).receiverstart]-pulse; % moving as a receiver

    onsets{14} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{15} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback

    % durations of non-interest
    durations{7} = [data.event(1:1:94).goalconfiguration]-[data.event(1:1:94).roleassignment]; % role assignment (ITI) & token assignment

    durations{8} = [data.event(2:2:94).senderend]-[data.event(2:2:94).senderstart]; % moving as a sender
    durations{9} = [data.event(2:2:94).receiverstart]-[data.event(2:2:94).senderend]; % waiting as a sender (receiver planning)
    durations{10} = [data.event(2:2:94).receiverend]-[data.event(2:2:94).receiverstart]; % observing as a sender (receiver moving)

    durations{11} = [data.event(1:2:94).senderstart]-[data.event(1:2:94).goalconfiguration]; % waiting as a receiver (sender planning)
    durations{12} = [data.event(1:2:94).receiverstart]-[data.event(1:2:94).senderend]; % planning as a receiver
    durations{133} = [data.event(1:2:94).receiverend]-[data.event(1:2:94).receiverstart]; % moving as a receiver

    durations{14} = .5;
    durations{15} = .5;
end

%% store info in matfile 

regr_dir = fullfile(cfg.dir.preproc, cfg.subj,'ses-tcg/mri', cfg.dir.regr);
if ~exist(regr_dir,'dir'); mkdir(regr_dir); end

save (fullfile(regr_dir,[cfg.prefix.cond,'_tcg_', subj]),'names','onsets','durations');
%==========================================================================
