
%%% This code will plot the XY position of the end-effector in space.
%%% Note: This code is independent of PsychToolBox.


%clear; clc

% Load the DLL files
my_pwd = 'C:\Users\rris\Documents\MATLAB\Control library\.dll files\';
Articares = NET.addAssembly(strcat(my_pwd,'\Articares.Core.dll'));
Log = NET.addAssembly(strcat(my_pwd,'\NLog.dll'));

% Connect H-MAN to the workstation
%instance = ConnectHmanV1();

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
ch_size = 10;
stiff   = [1000 0;0 1];  % N/m stiffness
damp    = [0 0;0 0];     % N/m viscous field


% Define channel angle w.r.t X-axis, in degrees.
theta = 90;
% Define rotation matrix w.r.t X-axis
%rot_matX = [ cosd(theta) -sind(theta); sind(theta) cosd(theta) ];
% Define rotation matrix w.r.t Y-axis >>>
rot_matY = [ cosd(90-theta) -sind(90-theta); sind(90-theta) cosd(90-theta) ];
% Compute stiffness and damping matrix w.r.t Y-axis >>>
k_matY   = rot_matY * stiff * rot_matY';
b_matY   = rot_matY * damp  * rot_matY';


%% Plot XY position in space
while (1)
    % Read instantaneous position (in metre)
    posX = instance.current_x;
    posY = instance.current_y;
    fprintf('Total force = %f\n',instance.force_tot);
    pause(1/fSample); 

    % Compute rotation matrix w.r.t X-axis....
    posRot = rot_matY * [posX; posY];
  
    % NOTE: unit of position changed!
    if ( abs(posRot(1)) > ch_size/1000 && posRot(2) <= 0.06 )
        myColour = 'r.';
        instance.SetTarget( num2str(sign(posRot(1))*ch_size), ...
                            num2str(posRot(2)), ...
                            num2str(k_matY(1,1)), num2str(k_matY(2,2)), ...
                            num2str(-k_matY(1,2)), num2str(-k_matY(2,1)), ...
                            num2str(b_matY(1,1)), num2str(b_matY(2,2)), ...
                            num2str(-b_matY(1,2)), num2str(-b_matY(2,1)),'1','0' );
                        
    elseif ( abs(posRot(1)) > ch_size/1000 && posRot(2) > 0.06 )
        myColour = 'k.';
        instance.SetTarget( num2str(posRot(1)*1000), '60', ...
                            '0','1000','0','0','0','0','0','0','1','0' );   
                        
    elseif ( abs(posRot(1)) < ch_size/1000 && posRot(2) > 0.06 )
        myColour = 'k.';
        instance.SetTarget( num2str(posRot(1)*1000), '60', ...
                            '500','500','0','0','0','0','0','0','1','0' );   
    
    elseif ( abs(posRot(1)) < ch_size/1000 && posRot(2) <= 0.06 )
        myColour = 'g.'; % Good zone!!
        instance.SetTarget( '0','0','0','0','0','0','0','0','0','0','1','0' );
    
    end
    
    % Plot the data with certain color!
    plot(posX, posY, myColour, 'MarkerSize', 20);
    
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
