function [data] = read_logfile_tcg(logfile)

% --------------------------------------------------------
% READ_LOGFILE_TCG reads communication game logfiles, originating
% from either run_tcg.m or run_tcg_kids.m
%
% INPUT
% Use as: [data] = read_logfile_tcg(logfile)
% where logfile is a '*.txt' file
%
% OUTPUT
% A struct containing;
% info      recording file, date and onset, and game type
% trial     rows (trials) x columns (variables)
% label     variable names
% event     onsets and durations of task events (used with preproc)
% photodio  onsets and durations of sync events (used with trialfun_tcg)
% scantrig  scantrigger onsets (used with ASD_scanning)
% token     token positions (used with comm_replay/search_replay)
% touch     touch coordinates (touchscreen only)
%
% Arjen Stolk, 2020
% --------------------------------------------------------

% open and read ascii-file line by line
fileline = 0;
fid = fopen(logfile,'r'); % open ascii-file
data.info{1} = logfile;
while fileline >= 0 % read line by line
  
  fileline = fgets(fid); % read a line
  if fileline > 0
    
    % recording info
    if ~isempty(findstr(fileline,'ExpStart'))
      data.info{2} = fileline;
      SenderPlayer = 1; ReceiverPlayer = 2; % unless overwritten at role assignment
    end
    if ~isempty(findstr(fileline,'ExpEnd'))
      data.info{3} = fileline;
    end
    
    % trial info
    if ~isempty(findstr(fileline,'TRIAL'))
      TrialNr = sscanf(fileline(findstr(fileline,'TRIAL'):end),'TRIAL #%d');
      TrialOnset = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
      Type = sscanf(fileline(findstr(fileline,'type'):findstr(fileline,',')-1),'type = %s');
      switch Type
        case 'practice' % tcg
          TrialType = 1;
        case 'replay' % tcg
          TrialType = 1;
        case 'training' % tcg
          TrialType = 1;
        case 'scanning' % tcg
          TrialType = 1;
        case 'known' % tcg
          TrialType = 1;
        case 'novel_1' % tcg
          TrialType = 2;
        case 'novel_2' % tcg
          TrialType = 3;
        case 'novel_3' % tcg
          TrialType = 4;
        case 'novel_4' % tcg
          TrialType = 5;
        case 'easy' % tcg kids
          TrialType = 1;
        case 'hard' % tcg kids
          TrialType = 2;
      end
      
      if ~isempty(findstr(fileline,', #')) % tcg specific
        data.info{4} = 'tcg';
        TrialTypeNr = sscanf(fileline(findstr(fileline,', '):end),', #%d');
      end
      
      if ~isempty(findstr(fileline,'addressee')) % tcg kids specific
        data.info{4} = 'tcg kids';
        Addressee = sscanf(fileline(findstr(fileline,'addressee'):findstr(fileline,')')-1),'addressee = %s');
        switch Addressee
          case 'child'
            AddresseeType = 1; % child addressee
          case 'adult'
            AddresseeType = 2; % adult addressee
        end
      end
    end
    
    % role info
    if ~isempty(findstr(fileline,'role assignment')) % tcg only
      P1Role = sscanf(fileline(findstr(fileline,'p1'):findstr(fileline,',')-1),'p1 = %s');
      switch P1Role
        case 'SENDER' % Player 1 (blue) played the sender, Player 2 (orange) the receiver
          SenderPlayer = 1; ReceiverPlayer = 2;
        case 'Avsender' % Player 1 (blue) played the sender, Player 2 (orange) the receiver
          SenderPlayer = 1; ReceiverPlayer = 2;
        case 'RECEIVER' % Player 2 (orange) played the sender, Player 1 (blue) the receiver
          SenderPlayer = 2; ReceiverPlayer = 1;
        case 'Mottaker' % Player 2 (orange) played the sender, Player 1 (blue) the receiver
          SenderPlayer = 2; ReceiverPlayer = 1;
      end
      data.event(TrialNr).roleassignment = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    
    % synchronization info
    if ~isempty(findstr(fileline,'token assignment')) % tcg only - use for sync
      data.photodio(TrialNr).onset = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
      data.event(TrialNr).tokenassignment = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    
    if ~isempty(findstr(fileline,'baseline')) % tcg kids only - use for sync
      data.photodio(TrialNr).onset = sscanf(fileline(findstr(fileline,'baseline'):end),'baseline - time %f');
      data.event(TrialNr).baseline = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    
    % goal configuration
    if ~isempty(findstr(fileline,'goal'))
      GoalOnset = sscanf(fileline(findstr(fileline,'time'):end),'time %f');      
      if isfield(data, 'photodio')
        data.photodio(TrialNr).duration = GoalOnset - data.photodio(TrialNr).onset;
      end
      data.token.sender{TrialNr}.coord = [];
      data.token.sender{TrialNr}.time = [];
      data.token.receiver{TrialNr}.coord = [];
      data.token.receiver{TrialNr}.time = [];
      data.touch.sender{TrialNr}.coord = [];
      data.touch.sender{TrialNr}.time = [];
      data.touch.receiver{TrialNr}.coord = [];
      data.touch.receiver{TrialNr}.time = [];
      SenderPlanTime = NaN;
      SenderMovTime = NaN;
      SenderNumMoves = NaN;
      SenderLocSuccess = NaN;
      SenderOriSuccess = NaN;
      TargetTime = NaN;
      NonTargetTime = NaN;
      ReceiverPlanTime = NaN;
      ReceiverMovTime = NaN;
      ReceiverNumMoves = NaN;
      ReceiverTargetPos = NaN;
      ReceiverEndPos = NaN;
      ReceiverLocSuccess = NaN;
      ReceiverOriSuccess = NaN;
      Success = NaN;
      WaitingForSender = 0;
      WaitingForReceiver = 0;
      WaitForOffTarget = 0;
      data.event(TrialNr).goalconfiguration = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    
    % sender turn
    if ~isempty(findstr(fileline,'sender start'))
      if strcmp(data.info{4}, 'tcg')
        data.token.sender{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'pos'):end),'pos [%f,%f], ang %f'); % for replay purposes
      elseif strcmp(data.info{4}, 'tcg kids')
        data.token.sender{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'pos'):end),'pos [%f,%f'); % for replay purposes
      end
      data.token.sender{TrialNr}.time(end+1,:) = sscanf(fileline(findstr(fileline,'time'):end),'time %f'); % for replay purposes
      SenderMovOnset = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
      SenderPlanTime = SenderMovOnset - GoalOnset;
      SenderNumMoves = 0;
      TargetNum = 0;
      WaitingForSender = 1;
      data.event(TrialNr).senderstart = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    
    if ~isempty(findstr(fileline,'sender position'))
      if strcmp(data.info{4}, 'tcg')
        data.token.sender{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'position'):end),'position [%f,%f], angle %f'); % for replay purposes
      elseif strcmp(data.info{4}, 'tcg kids')
        data.token.sender{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'position'):end),'position [%f,%f'); % for replay purposes
      end
      data.token.sender{TrialNr}.time(end+1,:) = sscanf(fileline(findstr(fileline,'time'):end),'time %f'); % for replay purposes
      SenderNumMoves = SenderNumMoves +1;
      if WaitForOffTarget
        TargetTime(end+1) = data.token.sender{TrialNr}.time(end,:)-data.token.sender{TrialNr}.time(end-1,:);
        WaitForOffTarget = 0;
      else
        NonTargetTime(end+1) = data.token.sender{TrialNr}.time(end,:)-data.token.sender{TrialNr}.time(end-1,:);
      end
    end
    if ~isempty(findstr(fileline,'on target'))
      if strcmp(data.info{4}, 'tcg')
        data.token.sender{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'target'):end),'target [%f,%f], angle %f'); % for replay purposes
      elseif strcmp(data.info{4}, 'tcg kids')
        data.token.sender{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'target'):end),'target [%f,%f'); % for replay purposes
      end
      data.token.sender{TrialNr}.time(end+1,:) = sscanf(fileline(findstr(fileline,'time'):end),'time %f'); % for replay purposes
      SenderNumMoves = SenderNumMoves +1;
      TargetNum = TargetNum +1;
      ReceiverTargetPos = data.token.sender{TrialNr}.coord(end,1:2);
      WaitForOffTarget = 1; % for calculating TargetTime when off target
    end
    if ~isempty(findstr(fileline,'sender touch')) % note that coord [0,0] is top left of screen (use 'axis ij' when plotting)
      data.touch.sender{TrialNr}.coord(:,end+1) = sscanf(fileline(findstr(fileline,'coord'):end),'coord [%f, %f');
      data.touch.sender{TrialNr}.time(:,end+1) = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    
    if ~isempty(findstr(fileline,'sender end'))
      if strcmp(data.info{4}, 'tcg')
        data.token.sender{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'pos'):end),'pos [%f,%f], ang %f'); % for replay purposes
      elseif strcmp(data.info{4}, 'tcg kids')
        data.token.sender{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'pos'):end),'pos [%f,%f'); % for replay purposes
      end
      data.token.sender{TrialNr}.time(end+1,:) = sscanf(fileline(findstr(fileline,'time'):end),'time %f'); % for replay purposes
      SenderMovOffset = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
      if WaitingForSender
        SenderMovTime = SenderMovOffset - SenderMovOnset;
      end
      if WaitForOffTarget
        TargetTime(end+1) = data.token.sender{TrialNr}.time(end,:)-data.token.sender{TrialNr}.time(end-1,:);
      else
        % for tcg kids, exclude additional time on nest (pos [0 0]) at end of turn
        if ~(strcmp(data.info{4}, 'tcg kids') && isequal(data.token.sender{TrialNr}.coord(end,:),[0 0]))
          NonTargetTime(end+1) = data.token.sender{TrialNr}.time(end,:)-data.token.sender{TrialNr}.time(end-1,:);
        end
      end
      TargetTime = nanmean(TargetTime); % take the average
      NonTargetTime = nanmean(NonTargetTime);
      WaitingForReceiver = 0;
      data.event(TrialNr).senderend = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    if ~isempty(findstr(fileline,'sender location'))
      SenderEndLocation = sscanf(fileline(findstr(fileline,'location'):end),'location %s');
      if strcmp(SenderEndLocation, 'correct')
        SenderLocSuccess = 1;
      elseif strcmp(SenderEndLocation, 'incorrect')
        SenderLocSuccess = 0;
      end
    end
    if ~isempty(findstr(fileline,'sender orientation'))
      SenderEndOrientation = sscanf(fileline(findstr(fileline,'orientation'):end),'orientation %s');
      if strcmp(SenderEndOrientation, 'correct')
        SenderOriSuccess = 1;
      elseif strcmp(SenderEndOrientation, 'incorrect')
        SenderOriSuccess = 0;
      end
    end
    
    % receiver turn
    if ~isempty(findstr(fileline,'receiver start'))
      if strcmp(data.info{4}, 'tcg')
        data.token.receiver{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'pos'):end),'pos [%f,%f], ang %f'); % for replay purposes
      elseif strcmp(data.info{4}, 'tcg kids')
        data.token.receiver{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'coord'):end),'coord [%f,%f'); % for replay purposes
      end
      data.token.receiver{TrialNr}.time(end+1,:) = sscanf(fileline(findstr(fileline,'time'):end),'time %f'); % for replay purposes
      ReceiverMovOnset = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
      ReceiverPlanTime = ReceiverMovOnset - SenderMovOffset;
      ReceiverNumMoves = 0;
      if isfield(data, 'photodio')
        data.photodio(TrialNr).latency = ReceiverMovOnset - data.photodio(TrialNr).onset;
      end
      WaitingForReceiver = 1;
      data.event(TrialNr).receiverstart = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    
    if ~isempty(findstr(fileline,'receiver position'))
      if strcmp(data.info{4}, 'tcg') % does not exist for tcg kids
        data.token.receiver{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'position'):end),'position [%f,%f], angle %f'); % for replay purposes
        data.token.receiver{TrialNr}.time(end+1,:) = sscanf(fileline(findstr(fileline,'time'):end),'time %f'); % for replay purposes
      end
      ReceiverNumMoves = ReceiverNumMoves +1;
    end
    if ~isempty(findstr(fileline,'receiver touch')) % note that coord [0,0] is top left of screen (use 'axis ij' when plotting)
      data.touch.receiver{TrialNr}.coord(:,end+1) = sscanf(fileline(findstr(fileline,'coord'):end),'coord [%f, %f');
      data.touch.receiver{TrialNr}.time(:,end+1) = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    
    if ~isempty(findstr(fileline,'receiver end'))
      if strcmp(data.info{4}, 'tcg')
        data.token.receiver{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'pos'):end),'pos [%f,%f], ang %f'); % for replay purposes
      elseif strcmp(data.info{4}, 'tcg kids')
        data.token.receiver{TrialNr}.coord(end+1,:) = sscanf(fileline(findstr(fileline,'coord'):end),'coord [%f,%f'); % for replay purposes
      end
      data.token.receiver{TrialNr}.time(end+1,:) = sscanf(fileline(findstr(fileline,'time'):end),'time %f'); % for replay purposes
      ReceiverMovOffset = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
      if WaitingForReceiver
        ReceiverMovTime = ReceiverMovOffset - ReceiverMovOnset;
      end
      ReceiverEndPos = data.token.receiver{TrialNr}.coord(end,1:2);
      data.event(TrialNr).receiverend = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    if ~isempty(findstr(fileline,'receiver location'))
      ReceiverEndLocation = sscanf(fileline(findstr(fileline,'location'):end),'location %s');
      if strcmp(ReceiverEndLocation, 'correct')
        ReceiverLocSuccess = 1;
      elseif strcmp(ReceiverEndLocation, 'incorrect')
        ReceiverLocSuccess = 0;
      end
    end
    if ~isempty(findstr(fileline,'receiver orientation'))
      ReceiverEndOrientation = sscanf(fileline(findstr(fileline,'orientation'):end),'orientation %s');
      if strcmp(ReceiverEndOrientation, 'correct')
        ReceiverOriSuccess = 1;
      elseif strcmp(ReceiverEndOrientation, 'incorrect')
        ReceiverOriSuccess = 0;
      end
    end
    
    % feedback
    if ~isempty(findstr(fileline,'feedback'))
      Feedback = sscanf(fileline(findstr(fileline,'feedback'):end),'feedback %s');
      TrialOffset = sscanf(fileline(findstr(fileline,'time'):end),'time %f') +.5; % feedback lasted .5 sec for both tasks
      if strcmp(Feedback, 'correct')
        Success = 1;
      elseif strcmp(Feedback, 'incorrect')
        Success = 0;
      end
      
      % bookkeeping
      if strcmp(data.info{4}, 'tcg')
        if isnan(ReceiverLocSuccess) % backward compatibility
          if isequal(ReceiverEndPos, ReceiverTargetPos) && ~isnan(any(ReceiverEndPos)) % if receiver at target
            if Success % both location and orientation correct
              ReceiverLocSuccess = 1;
              ReceiverOriSuccess = 1;
            elseif ~Success % only location correct
              ReceiverLocSuccess = 1;
              ReceiverOriSuccess = 0;
            end
          else % receiver not at target
            ReceiverLocSuccess = 0; % location incorrect
            ReceiverOriSuccess = 0; % assuming all incorrect
          end
          SenderLocSuccess = 1; % since this was only for replay designs (tcg_pfc)
          SenderOriSuccess = 1;
        end
        data.trial(TrialNr,:) = [TrialNr TrialType TrialTypeNr TrialOnset ...
          SenderPlayer SenderPlanTime SenderMovTime SenderNumMoves TargetNum TargetTime NonTargetTime ...
          ReceiverPlayer ReceiverPlanTime ReceiverMovTime ReceiverNumMoves ...
          Success SenderLocSuccess SenderOriSuccess ReceiverLocSuccess ReceiverOriSuccess ...
          TrialOffset];
      elseif strcmp(data.info{4}, 'tcg kids')
        if isequal(data.token.sender{TrialNr}.coord(end,:),[0 0]) % returned to nest
          SenderLocSuccess = 1;
        else
          SenderLocSuccess = 0;
        end
        data.trial(TrialNr,:) = [TrialNr TrialType AddresseeType TrialOnset ...
          SenderPlanTime SenderMovTime SenderNumMoves TargetNum TargetTime NonTargetTime ...
          ReceiverPlanTime ReceiverMovTime ReceiverNumMoves ...
          Success SenderLocSuccess ...
          TrialOffset];
      end
      data.event(TrialNr).feedback = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    
    % scan triggers
    if ~isempty(findstr(fileline,'SCANNER #1'))
      if ~isfield(data, 'prismafit')
        data.prismafit = [];
      end
      data.prismafit(end+1).time = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    if ~isempty(findstr(fileline,'SCANNER #2'))
      if ~isfield(data, 'prisma')
        data.prisma = [];
      end
      data.prisma(end+1).time = sscanf(fileline(findstr(fileline,'time'):end),'time %f');
    end
    
  end
