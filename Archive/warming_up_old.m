

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------  Notice: Code for motor behavioural assessment with robot  --------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clc;
clear; close all;
fprintf("\n--------  Warming up (Preparation)   --------\n");


%% First, establish connection with H-MAN!
% Obtain the instance handler, stiffness, and damping parameters.
[instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();

% (0) Produce filename for the current trial based on user-defined information
%[subjID, ~, myresultfile] = collectInfo( "warm" );


%% Trial-related parameters -----------------------------------------------
Ntrial = 20;
hitScore  = 0;   % Add +10 for each success
toshuffle = repmat(1:4,[1 Ntrial/4]);   % We have 4 target directions!!!
eachTrial = Shuffle(toshuffle);
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';
trialData = double.empty();
toSave   = double.empty();  
toSave2  = double.empty();
lastXpos = instance.hman_data.location_X; 
lastYpos = instance.hman_data.location_Y;

% Sample frequency, timing parameters 
sample_freq = 200;   % IMPORTANT that the sample freq remains the same!!!
move_duration = 0.8;
t = 0: 1/sample_freq : move_duration;
curTrial = 1; 
timerFlag = true;
delay_at_target = 1;  % Hold at target position (sec)

% Create a flag to denote which stages of the movement it is:
%        0: hand still stationary at the start
%        1: move to a target
%        2: reached the target and stop
%        3: move back to the start
%        4: stay and ready for next trial
trialFlag = 0;

% Define the SIZE of the target!
targetSize = 15;  % >>>>>>>>>>>>>>

% Let's compute the centre of the TARGET locations (convert to mm unit).
% Here, I define four visual target locations for reaching.
targetDist = 0.1;   % >>>>>>>> This is shorter than usual reaching distance!
targetCtr = [[ targetDist*cosd(30);
               targetDist*cosd(60);
               targetDist*cosd(120);
               targetDist*cosd(150)], ...
             [ targetDist*sind(30);
               targetDist*sind(60);
               targetDist*sind(120);
               targetDist*sind(150)]] ;
ang = [30,60,120,150];  % Angle (degree) w.r.t positive X-axis.


%% GAMING DISPLAY: Plot the X,Y data --------------------------------------
SetMouse(10,10);  % Put away mouse cursor
% Call the function to prepare game display!
fig = game_interface(1,0);
instantCursor = plot(0,0,'k.');

% Define the required audio file
[wind, Fs] = audioread( strcat(myPath,'\Audio\wind.mp3') );

% Load the photo map, let the subject explore the map.
photo = imread( strcat(myPath,'\Images\mbs.png') );
aaaa  = image(flipud(photo),'XData',[-0.14 0.14],'YData',[-0.016 0.167]);

%% PART 1 - Range of Motion Exercise inside the workspace -----------------
% Basically subjecs free to make movement with the handle inside the
% workspace, under no-force whatsoever. Do this exercise for max 5 minutes.

pause(1.0);
fprintf('\nPART 1: Press ANY key to proceed to next stage........\n');
count = 0;
message = 'Move around the Singapore map';
mytext  = text(-0.1,0.184,message,'FontSize',47,'Color','g');

% Play BEEP tone and disply MOVE cue for 1.5 sec!!
goCue = plot_image(10, 0, 0.1, 40);
play_tone(1250, 0.18);
pause_me(1.25);
delete(goCue);  % delete from the plot after a sufficient time

while (1)
    % Obtain H-MAN handle position in real-time and plot it. Convert to mm unit!
    myXpos = instance.hman_data.location_X; 
    myYpos = instance.hman_data.location_Y;
    
    % Estimate the cursor speed (in mm, and use sample rate).........
    speed = sqrt((myXpos-lastXpos)^2 + (myYpos-lastYpos)^2) * sample_freq;
    % Compute distance between handle-Start in real world coordinate
%    dist2Start  = sqrt(myXpos^2 + myYpos^2);
    % If movement distance is beyond certain value, reduce cover alpha    
    if (speed > 2) %&& (dist2Start > 0.07)
        if (mod(count,9)==0)   % just to prevent playing sound each time
            sound(wind, Fs);
        end
        %alp = alp-5;  count = count + 1;
    end
    %set(bbbb, 'AlphaData', alp);
    pause(0.009);  % give small delay!

    % This controls how the CURSOR is displayed on the screen.
    %delete(instantCursor);   % remove from the plot first, then redraw the cursor
    instantCursor = plot(myXpos,myYpos,'b.','MarkerSize', 35);   
    lastXpos = myXpos; lastYpos = myYpos;
    
    if (KbCheck)
        break; % Shall bail out if we press any key!
    end
end

% Done with exercise. Remove all previous images.
mychild = fig.Children.Children;
delete(mychild); %delete(aaaa); delete(mytext); delete(instantCursor); %delete(bbbb); 
pause(0.5);

% Define the required audio file: Ask subjects to stay relaxed!
relax = plot_image(11, 0, 0.1, 30);
%[relax_wav, Fs] = audioread( strcat(myPath,'\Audio\relax2.mp3') );
%sound(relax_wav, Fs);
pause(3);
delete(relax);
    
    
% Create minimum jerk trajectory back to START position
movepos = moveTo(instance,0,0,0.6);
Xpos = num2str(movepos(:,1));  Ypos = num2str(movepos(:,2));
    
% Move handle back to ORIGIN, zero position 
for j = 1:length(Xpos)
    xt = Xpos(j,:);  yt = Ypos(j,:);
    instance.SetTarget(xt,yt,'3000','3000','0','0','0','0','0','0','1','0'); 
    pause(1/sample_freq);
    if (KbCheck)
        break; % Shall bail out if we press any key!
    end
end




%% Part 2 - Main loop: looping through ALL trials! ------------------------
fprintf('\nPART 2: Starting the resistive reaching task........\n');
pause(3.0)
for curTrial = 1:Ntrial

    % Preparting current target position, then plot the target location.
    m = eachTrial(curTrial);
    nextTrial = false;  
    fprintf('\nTRIAL %d, ANGLE: %d\n', curTrial, ang(m));
    
    hitFlag   = false;  % Have I hit the target?
    timerFlag = true;   % Can we call the hold timer again?
    aimless_  = true;   % Is the subject unable to reach?
    pos_index = 0;      % index for instantaneous position (min jerk)
    counter   = 0;      % Will be used for displaying cursor purposes
    
    % Plot the TARGET POSITION so as to show the subjects
    plot_image( 13, targetCtr(m,1), targetCtr(m,2), targetSize );    
    pause_me(2.0);
    
    % Play BEEP tone and disply MOVE cue for 1.5 sec!!
    goCue = plot_image(10, 0, 0.12, 25);
    play_tone(1250, 0.18);
    pause_me(1.25);
    delete(goCue);  % delete from the plot after a sufficient time
    
    % While the handle is free and subject starts moving by himself...
    while (~KbCheck && ~nextTrial)
    
        % Data rate, pause in-between loop
        tstart = tic;   % this is to calculate elapsed time per loop
        pause(1/sample_freq);
        
        % Obtain H-MAN handle position in real-time and plot it. Convert to mm unit!
        myXpos = instance.hman_data.location_X; 
        myYpos = instance.hman_data.location_Y;

        % Estimate the cursor speed (in mm, and use sample rate).........
        speed = sqrt((myXpos-lastXpos)^2 + (myYpos-lastYpos)^2) *1000*sample_freq;
        % Compute distance between handle-Start in real world coordinate
        dist2Start  = sqrt(myXpos^2 + myYpos^2);
        % Compute distance between handle-Target in real world coordinate
        dist2Target = sqrt((myXpos-targetCtr(m,1))^2 + (myYpos-targetCtr(m,2))^2);
        
        % This controls how the CURSOR is displayed on the screen.
        if(counter == 8)
            delete(instantCursor);   % remove from the plot first, then redraw the cursor
            instantCursor = plot(myXpos,myYpos,'w.','MarkerSize',60);   
            counter = 0;
        else
            counter = counter + 1;            
        end
        
        switch( trialFlag )
        % STAGE-1 : Moving towards the target (press any key to exit)
        case 1            
            % Important! Now set resistive force, preventing it from leaving the START  >>>>>>>>>>
            instance.SetTarget('0','0','200','200','0','0','0','0','0','0','1','0');
            if (aimless_)
                aimless_ = false;
                tic;   % Start timer!
            end       
            % Subject cannot be aimlessly reaching forever. Put 7cm reaching distance as limit.
            if (dist2Start < 0.07) 
                if (toc > 6.0)   % this is 6-sec timeout!!!
                    aimless_ = true;
                    trialFlag = 3;   % Mouse cursor moves back to the START
                    text(-0.03,0.16,'Try again...','FontSize',50,'Color','r','FontWeight','bold');
                    fprintf("   Timeout. Failed to reach to this direction!\n");
                end
            % Note: ensure that subject is able to move beyond a distance > 0.10 m.
            else
                if (timerFlag)
                    %fprintf("   Movement slowing down!\n");
                    tic;     % Start timer
                end
                % If the cursor is close enough to the TARGET, check if the movement 
                % is SLOW enough, almost stopping. Then prepare to HOLD for 2 seconds.
                if (speed < 10)
                    timerFlag = false;   % Update flag to allow tic again
                else
                    timerFlag = true;   % Update flag to allow tic again
                end
                if (toc > delay_at_target)
                    % Ready to move to the next stage 
                    trialFlag = 2;
                    % Update flag to allow new 'tic'
                    timerFlag = true;   
                    % Set hold position of H-man, run once! >>>>>>>>>>>>>>
                    hold_pos(instance);
                end           
            end      
                
        % STAGE-2 : Managed to reach and stop around the target
        case 2
            if (timerFlag)
                tic;   % Start timer
                timerFlag = false;   % Update flag so as to prevent 'tic' again
                
                % Updated: compute trial-related KINEMATIC performance measures
                [ t_meanpd_target,t_area_target,t_pd_target,t_pdmaxv_target,t_pd200_target,...
                        stpx, stpy, PeakVel ] =  get_Kinematic( trialData, targetCtr(m,:), sample_freq );
                % Then save the performance data and reward status
                toSave2 = [toSave2; [curTrial,dist2Target,t_meanpd_target,t_area_target,t_pd_target,...
                         t_pdmaxv_target,t_pd200_target,stpx, stpy, PeakVel] ];

            end
            if (toc > 0.3)  % Wait for a while...
                trialFlag = 3;
                timerFlag = true;    % Update flag to allow new 'tic'   
                fprintf('   Now moving back to START position.\n');
                
                % Ask subjects to relax before returning the hand back to start position
                relax = plot_image(11, 0, 0.1, 30);
                pause_me(1.5);
                delete(relax);                    
            end
                
        % STAGE-3 : Moving BACK to the Start position (press any key to exit)
        case 3       
            if(timerFlag)
                % This is for generation of minimum jerk trajectory!
                movepos = moveTo(instance,0,0,0.5);
                xt = num2str(movepos(:,1));   yt = num2str(movepos(:,2));
                timerFlag = false;
            end           
            % Move the handle back to start using minimum jerk trajectory >>>>>>>>
            if (pos_index < length(movepos))
                pos_index = pos_index + 1;
                instance.SetTarget( xt(pos_index,:),yt(pos_index,:),kxx,kyy,kxy,kyx,'0','0','0','0','1','0' ); 
            else
                hold_pos(instance);
                % Go to the LAST stage
                trialFlag = 4;
                timerFlag = true;    % Update flag to allow new 'tic'   
            end
        
        % STAGE-4 : Now staying at the Start position (press any key to exit)
        case 4
            if (timerFlag)
                tic;   % Start timer
                timerFlag = false;   % Update flag so as to prevent 'tic' again
            end        
            % Hold for 1.5 second at the Start position, then move to next trial
            if (toc > 1.5)
                fprintf('   Ready for the next trial~\n');
                % Update flag so as to allow 'tic'
                timerFlag = true;
                % After time lapse, we are ready to go to the next trial
                nextTrial = true;
                trialFlag = 0;  %%% added
            end
            
        % STAGE 0: check if the handle has left the Start position?
        otherwise
            if (timerFlag)
                timerFlag = false;    % Update flag so as to prevent 'tic' again
                null_force(instance); % RELEASE the handle holding force; >>>>>>>>>>>
            end
            if (dist2Start > 0.004 && speed > 10)
                trialFlag = 1;  fprintf("   Handle starts moving!\n");
                timerFlag = true;     % Reset flag to allow new 'tic'
            end       
        end
        % The position value at t-1
        lastXpos = myXpos;   lastYpos = myYpos;
        
        % Elapsed time per loop
        elapsed = toc(tstart);
        
        % STAGE-5 : Recording important kinematic data for each trial ................
        %    col-1    : Trial number
        %    col-2    : Stage of movement
        %    col-3,4  : Target position, angle (m)
        %    col-5,6  : Handle X,Y position
        %    col-7,8  : Handle X,Y velocity
        %    col-9    : Hit target or missed
        %    col-10   : Total score
        %    col-11   : Elapsed time per sample
        %    col-12   : Emergency button status
        %    col-13   : Force total by robot
        trialData =  [ trialData; curTrial, trialFlag, m, ang(m), ...
                       double(instance.hman_data.location_X), double(instance.hman_data.location_Y), ...
                       double(instance.hman_data.velocity_X), double(instance.hman_data.velocity_Y), ...
                       hitFlag, hitScore, elapsed, double(instance.hman_data.state), ...
                       double(instance.hman_data.force) ];
    end
        
    % We also append trajectory data to the Mega Array to be saved!
    toSave = [toSave; trialData]; 
    trialData = double.empty();  
    
    % Clear the figure from old position data. First, obtain the handler to the
    % children part of the figure, then delete the components!
    mychild  = fig.Children.Children;
    delete(mychild(1:length(mychild)-1));

    % CONTINUE TO THE NEXT TRIAL.....
    t1 = text(-0.04,0.16,'Next trial~','FontSize',55,'FontWeight','bold','Color','w');
    pause(0.01); 
    curTrial = curTrial + 1; 
    pause_me(delay_at_target);     % Let's pause for a while...
    delete(t1);                    % then remove the text from the screen
    
    if (KbCheck)
        break; % Shall bail out if we press any key!
    end
   
end


%% Saving trial data.........
dlmwrite(strcat(myPath, 'Trial Data\','traj.csv'), toSave);
dlmwrite(strcat(myPath, 'Trial Data\','trial.csv'), toSave2);

% For safety: Ensure the force is null after quiting the loop!
null_force(instance); 
close all;

% Stop TCP connection 
instance.CloseConnection();

[mywav, Fs] = audioread( strcat(myPath,'\Audio\claps3.wav') );
sound(mywav, Fs);
fprintf('\nWarming up finished, bye!!\n');
pause(3.0)

close all; clear; clc;  % Wait to return to MainMenu?
fprintf("\nReturning to Main Menu selection........\n");

