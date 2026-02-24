function [cfg] = bch_setup_model1_tcg_blocks_bins(cfg)
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

% Trialnumbers corresponding to different trial types

% accuracy for known and novel blocks
known_block = zeros(20,1);
novel_block_sender = zeros(25,1); novel_block_receiver = zeros(25,1);

% read logile
subjnr = str2num(subj(5:end));

z = (-1)^subjnr;
if z == -1 % subjnr is odd --> player 1
    pair = round(subjnr/2);
    player = 1;
    data = read_logfile_tcg_fMRI(fullfile(cfg.fmri.root,cfg.subj,cfg.dir.beh,['t' num2str(pair) 'p' num2str(subjnr) '_tcg_ASD_scanning.txt']));
else % subjnr = even --> player 2
    pair = subjnr/2;
    player = 2;
    subjnr_player1 = subjnr-1;
    data = read_logfile_tcg_fMRI(fullfile(cfg.fmri.root,cfg.subj,cfg.dir.beh,['t' num2str(pair) 'p' num2str(subjnr_player1) '_tcg_ASD_scanning.txt']));
end

% event names
names = {'Known block 1','Known block 2', 'Known block 3', 'Known block 4', 'Known block 5', 'Known block 6', 'Known block 7', 'Known block 8', 'Known block 9', 'Known block 10', 'Known block 11',...
    'Novel block 1','Novel block 2','Novel block 3', 'Novel block 4', 'Novel block 5', 'Novel block 6', 'Novel block 7', 'Novel block 8', 'Novel block 9', 'Novel block 10',...
    'Role and token assignment', 'Moving as a sender', 'Waiting as a sender', 'Observing as a sender',...
    'Waiting as a receiver', 'Planning as a receiver', 'Moving as a receiver', 'Positive feedback', 'Negative feedback'};

% event onsets and durations
if player == 1 % PrismaFit, player 1 started as sender
    
    % get scanner onset
    pulse = cell2mat(struct2cell(data.prismafit(1)));
    
    % events of interest
    known_begin = (1:9:94); known_end = known_begin+3; % blocks of 4 trials
    novel_begin = (5:9:90); novel_end = novel_begin+4; % blocks of 5 trials
    
    for k = 1:length(known_begin)
        onsets{k} = [data.event(known_begin(k)).roleassignment]-pulse; % known blocks - onsets
    end
    
    for n = 1:length(novel_begin)
        onsets{end+1} = [data.event(novel_begin(n)).roleassignment]-pulse; % novel blocks - onsets
    end
    
    % events of non-interest
    onsets{end+1} = [data.event(1:1:94).roleassignment]-pulse; % role and token assignment 
    onsets{end+1} = [data.event(1:2:94).senderstart]-pulse; % moving as a sender
    onsets{end+1} = [data.event(1:2:94).senderend]-pulse; % waiting as a sender (receiver planning)
    onsets{end+1} = [data.event(1:2:94).receiverstart]-pulse; % observing as a sender (receiver moving)
    
    onsets{end+1} = [data.event(2:2:94).goalconfiguration]-pulse; % waiting as a receiver (sender planning)
    onsets{end+1} = [data.event(2:2:94).senderend]-pulse; % planning as a receiver
    onsets{end+1} = [data.event(2:2:94).receiverstart]-pulse; % moving as a receiver
    
    onsets{end+1} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{end+1} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback

    % durations
    for k = 1:length(known_begin)
        durations{k} = [data.event(known_end(k)).feedback]-[data.event(known_begin(k)).roleassignment];
    end

    for n = 1:length(novel_begin)
        durations{end+1} = [data.event(novel_end(n)).feedback]-[data.event(novel_begin(n)).roleassignment];
    end

    % events of non-interest
    durations{end+1} = [data.event(1:1:94).goalconfiguration]-[data.event(1:1:94).roleassignment]; % role and token assignment 
    durations{end+1} = [data.event(1:2:94).senderend]-[data.event(1:2:94).senderstart]; % moving as a sender
    durations{end+1} = [data.event(1:2:94).receiverstart]-[data.event(1:2:94).senderend]; % waiting as a sender (receiver planning)
    durations{end+1} = [data.event(1:2:94).receiverend]-[data.event(1:2:94).receiverstart]; % observing as a sender (receiver moving)
    
    durations{end+1} = [data.event(2:2:94).senderstart]-[data.event(2:2:94).goalconfiguration]; % waiting as a receiver (sender planning)
    durations{end+1} = [data.event(2:2:94).receiverstart]-[data.event(2:2:94).senderend]; % planning as a receiver
    durations{end+1} = [data.event(2:2:94).receiverend]-[data.event(2:2:94).receiverstart]; % moving as a receiver
   
    durations{end+1} = .5;
    durations{end+1} = .5;

