

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--- Note: Code for Passive Assessment of Proprioception Type 2 (H-MAN style) ----
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clc;
clear; close all; 
fprintf("\n------ Passive Matching Task with Keypress -----\n");

% (0) Produce filename for the current trial based on user-defined information imgNum 
% refers to block number; now using GUI! (4 Apr 2021).
guiOut = gui( 'somato2' );
save('setting.mat', 'guiOut');   % save the updated subject's setting
subjID = guiOut.subject;  myresultfile = guiOut.filename;  
control= guiOut.control;  practice = guiOut.practice;
session = str2num(guiOut.session); imgNum = str2num(guiOut.block);


%% Then establish connection with H-MAN!
% Obtain the instance handler, stiffness, and damping parameters.
[instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();


%% Trial-related parameters -----------------------------------------------
Ntrial = 20;        % Total number of trials per block
toshuffle = repmat(1:4,[1 Ntrial/4]);       % We have 4 target directions!!
eachTrial = Shuffle(toshuffle);             % We shuffle the target position
trialData = double.empty();
toSave = double.empty();                    % Initialize variable to save kinematic data
lastXpos = instance.hman_data.location_X;   % To contain robot latest Ypos
lastYpos = instance.hman_data.location_Y;   % To contain robot latest Ypos
k_asst = 250;   % max Stiffness value (N/m) for assistive mode
global myPath;

% Create a flag to denote which stages of the movement it is:
%        5: robot moves to a target (reference traj)
%        6: robot moves back to origin
%        1: subject moves actively to the target
%        3: robot moves back to origin
trialFlag = 1;

% Sample frequency, timing parameters ------------------------------------
sample_freq = 200;      % Define so that sample freq remains the same!
move_duration = 1.0;    % estimated to be 2 sec movement!
t = 0: 1/sample_freq : move_duration;
curTrial = 1;           % Initialize current trial=1
timerFlag = true;       % Inttialize timerFlag to activate timer
delay_at_target = 2.0;  % Hold at target position (2-sec)


%% GAMING DISPLAY: Plot the X,Y data --------------------------------------
SetMouse(10,10);  % Put away mouse cursor
% Call the function to prepare game display!
fig = game_interface(1,0,0);

% Define keyboard press function associated with the window!
set(fig,'WindowKeyPressFcn',@KeyPressFcn);
% Define global variable as a flag to quit the main loop upon a keypress.
global bailOut;  
global replayOut;  
global pauseFlag;
bailOut = false;   replayOut = false;   pauseFlag = true;

% Create circular target traces. Here, I define four target locations for reaching.
targetDist = 0.11;     % 11 cm reference distance 
replay_Dist = 0.17;    % 17 cm replay distance (to be used in PART-2)

c = 0.005*[cos(0:2*pi/100:2*pi);sin(0:2*pi/100:2*pi)];
plot( c(1,:)+targetDist*cosd(30), c(2,:)+targetDist*sind(30), ...
      c(1,:)+targetDist*cosd(60), c(2,:)+targetDist*sind(60), ... 
      c(1,:)+targetDist*cosd(120),c(2,:)+targetDist*sind(120), ...
      c(1,:)+targetDist*cosd(150),c(2,:)+targetDist*sind(150), 'LineWidth',5);

% Let's compute the centre of the TARGET locations (convert to mm unit).
% NOTE: I don't define the targetDist here because the distance may vary in every loop !!
targetCtr = 1000 * [[cosd(30); cosd(60); cosd(120); cosd(150)], [sind(30); sind(60); sind(120); sind(150)]] ;
ang = [30,60,120,150];  % Angle (degree) w.r.t positive X-axis.

% Define the required audio file: Ask subjects to stay relaxed!
[eyes_wav, Fs] = audioread( strcat(myPath,'\Audio\close_eyes.mp3') );
sound(eyes_wav, Fs);
text(-0.075,0.13,'Eyes closed and always relax!','FontSize',38,'FontWeight','bold','Color','g');

% Reading audio file for reference movement
[ref, Fs]   = audioread( strcat(myPath,'\Audio\reference.mp3') );
[match, Fs] = audioread( strcat(myPath,'\Audio\matching.mp3') );

fprintf('\nPress <Spacebar> to continue ..........\n');
while pauseFlag     % There will be Pause to ensure subjects are ready
    pauseText = text(-0.055,0.14,"Ready to play?",'FontSize',55,'Color','w','FontWeight','bold');
    pause(0.5);   delete(pauseText);
end



%% TRIAL LOOP = Keep looping until Ntrial is met OR a key is pressed
while (curTrial <= Ntrial) && (~bailOut)
    
    m = eachTrial(curTrial);  
    fprintf('\nTRIAL %d, ANGLE: %d\n', curTrial, ang(m));
    
    % PART 1: Generate reference trajectory to a target position ---------------------
    % (1) Ensure robot produces no force
    null_force(instance);

    % (2) Set target position and other parameters
    start_X = 0;   start_Y = 0;
    end_X   = targetDist * targetCtr(m,1);  % Unit: mm -> m
    end_Y   = targetDist * targetCtr(m,2);  % Unit: mm -> m

    % (3) Creating minimum jerk trajectory to target position
    out = min_jerk([start_X start_Y 0], [end_X end_Y 0], t);
    fprintf('   1. Producing reference trajectory.\n');
    % Convert position into string for robot command
    Xpos = num2str(out(:,1)); Ypos = num2str(out(:,2));

    %[ref, Fs] = audioread( strcat(myPath,'\Audio\reference.mp3') );
    %sound(ref, Fs); pause(1.0); 
    
    % (4a) Move handle to target!
    trialFlag = 5;
    for j = 1:length(out)
        xt = Xpos(j,:);  yt = Ypos(j,:);
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        trialData(j,:) = [ curTrial, trialFlag, m, ang(m), ... 
                           double(instance.hman_data.location_X), double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), double(instance.hman_data.velocity_Y), ...
                           double(instance.hman_data.state), double(instance.hman_data.force) ];
        if (bailOut)
            break; % Shall bail out if we press any key!
        end
    end
   
    if (~isempty(trialData))
        % Plot this trajectory. Save trial data into a mega array;    
        h1 = plot(trialData(:,5), trialData(:,6), 'b.');
        toSave = [toSave; trialData];
        trialData = double.empty();
    end
    
    % Pause for 2 seconds at the target location
    pause_me(delay_at_target);   

    % (5) Create minimum jerk trajectory back to START position
    out2 = min_jerk([end_X end_Y 0], [start_X start_Y 0], t);
    % Convert position into string for robot command
    Xpos = num2str(out2(:,1)); Ypos = num2str(out2(:,2));
    
    % (6) Move handle back to ORIGIN, zero position 
    trialFlag = 6;
    for j = 1:length(out2)
        xt = Xpos(j,:);  yt = Ypos(j,:);
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        trialData(j,:) = [ curTrial, trialFlag, m, ang(m), ... 
                           double(instance.hman_data.location_X), double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), double(instance.hman_data.velocity_Y), ...
                           double(instance.hman_data.state), double(instance.hman_data.force)];
        if (bailOut)
            break; % Shall bail out if we press any key!
        end
    end
    
    if (~isempty(trialData))
        % Plot this trajectory. Save trial data into a mega array;    
        h2 = plot(trialData(:,5), trialData(:,6), 'b.');
        toSave = [toSave; trialData];
        trialData = double.empty();
    end
        
    % (7) Hold the handle position at the START.
    hold_pos(instance);  pause_me(delay_at_target);  
    
    while pauseFlag   % Updated Mar 2021; pause the game by pressing "Spacebar"
        pauseText = text(-0.04,0.16,"Pausing...",'FontSize',55,'Color','w','FontWeight','bold');
        pause(0.5);
        delete(pauseText);
    end
    
    
    % PART 2: Let the user decides to match the reference distance ----------------------
    % (1) Ensure robot produces no force
    null_force(instance);

    % (2) Set target position and other parameters. NOTE: Provide longer replay distance!!
    start_X = 0;   start_Y = 0;
    end_X   = replay_Dist * targetCtr(m,1);  % Unit: mm -> m
    end_Y   = replay_Dist * targetCtr(m,2);  % Unit: mm -> m

    % (3) Creating minimum jerk trajectory to target position. NOTE: Now the speed must be slower!!
    t_replay = 0: 1/sample_freq : move_duration*10;
    out = min_jerk([start_X start_Y 0], [end_X end_Y 0], t_replay);
    fprintf('   2. Passive matching trajectory.\n');
    % Convert position into string for robot command
    Xpos = num2str(out(:,1)); Ypos = num2str(out(:,2));

    % (4a) Move handle to target for matching task!
    trialFlag = 1;
    for j = 1:length(out)
        xt = Xpos(j,:);  yt = Ypos(j,:);
        instance.SetTarget(xt,yt,'1600','1600','0','0','10','10','0','0','1','0');  %%%%%%%%%%%%
        pause(1/sample_freq);
        trialData(j,:) = [ curTrial, trialFlag, m, ang(m), ... 
                           double(instance.hman_data.location_X), double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), double(instance.hman_data.velocity_Y), ...
                           double(instance.hman_data.state), double(instance.hman_data.force) ];
        if (replayOut)
            fprintf('   3. Participant produced answer! Saving current position\n');
            replayOut = false;
            break; % Shall bail out if we press any key!
        end
        if (bailOut)
            break; % Shall bail out if we press any key!
        end
    end
   
    if (~isempty(trialData))
        % Plot this trajectory. Save trial data into a mega array;    
        h3 = plot(trialData(:,5), trialData(:,6), 'b.');
        toSave = [toSave; trialData];
        trialData = double.empty();
    end
    
    % Pause for 2 seconds at the target location
    pause_me(delay_at_target);   

    % (5) Capture the current handle position....
    now_X = instance.hman_data.location_X*1000;  % Take note unit!
    now_Y = instance.hman_data.location_Y*1000;

    % (6) Create minimum jerk trajectory back to START position
    out2 = min_jerk([now_X now_Y 0], [start_X start_Y 0], t);
    % Convert position into string for robot command
    Xpos = num2str(out2(:,1)); Ypos = num2str(out2(:,2));
    
    % (7) Move handle back to ORIGIN, zero position 
    trialFlag = 3;
    for j = 1:length(out2)
        xt = Xpos(j,:);  yt = Ypos(j,:);
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        trialData(j,:) = [ curTrial, trialFlag, m, ang(m), ... 
                           double(instance.hman_data.location_X), double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), double(instance.hman_data.velocity_Y), ...
                           double(instance.hman_data.state), double(instance.hman_data.force)];
        if (bailOut)
            break; % Shall bail out if we press any key!
        end
    end
    
    if (~isempty(trialData))
        % Plot this trajectory. Save trial data into a mega array;    
        h4 = plot(trialData(:,5), trialData(:,6), 'b.');
        toSave = [toSave; trialData];
        trialData = double.empty();
    end
        
    % (8) Hold the handle position at the START.
    hold_pos(instance);
    pause_me(delay_at_target);
    fprintf('   4. Moving to NEXT TRIAL!\n');
    
    % (9) Clear the figure from old position data. First, obtain the handler to the
    % children part of the figure, then delete the components!
    try    
        delete([h1,h2,h3,h4]);
    catch
    end
    % (10) Ready to continue to the next trial...
    curTrial = curTrial + 1;

