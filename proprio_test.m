
%%% This code will HOLD the end-effector in the current position.

%clear; clc

% Load the DLL files
my_pwd = 'C:\Users\rris\Documents\MATLAB\Control library\.dll files\';
Articares = NET.addAssembly(strcat(my_pwd,'\Articares.Core.dll'));
Log = NET.addAssembly(strcat(my_pwd,'\NLog.dll'));

% Connect H-MAN to the workstation
%instance = ConnectHman();
NLog.Common.InternalLogger.Info('Connection with H-MAN established');


% Trial-related parameters -----------------------------------------------
Ntrial = 40;
hitScore  = 0;   % Add +10 for each time hit the target
toshuffle = repmat(1:5,[1 Ntrial/5]);   % We have 5 target directions!!
eachTrial = Shuffle(toshuffle);
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';

trialData = double.empty();
toSave = double.empty();
lastXpos = 0; lastYpos = 0;

% Create a flag to denote which stages of the movement it is:
%        5: robot moves to a target (reference traj)
%        6: robot moves back to origin
%        1: subject moves back to target
%        3: robot moves back to origin
trialFlag = 1;


%% Plot the X,Y data -----------------------------------------------------
figure(1)
% Create circular target traces
c = 0.005*[cos(0:2*pi/100:2*pi);sin(0:2*pi/100:2*pi)];
targetDist = 0.15;
plot(c(1,:),c(2,:), ...
      c(1,:)+targetDist*cosd(90), c(2,:)+targetDist*sind(90), ...
      c(1,:)+targetDist*cosd(30), c(2,:)+targetDist*sind(30), ...
      c(1,:)+targetDist*cosd(60), c(2,:)+targetDist*sind(60), ... 
      c(1,:)+targetDist*cosd(120),c(2,:)+targetDist*sind(120), ...
      c(1,:)+targetDist*cosd(150),c(2,:)+targetDist*sind(150));
hold on;
axis([-0.18,0.18,-0.1,0.2]);
set(gcf,'Position',[500 300 800 650]);  % control figure position
set(gca,'FontSize', 14);   % control font in the figure
xlabel('X position (m)'); ylabel('Y position (m)');



% Let's compute the centre of the TARGET locations (convert to mm unit)
targetCtr = [[ targetDist*cosd(30);
               targetDist*cosd(60);
               targetDist*cosd(90);
               targetDist*cosd(120);
               targetDist*cosd(150)] * 1000, ...
             [ targetDist*sind(30);
               targetDist*sind(60);
               targetDist*sind(90);
               targetDist*sind(120);
               targetDist*sind(150)] * 1000] ;

           
% Robot-related parameters -----------------------------------------------
% Sample frequency.
sample_freq = 1000;
move_duration = 1;
t = 0: 1/sample_freq : move_duration;
% Robot stiffness and viscuous field!
kxx = num2str(3000); 
kyy = num2str(3000);
kxy = num2str(0); kyx = num2str(0);
bxx = num2str(60);  
byy = num2str(20);

i = 1; 
timerFlag = true;


