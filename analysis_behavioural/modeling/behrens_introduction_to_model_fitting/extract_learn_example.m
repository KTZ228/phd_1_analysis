function [out]=extract_learn_example(data_name,dir_name)

% script to extract matlab data from presentation file output of learning
% task. Adapted for 2 option linked task

if nargin<2
    dir_name=pwd;
end

if isunix
if ~strcmp(dir_name(end),'/')
    dir_name=[dir_name,'/'];
end
else
if ~strcmp(dir_name(end),'\')
    dir_name=[dir_name,'\'];
end
end
data_name=[dir_name,data_name,'_vol_train_log.dat'];

fid=fopen(data_name,'r');

% this creates a cell array with all the data from the file
raw_data=[];
while feof(fid)==0
raw_data=[raw_data,textscan(fgetl(fid),'%s','delimiter','\t')];
end
fclose(fid);

out=struct;

header_found=0;
% loop through the raw data
for i=1:size(raw_data,2)
    
    if header_found==1
        
        
        trial_number=str2double(raw_data{1,i}{1});
        out.shape1_win(trial_number,1)=str2double(raw_data{1,i}{shape1_win_num});
        out.shape2_win(trial_number,1)=str2double(raw_data{1,i}{shape2_win_num});
        out.shape1_loss(trial_number,1)=str2double(raw_data{1,i}{shape1_loss_num});
        out.shape2_loss(trial_number,1)=str2double(raw_data{1,i}{shape2_loss_num});
        out.button_press(trial_number,1)=str2double(raw_data{1,i}{button_press_num});
        out.trial_outcome(trial_number,1)=str2double(raw_data{1,i}{trial_outcome_num});
        out.outcome_order(trial_number,1)=str2double(raw_data{1,i}{outcome_order_num});
        out.reaction_time(trial_number,1)=str2double(raw_data{1,i}{reaction_time_num});
        out.total(trial_number,1)=str2double(raw_data{1,i}{total_num});
        
    else
        if strncmp(raw_data{1,i}{1},'Particip',8)
           out.block_order=str2double(regexprep(raw_data{1,i}{2},'order_num',''));
            
        end
       
    end
    
     if strcmp(raw_data{1,i}{1},'trial_number')   % this identifies the header line
        % the following code determines the column positions of the
        % relevant data
      shape1_win_num=find(strcmpi('shape1_win',raw_data{1,i})); % time of trial onset
      shape2_win_num=find(strcmpi('shape2_win',raw_data{1,i}));
      shape1_loss_num=find(strcmpi('shape1_loss',raw_data{1,i}));
      shape2_loss_num=find(strcmpi('shape2_loss',raw_data{1,i}));
      button_press_num=find(strcmpi('button_pressed',raw_data{1,i}));
      trial_outcome_num=find(strcmpi('trial_outcome',raw_data{1,i}));
       outcome_order_num=find(strcmpi('outcome_order',raw_data{1,i}));
       reaction_time_num=find(strcmpi('reaction_time',raw_data{1,i}));
      total_num=find(strcmpi('total',raw_data{1,i}));
     
        header_found=1;
    end
    
end

        
        
        