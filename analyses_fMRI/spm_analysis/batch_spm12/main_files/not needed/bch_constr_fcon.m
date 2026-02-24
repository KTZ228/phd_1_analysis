function m = bch_constr_fcon(c,varargin)
%--------------------------------------------------------------------------
% BCH_CONSTR_FCON constructs F-contrasts for batch_spm5 (BCH_JOB_CON1_EXP).
%
% FORMAT:   m = bch_contr_fcon(c,nr,d,incl);
% INPUT:    c   - If input c is an array of integers, it constructs a
%                 matrix of zeros with max(c) columns and length(c) rows
%                 and with length(c) ones on each corresponding column.
%                 If size(c,1) > 1, then the the matrix has size(c,1) rows
%                 with ones on the correspondings columns.
%                 If the a row contains zeros or NaNs then that row will be
%                 ignored.
%                 If size(c,3) == 2, then the values in c(:,:,2) are taken
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
%                 usefull if you use not only the hrf, but also the
%                 temporal and/or dispersion derivative. These expand your
%                 model in a predictable way. Example: If c = [1 3 5] and
%                 d == 2, then c will be [1 5 9]. If d == 3, then c will be
%                 [1 7 13]. If d is not specified, it will not perform any
%                 multiplication. If length(d) == 2 the F-contrast is not
%                 expanded but only shifted to the right with d(1)*d(2). As
%                 a result c(1,:)  = c(1,:) + d(1)*d(2). This is
%                 particularly usefull if the F-contrasts is on user
%                 specified regressors (rp) and not on model regressors.
%           incl- If you have included a temporal and/or dispersion
%                 derivative in your model (i.e. d > 1), but you don't want
%                 to include them in your F-contrast, you should state incl
%                 as false or 0. If d is specified, but incl is not, it is
%                 assumed true or 1;
% OUTPUT:   m   - The resulting contrast matrix.
%
% EXAMPLES: c = [1 3 5]             m = [1 0 0 0 0; 0 0 1 0 0; 0 0 0 0 1]
%           c = [1 3 5; 2 4 6]      m = [1 0 1 0 1 0; 0 1 0 1 0 1]
%           c = [1 3 5; 0 0 0]      m = [1 0 1 0 1]
%           c = [1 3 5; 2 NaN 6]    m = [1 0 1 0 1]
%           c(:,:,1) = [1 3 5]
%           c(:,:,2) = [1 -2 1]     m = [1 0 0 0 0; 0 0 -2 0 0; 0 0 0 0 1]
%           c(:,:,1) = [3 5; 4 6]
%           c(:,:,2) = [1 -1; 1 -1] m = [0 0 1 0 -1 0; 0 0 0 1 0 -1]
%
% created by Lennart Verhagen, jan-2005
% L.Verhagen@fcdonders.ru.nl
% version 2008-07-10
%--------------------------------------------------------------------------

% sort input
for v = 1:length(varargin)
    if iscell(varargin{v})
        nr = varargin{v};
    elseif islogical(varargin{v})
        incl = varargin{v};
    else
        if ~exist('d','var')
            d = varargin{v};
        else
            incl = logical(varargin{v});
        end
    end
end

% if input is missing, set as default
if ~exist('nr','var')
    nr = {[NaN NaN 1]};
end
if ~exist('d','var')
    d = 1;
end
if ~exist('incl','var')
    incl = true;
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

for ss = 1:length(c)
    
    % adapt c based on d and incl.
    if d(1) > 1 && length(d)==1
        c{ss}(:,:,1) = (c{ss}(:,:,1).*d) - (d-1);
        if incl
            for i = 1:d-1
                tc{i}(:,:,1) = c{ss}(:,:,1)+i;
                if size(c{ss},3) == 2
                    tc{i}(:,:,2) = c{ss}(:,:,2);
                end
            end
            for i = 1:length(tc)
                c{ss} = sortrows([c{ss} tc{i}]',1)';
            end
            clear tc;
        end
    elseif length(d)==2
        c{ss}(:,:,1) = c{ss}(:,:,1) + prod(d);
    end

    % adapt nr based on d.
    nr{ss}(1) = nr{ss}(1)*d(1);
    
    % if indicated by nr{ss}(3) that the contrasts for this session should
    % be excluded, replace the c{ss} by NaNs.
    if nr{ss}(3) == 0
        c{ss} = NaN;
    end
    
    % if the third dimension is not given, use only ones
    if size(c{ss},3)==1
        c{ss}(:,:,2) = ones(size(c{ss}(:,:,1)));
    end

    % transpose the vector if needed
    if size(c{ss},1)==1
        tc = [];
        for i = 1:size(c{ss},3)
            tc(:,:,i) = c{ss}(:,:,i)';
        end
        c{ss} = tc;
    end
    clear tc;

    % zeros and nans can not be indexed
    c{ss} = c{ss}(sum(sum(( c{ss}==0 | isnan(c{ss}) ),3),2)==0,:,:);
    
end

% make the f-contrast matrix
for ss = 1:length(c)
    i(ss) = size(c{ss},1);
end
i = max(i);
j = 0;
for ss = 1:length(nr)
    if any(isnan(nr{ss}))
        j = j + max(max(c{ss}(:,:,1)));
    else
        j = j + sum(nr{ss}(1:2));
    end
end
m = zeros(i,j);

% and fill it with the correct numbers
start = 0;
for ss = 1:length(c)
    for i = 1:size(c{ss},1)
        for j = 1:size(c{ss},2)
            m(i,start+c{ss}(i,j,1)) = c{ss}(i,j,2) * nr{ss}(3);
        end
    end
    start = start + sum(nr{ss}(1:2));
end
%==========================================================================
