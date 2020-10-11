

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------   Note: Code for SensoriMotor Training Task with Reward   ---------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clc; clear; close all; 
fprintf("\n---------   Training sessions   --------\n");
fprintf("Take note whether this client is a control group.... \n\n");


%% First, establish connection with H-MAN!
% Obtain the instance handler, stiffness, and damping parameters.
[instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();

% (0) Produce filename for the current trial based on user-defined information
%[subjID, ~, ~, myresultfile] = collectInfo( mfilename );


%% Trial-related parameters -----------------------------------------------
Ntrial = 16;
hitScore  = 0;   % Add +10 for each success
toshuffle = repmat(1:4,[1 Ntrial/4]);   % We have 4 target directions!!!
eachTrial = Shuffle(toshuffle);
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';
trialData = double.empty();
toSave = double.empty();  toSave2 = double.empty();
lastXpos = instance.hman_data.location_X; 
lastYpos = instance.hman_data.location_Y;


% Define different boolean flags, this depends on whether it's CONTROL group!?
control = input('Is this control group? (y/n) ','s');
if (control=='y')
    showCursor = true;   % to show the mouse cursor during movement?
    showReward = true;   % to show the score with feedback?
else
    showCursor = false;  % to show the mouse cursor during movement?
    showReward = true;   % to show the score with feedback?
end

% Sample frequency, timing parameters 
sample_freq = 200;   % IMPORTANT that the sample freq remains the same!!!
move_duration = 0.8;
t = 0: 1/sample_freq : move_duration;
curTrial = 1; 
timerFlag = true;
delay_at_target = 2;  % Hold at target position (in second)

% Create a flag to denote which stages of the movement it is:
%        0: hand still stationary at the start
%        1: move to a target
%        2: reached the target and stop
%        3: move back to the start
%        4: stay and ready for next trial
trialFlag = 0;

% Define the SIZE of the target!
targetSize = 15;            %>>>>>>>>>>>>>>

% Let's compute the centre of the TARGET locations (convert to mm unit).
% Here, I define four visual target locations for reaching.
targetDist = 0.15;
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
% Open an empty figure, remove the toolbar
SetMouse(10,10);  % Put away mouse cursor
% Call the function to prepare game display! Display background too...
fig = game_interface(1,1);
instantCursor = plot(0,0,'k.');  

% Define keyboard press function associated with the window!
set(fig,'WindowKeyPressFcn',@KeyPressFcn);
% Define global variable as a flag to quit the main loop upon a keypress.
global bailOut    
bailOut = false;

% Define the required audio file
[wav1, Fs] = audioread( strcat(myPath,'\Audio\assess.mp3') );

% Text to be displayed as feedback
txt1 = 'Next trial ~';
txt2 = 'Good job!!';
txt3 = 'Current score:';
txt4 = 'Try again...';



%% Main loop: looping through ALL trials! ----------------------------------
pause_me(2.0);
for curTrial = 1:Ntrial

    % Preparting current target position, then plot the target location.
    m = eachTrial(curTrial);
    fprintf('\nTRIAL %d, ANGLE: %d\n', curTrial, ang(m));
    nextTrial = false;  % Flag to quit the active moving loop
    thePoints = [];     % Array for mouse position
    hitFlag   = false;  % Have I hit the target?
    timerFlag = true;   % Can we call the hold timer again?
    aimless_  = true;   % Is the subject unable to reach?
    pos_index = 0;      % index for instantaneous position (min jerk)
    counter   = 0;      % Will be used for displaying cursor purposes
    
    % Plot the TARGET POSITION so as to show the subjects
    pause_me(1.5);
    %mytarget = plot( c(1,:)+targetCtr(m,1), c(2,:)+targetCtr(m,2),'LineWidth',5);
    plot_image( m, targetCtr(m,1), targetCtr(m,2), targetSize );    
    pause_me(1.5);

    % Play BEEP tone and disply MOVE cue for 1.5 second!!
    goCue = plot_image(10, 0, 0.1, 30);
    play_tone(1250, 0.18);
    pause_me(1.25);
    delete(goCue);  % delete from the plot after a sufficient time
    
    % While the handle is free and subject is actively moving by himself...
    while (~bailOut && ~nextTrial)
    
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
        if(counter == 8)% && trialFlag == 1)
            delete(instantCursor);   % remove from the plot first, then redraw the cursor
            if (showCursor)
                instantCursor = plot(myXpos,myYpos,'w.','MarkerSize',60);   
            else
                if (dist2Start < 0.02)
                    instantCursor = plot(myXpos,myYpos,'w.','MarkerSize',60);   
                else   % remove the cursor if beyond a certain distance from the start
                    delete(instantCursor);
                end
            end
            counter = 0;
        else
            counter = counter + 1;            
        end
        
        switch( trialFlag )
        % STAGE-1 : Moving towards the target (press any key to exit)
        case 1
            if (aimless_)
                aimless_ = false;
                tic;   % Start timer!
            end

            % NEW: Virtual channel based on target angle, current handle position, ch size!
            if (control=='n')  % this feedback is not for control group!
                channel(ang(m), [myXpos,myYpos], instance, 5);
            end
            
            % Record mouse position in in an array
            thePoints = [thePoints; myXpos myYpos];          
        
            % Subject cannot be aimlessly reaching forever
            if (dist2Start < 0.10) 
                if (toc > 5.0)   % this is 5 seconds timeout!!!
                    aimless_ = true;
                    trialFlag = 3;   % Mouse cursor moves back to the START
                    text(-0.03,0.16,txt4,'FontSize',50,'Color','r','FontWeight','bold');
                    fprintf("   Timeout. Failed to reach to this direction!\n");
                end
            % Note: ensure that subject is able to move beyond a distance > 0.10 m.
            else
                if (timerFlag)
                    %fprintf("   Movement slowing down!\n");
                    tic;     % Start timer
                end
                % If the cursor is close enough to the TARGET, check if the movement 
                % is SLOW enough, almost stopping. Then prepare to STOP for 2 seconds.
                if (speed < 10)
                    timerFlag = false;   % Update flag to allow tic again
                else
                    timerFlag = true;    % Update flag to allow tic again
                end                
                if (toc > delay_at_target)
                    % After 2 seconds stop, ready to move to the next stage 
                    trialFlag = 2;
                    % Update flag to allow new 'tic'
                    timerFlag = true;   
                    % Set hold position of H-man, run once! >>>>>>>>>>>>>>
                    hold_pos(instance);
                end           
            end      
            
        % STAGE-2 : Managed to reach the target and stop. Check if the trial is SUCCESSFUL!
        case 2
            if (timerFlag)
                tic;   % Start timer
                timerFlag = false;   % Update flag so as to prevent 'tic' again
                
                % Updated: compute trial-related KINEMATIC performance measures
                [ t_meanpd_target,t_area_target,t_pd_target,t_pdmaxv_target,t_pd200_target,stpx,stpy,PeakVel ] = ...
                                                         get_Kinematic( trialData, targetCtr(m,:), sample_freq );
                % Check criteria for successful trial!!                                     
                if (dist2Target < targetSize/1000 && t_pd_target < targetSize/900) 
                    fprintf('   Target hit. Well done!\n');             
                    hitFlag = true;  hitCol = 'green';
                else
                    fprintf('   Be more accurate!\n');
                    hitFlag = false; hitCol = 'red';
                end
                % Then save the performance data and reward status
                toSave2 = [toSave2; [curTrial,dist2Target,t_meanpd_target,t_area_target,t_pd_target,t_pdmaxv_target,...
                                     t_pd200_target,stpx,stpy,PeakVel,hitFlag] ];
           end
            if (toc > 0.3)  % just a short delay here
                trialFlag = 3;
                timerFlag = true;    % Update flag to allow new 'tic'   
                fprintf('   Now moving back to START position.\n');
                
                % Note: We give INTERMITTENT FEEDBACK (KR and KP)
                if(showReward)            
                    if (hitFlag) 
                        % Play audio feedback. Note: ensure it's called ONCE only!             
                        % Show the text on the screen as positive feedback!
                        hitScore = hitScore + 10;     % Increase hit score
                        txt2  = play_KR(myPath);
                        mymsg = [txt2, newline, txt3, ' ', int2str(hitScore)];
                        text(-0.05,0.175,mymsg,'FontSize',45,'Color',hitCol,'FontWeight','bold');
                    else
                        text(-0.04,0.18,' ');   % If fails: no need negative feedback!
                    end
                    
                    % This trajectory feedback will always for rewarded/unrewarded trials.
                    % Draw movement trajectory just made together with ideal straight line.
                    mycursor = plot(myXpos,myYpos,'w.','MarkerSize',60); 
                    mytraj  = plot( thePoints(:,1),thePoints(:,2),hitCol,'LineWidth',4 );
                    refline = line([0,targetCtr(m,1)],[0,targetCtr(m,2)],'Color','w','LineWidth',2); 
                    pause_me(delay_at_target);
                end
            end
                
        % STAGE-3 : Moving BACK to the Start position. Remain relax!
        case 3       
            if(timerFlag)
                % This is for generation of minimum jerk trajectory!
                movepos = moveTo(instance,0,0,0.5);
                xt = num2str(movepos(:,1));
                yt = num2str(movepos(:,2));
                timerFlag = false;    delete(mycursor);
            end
            
            % Move the handle back to start using minimum jerk trajectory >>>>>>>>
            if (pos_index < length(movepos))
                pos_index = pos_index + 1;
                instance.SetTarget( xt(pos_index,:),yt(pos_index,:),kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0' ); 
            else
                % After minimum jerk has finished, the handle may not go back exactly since 
                % the robot is quite weak. The robot is quite weak, we ensure the handle 
                % goes back to the START first.
                if (dist2Start >= 10)
                    instance.SetTarget('0','0','2000','2000','0','0','0','0','0','0','1','0'); 
                else
                    % Set hold position of H-man, run only once! >>>>>>>>>>>>>>
                    hold_pos(instance);
                    % Go to the LAST stage
                    trialFlag = 4;
                end
                timerFlag = true;    % Update flag to allow new 'tic'
                % Using children handler, remove performance feedback after a while..............
                mychild  = fig.Children.Children;
                delete(mychild(1:3));
            end
        
        % STAGE-4 : Now staying at the Start position (press any key to exit)
        case 4
            if (timerFlag)
                tic;   % Start timer
                timerFlag = false;   % Update flag so as to prevent 'tic' again
            end        
            % Hold for 2 seconds at the Start position, then move to next trial
            if (toc > delay_at_target)
                fprintf('   Ready for the next trial~\n');
                % Update flag so as to allow 'tic'
                timerFlag = true;
                % After a while, we are ready for the next trial by quiting the loop with 'nextTrial' flag
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
        %fprintf("%d %f %f \n", trialFlag,dist2Start,speed); 
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
    delete(mychild(1:length(mychild)-2));

    % CONTINUE TO THE NEXT TRIAL.....
    t1 = text(-0.04,0.16,txt1,'FontSize',55,'FontWeight','bold','Color','w');
    pause(0.01); 
    curTrial = curTrial + 1; 
    pause_me(delay_at_target);     % Let's pause for a while...
    delete(t1);                    % then remove the text from the screen
    
    if (bailOut)
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
fprintf("\nClosing connection to H-man................\n");


%% Indicate code has ended by playing an audio message
[mywav, Fs] = audioread( strcat(myPath,'\Audio\claps3.wav') );
sound(mywav, Fs);
fprintf('\nTraining program has finished, bye!!\n');
pause(1.0)
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