end % end of fileline loop

% knwon trials: TrialType =1 ; novel trials: TrialType = 2

if ~isempty(findstr(logfile,'ASD_scanning'))
     
    data.trial(5:9,2) = 2;
    data.trial(14:18,2) = 2;
    data.trial(23:27,2) = 2; 
    data.trial(32:36,2) = 2;
    data.trial(41:45,2) = 2;
    data.trial(50:54,2) = 2;
    data.trial(59:63,2) = 2;
    data.trial(68:72,2) = 2;
    data.trial(77:81,2) = 2;   
    
end

% add label field
if strcmp(data.info{4}, 'tcg')
  data.label = {'TrialNr','TrialType','TrialTypeNr','TrialOnset', ...
    'SenderPlayer','SenderPlanTime','SenderMovTime','SenderNumMoves','TargetNum','TargetTime','NonTargetTime', ...
    'ReceiverPlayer','ReceiverPlanTime','ReceiverMovTime','ReceiverNumMoves', ...
    'Success','SenderLocSuccess','SenderOriSuccess','ReceiverLocSuccess','ReceiverOriSuccess', ...
    'TrialOffset'}; % the 4 sender and receiver success columns make sense for data later than July 2016
elseif strcmp(data.info{4}, 'tcg kids')
  data.label = {'TrialNr','TrialType','AddresseeType','TrialOnset', ...
    'SenderPlanTime','SenderMovTime','SenderNumMoves','TargetNum','TargetTime','NonTargetTime', ...
    'ReceiverPlanTime','ReceiverMovTime','ReceiverNumMoves','Success','SenderLocSuccess', ...
    'TrialOffset'};
end

% triallengths = diff([data.trial(:,4); sscanf(data.info{3}(findstr(data.info{3},'time'):end),'time %f')])
