
%%% This code features virtual channel production for H-man robot.
%%% Source: Campolo D, et al. 2014 on the passive haptic field.

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
minY = -0.15;  maxY = 0.15;

hfig = figure(1); % call the plot first
  plot(0,0); hold on;
  xlim([minX maxX]); ylim([minY maxY]);
  pause(0.5);
  
fSample = 200;  % to pause the loop (Hz)
null_force(instance);

% Define channel parameters, if any: size in X-axis (mm), and angle (deg).
% If the X pos (in mm unit) is fighting the channel, activate force!!!
Xch_size = 30;

% Define channel angle w.r.t X-axis (in degrees).
theta = 45;
rot_mat = [ cosd(theta) -sind(theta); sind(theta) cosd(theta) ];
stiff   = [ 1 0; 0 1000 ];   % see tha paper for elliptical field.
damping = [ 0 0; 0 0 ];     % see tha paper for elliptical field.
k_mat   = rot_mat * stiff * rot_mat';
damp    = rot_mat * damping * rot_mat';


%% Plot XY position in space
while (1)
    % Read instantaneous position (in metre)
    posX = instance.current_x;  
    posY = instance.current_y;
    pause(1/fSample); 

    %if ( abs(instance.torque_L) > 2.5 ||  abs(instance.torque_R) > 2.5 )
    %    col = 'red';
    %else
    %    col = 'green';
    %end
    
    posRot = [ cosd(90-theta) -sind(90-theta); sind(90-theta) cosd(90-theta) ] * [posX; posY];
    k_mat  = [ cosd(theta) -sind(theta); sind(theta) cosd(theta) ] * stiff
    %posRot = rot_mat * [posX; posY];
    
    if (abs(posRot(1)) > Xch_size/1000)
        %posX = posX - sign(posX)*0.03;
        col = 'red';
        instance.SetTarget( num2str(sign(posX)*Xch_size), num2str(posY), ...
                        num2str(k_mat(1,1)), num2str(k_mat(2,2)), ...
                        num2str(k_mat(2,1)), num2str(k_mat(1,2)), ...
                        num2str(damp(1,1)),  num2str(damp(2,2)), ...
                        num2str(damp(2,1)),  num2str(damp(1,2)), ...
                        '1','0' ); 
    else
        col = 'green';
        instance.SetTarget( '0','0','0','0','0','0','0','0','0','0','0','0' ); 
    end
 
    plot(posX, posY, '.', 'Color', col, 'MarkerSize', 20);
    
    % Detect key press then bail out
    %isKeyPressed = ~isempty(get(hfig,'CurrentCharacter'));
    if (KbCheck)
        break
    end
end

null_force(instance);
%close all;

%% Stop the saving data process
%instance.saveData = false;


%% Stop H-MAN
%instance.StopSystem()
