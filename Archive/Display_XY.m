
%%% This code will plot the XY position of the end-effector in space.
%%% Note: This code is independent of PsychToolBox.


%clear; clc

% Load the DLL files
my_pwd = 'C:\Users\rris\Documents\MATLAB\Control library\.dll files\';
Articares = NET.addAssembly(strcat(my_pwd,'\Articares.Core.dll'));
Log = NET.addAssembly(strcat(my_pwd,'\NLog.dll'));

% Connect H-MAN to the workstation
%instance = ConnectHman();

%% Write in the NLog text file
NLog.Common.InternalLogger.Info('Connection with H-MAN established');


%% Saving the position data
% Initialize the data saving process
%instance.saveData = true;
%pause(5) % pause the script for 5 seconds
% Check if the data is saving
%instance.tempData

% Save the data in a MATLAB variable
%data = ToArray(GetRange(instance.tempData,0,instance.tempData.Count));

% Define the workspace for H-man for the purpose of plotting.
minX = -0.15;  maxX = 0.15;
minY = -0.05;  maxY = 0.25;

hfig = figure(1); % call the plot first
  plot(0,0); hold on;
  xlim([minX maxX]); ylim([minY maxY]);

fSample = 200;  % to pause the loop (Hz)
null_force(instance);

% Define channel parameters, if any: size in X-axis (mm), and angle (deg).
% If the X pos (in mm unit) is fighting the channel, activate force!!!
Xch_size = 40;
kxx = 2000;   % N/m stiffness
toSave = double.empty(); 

%% Plot XY position in space
while (1)
    % Read instantaneous position (in metre)
    tic;
    posX = instance.current_x;
    posY = instance.current_y;
    pause(1/fSample); 
    %plot(posX, posY, 'r.', 'MarkerSize', 20); hold on;
    %fprintf('Current posX = %d, posXr = %d\n',posX,posY);

    %instance.SetTarget( num2str( sign(posRot(1))*Xch_size), num2str(posRot(2)), ...
    if ( abs(posX) > Xch_size/1000 )  % note unit change!
        plot(posX, posY, 'r.', 'MarkerSize', 20);
        %fprintf('Pushing channel\n');
        instance.SetTarget( num2str( sign(posX)*Xch_size), num2str(posY), ...
                            num2str(kxx),'0','0','0','0','0','0','0','1','0' ); 
    else
        plot(posX, posY, 'g.', 'MarkerSize', 20);
        %fprintf('Channel off...\n');
        instance.SetTarget( '0','0','0','0','0','0','0','0','0','0','1','0' ); 
    end
    
    % Detect key press then bail out
    isKeyPressed = ~isempty(get(hfig,'CurrentCharacter'));
    if isKeyPressed
        break
    end
    
    delay  = toc;
    toSave = [toSave; [posX, posY, delay]];
    
end

null_force(instance);
close all;

% Save the trajectory data......
dlmwrite(strcat(myPath, 'Trial Data\','m.csv'), toSave);

%% Stop the saving data process
%instance.saveData = false;


%% Stop H-MAN
%instance.StopSystem()
