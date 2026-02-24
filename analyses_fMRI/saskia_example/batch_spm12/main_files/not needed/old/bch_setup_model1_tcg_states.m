function [cfg] = bch_setup_model1_tcg_states(cfg)
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
%Version 2007-11-14
%
% adapted for SPM8 wrapper by Inge Volman, March 2012.
% ATyb June 2013
%--------------------------------------------------------------------------
subj = cfg.subj;
cfg = preproc_taskregressors(cfg,subj);

%==========================================================================

function cfg = preproc_taskregressors(cfg,subj)


% read logile
pair = subj(5:end-1);
player = str2num(subj(end));

data = read_logfile_tcg(fullfile(cfg.bids.root,cfg.subj,cfg.dir.beh,['pair' pair '_tcg_ASD_scanning.txt'])); % directory to original logfile (bids/subj/beh)

% event names

names = {'Known state', 'Novel state', 'Planning as Sender','Observing as Receiver',...
   'Role assignment', 'Token assignment',...
  'Moving as Sender','Waiting as Sender','Observing as Sender',...
  'Waiting as Receiver','Planning as Receiver','Moving as Receiver',...
  'Positive Feedback','Negative Feedback'};

% event onsets and durations
if player == 1 % PrismaFit, player 1 started as sender
  
    % get scanner onset
    pulse = cell2mat(struct2cell(data.prismafit(1)));
    
    % known & novel states
    known_indx = find(data.trial(1:1:85,2)==1); % find known trials
    novel_indx = find(data.trial(1:1:85,2)==2); % find novel trials
    
    onsets{1} = [data.event(known_indx(1:4:end)).roleassignment]-pulse; % known blocks
    onsets{2} = [data.event(novel_indx(1:5:end)).roleassignment]-pulse; % novel blocks
    
    % events of non-interest
    onsets{3} = [data.event(1:2:85).goalconfiguration]-pulse; % planning as a sender
    onsets{4} = [data.event(2:2:85).senderstart]-pulse; % observing as a receiver (sender moving)
    
    onsets{5} = [data.event(1:1:85).roleassignment]-pulse; % role assignment (ITI)
    onsets{6} = [data.event(1:1:85).tokenassignment]-pulse; % token assignment
       
    onsets{7} = [data.event(1:2:85).senderstart]-pulse; % moving as a sender
    onsets{8} = [data.event(1:2:85).senderend]-pulse; % waiting as a sender (receiver planning)
    onsets{9} = [data.event(1:2:85).receiverstart]-pulse; % observing as a sender (receiver moving)
    
    onsets{10} = [data.event(2:2:85).goalconfiguration]-pulse; % waiting as a receiver (sender planning)
    onsets{11} = [data.event(2:2:85).senderend]-pulse; % planning as a receiver
    onsets{12} = [data.event(2:2:85).receiverstart]-pulse; % moving as a receiver
    
    onsets{13} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{14} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback
   
    % durations of known & novel states
    durations{1} = ([data.event(known_indx(4:4:end)).feedback] + 0.5) -[data.event(known_indx(1:4:end)).roleassignment];
    durations{2} = ([data.event(novel_indx(5:5:end)).feedback] + 0.5) -[data.event(novel_indx(1:5:end)).roleassignment];
    
    % durations of non-interest
    durations{3} = [data.event(1:2:85).senderstart]-[data.event(1:2:85).goalconfiguration]; % planning as sender
    durations{4} = [data.event(2:2:85).senderend]-[data.event(2:2:85).senderstart]; % receiving as receiver (sender moving)
    
    if strcmp(pair,'101')
        durations{4}(16) = 6.9413;
    end
    
    % FIXME: For first pilot (pair 101), this duration{4} somehow has an
    % entry longer than 10 sec (16 sec) - perhaps missing a 'senderend' in the logfile
    % Quick fix: replaced this duration (16 secs) with mean duration of
    % other trials (in receiver observing novel)
    % durations{4}(16) = 6.9413; For first pilot (pair 101)
        
    durations{5} = [data.event(1:1:85).tokenassignment]-[data.event(1:1:85).roleassignment]; % role assignment (ITI)
    durations{6} = [data.event(1:1:85).goalconfiguration]-[data.event(1:1:85).tokenassignment]; % token assignment
    
    durations{7} = [data.event(1:2:85).senderend]-[data.event(1:2:85).senderstart]; % moving as a sender
    durations{8} = [data.event(1:2:85).receiverstart]-[data.event(1:2:85).senderend]; % waiting as a sender (receiver planning)
    durations{9} = [data.event(1:2:85).receiverend]-[data.event(1:2:85).receiverstart]; % observing as a sender (receiver moving)
    
    durations{10} = [data.event(2:2:85).senderstart]-[data.event(2:2:85).goalconfiguration]; % waiting as a receiver (sender planning)
    durations{11} = [data.event(2:2:85).receiverstart]-[data.event(2:2:85).senderend]; % planning as a receiver
    durations{12} = [data.event(2:2:85).receiverend]-[data.event(2:2:85).receiverstart]; % moving as a receiver
    
    durations{13} = .5;
    durations{14} = .5;
    