elseif player == 2 % Prisma, player 2 started as receiver
    
    % get scanner onset
    pulse = cell2mat(struct2cell(data.prisma(1)));
        
    % events of interest
    known_begin = (1:9:94); known_end = known_begin+3; % blocks of 4 trials
    novel_begin = (5:9:90); novel_end = novel_begin+4; % blocks of 5 trials

    for k = 1:length(known_begin)
        onsets{k} = [data.event(known_begin(k)).roleassignment]-pulse; % known blocks - onsets
    end
    
    for n = 1:length(novel_begin)
        onsets{end+1} = [data.event(novel_begin(n)).roleassignment]-pulse; % novel blocks - onsets
    end

     % events of non-interest
    onsets{end+1} = [data.event(1:1:94).roleassignment]-pulse; % role and token assignment
    onsets{end+1} = [data.event(2:2:94).senderstart]-pulse; % moving as a sender
    onsets{end+1} = [data.event(2:2:94).senderend]-pulse; % waiting as a sender (receiver planning)
    onsets{end+1} = [data.event(2:2:94).receiverstart]-pulse; % observing as a sender (receiver moving)
    onsets{end+1} = [data.event(1:2:94).goalconfiguration]-pulse; % waiting as a receiver (sender planning)
    onsets{end+1} = [data.event(1:2:94).senderend]-pulse; % planning as a receiver
    onsets{end+1} = [data.event(1:2:94).receiverstart]-pulse; % moving as a receiver
    
    onsets{end+1} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{end+1} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback
    
    % durations
    for k = 1:length(known_begin)
        durations{k} = [data.event(known_end(k)).feedback]-[data.event(known_begin(k)).roleassignment];
    end

    for n = 1:length(novel_begin)
        durations{end+1} = [data.event(novel_end(n)).feedback]-[data.event(novel_begin(n)).roleassignment];
    end

    % durations of non-interest
    durations{end+1} = [data.event(1:1:94).goalconfiguration]-[data.event(1:1:94).roleassignment]; % role and token assignment    
    durations{end+1} = [data.event(2:2:94).senderend]-[data.event(2:2:94).senderstart]; % moving as a sender
    durations{end+1} = [data.event(2:2:94).receiverstart]-[data.event(2:2:94).senderend]; % waiting as a sender (receiver planning)
    durations{end+1} = [data.event(2:2:94).receiverend]-[data.event(2:2:94).receiverstart]; % observing as a sender (receiver moving) 
    durations{end+1} = [data.event(1:2:94).senderstart]-[data.event(1:2:94).goalconfiguration]; % waiting as a receiver (sender planning)
    durations{end+1} = [data.event(1:2:94).receiverstart]-[data.event(1:2:94).senderend]; % planning as a receiver
    durations{end+1} = [data.event(1:2:94).receiverend]-[data.event(1:2:94).receiverstart]; % moving as a receiver
    
    durations{end+1} = .5;
    durations{end+1} = .5;

end

%% store info in matfile 
regr_dir = fullfile(cfg.fmri.root, cfg.subj, cfg.dir.regr);
if ~exist(regr_dir,'dir'); mkdir(regr_dir); end

save (fullfile(regr_dir,[cfg.prefix.cond,'_tcg_', subj]),'names','onsets','durations');
%==========================================================================
