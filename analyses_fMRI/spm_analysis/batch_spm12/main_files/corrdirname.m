function str = corrdirname(str,rep)

if nargin < 2
    rep = '-';
end

str = strrep(str,':',rep);
str = strrep(str,'/',rep);
str = strrep(str,'\',rep);
str = strrep(str,'?',rep);
str = strrep(str,'"',rep);
str = strrep(str,'<',rep);
str = strrep(str,'>',rep);
str = strrep(str,'|',rep);
str = strrep(str,'*',rep);