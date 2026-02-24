function [cfg] = bch_setup_model1_tcg_blocks(cfg)
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
names = {'Known block', 'Novel block','Role and token assignment', 'Moving as a sender', 'Waiting as a sender', 'Observing as a sender',...
         'Waiting as a receiver', 'Planning as a receiver', 'Moving as a receiver', 'Positive feedback', 'Negative feedback'};

% event onsets and durations
if player == 1 % PrismaFit, player 1 started as sender
    
    % get scanner onset
    pulse = cell2mat(struct2cell(data.prismafit(1)));
    
    % events of interest
    known_begin = (1:9:94); known_end = known_begin+3; % blocks of 4 trials
    novel_begin = (5:9:90); novel_end = novel_begin+4; % blocks of 5 trials

    onsets{1} = [data.event(known_begin).roleassignment]-pulse; % known blocks - onsets
    onsets{2} = [data.event(novel_begin).roleassignment]-pulse; % novel blocks - onsets
    
    % events of non-interest
    onsets{3} = [data.event(1:1:94).roleassignment]-pulse; % role and token assignment 
    onsets{4} = [data.event(1:2:94).senderstart]-pulse; % moving as a sender
    onsets{5} = [data.event(1:2:94).senderend]-pulse; % waiting as a sender (receiver planning)
    onsets{6} = [data.event(1:2:94).receiverstart]-pulse; % observing as a sender (receiver moving)
    
    onsets{7} = [data.event(2:2:94).goalconfiguration]-pulse; % waiting as a receiver (sender planning)
    onsets{8} = [data.event(2:2:94).senderend]-pulse; % planning as a receiver
    onsets{9} = [data.event(2:2:94).receiverstart]-pulse; % moving as a receiver
    
    onsets{10} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{11} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback

    % durations   
    durations{1} = [data.event(known_end).feedback]-[data.event(known_begin).roleassignment];
    durations{2} = [data.event(novel_end).feedback]-[data.event(novel_begin).roleassignment];
   
    % events of non-interest
    durations{3} = [data.event(1:1:94).goalconfiguration]-[data.event(1:1:94).roleassignment]; % token assignment 
    durations{4} = [data.event(1:2:94).senderend]-[data.event(1:2:94).senderstart]; % moving as a sender
    durations{5} = [data.event(1:2:94).receiverstart]-[data.event(1:2:94).senderend]; % waiting as a sender (receiver planning)
    durations{6} = [data.event(1:2:94).receiverend]-[data.event(1:2:94).receiverstart]; % observing as a sender (receiver moving)
    
    durations{7} = [data.event(2:2:94).senderstart]-[data.event(2:2:94).goalconfiguration]; % waiting as a receiver (sender planning)
    durations{8} = [data.event(2:2:94).receiverstart]-[data.event(2:2:94).senderend]; % planning as a receiver
    durations{9} = [data.event(2:2:94).receiverend]-[data.event(2:2:94).receiverstart]; % moving as a receiver
   
    durations{10} = .5;
    durations{11} = .5;

elseif player == 2 % Prisma, player 2 started as receiver
    
    % get scanner onset
    pulse = cell2mat(struct2cell(data.prisma(1)));
        
    % events of interest
    known_begin = (1:9:94); known_end = known_begin+3; % blocks of 4 trials
    novel_begin = (5:9:90); novel_end = novel_begin+4; % blocks of 5 trials

    onsets{1} = [data.event(known_begin).roleassignment]-pulse; % known blocks - onsets
    onsets{2} = [data.event(novel_begin).roleassignment]-pulse; % novel blocks - onsets
    
    % events of non-interest
    onsets{3} = [data.event(1:1:94).roleassignment]-pulse; % role and token assignment
    onsets{4} = [data.event(2:2:94).senderstart]-pulse; % moving as a sender
    onsets{5} = [data.event(2:2:94).senderend]-pulse; % waiting as a sender (receiver planning)
    onsets{6} = [data.event(2:2:94).receiverstart]-pulse; % observing as a sender (receiver moving)
    onsets{7} = [data.event(1:2:94).goalconfiguration]-pulse; % waiting as a receiver (sender planning)
    onsets{8} = [data.event(1:2:94).senderend]-pulse; % planning as a receiver
    onsets{9} = [data.event(1:2:94).receiverstart]-pulse; % moving as a receiver
    
    onsets{10} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{11} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback
    
    % durations   
    durations{1} = [data.event(known_end).feedback]-[data.event(known_begin).roleassignment];
    durations{2} = [data.event(novel_end).feedback]-[data.event(novel_begin).roleassignment];
    
    % durations of non-interest
    durations{3} = [data.event(1:1:94).goalconfiguration]-[data.event(1:1:94).roleassignment]; % role and token assignment    
    durations{4} = [data.event(2:2:94).senderend]-[data.event(2:2:94).senderstart]; % moving as a sender
    durations{5} = [data.event(2:2:94).receiverstart]-[data.event(2:2:94).senderend]; % waiting as a sender (receiver planning)
    durations{6} = [data.event(2:2:94).receiverend]-[data.event(2:2:94).receiverstart]; % observing as a sender (receiver moving) 
    durations{7} = [data.event(1:2:94).senderstart]-[data.event(1:2:94).goalconfiguration]; % waiting as a receiver (sender planning)
    durations{8} = [data.event(1:2:94).receiverstart]-[data.event(1:2:94).senderend]; % planning as a receiver
    durations{9} = [data.event(1:2:94).receiverend]-[data.event(1:2:94).receiverstart]; % moving as a receiver
    
    durations{10} = .5;
    durations{11} = .5;

end

%% store info in matfile 
regr_dir = fullfile(cfg.fmri.root, cfg.subj, cfg.dir.regr);
if ~exist(regr_dir,'dir'); mkdir(regr_dir); end

save (fullfile(regr_dir,[cfg.prefix.cond,'_tcg_', subj]),'names','onsets','durations');
%==========================================================================

% 
%     % parametric modulation of accuracy
%     kbegin = [1:2:22]; kend = [2:2:22];
%     nbegin_sender = [1 4 6 9 11 14 16 19 21 24];
%     nend_sender = [3 5 8 10 13 15 18 20 23 25];
%     nbegin_receiver = [1 3 6 8 11 13 16 18 21 23];
%     nend_receiver = [2 5 7 10 12 15 17 20 22 25];
% 
%     % known blocks
%     for k = 1:10
%         known_block(kbegin(k):kend(k)) = mean(data.trial(nblock(k):nblock(k)+4,16));
%     end
% 
%     % interpolate novel accuracy for last block of known trials
%     x = [1:20];
%     v = known_block;
%     xq = [21 22];
%     known_interp = interp1(x,v,xq,'linear','extrap');
%     known_block = vertcat(known_block, known_interp');
% 
%     % novel blocks
%     for n = 1:length(nblock)
%         novel_block_sender(nbegin_sender(n):nend_sender(n)) = mean(data.trial(nblock(n):nblock(n)+4,16));
%         novel_block_receiver(nbegin_receiver(n):nend_receiver(n)) = mean(data.trial(nblock(n):nblock(n)+4,16));
%     end
% 
%     % parametric modulators for the first four regressors
%     pmod{1} = struct('name',{'accuracy_known'},'param',{known_block},'poly',{1});
%     pmod{2} = struct('name',{'accuracy_novel_sender'},'param',{novel_block_sender},'poly',{1});
%     pmod{3} = struct('name',{'accuracy_known'},'param',{known_block},'poly',{1});
%     pmod{4} = struct('name',{'accuracy_novel_receiver'},'param',{novel_block_receiver},'poly',{1});