end


%% Saving trial data.........
        % Recording important kinematic data for each trial
        %    col-1 : Trial number
        %    col-2 : Stage of movement
        %    col-3,4 : Target position, angle (m)
        %    col-5,6 : handle X,Y position
        %    col-7,8 : handle X,Y velocity
        %    col-9   : Emergency button state
        %    col-10  : force value
if (~practice && ~isempty(toSave))
    varNames = {'trial','flag','m','angle','posX','posY','velX','velY','emerg','force'};
    writetable( array2table(toSave,'VariableNames',varNames), ... % Trajectory data
            strcat(myPath, 'Trial Data\',myresultfile,'.csv')); 
end
% For safety: Ensure the force is null after quiting the loop!
null_force(instance); 

% Stop TCP connection 
instance.CloseConnection();
fprintf("\nClosing connection to H-man................\n");


%% Indicate code has ended by playing an audio message
[mywav, Fs] = audioread( strcat(myPath,'\Audio\claps3.wav') );
sound(mywav, Fs);
fprintf('\nProprioception Test-2 finished, bye!!\n');
pause(2.0)
close all; clear; clc;  % Wait to return to MainMenu?
fprintf("\nReturning to Main Menu selection..........\n");


%% Function to detect ESC keyboard press, it returns the flag defined as global.
% Another key press events are for response and pausing the game...
function [bailOut, replayOut] = KeyPressFcn(~,evnt)
    global bailOut;  global replayOut;  global pauseFlag;
    %fprintf('key event is: %s\n',evnt.Key);
    if(evnt.Key=="escape")
       bailOut = true;
       replayOut = false;
    end
    if(evnt.Key=="return")
       bailOut = false;
       replayOut = true;
    end
    if(evnt.Key=="space")
       pauseFlag = ~pauseFlag; 
       if (pauseFlag), fprintf("Pausing the game now.....\n");
       else, fprintf("Continuing the game now.....\n");
       end
    end
end
