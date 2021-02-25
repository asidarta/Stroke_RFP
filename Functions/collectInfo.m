
function [subjID, session, block, filename] = collectInfo( strName )

% This function gets subject information from the user input such as subj ID, session #, 
% group. This is used to produce file and folder name to save. 

% NOTE: This is hardcoded here!
mypath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\Trial Data\';

if (isempty(strName))
    strName = 'result';
end

% Defined by user...
subjID  = input('\nEnter subject ID (Sxx): ','s');
%group   = input('Enter group type: ','s');
block   = 0;

% Check if this is training session. If yes you have to input session
% number (multiple sessions), and also block number. Assessment has only 
% one block.

if (strName == "train")
% Let's use try..catch!
    try
        session = input('Enter session number  : ');
        block   = input('Enter block number    : ');
    catch
        warning('Please give a number only!');
    end
else
    session = input('Enter session name    : ','s');
    block = 1;
end

if (isempty(session))
    warning('Please do not leave it empty!');
    session = input('Enter session number  : ');
end

% Extract current time
formatOut = 'HHMM'; 

% Produce filename directly here.........
filename = strcat(subjID,'_',strName,'_',num2str(session),'_',num2str(block),...,
                  '_',datestr(now,formatOut));
              
KbCheck;
filename

% (25/2) I added subject folder and session folder to place the saved data in!!
filename = strcat(subjID,'\',num2str(session),'\',subjID,'_',strName,'_',num2str(session),...,
                  '_',num2str(block),'_',datestr(now,formatOut));



%% Important!! 
% We have to check if the subject folder has been created in the working directory. 
if ~exist(strcat(mypath,subjID), 'dir')
    fprintf('Subject folder not found. Creating one....\n');
    mkdir(strcat(mypath,subjID))    % name the folder as subjID!
else
    fprintf('Subject folder found. No need to create one\n');
end

if ~exist(strcat(mypath,subjID,'\',num2str(session)), 'dir')
    mkdir(strcat(mypath,subjID,'\',num2str(session)))   % For session folder!
end