elseif player == 2 % Prisma, player 2 started as receiver
    
    % get scanner onset
    pulse = cell2mat(struct2cell(data.prisma(1)));
         
     % known & novel states
    known_indx = find(data.trial(1:1:85,2)==1); % find known trials
    novel_indx = find(data.trial(1:1:85,2)==2); % find novel trials
    
    onsets{1} = [data.event(known_indx(1:4:end)).roleassignment]-pulse; % known blocks
    onsets{2} = [data.event(novel_indx(1:5:end)).roleassignment]-pulse; % novel blocks
    
    % events of non-interest
    onsets{3} = [data.event(2:2:85).goalconfiguration]-pulse; % planning as a sender
    onsets{4} = [data.event(1:2:85).senderstart]-pulse; % observing as a receiver (sender moving)
    
    % events of non-interest
    onsets{5} = [data.event(1:1:85).roleassignment]-pulse; % role assignment (ITI)
    onsets{6} = [data.event(1:1:85).tokenassignment]-pulse; % token assignment
    
    onsets{7} = [data.event(2:2:85).senderstart]-pulse; % moving as a sender
    onsets{8} = [data.event(2:2:85).senderend]-pulse; % waiting as a sender (receiver planning)
    onsets{9} = [data.event(2:2:85).receiverstart]-pulse; % observing as a sender (receiver moving)
    
    onsets{10} = [data.event(1:2:85).goalconfiguration]-pulse; % waiting as a receiver (sender planning)
    onsets{11} = [data.event(1:2:85).senderend]-pulse; % planning as a receiver
    onsets{12} = [data.event(1:2:85).receiverstart]-pulse; % moving as a receiver
    
    onsets{13} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{14} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback
    
    % durations of known & novel states
    durations{1} = ([data.event(known_indx(4:4:end)).feedback] + 0.5) -[data.event(known_indx(1:4:end)).roleassignment];
    durations{2} = ([data.event(novel_indx(5:5:end)).feedback] + 0.5) -[data.event(novel_indx(1:5:end)).roleassignment];
    
    % durations of non-interest
    durations{3} = [data.event(2:2:85).senderstart]-[data.event(2:2:85).goalconfiguration]; % planning as sender
    durations{4} = [data.event(1:2:85).senderend]-[data.event(1:2:85).senderstart]; % observing as receiver (sender moving)
    
    if strcmp(pair,'101')
        durations{4}(10) = 6.5612;
    end
    
    % FIXME: For first pilot (pair 101), this duration{4} somehow has an
    % entry longer than 10 sec (11 sec) - perhaps missing a 'senderend' in the logfile
    % Quick fix: replaced this duration (11 secs) with mean duration of
    % other trials (in receiver observing known)
    % durations{4}(10) = 6.5612; For first pilot (pair 101)
    
    % durations of non-interest
    durations{5} = [data.event(1:1:85).tokenassignment]-[data.event(1:1:85).roleassignment]; % role assignment (ITI)
    durations{6} = [data.event(1:1:85).goalconfiguration]-[data.event(1:1:85).tokenassignment]; % token assignment
    
    durations{7} = [data.event(2:2:85).senderend]-[data.event(2:2:85).senderstart]; % moving as a sender
    durations{8} = [data.event(2:2:85).receiverstart]-[data.event(2:2:85).senderend]; % waiting as a sender (receiver planning)
    durations{9} = [data.event(2:2:85).receiverend]-[data.event(2:2:85).receiverstart]; % observing as a sender (receiver moving)
    
    durations{10} = [data.event(1:2:85).senderstart]-[data.event(1:2:85).goalconfiguration]; % waiting as a receiver (sender planning)
    durations{11} = [data.event(1:2:85).receiverstart]-[data.event(1:2:85).senderend]; % planning as a receiver
    durations{12} = [data.event(1:2:85).receiverend]-[data.event(1:2:85).receiverstart]; % moving as a receiver
    
    durations{13} = .5;
    durations{14} = .5;
end

%% store info in matfile 

regr_dir = fullfile(cfg.fmri.root, cfg.subj, cfg.dir.regr);
if ~exist(regr_dir,'dir'); mkdir(regr_dir); end

save (fullfile(regr_dir,[cfg.prefix.cond,'_tcg_', subj]),'names','onsets','durations');
%==========================================================================
