
%%% This code will plot the XY position of the end-effector in space.
%%% Note: This code is independent of PsychToolBox.


clear; clc

% Load the DLL files
my_pwd = 'C:\Users\rris\Documents\MATLAB\Control library\V2\';
Articares = NET.addAssembly(strcat(my_pwd,'\Articares.Core.dll'));
Log = NET.addAssembly(strcat(my_pwd,'\NLog.dll'));

% Connect PC to H-MAN. Use this new function to also prepare the setting.
[instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();

%% Write in the NLog text file
NLog.Common.InternalLogger.Info('Connection with H-MAN established');


%% Define the workspace for H-man for the purpose of plotting.
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



%% Loop for using H-man

instance.save_data = true;   % Initialize the data saving process
pause(2)

while (1)
    % Read instantaneous position (in metre)
    tic;
    posX = instance.hman_data.location_X;
    posY = instance.hman_data.location_Y;
    fprintf('My position (cm) is %f and %f\n', 100*posX, 100*posY);
    pause(1/fSample); 

    if (abs(posX*100) > 5)
        instance.SetTarget(num2str(1000*posX),num2str(1000*posY),'500','500',...
                           '0','0','20','20','0','0','1','0');
    else
        null_force(instance)
    end
    % Detect key press then bail out
    isKeyPressed = ~isempty(get(hfig,'CurrentCharacter'));
    if isKeyPressed
        break
    end
    
    delay = toc;
end

null_force(instance);
close all;


%% Saving the position data
% Get H-MAN data from the temporary variable in a MATLAB variable
data = ToArray(GetRange(instance.temp_hman_data_list,0,instance.temp_hman_data_list.Count));

% Stop the saving data process
instance.save_data = false;

% Save data as an array
for tem = 1:data.Length
    saveHMan(tem,1) = data(tem).location_X;
    saveHMan(tem,2) = data(tem).location_Y;
end

% Plot all
plot(saveHMan(:,1)*1000, saveHMan(:,2)*1000, '.')


%% Stop H-MAN
instance.CloseConnection()
