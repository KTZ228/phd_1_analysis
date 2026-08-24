function [out]=fit_linked_2lr_beta_add(information,choice, start, alphabins,betabins, resp_made,fig_yes)

%

% Bayesian model fit for 2 option vol training task in which outcomes are linked.
% (i.e. if one option wins, the other doesn't).
% Information contains two columns: wins for "shape a", lossses for "shape a" 
% "shape a" is one of the two options, the other is "shape b" (outcomes for shape b are 1-those for shape a)
% choice is the participant choice (select shape a==1, select shape b==0), start is the initial beliefs about reward and loss associations [rew_start loss_start]
% alphabins sets number of points to
% estimate lr, betabins same for beta (and the additive term), resp_made is trials on which a
% response was made.
% in this script a single beta is used and a bias term adds to
% the value calculation (causing a stable constant bias towards shape a or
% b)
if(nargin<7) fig_yes=0; end
if(nargin<6) resp_made=true(size(information,1),1); end
if(nargin<5) betabins=30; end
if(nargin<4) alphabins=30; end

out=struct;

% NB calculations (of mean and variance) of both learning rate and decision
% temperature are performed in log space.

%This creates a vector of length alphabins the value of which changes linearly from log(0.01)=-4.6052 to
%log(1)=0. this will be used to create a logarithmic distribution of
%learning rates (i.e. they are likely to be low)
i=log(0.01):(log(1)-log(0.01))/(alphabins-1):log(1);

% this creates a vector of length betabins the value of which changes
% linearly from log(0.1) to log(100). It will be used to create a
% logarithmic distribution of inverse temperatures.
b_label=log(0.1):(log(100)-log(0.1))/(betabins-1):log(100);


% Uniform sample of value offsets. Same accuity as beta. Max values are -1
% to +1. Allows people to have a preference for a shape (which some people
% do)
val_label=-1:2/(betabins-1):1;


% this runs a modified Rescorla-Wagner model which uses separate learning
% rates for wins and losses. Output is a two column vector with the
% estimated value (of shape a) for win and loss outcomes.

for k=1:length(i)
for j=1:length(i)
    rlout=rescorla_wagner_2lr(information(:,1:2),[exp(i(k)) exp(i(j))],start); % calculates separate value for wins and losses 
    val_diff(k,j,:)=rlout(:,1)-rlout(:,2); % this is the relative value for shape a of wins - losses
 
end
end

% replicate the value matrix to account for betas and add term. This
% produces a 5 dimensional matrix with the dimensions coding (in order):
% 1) win lr, 2) loss lr, 3) trial number, 4) beta value, 5) add value (i.e.
% the bias term)
mmdl=repmat(val_diff,[1,1,1,length(b_label),length(b_label)]);

clear val_diff % save a bit of memory

% create a 5 dimensional matrix of same size as above that represents the
% add value along the 5th dimension
val_add=repmat(permute(val_label,[1 3 4 5 2]),[length(i) length(i) length(information) length(b_label) 1]);

%skew values by addiing hte bias term to the outcome of the rescorla wagner
%model
mmdl=mmdl+val_add;

%create a 5 dimensional matrix, as above, that represents the possible values of beta along the fourth dimension 
beta=repmat(permute(exp(b_label),[1 3 4 2 5]),[length(i) length(i) length(information) 1 length(b_label)]);

