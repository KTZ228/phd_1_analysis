function m = bch_constr_tcon(c,varargin)
%--------------------------------------------------------------------------
% CONSTRUCT_TCON constructs T-contrasts for batch_spm5 (BCH_JOB_CON1_EXP).
%
% FORMAT:   m = contr_tcon(c,d);
% INPUT:    c   - If input c is an array of integers, it constructs a row
%                 of zeros with max(c) columns with length(c) ones on each
%                 corresponding column. If c is a matrix with two rows,
%                 constr_tcon gives the values denoted by the second row
%                 instead of just ones.
%           nr  - You can specify your contrast for one session, or for
%                 multiple sessions in one go. In the latter case you need
%                 to specify the number of model and nuisance regressors
%                 for each session and if you want to include this session
%                 or not. nr = [nr_model_regr nr_nuis_regr incl_sess]; This
%                 incl_sess variable is used as a weight. So set to 0 if
%                 you want to exclude this session. Set to 1 to include.
%                 Set to 2 to multiply by 2. Etc.
%           d   - You can also give a multiplication factor (d). This is
%                 usefull if you use not only the canonical hrf, but also
%                 the temporal and/or dispersion derivative. These expand
%                 your model in a predictable way. Example: If c = [1 3 5]
%                 and d == 2, then c will be [1 5 9]. If d == 3, then c
%                 will be [1 7 13]. If d is not specified, then c is not
%                 multiplied. If length(d) == 2 the F-contrast is not
%                 expanded but only shifted to the right with d(1)*d(2). As
%                 a result c(1,:)  = c(1,:) + d(1)*d(2). This is
%                 particularly usefull if the T-contrast is on user
%                 specified regressors (rp) and not on model regressors.
%
% EXAMPLES: c = [1 3 5]             m = [1 0 1 0 1]
%           c = [1;3;5]             m = [1 0 1 0 1]
%           c = [1 3 5; 1 1 -2]     m = [1 0 1 0 -2]
%
% created by Lennart Verhagen, jan-2005
% L.Verhagen@fcdonders.ru.nl
% version 2008-07-10
%--------------------------------------------------------------------------

% sort input
for v = 1:length(varargin)
    if iscell(varargin{v})
        nr = varargin{v};
    elseif ~exist('d','var')
        d = varargin{v};
    end
end

% if input is missing, set as default
if ~exist('nr','var')
    nr = {[NaN NaN 1]};
end
if ~exist('d','var')
    d = 1;
end
for ss = 1:length(nr)
    if length(nr{ss}) < 3
        nr{ss}(3) = 1;
    end
end

% Place c in a cell structure, if not done so already
if ~iscell(c)
    xc{1} = c;
    c = xc;
end

% If only one session is specified in c, but more are indicated by nr, then
% assume that c can be repeated over all sessions.
if length(c) == 1
    for ss = 2:length(nr)
        c{ss} = c{1};
    end
end

% loop over sessions
for ss = 1:length(c)
    
    % if indicated by nr{ss}(3) that the contrasts for this session should
    % be excluded, replace the c{ss} by NaNs.
    if nr{ss}(3) == 0
        c{ss} = NaN;
    end
    
    % transpose c if necessary
    if size(c{ss},1) > size(c{ss},2) && size(c{ss},1) > 2
        c{ss} = c{ss}';
    end
    
    if d(1) > 1 && length(d)==1
        % place c only on the canonical basis function, not the derivatives
        c{ss}(1,:) = (c{ss}(1,:).*d) - (d-1);
    elseif length(d)==2
        % or shift c to the right by prod(d)
        c{ss}(1,:) = c{ss}(1,:) + prod(d);
    end
    
    % adapt nr based on d.
    nr{ss}(1) = nr{ss}(1)*d(1);
    
    % if no contrasts are given, assume every selected regressors is 1.
    if size(c{ss},1) == 1
        c{ss} = [c{ss}; ones(1,size(c{ss},2))];
    end

    % zeros and nans can not be indexed
    % c{ss} = c{ss}(sum(( c{ss}==0 | isnan(c{ss}) ),2)==0,:);
    
end

% make the t-contrast matrix
j = 0;
for ss = 1:length(nr)
    if any(isnan(nr{ss}))
        j = j + max(c{ss}(1,:));
    else
        j = j + sum(nr{ss}(1:2));
    end
end
m = zeros(1,j);

% and fill it with the correct numbers
start = 0;
for ss = 1:length(c)
    if ~any(isnan(c{ss}(1,:)))
        m(start + c{ss}(1,:)) = c{ss}(2,:) * nr{ss}(3);
    end
    start = start + sum(nr{ss}(1:2));
end
%==========================================================================