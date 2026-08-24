function [r]=rescorla_wagner_2lr(Y,alpha,start)
%[r]=rescorla_wagner(Y,alpha,start)
% Y is column of wins and losses
% alpha is [reward_lr loss_lr], start is [start_reward start_loss]
%[r]=rescorla_wagner(Y,alpha)  (start is assumed to be 0.5
% Output is probability estimate

if(nargin<3) start=[0.5 0.5];end
r=zeros(size(Y));
r(1,:)=start;
for i=2:size(r,1)
  r(i,1)=r(i-1,1)+alpha(1)*(Y(i-1,1)-r(i-1,1));
  r(i,2)=r(i-1,2)+alpha(2)*(Y(i-1,2)-r(i-1,2));
end