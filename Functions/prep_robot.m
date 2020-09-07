
function [instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot()
   % This function will establish connection to the robot. At the same time,
   % it is the place to define robot instances, stiffness, and damping.


%% Load the DLL files
my_pwd = 'C:\Users\rris\Documents\MATLAB\Control library\V2\';
Articares = NET.addAssembly(strcat(my_pwd,'\Articares.Core.dll'));
Log = NET.addAssembly(strcat(my_pwd,'\NLog.dll'));


%% Establish connection with robot!
fprintf("Preparing connection to H-man................\n");

% IMPORTANT: This creates the object ‘instance’ of the ‘Articares.Core.ArticaresComm’ 
% class through a MATLAB function and establish the TCP connection
instance = ConnectHMan();

% Call this immediately after opening a connection to H-MAN!
% H-MAN will not produce any force to the handle and send response data, unless target 
% parameters for all active targets have been set. We send a dummy setTarget.
instance.StartExercise();
instance.SetTarget('0','0','0','0','0','0','0','0','0','0','1','0')


%% Robot parameter setup: stiffness (N/m) and viscuous field (N.s/m)!
% Set stiffness and damping parameters in numerical values.
kxx = num2str(3500);
kyy = num2str(3500);
kxy = num2str(0); 
kyx = num2str(0);
bxx = num2str(0);  
byy = num2str(0);
bxy = num2str(0); 
byx = num2str(0);

% Set H-MAN timeout in millisecond!
instance.timeout_ms = 5;

% Set to enable safety feature!
instance.SetSafety(true);

% Toggle filter for the velocity data
%instance.ToggleFilter(1);