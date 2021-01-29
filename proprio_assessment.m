

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%---- Note: Code for Passive Assessment of Proprioception Type 1 (Joint Position Matching) ---
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clc;
clear; close all; 
fprintf("\n--------   Joint Position Matching   --------\n");


%% First, establish connection with H-MAN!
% Obtain the instance handler, stiffness, and damping parameters.
[instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();

% (0) Produce filename for the current trial based on user-defined information
[subjID, ~, ~, myresultfile] = collectInfo( "somato_jpm" );


%% Trial-related parameters -----------------------------------------------
Ntrial = 40;
toshuffle = repmat(1:4,[1 Ntrial/4]);   % We have 4 target directions!!
eachTrial = Shuffle(toshuffle);
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';

trialData = double.empty();
toSave = double.empty();
lastXpos = instance.hman_data.location_X; 
lastYpos = instance.hman_data.location_Y;
k_asst = 250;   % max Stiffness value (N/m) for assistive mode

% Create a flag to denote which stages of the movement it is:
%        5: robot moves to a target (reference traj)
%        6: robot moves back to origin
%        1: subject moves actively to the target
%        3: robot moves back to origin
trialFlag = 1;

% Sample frequency, timing parameters ------------------------------------
sample_freq = 200;
move_duration = 1.0;    % estimated to be 2 sec movement!
t = 0: 1/sample_freq : move_duration;
curTrial = 1; 
timerFlag = true;
delay_at_target = 1.0;  % Hold at target position (sec)


%% GAMING DISPLAY: Plot the X,Y data --------------------------------------
SetMouse(10,10);  % Put away mouse cursor
% Call the function to prepare game display!
fig = game_interface(1,0,0);

% Define keyboard press function associated with the window!
set(fig,'WindowKeyPressFcn',@KeyPressFcn);
% Define global variable as a flag to quit the main loop upon a keypress.
global bailOut    
bailOut = false;

% Create circular target traces. Here, I define four target locations for reaching.
targetDist = 0.15;

c = 0.005*[cos(0:2*pi/100:2*pi);sin(0:2*pi/100:2*pi)];
plot( c(1,:)+targetDist*cosd(30), c(2,:)+targetDist*sind(30), ...
      c(1,:)+targetDist*cosd(60), c(2,:)+targetDist*sind(60), ... 
      c(1,:)+targetDist*cosd(120),c(2,:)+targetDist*sind(120), ...
      c(1,:)+targetDist*cosd(150),c(2,:)+targetDist*sind(150), 'LineWidth',5);

% Let's compute the centre of the TARGET locations (convert to mm unit).
% Here, I define four visual target locations for reaching.
targetCtr  = targetDist* [ [cosd(30); cosd(60); cosd(120); cosd(150)], ... 
                           [sind(30); sind(60); sind(120); sind(150)] ] ;
ang = [30,60,120,150];  % Angle (degree) w.r.t positive X-axis.

% Define the required audio file: Ask subjects to stay relaxed!
[eyes_wav, Fs] = audioread( strcat(myPath,'\Audio\close_eyes.mp3') );
pause(2.0); sound(eyes_wav, Fs);



%% TRIAL LOOP = Keep looping until Ntrial is met OR a key is pressed
pause_me(2.0)
while (curTrial <= Ntrial) && (~bailOut)
    
    m = eachTrial(curTrial);  
    fprintf('\nTRIAL %d, ANGLE: %d\n', curTrial, ang(m));
    
    % PART 1: Generate reference trajectory to a target position ---------------------
    % (1) Ensure robot produces no force
    null_force(instance);

    % (2) Set target position and other parameters
    start_X = 0;   start_Y = 0;
    end_X   = 1000 * targetCtr(m,1);  % Unit: mm -> m
    end_Y   = 1000 * targetCtr(m,2);  % Unit: mm -> m

    % (3) Creating minimum jerk trajectory to target position
    out = min_jerk([start_X start_Y 0], [end_X end_Y 0], t);
    fprintf('   1. Producing reference trajectory.\n');
    % Convert position into string for robot command
    Xpos = num2str(out(:,1)); Ypos = num2str(out(:,2));

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
    pause_me(2*delay_at_target);   

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
    hold_pos(instance);

    % (8) Play BEEP tone and display MOVE cue for 1.5 sec...
    %pause_me(1);  
    goCue = plot_image([], 10, 0, 0.1, 20);
    play_tone(1250, 0.2);
    pause_me(delay_at_target);
    pause_me(delay_at_target);  
    
    
    % PART 2: Let the user moves the handle to a target position ----------------------
    % (1) Preparation. Produce zero force.   
    trialFlag = 1; %a = []; 
    fprintf('   2. Now joint position matching\n');
    j = 1;
    null_force(instance);
    incrStiff = 0;      % stiffness ramping counter
    t_active = tic;     % timer for active reaching
    delete(goCue);      % remove go visual cue
    
    while (~bailOut)
        %plot(instance.location_X, instance.location_Y, 'r.');
        pause_me(1/sample_freq);

        % Computing speed (Robot velocity readout is not good!)
        speedX = (instance.hman_data.location_X - lastXpos);   
        speedY = (instance.hman_data.location_Y - lastYpos);
        speed  = 1000* sqrt(speedX^2 + speedY^2);  % unit in mm/sec.
        
        % Compute the distance between the CURSOR and the START centre
        dist2Start = sqrt(instance.hman_data.location_X^2 + instance.hman_data.location_Y^2);

        % Compute the distance between the CURSOR and the TARGET centre
        dist2Target = sqrt((instance.hman_data.location_X-end_X/1000)^2 + ...
                           (instance.hman_data.location_Y-end_Y/1000)^2);

        trialData(j,:) = [ curTrial, trialFlag, m, ang(m), ...
                           double(instance.hman_data.location_X), double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), double(instance.hman_data.velocity_Y), ...
                           double(instance.hman_data.state), double(instance.hman_data.force)];
        %a = [a; speed];
        %figure(2); plot(a); ylim([0 2]); hold on;

        % (2) If after 4 sec subjects cannot move well, and the distance from the start 
        % is too short, it's likely the arm is too weak. Activate assistive mode!
        if ( dist2Start <= 0.1 )
            if ( toc(t_active) > 4 )
                if (~incrStiff)
                	fprintf("   3a. Assistive mode is ON\n");
                end
                if (incrStiff > k_asst)  % Assistive mode
                    incrStiff = k_asst;
                end                                    
                instance.SetTarget( num2str(end_X),num2str(end_Y),num2str(incrStiff), ...
                                    num2str(incrStiff),'0','0','10','10','0','0','1','0' );     
                incrStiff = incrStiff + 5;
            end
        % (3) If far enough, it means subjects are capable of still moving.
        % Check if they have stopped moving and held the hand stationary!
        else
            if( speed < 1 )
                if (timerFlag)
                    fprintf("   3. Good. Handle moves far enough...\n");
                    tic;
                    timerFlag = false;
                end
                % Once the hand is stationary for 2 second, then....
                if (toc > 2)
                    fprintf("   4. Hold position remains for 1 sec!\n");
                    timerFlag = true;
                    break
                end
            end
        end
              
        lastXpos = instance.hman_data.location_X; lastYpos = instance.hman_data.location_Y;
        j=j+1; % loop counter
        
    end
    
    if (~isempty(trialData))
        % Plot this trajectory. Save trial data into a mega array;
        h3 = plot(trialData(:,5), trialData(:,6), 'r.');
        toSave = [toSave; trialData];
        trialData = double.empty();
    end
   
    % (4) Preparing to move back from the Target!
    % Then hand position can move back to the center.
    trialFlag = 3;
    fprintf('   5. Handle moves back to the origin\n');

    % Create minimum jerk trajectory back to START position
    out4 = min_jerk([instance.hman_data.location_X*1000 instance.hman_data.location_Y*1000 0], ... 
                    [start_X start_Y 0], t);
    % Convert position into string for robot command
    Xpos = num2str(out4(:,1)); Ypos = num2str(out4(:,2));
    
    % (5) Move handle back to ORIGIN, zero position 
    for j = 1:length(out4)
        xt = Xpos(j,:);  yt = Ypos(j,:);
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        if (bailOut)
            break; % Shall bail out if we press any key!
        end
    end

    % (6) Hold the handle position at the START, pause for 2 sec.
    hold_pos(instance);
    pause_me(2);
    fprintf('   6. Moving to NEXT TRIAL!\n');
    
    % (7) Clear the figure from old position data. First, obtain the handler to the
    % children part of the figure, then delete the components!
    try    
        delete([h1,h2,h3]);
    catch
    end
    % (8) Ready to continue to the next trial...
    curTrial = curTrial + 1;

