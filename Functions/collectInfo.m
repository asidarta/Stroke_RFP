function [subjID, session, group, filename] = collectInfo( strName )
% This function collects info of the trial such as subj ID, session #, 
% and group. 

if (isempty(strName))
    strName = 'result';
end

subjID  = input('Enter subject ID (Sxx): ','s');
group   = input('Enter group type (sham/exp): ','s');

% Let's use try..catch!
try
    session = input('Enter session number: ');
catch
    warning('Please give a number only!');
end

if (isempty(session))
    warning('Please do not leave it empty!');
    session = input('Enter session number: ');
end

% Extract current time
formatOut = 'HHMM'; 

% Produce filename directly here.........
filename = strcat('subjID','_',group,'_',num2str(session),'_',...
                  strName,'_',datestr(now,formatOut));
              
KbCheck;


