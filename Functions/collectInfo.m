
function [subjID, session, filename] = collectInfo( strName )

% This function gets subject information from the user input, 
% such as subj ID, session #, group, and filename. 

if (isempty(strName))
    strName = 'result';
end

% Defined by user...
subjID  = input('\nEnter subject ID (Sxx): ','s');
%group   = input('Enter group type: ','s');

if (strName == "train")
% Let's use try..catch!
    try
        session = input('Enter session number: ');
    catch
        warning('Please give a number only!');
    end
else
    session = input('Enter session name: ','s');
end

if (isempty(session))
    warning('Please do not leave it empty!');
    session = input('Enter session number: ');
end

% Extract current time
formatOut = 'HHMM'; 

% Produce filename directly here.........
filename = strcat(subjID,'_',strName,'_',num2str(session),'_',...
                  datestr(now,formatOut));
              
KbCheck;
filename