%% Trial loop. Keep looping until Ntrial is met OR a key is pressed
while (i < Ntrial) && (~KbCheck)
    
    k = eachTrial(i);  
    fprintf('\nTRIAL %d: Reference trajectory.\n', i);
    
    % PART 1: Generate reference trajectory to a target position ---------
    % (1) Ensure no force first 
    null_force(instance);

    % (2) Set target position and other parameters
    start_X = instance.current_x*1000;  % Unit: mm -> m
    start_Y = instance.current_y*1000;  % Unit: mm -> m
    end_X   = targetCtr(k,1);  % Unit: mm -> m
    end_Y   = targetCtr(k,2);  % Unit: mm -> m

    % (3) Minimum jerk haptic targets generation
    out = min_jerk([start_X start_Y 0], [end_X end_Y 0], t);
    
    % (4) Move handle to target!
    trialFlag = 5;
    for j = 1:length(out)
        xt = num2str(round(out(j,1)));
        yt = num2str(round(out(j,2)));
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        trialData(j,:) = [ i, trialFlag, round(targetCtr(k,1)), round(targetCtr(k,2)), ...
                           double(instance.current_x),  double(instance.current_y), ...
                           double(instance.velocity_x), double(instance.velocity_y), ...
                           double(instance.fb_emergency)];
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end
   
    % Plot this trajectory. Save trial data into a mega array;    
    h1 = plot(trialData(:,5), trialData(:,6), 'b.');
    toSave = [toSave; trialData];
    
    % Pause for 3 seconds at the target location
    pause_me(3);   

    % (5) Minimum jerk haptic targets to zero (START) position
    out = min_jerk([end_X end_Y 0], [start_X start_Y 0], t);

    % (6) Move handle back to ORIGIN, zero position 
    trialFlag = 6;
    for j = 1:length(out)
        xt = num2str(round(out(j,1)));
        yt = num2str(round(out(j,2)));
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        trialData(j,:) = [ i, trialFlag, round(targetCtr(k,1)), round(targetCtr(k,2)), ...
                           double(instance.current_x),  double(instance.current_y), ...
                           double(instance.velocity_x), double(instance.velocity_y), ...
                           double(instance.fb_emergency)];
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end
    
    % Plot this trajectory. Save trial data into a mega array;    
    h2 = plot(trialData(:,5), trialData(:,6), 'b.');
    toSave = [toSave; trialData];

    % (7) Set zero force. Pause for 2 seconds at the target location.
    hold_pos(instance);

    % (8) Play tone with a certain duration and frequency
    play_tone(1250, 0.2);
    pause_me(2);  
    
    
    % PART 2: Let the user moves the handle to a target position ---------
    % (1) Preparation. Produce zero force.   
    trialFlag = 1; a=[]; 
    fprintf('     Now joint position matching\n');
    j=1; % loop counter
    null_force(instance);
    
    while (~KbCheck)
        %plot(instance.current_x, instance.current_y, 'r.');
        pause(1/sample_freq);

        % Computing speed (Robot velocity readout is not good!)
        speedX = (instance.current_x - lastXpos);   
        speedY = (instance.current_y - lastYpos);
        speed  = 1000* sqrt(speedX^2 + speedY^2);  % unit in mm/sec.
        
        % Compute the distance between the CURSOR and the START centre
        dist2Start = sqrt(instance.current_x^2 + instance.current_y^2);

        % Compute the distance between the CURSOR and the TARGET centre
        dist2Target = sqrt((instance.current_x-targetCtr(k,1)/1000)^2 + ...
                           (instance.current_y-targetCtr(k,2)/1000)^2);

        trialData(j,:) = [ i, trialFlag, round(targetCtr(k,1)), round(targetCtr(k,2)), ...
                           double(instance.current_x),  double(instance.current_y), ...
                           double(instance.velocity_x), double(instance.velocity_y), ...
                           double(instance.fb_emergency)];

        a = [a; speed];
        figure(2); plot(a); ylim([0 2]); hold on;
        
        % This is a point attractor to a target when the subject is TOO WEAK TO MOVE
        if (speed < 1)
            instance.SetTarget(num2str(end_X),num2str(end_Y),'90','90','0','0','0','0','0','0','1','0');     
        end
        
        if (dist2Start > 0.075) && (speed < 1)
            if (timerFlag)
                fprintf("     Movement production stops!\n");
                tic;
                timerFlag = false;
            end
            %toc
            % Once the hand is stationary for 2 seconds, then do this....
            if (toc > 2)
                fprintf("     Hand position remains for 2 sec!\n");
                timerFlag = true;
                break
            end
        end
        
        lastXpos = instance.current_x;
        lastYpos = instance.current_y;
        j=j+1; % loop counter
    end   
    
    % Plot this trajectory. Save trial data into a mega array;    
    h3 = plot(trialData(:,5), trialData(:,6), 'r.');
    toSave = [toSave; trialData];
    trialData = double.empty();
    
    % Hand position moves back to the center.
    trialFlag = 3;
    fprintf('     Handle moves back to the origin\n');
     
    % (2) Minimum jerk haptic targets to zero (START) position
    out = min_jerk([instance.current_x*1000 instance.current_y*1000 0], ...
                   [start_X start_Y 0], t);
    
    % (3) Now move the handle back to the zero position.
    for j = 1:length(out)
        xt = num2str(round(out(j,1)));
        yt = num2str(round(out(j,2)));
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        trialData(j,:) = [ i, trialFlag, round(targetCtr(k,1)), round(targetCtr(k,2)), ...
                           double(instance.current_x),  double(instance.current_y), ...
                           double(instance.velocity_x), double(instance.velocity_y), ...
                           double(instance.fb_emergency)];
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end

    % Plot this trajectory. Save trial data into a mega array;    
    h4 = plot(trialData(:,5), trialData(:,6), 'g.');
    toSave = [toSave; trialData];
    trialData = double.empty();

    % (4) Pause at the zero position for 2 seconds
    pause_me(2);
    fprintf('     Moving to NEXT TRIAL!\n');
    
    % (5) Ready to continue to next trial...
    i = i+1;
    
    % Clear figure with old position data
    delete(h1); delete(h2); delete(h3); delete(h4); 

end


% For safety: Ensure the force is null after quiting the loop!
null_force(instance); 
close all;