end



%% Saving trial data.........
dlmwrite(strcat(myPath, 'Trial Data\',myresultfile,'.csv'), toSave);
        % Recording important kinematic data for each trial
        %    col-1 : Trial number
        %    col-2 : Stage of movement
        %    col-3,4 : Target position, angle (m)
        %    col-5,6 : handle X,Y position
        %    col-7,8 : handle X,Y velocity
        %    col-9   : Emergency button state

% For safety: Ensure the force is null after quiting the loop!
null_force(instance); 

% Stop TCP connection 
instance.CloseConnection();
fprintf("\nClosing connection to H-man................\n");


%% Indicate code has ended by playing an audio message
[mywav, Fs] = audioread( strcat(myPath,'\Audio\claps3.wav') );
sound(mywav, Fs);
fprintf('\nProprioception Test finished, bye!!\n');
pause(2.0)
close all; clear; clc;  % Wait to return to MainMenu?
fprintf("\nReturning to Main Menu selection..........\n");


%% Function to detect ESC keyboard press, it returns the flag defined as global.
function bailOut = KeyPressFcn(~,evnt)
    global bailOut
    %fprintf('key event is: %s\n',evnt.Key);
    if(evnt.Key=="escape")
       bailOut = true;  %fprintf('--> You have pressed wrongly, dear!\n');
    end
end
