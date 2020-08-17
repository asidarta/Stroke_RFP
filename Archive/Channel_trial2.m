
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

% Define the workspace for H-man for the purpose of plotting.
minX = -0.15;  maxX = 0.15;
minY = -0.05;  maxY = 0.25;

hfig1 = figure(1); % call the plot first
  plot(0,0); hold on;
  xlim([minX maxX]); ylim([minY maxY]);

fSample = 200;  % to pause the loop (Hz)
null_force(instance);

% Define channel parameters, if any: size in X-axis (mm), and angle (deg).
% If the X pos (in mm unit) is fighting the channel, activate force!!!
ch_size = 5;
stiff   = [2000 0;0 1];   % N/m stiffness

% Define channel angle w.r.t X-axis, in degrees.
theta = 30;
% Define rotation matrix w.r.t X-axis
%rot_matX = [ cosd(theta) -sind(theta); sind(theta) cosd(theta) ];
% Define rotation matrix w.r.t Y-axis >>>
rot_matY = [ cosd(90-theta) -sind(90-theta); sind(90-theta) cosd(90-theta) ];
% Compute stiffness matrix w.r.t Y-axis >>>
k_matY   = rot_matY * stiff * rot_matY';


%% Plot XY position in space
while (1)
    % Read instantaneous position (in metre)
    posX = instance.current_x;
    posY = instance.current_y;
    pause(1/fSample); 

    % Compute rotation matrix w.r.t X-axis....
    posRot = rot_matY * [posX; posY];
  
    if ( abs(posRot(1)) > ch_size/1000 )  % note unit change!
        %figure(1); plot(posRot(1), posRot(2), 'r.', 'MarkerSize', 20);
        plot(posX, posY, 'r.', 'MarkerSize', 20);
        instance.SetTarget( num2str(sign(posRot(1))*ch_size), ...
                            num2str(posRot(2)), ...
                            num2str(k_matY(1,1)), num2str(k_matY(2,2)), ...
                            num2str(-k_matY(1,2)), num2str(-k_matY(2,1)), ...
                            '0','0','0','0','1','0' );                     
    else
        %figure(1); plot(posRot(1), posRot(2), 'g.', 'MarkerSize', 20);
        plot(posX, posY, 'g.', 'MarkerSize', 20);
        instance.SetTarget( '0','0','0','0','0','0','0','0','0','0','1','0' ); 
    end
    
    % Detect key press then bail out
    isKeyPressed = ~isempty(get(hfig1,'CurrentCharacter'));
    if isKeyPressed
        break
    end
    
end

null_force(instance);
close all;


%% Stop the saving data process
%instance.saveData = false;


%% Stop H-MAN
%instance.StopSystem()
