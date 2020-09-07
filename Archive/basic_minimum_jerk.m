%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% This code lets the H-MAN to move the handle to a predefined target 
% position in space using minimum jerk trajectory. User can also see
% the trajectory profile produced by H-MAN.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Has been revised for DLL library V2 !!!

clear; clc
% Obtain the instance handler, stiffness, and damping parameters.
[instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();

% Trial-related parameters -----------------------------------------------
Ntrial = 40;
toshuffle = repmat(1:5,[1 Ntrial/5]);   % We have 5 target directions!!
eachTrial = Shuffle(toshuffle);
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';
trialFlag = 0;
trialData = double.empty();
toSave = double.empty();
transition_time = 10;

%% Plot the X,Y data -----------------------------------------------------
figure(1)
% Create circular target traces
plot(0,0);
hold on;
axis([-0.18,0.18,-0.1,0.2]);
set(gcf,'Position',[500 300 800 650]);  % control figure position
set(gca,'FontSize', 14);   % control font in the figure
xlabel('X position (m)'); ylabel('Y position (m)');

targetDist = 0.15;   % unit = metre

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

           
% Sample frequency, timing parameters ------------------------------------
move_duration = 2;  % unit in second
t = 0: 20/1000 : move_duration;
i = 1; 
timerFlag = true;
delay_at_target = 1.0;  % Hold at target position (sec)




%% Trial loop. Keep looping until Ntrial is met OR a key is pressed
while (i < Ntrial) && (~KbCheck)
    
    k = eachTrial(i);  
    fprintf('\nTRIAL %d\n', i);
    
    % PART 1 --------------------------------------------------------------
    % (1) Ensure no force first 
    null_force(instance);

    % (2) Set target position and other parameters
    start_X = 0;
    start_Y = 0;
    end_X   = targetCtr(k,1);  
    end_Y   = targetCtr(k,2);  

    % (3) Minimum jerk haptic targets generation
    out = min_jerk([start_X start_Y 0], [end_X end_Y 0], t);
    out=out(:,1:2);
    fprintf('   Producing trajectory.\n', i);
    
if(0)
    % (4) Move handle to target!
    for j = 1:length(out)
        xt = num2str(round(out(j,1)));
        yt = num2str(round(out(j,2)));
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        trialData(j,:) = [ i, trialFlag, round(end_X), round(end_Y), ...
                           double(instance.hman_data.location_X), ...
                           double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), ...
                           double(instance.hman_data.velocity_Y) ];
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end
end

    multitarget_transition_mode(instance, out, kxx, kyy, kxy, kyx, bxx, byy, bxy, byx, transition_time)

    % Plot this trajectory. Save trial data into a mega array;    
%    h1 = plot(trialData(:,5), trialData(:,6), 'b.');
    toSave = [toSave; trialData];
    
    % Pause for 3 seconds at the target location
    pause_me(delay_at_target);   

    % (5) Minimum jerk haptic targets to zero (START) position
    out2 = min_jerk([end_X end_Y 0], [start_X start_Y 0], t);

if(0)
    % (6) Move handle back to ORIGIN, zero position 
    for j = 1:length(out2)
        xt = num2str(round(out2(j,1)));
        yt = num2str(round(out2(j,2)));
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        trialData(j,:) = [ i, trialFlag, round(end_X), round(end_Y), ...
                           double(instance.hman_data.location_X), ...
                           double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), ...
                           double(instance.hman_data.velocity_Y) ];
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end
end

    multitarget_transition_mode(instance, out2, kxx, kyy, kxy, kyx, bxx, byy, bxy, byx, transition_time) 
    
    % Plot this trajectory. Save trial data into a mega array;    
%    h2 = plot(trialData(:,5), trialData(:,6), 'b.');
    toSave = [toSave; trialData];

    % (7) Set zero force. Pause for 2 seconds at the target location.
    hold_pos(instance);
    pause_me(1);  

if(0)
    % PART 2 --------------------------------------------------------------
    % (1) Preparation. Produce zero force.   
    a=[]; 
    fprintf('   Now repeat\n');
    null_force(instance);

    % (3) Minimum jerk haptic targets generation
    out3 = min_jerk([start_X start_Y 0], [end_X end_Y 0], t);
    
    % (4) Move handle to target!
    for j = 1:length(out3)
        xt = num2str(round(out3(j,1)));
        yt = num2str(round(out3(j,2)));
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        trialData(j,:) = [ i, trialFlag, round(end_X), round(end_Y), ...
                           double(instance.hman_data.location_X), ...
                           double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), ...
                           double(instance.hman_data.velocity_Y) ];
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end
   
    % Plot this trajectory. Save trial data into a mega array;    
    h3 = plot(trialData(:,5), trialData(:,6), 'r.');
    toSave = [toSave; trialData];
    trialData = double.empty();

    % (5) Pause for 3 seconds at the target location
    pause_me(delay_at_target); 
    
    % Hand position moves back to the center.
    fprintf('   Handle moves back to the origin\n');
    
    % Minimum jerk haptic targets to zero (START) position
    out4 = min_jerk([end_X end_Y 0], [start_X start_Y 0], t);
    
    % (6) Move handle back to ORIGIN, zero position 
    for j = 1:length(out4)
        xt = num2str(round(out4(j,1)));
        yt = num2str(round(out4(j,2)));
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
        trialData(j,:) = [ i, trialFlag, round(end_X), round(end_Y), ...
                           double(instance.hman_data.location_X), ...
                           double(instance.hman_data.location_Y), ...
                           double(instance.hman_data.velocity_X), ...
                           double(instance.hman_data.velocity_Y) ];
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end
    
    % Plot this trajectory. Save trial data into a mega array;    
    h4 = plot(trialData(:,5), trialData(:,6), 'r.');
    toSave = [toSave; trialData];
    trialData = double.empty();
    
    % (7) Set zero force. Pause for 2 seconds at the target location.
    hold_pos(instance);
end

    % (8) Pause at the zero position for 2 seconds
    pause_me(2);
    fprintf('   Moving to NEXT TRIAL!\n');
    
    % (9) Ready to continue to the next trial...
    i = i+1;

end


% For safety: Ensure the force is null after quiting the loop!
null_force(instance); 
% close all;
instance.CloseConnection()
