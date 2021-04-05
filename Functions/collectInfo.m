
function [subjID, session, block, filename, control] = collectInfo( strName )

% This function gets subject information from the user input such as subj ID, session #, 
% block, and if it's a control group. This is used to produce file and folder name to save. 

% NOTE: This is hardcoded here!
mypath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\Trial Data\';

if (isempty(strName)), strName = 'result'; end


%% Important!! 
% We have to check if the subject folder has been created in the working directory. 
subjID  = input('\nEnter subject ID (Sxx): ','s');
block   = 0;
if ~exist(strcat(mypath,subjID), 'dir')
    fprintf('Subject folder not found. Creating one....\n\n');
    mkdir(strcat(mypath,subjID))    % name the folder as subjID!
else
    fprintf('Subject folder found or already created!\n\n');
end




%% Check if this is training session. If yes you have to input session
% number (multiple sessions), and also block number. Assessment has only 
% one block.

% Let's use try..catch!
try
    if (strName == "train")
        session = input('Enter session number  : ');
%           fprintf('Data for today not found. Creating one....\n\n');
%        end
        %block   = input('Enter block number    : ');
%       if (exist(strcat(mypath,subjID,'\',num2str(session),'\train.dat'),'file'))
%           mysetting = readtable(strcat(mypath,subjID,'\',num2str(session),'\train.dat'));
%           block   = mysetting.block + 1;     %%%%%%>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%           control = char(mysetting.control);
%       else
            block   = input('Enter block number    : ');
            control = input('Is this control group? (y/n) ','s');
%           fprintf('Creating a new setting file');
%       end
    else
        session = input('Enter session name    : ','s');
        block = 1; control='y';
    end
catch
    warning('Error: Check if you give the correct inputs .........');
end

% If the session folder doesn't exist, create one first to save the data
if ~exist(strcat(mypath,subjID,'\',num2str(session)), 'dir')
    mkdir(strcat(mypath,subjID,'\',num2str(session)))   % For session folder!
end
    
    
    
%% Extract current time
formatOut = 'HHMM'; 

% (25/2) I added subject folder and session folder to place the saved data in!!
filename = strcat(subjID,'\',num2str(session),'\',subjID,'_',strName,'_',num2str(session),...,
                  '_',num2str(block),'_',datestr(now,formatOut));

