

%This fits a model with a win lr, loss lr, beta and an additive term on the
%value which influences overall preference for one symbol relative to the
%other

%The task is described in pulcu and browning elife 2017 (or pulcu et al. 
% Biological psychaitry 2019). There are three
%blocks of 80 trials each. Each trial requires a choice between two options
%(same options across a block). After the choice there is an indepenent win
%outcome and a loss outcome-- you see which of the two options has the win
%and which the loss, you get that outcome (win and/or loss) if you have
%selected the shape it is associated with. The blocks vary in the volatility/
% stability of the two outcomes. First block-- both outcomes are volatile;
% in one of the last two blocks win is volatile and loss is stable, in the
% other loss is volatile and win is stable. 

% normatively people should use a higher learning rate for outcomes that
% are volatile than stable (and people always do do this).


    fig_out=1; % plot figures yes/no

% parse data from the vol learn task on a subject

%extract data from presentation file
sub_data=extract_learn_example('example_data',pwd);

%don't use this number of trials at the start of each block when fitting
%the parameters
miss_trials=10;

trials_to_use=true(80,1);
trials_to_use(1:miss_trials)=false;

% arrange the extracted data into the format needed by the fitting function
information=[sub_data.shape1_win, sub_data.shape1_loss];
choice=sub_data.button_press;
choice(choice==2)=0; % NB choice in the presentation script is coded as 1 or 2-- for the fitting script it needs to be 1 and 0.

% fit model to first, middle and last block of the task-- i.e. each block
% is 80 trials long

% IF YOU WANT TO UNDERSTAND THE ACUTAL FITTING PROCESS YOU SHOULD LOOK AT
% THE FUNCTION "fit_linked_2lr_beta_add".

%first block
start_point=1;
end_point=80;
[out1]=fit_linked_2lr_beta_add(information(start_point:end_point,:),choice(start_point:end_point), [0.5 0.5], 40,30,trials_to_use,fig_out);

%second block
start_point=81;
end_point=160;
[out2]=fit_linked_2lr_beta_add(information(start_point:end_point,:),choice(start_point:end_point), [0.5 0.5], 40,30,trials_to_use,fig_out);

%third block
start_point=161;
end_point=240;
[out3]=fit_linked_2lr_beta_add(information(start_point:end_point,:),choice(start_point:end_point), [0.5 0.5], 40,30,trials_to_use,fig_out);

% arrange the extracted parameters in a useful way
rew_lr=[out1.mean_alpha_rew, out2.mean_alpha_rew, out3.mean_alpha_rew];
loss_lr=[out1.mean_alpha_loss, out2.mean_alpha_loss, out3.mean_alpha_loss];
beta=[out1.mean_beta, out2.mean_beta,out3.mean_beta];
val_add=[out1.mean_val_add, out2.mean_val_add,out3.mean_val_add];

%Make sure you label the figures correctly (i.e. work out the order of win and loss
%volatile blocks)
if sub_data.block_order==1
    barlabs= {'Both','Negative', 'Positive'};
else
    barlabs= {'Both','Positive','Negative'};
end

data_out.out1=out1;
data_out.out2=out2;
data_out.out3=out3;


%plot some additional figures-- the fitting script plots the individual marginal
%distributions, the figures below are surfaces, each showing the marginal
%positerior of pairs of parameters (so you can see how well each one has
%been estimated).
if fig_out
  
    labels={out1.lr_label,out1.lr_label,out1.beta_label,out1.val_add_label};
    axislabels={'WIN LR','LOSS LR', 'BETA', 'VAL ADD'};
    
    
    %all combinations of 2 ones in 4 binary options
    combs=unique(perms([1 1 0 0]),'rows');
    
    
    for blocknum=1:3
        figure;
        title(['Block ',num2str(blocknum)]);
        for fperm=1:size(combs,1)
            subplot(2,3,fperm);
            notuse= find(combs(fperm,:)==0);
            touse=find(combs(fperm,:)==1);
            surface(labels{touse(2)},labels{touse(1)}, squeeze(sum(sum(data_out.(['out',num2str(blocknum)]).posterior_prob,notuse(1)),notuse(2))),'linestyle','none')
            ylabel([axislabels{1,touse(1)}]);
            xlabel([axislabels{1,touse(2)}]);
            if touse(2)~=4
                set(gca,'xscale','log');
            end
            if touse(1)~=4
                set(gca,'yscale','log');
            end
        end
    end
end