% calculate the probability of selecting shape a (i.e. the output of the
% soft max.
probsa=1./(1+exp(-beta.*mmdl));

clear beta val_add % save a bit of memory


  % create a 5D matrix of the same dimensions as before with the choices
  % (i.e. 1== chose shape a, 0== chose shape b)
  % arranged along the third dimension
  ch=repmat(permute(choice,[2 3 1 4 5]),[length(i) length(i)  1 length(b_label) length(b_label)]);

  % This calculates the likelihood of the choices made given the model
  % parameters
  probch=((ch.*probsa)+((1-ch).*(1-probsa)));
  clear probsa % save memory

  %this bit removes data from trials in which the participant made no
  %response (or trials we don't want to use when estimating the parameters)
  probch=probch(:,:,resp_made,:,:);

  % This calculates the overall liklihood of the parameters by taking the
  % product across the individual trials. Note that this results in a
  % four dimensional matrix which contains the likelihood of the data
  % given the four parameters which are coded on the dimensions (LR wins, 
  % LR losses, inv temperature, bias). 
  out.posterior_prob(:,:,:,:)=squeeze(prod(probch,3));  

  %renormalise-- this forces the sum across all values in the four
  %dimensional matrix to add to 1. i.e. it turns the liklihood distribution
  %into a posterior distribution (it assumes that sampling of the
  %hypothesis space is exhaustive, so the sum over all possible parameter
  %likelihood values is p(data)-- the denominator of bayes theorem). 
  out.posterior_prob=out.posterior_prob./(sum(sum(sum(sum(out.posterior_prob)))));
  
  clear probch

% this returns the actual values of the parameters used for
% graphing
alphalabel=exp(i);
betalabel=exp(b_label);


% This produces a marginal distribution of the win learning rate by summing
% across the other dimensions.
% The numerator sums over dimensions 2, 3 and 4 leaving a 1D vector which contains
% the marginal likelihood for each of the possible values of win learning rate.
out.marg_alpha_rew=squeeze(sum(sum(sum(out.posterior_prob,3),2),4));

% This generates the expected value of the win learning rate using a weighted
% sum-- marginal probabilities multiplied by learning rate values. Note
% for both the learning rate and temperature mean and variance are
% caculated in log space
out.mean_alpha_rew=exp(i*out.marg_alpha_rew); % NB in matlab the * operator performs matrix multiplaction rather than simple elmentwise [this line is equivalent to: exp(sum(i.*out.marg_alpha_rew'))];

% this calculates the variance of the distribution of win learning rates
out.var_alpha_rew=exp(((i-log(out.mean_alpha_rew)).^2)*out.marg_alpha_rew);

% this does the same as above for loss learning rate
out.marg_alpha_loss=squeeze(sum(sum(sum(out.posterior_prob,1),3),4))';
out.mean_alpha_loss=exp(i*out.marg_alpha_loss);
out.var_alpha_loss=exp(((i-log(out.mean_alpha_loss)).^2)*out.marg_alpha_loss);


% as above for beta (inv temperature)

    out.marg_beta=squeeze(sum(sum(sum(out.posterior_prob,1),2),4));
    out.mean_beta=exp(b_label*out.marg_beta);
    out.var_beta=exp(((b_label-log(out.mean_beta)).^2)*out.marg_beta);
    
% as above for bias term
    out.marg_val_add=squeeze(sum(sum(sum(out.posterior_prob,1),2),3));
    out.mean_val_add=val_label*out.marg_val_add;
    out.var_val_add=(((val_label-out.mean_val_add).^2)*out.marg_val_add);


% put relevant values in the output structure
out.beta_label=betalabel;
out.val_add_label=val_label;
out.lr_label=alphalabel;
out.lr_points=i;
out.beta_points=b_label;


% plot marginal distributions if required
if fig_yes==1 
   figure
   subplot(2,2,1);
   plot(alphalabel,out.marg_alpha_rew);
   title('Learning Rate Reward');
   subplot(2,2,2);
   plot(alphalabel,out.marg_alpha_loss);
   title('Learning Rate Loss');
   subplot(2,2,3);
   plot(betalabel,out.marg_beta);
    title('Beta');
      subplot(2,2,4);
    plot(val_label,out.marg_val_add);
    title('Value Add');

    
   
end

% get LL (log likelihood) as well as BIC and AIC from estimated parameters
% this is useful for model comparison
ler=rescorla_wagner_2lr(information(:,1:2),[out.mean_alpha_rew out.mean_alpha_loss],start);
bel=ler(:,1)-ler(:,2);
bel=bel+out.mean_val_add;
prob_ch_left=1./(1+exp(-out.mean_beta.*bel));
likelihood=prob_ch_left;
likelihood(choice==0)=1-likelihood(choice==0);
out.neg_log_like=-sum(log(likelihood(resp_made)+1e-16));
out.BIC=(2.*out.neg_log_like)+4*sum(resp_made); % BIC given 4 free parameters
out.AIC=(2.*out.neg_log_like)+8;
   