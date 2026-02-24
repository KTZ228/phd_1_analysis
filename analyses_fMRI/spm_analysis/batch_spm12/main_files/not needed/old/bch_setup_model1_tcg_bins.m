function [cfg] = bch_setup_model1_tcg_bins(cfg)
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
names = {'Sender Known trials 1', 'Sender Known trials 2', 'Sender Known trials 3', 'Sender Known trials 4', 'Sender Known trials 5', 'Sender Known trials 6',...
         'Sender Known trials 7', 'Sender Known trials 8', 'Sender Known trials 9', 'Sender Known trials 10', 'Sender Known trials 11',...
         'Sender Novel trials 1', 'Sender Novel trials 2', 'Sender Novel trials 3', 'Sender Novel trials 4', 'Sender Novel trials 5',...
         'Sender Novel trials 6', 'Sender Novel trials 7', 'Sender Novel trials 8', 'Sender Novel trials 9', 'Sender Novel trials 10',...
         'Receiver Known trials 1', 'Receiver Known trials 2', 'Receiver Known trials 3', 'Receiver Known trials 4', 'Receiver Known trials 5', 'Sender Known trials 6',...
         'Receiver Known trials 7', 'Receiver Known trials 8', 'Receiver Known trials 9', 'Receiver Known trials 10', 'ReceiverKnown trials 11',...
         'Receiver Novel trials 1', 'Receiver Novel trials 2', 'Receiver Novel trials 3', 'Receiver Novel trials 4', 'Receiver Novel trials 5',...
         'Receiver Novel trials 6', 'Receiver Novel trials 7', 'Receiver Novel trials 8', 'ReceiverNovel trials 9', 'Receiver Novel trials 10',...
         'Token assignment','Moving as Sender','Waiting as Sender','Observing as Sender','Waiting as Receiver','Planning as Receiver','Moving as Receiver',...
         'Positive Feedback','Negative Feedback'};

