

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------  Notice: Code for Passive Assessment of Proprioception  ---------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clc;
clear; close all; 

%% First, establish connection with H-MAN!
% Obtain the instance handler, stiffness, and damping parameters.
[instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();

% (0) Produce filename for the current trial based on user-defined information
%[subjID, ~, ~, myresultfile] = collectInfo( mfilename );


%% Trial-related parameters -----------------------------------------------
Ntrial = 100;
toshuffle = repmat(1:4,[1 Ntrial/4]);   % We have 4 target directions!!
eachTrial = Shuffle(toshuffle);
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';

trialData = double.empty();
toSave = double.empty();
lastXpos = instance.hman_data.location_X; 
lastYpos = instance.hman_data.location_Y;
k_asst = 200;   % max Stiffness value (N/m) for assistive mode

% Create a flag to denote which stages of the movement it is:
%        5: robot moves to a target (reference traj)
%        6: robot moves back to origin
%        1: subject moves actively to the target
%        3: robot moves back to origin
trialFlag = 1;

% Sample frequency, timing parameters ------------------------------------
sample_freq = 200;
move_duration = 3;
t = 0: 1/sample_freq : move_duration;
curTrial = 1; 
timerFlag = true;
delay_at_target = 1.0;  % Hold at target position (sec)


%% GAMING DISPLAY: Plot the X,Y data --------------------------------------
% Open an empty figure, remove the toolbar.
SetMouse(10,10);  % Place away mouse cursor
fig = figure(1);
set(fig, 'Toolbar', 'none', 'Menubar', 'none');
%mychild = fig.Children;

% Creating a tight margin plot region!
ax = gca;
outerpos = ax.OuterPosition;
ti = ax.TightInset; 
left = outerpos(1) + ti(1)/2;
bottom = outerpos(2) + ti(2)/2;
ax_width = outerpos(3) - ti(1)/2 - ti(3)/2;
ax_height = outerpos(4) - ti(2)/2 - ti(4)/2;
ax.Position = [left bottom ax_width ax_height];

% Create circular target traces. Here, I define four target locations for reaching.
c = 0.005*[cos(0:2*pi/100:2*pi);sin(0:2*pi/100:2*pi)];
targetDist = 0.15;
plot( c(1,:)+targetDist*cosd(30), c(2,:)+targetDist*sind(30), ...
      c(1,:)+targetDist*cosd(60), c(2,:)+targetDist*sind(60), ... 
      c(1,:)+targetDist*cosd(120),c(2,:)+targetDist*sind(120), ...
      c(1,:)+targetDist*cosd(150),c(2,:)+targetDist*sind(150), ...
      c(1,:),c(2,:), 'LineWidth',5);
hold on;

% Setting cosmetic/appearance of the plot
ylim([-0.02,0.18]);
set(gcf,'Position', get(0, 'Screensize'));  % control figure size (full screen)
set(gcf,'Color','k');                       % set figure background color black
set(gca,'FontSize', 14);                    % control font in the figure
set(gca,'XColor','k','YColor','k');         % set grid color to black
set(gca,'Color','k');                       % set plot background color black
set(gca,'XTick',[],'YTick',[]);             % remove X/Y ticks
set(gca,'XTickLabel',[],'YTickLabel',[]);   % remove X/Y tick labels
daspect([1 1 1])                            % maintaining aspect ratio

% Let's compute the centre of the TARGET locations (convert to mm unit).
% Here, I define four visual target locations for reaching.
targetCtr = [[ targetDist*cosd(30);
               targetDist*cosd(60);
               targetDist*cosd(120);
               targetDist*cosd(150)] * 1000, ...
             [ targetDist*sind(30);
               targetDist*sind(60);
               targetDist*sind(120);
               targetDist*sind(150)] * 1000] ;
ang = [30,60,120,150];  % Angle (degree) w.r.t positive X-axis.




%% TRIAL LOOP = Keep looping until Ntrial is met OR a key is pressed
pause_me(2.0)
while (curTrial <= Ntrial) && (~KbCheck)
    
    m = eachTrial(curTrial);  
    fprintf('\nTRIAL %d, ANGLE: %d\n', curTrial, ang(m));
    
    % PART 1: Generate reference trajectory to a target position ---------------------
    % (1) Ensure no force first 
    null_force(instance);

    % (2) Set target position and other parameters
    start_X = 0; %instance.hman_data.location_X*1000;  % Unit: mm -> m
    start_Y = 0; %instance.hman_data.location_Y*1000;  % Unit: mm -> m
    end_X   = targetCtr(m,1);  % Unit: mm -> m
    end_Y   = targetCtr(m,2);  % Unit: mm -> m

    % (3) Minimum jerk haptic targets generation
    out = min_jerk([start_X start_Y 0], [end_X end_Y 0], t);
    fprintf('   1. Producing reference trajectory.\n');
    % Convert position into string for robot command
    Xpos = num2str(out(:,1)); Ypos = num2str(out(:,2));
    
    % (4) Move handle to target!
    trialFlag = 5;
    for j = 1:length(out)
        xt = Xpos(j,:);  yt = Ypos(j,:);
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        %pause(1/sample_freq);
        trialData(j,:) = [ curTrial, trialFlag, m, ang(m), ... %round(end_X), round(end_Y), ...
                           double(instance.hman_data.location_X), double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), double(instance.hman_data.velocity_Y), ...
                           double(instance.hman_data.state) ];
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end
   
    if (~isempty(trialData))
        % Plot this trajectory. Save trial data into a mega array;    
        h1 = plot(trialData(:,5), trialData(:,6), 'b.');
        toSave = [toSave; trialData];
        trialData = double.empty();
    end
    
    % Pause for 3 seconds at the target location
    pause_me(delay_at_target);   

    % (5) Minimum jerk haptic targets to zero (START) position
    out2 = min_jerk([end_X end_Y 0], [start_X start_Y 0], t);
    % Convert position into string for robot command
    Xpos = num2str(out2(:,1)); Ypos = num2str(out2(:,2));
    
    % (6) Move handle back to ORIGIN, zero position 
    trialFlag = 6;
    for j = 1:length(out2)
        xt = Xpos(j,:);  yt = Ypos(j,:);
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        %pause(1/sample_freq);
        trialData(j,:) = [ curTrial, trialFlag, m, ang(m), ... %round(end_X), round(end_Y), ...
                           double(instance.hman_data.location_X), double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), double(instance.hman_data.velocity_Y), ...
                           double(instance.hman_data.state)];
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end
    
    if (~isempty(trialData))
        % Plot this trajectory. Save trial data into a mega array;    
        h2 = plot(trialData(:,5), trialData(:,6), 'b.');
        toSave = [toSave; trialData];
        trialData = double.empty();
    end
        
    % (7) Set zero force. Pause for 2 seconds at the target location.
    hold_pos(instance);

    % (8) Play BEEP tone and disply MOVE cue...
    %pause_me(1);  
    goCue = plot_image(10, 0, 0.1, 20);
    %play_tone(1250, 0.2);
    pause_me(delay_at_target);
    pause_me(delay_at_target);  
    
    
    % PART 2: Let the user moves the handle to a target position ----------------------
    % (1) Preparation. Produce zero force.   
    trialFlag = 1; 
    %a = []; 
    fprintf('   2. Now joint position matching\n');
    j = 1;
    null_force(instance);
    incrStiff = 0;      % stiffness ramping counter  (????????)
    t_active = tic;     % timer for active reaching
    delete(goCue);      % remove go visual cue
    
    while (~KbCheck)
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
                           double(instance.hman_data.state)];
        %a = [a; speed];
        %figure(2); plot(a); ylim([0 2]); hold on;

        % If after 4 sec subjects cannot move well, and the distance from the start 
        % is too short, it's likely the arm is too weak. Activate assistive mode!
        if ( dist2Start <= 0.1 )
            if ( toc(t_active) > 4 )
                if (~incrStiff)
                	fprintf("   3a. Assistive mode is ON\n");
                end
                if (incrStiff > k_asst)  % Assistive mode
                    incrStiff = k_asst;
                end                                    
                instance.SetTarget( num2str(end_X),num2str(end_Y),num2str(incrStiff/2), ...
                                    num2str(incrStiff),'0','0','10','10','0','0','1','0' );     
                incrStiff = incrStiff + 5;
            end
        % If far enough, it means subjects are capable of still moving.
        % Check if they have stopped moving
        else
            if( speed < 1 )
                if (timerFlag)
                    fprintf("   3. Good. Handle moves far enough...\n");
                    tic;
                    timerFlag = false;
                end
                % Once the hand is stationary for 2 seconds, then do this....
                if (toc > 2)
                    fprintf("   4. Hold position remains for 2 sec!\n");
                    timerFlag = true;
                    break
                end
            end
        end
              
        lastXpos = instance.hman_data.location_X;
        lastYpos = instance.hman_data.location_Y;
        j=j+1; % loop counter
        
    end
    
    if (~isempty(trialData))
        % Plot this trajectory. Save trial data into a mega array;
        h3 = plot(trialData(:,5), trialData(:,6), 'r.');
        toSave = [toSave; trialData];
        trialData = double.empty();
    end
   
    % (4) Pause for 3 seconds at the target location
    pause_me(delay_at_target); 
    
    % Hand position moves back to the center.
    trialFlag = 3;
    fprintf('   6. Handle moves back to the origin\n');

    % Minimum jerk haptic targets to zero (START) position
    out4 = min_jerk([instance.hman_data.location_X*1000 instance.hman_data.location_Y*1000 0], ... 
                    [start_X start_Y 0], t);
    % Convert position into string for robot command
    Xpos = num2str(out4(:,1)); Ypos = num2str(out4(:,2));
                
    % (5) Move handle back to ORIGIN, zero position 
    for j = 1:length(out4)
        xt = Xpos(j,:);  yt = Ypos(j,:);
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        %pause(1/sample_freq);
        trialData(j,:) = [ curTrial, trialFlag, m, ang(m), ...
                           double(instance.hman_data.location_X), double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), double(instance.hman_data.velocity_Y), ...
                           double(instance.hman_data.state)];
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end
    
    if (~isempty(trialData))
        % Plot this trajectory. Save trial data into a mega array;    
        toSave = [toSave; trialData];
        trialData = double.empty();
    end
    
    % (6) Set zero force. Pause for 2 seconds at the target location.
    hold_pos(instance);

    % (7) Pause at the zero position for 2 seconds
    pause_me(2);
    fprintf('   7. Moving to NEXT TRIAL!\n');
    
    % (8) Ready to continue to the next trial...
    curTrial = curTrial + 1;
    
    % (9) Clear the figure from old position data. First, obtain the handler to the
    % children part of the figure, then delete the components!
    mychild  = fig.Children.Children;
    delete(mychild(1:length(mychild)-6));

end

%% Saving trial data.........
%dlmwrite(strcat(myPath, 'Trial Data\',myresultfile), toSave);
        % Recording important kinematic data for each trial
        %    col-1 : Trial number
        %    col-2 : Stage of movement
        %    col-3,4 : Target position, angle (m)
        %    col-5,6 : handle X,Y position
        %    col-7,8 : handle X,Y velocity
        %    col-9  : Emergency button state



% For safety: Ensure the force is null after quiting the loop!
null_force(instance); 
close all;

% Stop TCP connection 
instance.CloseConnection();
fprintf("\nClosing connection to H-man................\n");


%% Indicate code has ended by playing an audio message
[mywav, Fs] = audioread( strcat(myPath,'\Audio\claps3.wav') );
sound(mywav, Fs);
fprintf('\nProprioception Test finished, bye!\n');