% event onsets and durations
if player == 1 % PrismaFit, player 1 started as sender
  
    % get scanner onset
    pulse = cell2mat(struct2cell(data.prismafit(1)));
    
    % novel and known trials for sender and receiver roles
    known_indx_sender=find(data.trial(1:2:94,2)==1); % known trials as a sender
    novel_indx_sender=find(data.trial(1:2:94,2)==2); % novel trials as a sender
    known_indx_receiver=find(data.trial(2:2:94,2)==1); % known trials as a receiver
    novel_indx_receiver=find(data.trial(2:2:94,2)==2); % novel trials as a receiver 
    
    % events of interest
    % known blocks sender
    senderPlan = [data.event(1:2:94).goalconfiguration]-pulse; % planning as a sender 

    known_blocks_sender = find(diff(known_indx_sender)==1);
    known_blocks_sender = [known_blocks_sender, known_blocks_sender+1];
    known_blocks_sender_indx = known_indx_sender(known_blocks_sender);

    for i = 1: size(known_blocks_sender_indx,1)
       onsets{i} =  senderPlan(known_blocks_sender_indx(i,:));
    end

    % novel blocks sender
    onsets{12} = senderPlan(:,3:5); % novel block 1 - sender
    onsets{13} = senderPlan(:,8:9); % novel block 2 - sender
    onsets{14} = senderPlan(:,12:14); % novel block 3 - sender
    onsets{15} = senderPlan(:,17:18); % novel block 4 - sender
    onsets{16} = senderPlan(:,21:23); % novel block 5 - sender
    onsets{17} = senderPlan(:,26:27); % novel block 6 - sender
    onsets{18} = senderPlan(:,30:32); % novel block 7 - sender
    onsets{19} = senderPlan(:,35:36); % novel block 8 - sender
    onsets{20} = senderPlan(:,39:41); % novel block 9 - sender
    onsets{21} = senderPlan(:,44:45); % novel block 10 - sender
     
    % known blocks receiver
    receiverObserv = [data.event(2:2:94).senderstart]-pulse; % observing as a receiver (sender moving)
 
    known_blocks_receiver = find(diff(known_indx_receiver)==1);
    known_blocks_receiver = [known_blocks_receiver, known_blocks_receiver+1];
    known_blocks_receiver_indx = known_indx_receiver(known_blocks_receiver);

    for i = 1: size(known_blocks_receiver_indx,1)
       onsets{i+21} =  receiverObserv(known_blocks_receiver_indx(i,:));
    end

    % novel blocks receiver
    onsets{33} = receiverObserv(:,3:4); % novel block 1 - receiver
    onsets{34} = receiverObserv(:,7:9); % novel block 2 - receiver
    onsets{35} = receiverObserv(:,12:13); % novel block 3 - receiver
    onsets{36} = receiverObserv(:,16:18); % novel block 4 - receiver
    onsets{37} = receiverObserv(:,21:22); % novel block 5 - receiver
    onsets{38} = receiverObserv(:,25:27); % novel block 6 - receiver
    onsets{39} = receiverObserv(:,30:31); % novel block 7 - receiver
    onsets{40} = receiverObserv(:,34:36); % novel block 8 - receiver
    onsets{41} = receiverObserv(:,39:40); % novel block 9 - receiver
    onsets{42} = receiverObserv(:,43:45); % novel block 10 - receiver
        
    % events of non-interest
    onsets{43} = [data.event(1:1:94).tokenassignment]-pulse; % token assignment 
    onsets{44} = [data.event(1:2:94).senderstart]-pulse; % moving as a sender
    onsets{45} = [data.event(1:2:94).senderend]-pulse; % waiting as a sender (receiver planning)
    onsets{46} = [data.event(1:2:94).receiverstart]-pulse; % observing as a sender (receiver moving)
    
    onsets{47} = [data.event(2:2:94).goalconfiguration]-pulse; % waiting as a receiver (sender planning)
    onsets{48} = [data.event(2:2:94).senderend]-pulse; % planning as a receiver
    onsets{49} = [data.event(2:2:94).receiverstart]-pulse; % moving as a receiver
    
    onsets{50} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{51} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback

    % durations of interest
    % known blocks sender
    dur_senderPlan = [data.event(1:2:94).senderstart]-[data.event(1:2:94).goalconfiguration];
    
    for i = 1: size(known_blocks_sender_indx,1)
       durations{i} =  dur_senderPlan(known_blocks_sender_indx(i,:));
    end
    
    % novel blocks sender
    durations{12} = dur_senderPlan(:,3:5); % novel block 1 - sender
    durations{13} = dur_senderPlan(:,8:9); % novel block 2 - sender
    durations{14} = dur_senderPlan(:,12:14); % novel block 3 - sender
    durations{15} = dur_senderPlan(:,17:18); % novel block 4 - sender
    durations{16} = dur_senderPlan(:,21:23); % novel block 5 - sender
    durations{17} = dur_senderPlan(:,26:27); % novel block 6 - sender
    durations{18} = dur_senderPlan(:,30:32); % novel block 7 - sender
    durations{19} = dur_senderPlan(:,35:36); % novel block 8 - sender
    durations{20} = dur_senderPlan(:,39:41); % novel block 9 - sender
    durations{21} = dur_senderPlan(:,44:45); % novel block 10 - sender
     
    % known blocks receiver
    dur_receiverObserv = [data.event(2:2:94).senderend]-[data.event(2:2:94).senderstart];
    
    for i = 1: size(known_blocks_receiver_indx,1)
       durations{i+21} =  dur_receiverObserv(known_blocks_receiver_indx(i,:));
    end

    % novel blocks receiver
    durations{33} = dur_receiverObserv(:,3:4); % novel block 1 - receiver
    durations{34} = dur_receiverObserv(:,7:9); % novel block 2 - receiver
    durations{35} = dur_receiverObserv(:,12:13); % novel block 3 - receiver
    durations{36} = dur_receiverObserv(:,16:18); % novel block 4 - receiver
    durations{37} = dur_receiverObserv(:,21:22); % novel block 5 - receiver
    durations{38} = dur_receiverObserv(:,25:27); % novel block 6 - receiver
    durations{39} = dur_receiverObserv(:,30:31); % novel block 7 - receiver
    durations{40} = dur_receiverObserv(:,34:36); % novel block 8 - receiver
    durations{41} = dur_receiverObserv(:,39:40); % novel block 9 - receiver
    durations{42} = dur_receiverObserv(:,43:45); % novel block 10 - receiver
        
    % events of non-interest
    durations{43} = [data.event(1:1:94).goalconfiguration]-[data.event(1:1:94).tokenassignment]; % token assignment 
    durations{44} = [data.event(1:2:94).senderend]-[data.event(1:2:94).senderstart]; % moving as a sender
    durations{45} = [data.event(1:2:94).receiverstart]-[data.event(1:2:94).senderend]; % waiting as a sender (receiver planning)
    durations{46} = [data.event(1:2:94).receiverend]-[data.event(1:2:94).receiverstart]; % observing as a sender (receiver moving)
    
    durations{47} = [data.event(2:2:94).senderstart]-[data.event(2:2:94).goalconfiguration]; % waiting as a receiver (sender planning)
    durations{48} = [data.event(2:2:94).receiverstart]-[data.event(2:2:94).senderend]; % planning as a receiver
    durations{49} = [data.event(2:2:94).receiverend]-[data.event(2:2:94).receiverstart]; % moving as a receiver
   
    durations{50} = .5;
    durations{51} = .5;

    elseif player == 2 % Prisma, player 2 started as receiver
    
    % get scanner onset
    pulse = cell2mat(struct2cell(data.prisma(1)));
        
    % novel and known trials for sender and receiver roles
    known_indx_sender=find(data.trial(2:2:94,2)==1); % knwon trials as a sender
    novel_indx_sender=find(data.trial(2:2:94,2)==2); % novel trials as a sender
    known_indx_receiver=find(data.trial(1:2:94,2)==1); % known trials as a receiver
    novel_indx_receiver=find(data.trial(1:2:94,2)==2); % novel trials as a receiver
    
    % events of interest
    % known blocks sender
    senderPlan =[data.event(2:2:94).goalconfiguration]-pulse; % planning as a sender
    
    known_blocks_sender = find(diff(known_indx_sender)==1);
    known_blocks_sender = [known_blocks_sender, known_blocks_sender+1];
    known_blocks_sender_indx = known_indx_sender(known_blocks_sender);

    for i = 1: size(known_blocks_sender_indx,1)
       onsets{i} =  senderPlan(known_blocks_sender_indx(i,:));
    end

    % novel blocks sender
    onsets{12} = senderPlan(:,3:4); % novel block 1 - sender
    onsets{13} = senderPlan(:,7:9); % novel block 2 - sender
    onsets{14} = senderPlan(:,12:13); % novel block 3 - sender
    onsets{15} = senderPlan(:,16:18); % novel block 4 - sender
    onsets{16} = senderPlan(:,21:22); % novel block 5 - sender
    onsets{17} = senderPlan(:,25:27); % novel block 6 - sender
    onsets{18} = senderPlan(:,30:31); % novel block 7 - sender
    onsets{19} = senderPlan(:,34:36); % novel block 8 - sender
    onsets{20} = senderPlan(:,39:40); % novel block 9 - sender
    onsets{21} = senderPlan(:,43:45); % novel block 10 - sender 
    
    % known blocks receiver
    receiverObserv = [data.event(1:2:94).senderstart]-pulse; % observing as a receiver (sender moving)
    
    known_blocks_receiver = find(diff(known_indx_receiver)==1);
    known_blocks_receiver = [known_blocks_receiver, known_blocks_receiver+1];
    known_blocks_receiver_indx = known_indx_receiver(known_blocks_receiver);

    for i = 1: size(known_blocks_receiver_indx,1)
       onsets{i+21} =  receiverObserv(known_blocks_receiver_indx(i,:));
    end

    % novel blocks receiver
    onsets{33} = receiverObserv(:,3:5); % novel block 1 - receiver
    onsets{34} = receiverObserv(:,8:9); % novel block 2 - receiver
    onsets{35} = receiverObserv(:,12:14); % novel block 3 - receiver
    onsets{36} = receiverObserv(:,17:18); % novel block 4 - receiver
    onsets{37} = receiverObserv(:,21:23); % novel block 5 - receiver
    onsets{38} = receiverObserv(:,26:27); % novel block 6 - receiver
    onsets{39} = receiverObserv(:,30:32); % novel block 7 - receiver
    onsets{40} = receiverObserv(:,35:36); % novel block 8 - receiver
    onsets{41} = receiverObserv(:,39:41); % novel block 9 - receiver
    onsets{42} = receiverObserv(:,44:45); % novel block 10 - receiver
       
    % events of non-interest
    onsets{43} = [data.event(1:1:94).tokenassignment]-pulse; % token assignment
    onsets{44} = [data.event(2:2:94).senderstart]-pulse; % moving as a sender
    onsets{45} = [data.event(2:2:94).senderend]-pulse; % waiting as a sender (receiver planning)
    onsets{46} = [data.event(2:2:94).receiverstart]-pulse; % observing as a sender (receiver moving)
    onsets{47} = [data.event(1:2:94).goalconfiguration]-pulse; % waiting as a receiver (sender planning)
    onsets{48} = [data.event(1:2:94).senderend]-pulse; % planning as a receiver
    onsets{49} = [data.event(1:2:94).receiverstart]-pulse; % moving as a receiver
    
    onsets{50} = [data.event(data.trial(:,16)==1).feedback]-pulse; % positive feedback
    onsets{51} = [data.event(data.trial(:,16)==0).feedback]-pulse; % negative feedback
    
    % durations of interest
    % known blocks sender
    dur_senderPlan = [data.event(2:2:94).senderstart]-[data.event(2:2:94).goalconfiguration]; % planning as a sender % CHECK: was data.event(1:2:85).goalconf

    for i = 1: size(known_blocks_sender_indx,1)
       durations{i} =  dur_senderPlan(known_blocks_sender_indx(i,:));
    end
    
    % novel blocks sender
    durations{12} = dur_senderPlan(:,3:4); % novel block 1 - sender
    durations{13} = dur_senderPlan(:,7:9); % novel block 2 - sender
    durations{14} = dur_senderPlan(:,12:13); % novel block 3 - sender
    durations{15} = dur_senderPlan(:,16:18); % novel block 4 - sender
    durations{16} = dur_senderPlan(:,21:22); % novel block 5 - sender
    durations{17} = dur_senderPlan(:,25:27); % novel block 6 - sender
    durations{18} = dur_senderPlan(:,30:31); % novel block 7 - sender
    durations{19} = dur_senderPlan(:,34:36); % novel block 8 - sender
    durations{20} = dur_senderPlan(:,39:40); % novel block 9 - sender
    durations{21} = dur_senderPlan(:,43:45); % novel block 10 - sender
     
    % known blocks receiver
    dur_receiverObserv = [data.event(1:2:94).senderend]-[data.event(1:2:94).senderstart]; % observing as a receiver (sender moving) % CHECK: was data.event(2:2:85).senderstart
   
    for i = 1: size(known_blocks_receiver_indx,1)
       durations{i+21} =  dur_receiverObserv(known_blocks_receiver_indx(i,:));
    end

    % novel blocks receiver
    durations{33} = dur_receiverObserv(:,3:5); % novel block 1 - receiver
    durations{34} = dur_receiverObserv(:,8:9); % novel block 2 - receiver
    durations{35} = dur_receiverObserv(:,12:14); % novel block 3 - receiver
    durations{36} = dur_receiverObserv(:,17:18); % novel block 4 - receiver
    durations{37} = dur_receiverObserv(:,21:23); % novel block 5 - receiver
    durations{38} = dur_receiverObserv(:,26:27); % novel block 6 - receiver
    durations{39} = dur_receiverObserv(:,30:32); % novel block 7 - receiver
    durations{40} = dur_receiverObserv(:,35:36); % novel block 8 - receiver
    durations{41} = dur_receiverObserv(:,39:41); % novel block 9 - receiver
    durations{42} = dur_receiverObserv(:,44:45); % novel block 10 - receiver
      
    % durations of non-interest
    durations{43} = [data.event(1:1:94).goalconfiguration]-[data.event(1:1:94).tokenassignment]; % token assignment    
    durations{44} = [data.event(2:2:94).senderend]-[data.event(2:2:94).senderstart]; % moving as a sender
    durations{45} = [data.event(2:2:94).receiverstart]-[data.event(2:2:94).senderend]; % waiting as a sender (receiver planning)
    durations{46} = [data.event(2:2:94).receiverend]-[data.event(2:2:94).receiverstart]; % observing as a sender (receiver moving) 
    durations{47} = [data.event(1:2:94).senderstart]-[data.event(1:2:94).goalconfiguration]; % waiting as a receiver (sender planning)
    durations{48} = [data.event(1:2:94).receiverstart]-[data.event(1:2:94).senderend]; % planning as a receiver
    durations{49} = [data.event(1:2:94).receiverend]-[data.event(1:2:94).receiverstart]; % moving as a receiver
    
    durations{50} = .5;
    durations{51} = .5;

end

%% store info in matfile 
regr_dir = fullfile(cfg.fmri.root, cfg.subj, cfg.dir.regr);
if ~exist(regr_dir,'dir'); mkdir(regr_dir); end

save (fullfile(regr_dir,[cfg.prefix.cond,'_tcg_', subj]),'names','onsets','durations');
%==========================================================================