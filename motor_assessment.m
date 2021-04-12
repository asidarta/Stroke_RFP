

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------   Note: Code for motor behavioural assessment with robot   --------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clc;
clear; close all;
fprintf("\n--------   Motor Assessment   --------\n");

% (0) Produce filename for the current trial based on user-defined information imgNum 
% refers to block number; now using GUI! (4 Apr 2021).
guiOut = gui( 'motor' );
save('setting.mat', 'guiOut');   % save the updated subject's setting
subjID = guiOut.subject;  myresultfile = guiOut.filename;  
control= guiOut.control;  practice = guiOut.practice;
session = str2num(guiOut.session); imgNum = str2num(guiOut.block);


%% Then, establish connection with H-MAN!
% Obtain the instance handler, stiffness, and damping parameters.
[instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();


%% Trial-related parameters -----------------------------------------------
Ntrial = 20;        % Total number of trials per block >>>
hitScore  = 0;      % (Not applicable for assessment)
toshuffle = repmat(1:4,[1 Ntrial/4]);      % We have 4 target directions!
eachTrial = Shuffle(toshuffle);            % We shuffle the target position
trialData = double.empty();
toSave = double.empty();                   % Initialize variable to save kinematic data
toSave2 = double.empty();                  % Initialize variable to save trial outcome
lastXpos = instance.hman_data.location_X;  % To contain robot latest Xpos
lastYpos = instance.hman_data.location_Y;  % To contain robot latest Ypos
global myPath;

% Sample frequency, timing parameters 
sample_freq = 200;          % Define so that sample freq remains the same!
move_duration = 0.8;        % Predefined movement duration;
t = 0: 1/sample_freq : move_duration;
curTrial = 1;               % Initialize current trial=1
timerFlag = true;           % Inttialize timerFlag to activate timer  
delay_at_target = 0.5;      % Hold at target position and inter-trial delay (sec)

% Create a flag to denote which stages of the movement it is:
%        0: hand still stationary at the start
%        1: move to a target
%        2: reached the target and stop
%        3: move back to the start
%        4: stay and ready for next trial
trialFlag = 0;
hold_pos(instance);  % >>>>>>>
 
% Define the SIZE of the target! This is smaller than the one used in training.
targetSize = 12;  %>>>>>>>>>>>>>>

% Let's compute the centre of the TARGET locations (convert to mm unit).
% Here, I define four visual target locations for reaching.
targetDist = 0.15;
targetCtr  = targetDist* [ [cosd(30); cosd(60); cosd(120); cosd(150)], ... 
                           [sind(30); sind(60); sind(120); sind(150)] ] ;
ang = [30,60,120,150];  % Angle (degree) w.r.t positive X-axis.


%% GAMING DISPLAY: Plot the X,Y data --------------------------------------
SetMouse(10,10);  % Put away mouse cursor
% Call the function to prepare game display, choose game theme #6
imgNum = 0; 
fig = game_interface(1,1,imgNum);
instantCursor = plot(0,0,'k.');

% Define keyboard press function associated with the window!
set(fig,'WindowKeyPressFcn',@KeyPressFcn);
% Define global variable as a flag to quit the main loop upon a keypress.
global bailOut;  bailOut = false;   
% Pause by default to allow final check before the trial
global pauseFlag;   pauseFlag = true;


% Define the required audio file (no longer used!)
[wav1, Fs] = audioread( strcat(myPath,'\Audio\assess.mp3') );

% Text to be displayed as feedback
txt1 = 'Next trial ~';
txt4 = 'Do not give up';

fprintf('\nPress <Spacebar> to continue ..........\n');
while pauseFlag     % There will be Pause to ensure subjects are ready
    pauseText = text(-0.055,0.14,"Ready to play?",'FontSize',55,'Color','w','FontWeight','bold');
    pause(0.5);   delete(pauseText);
end



%% Main loop: looping through ALL trials! ---------------------------------- 
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
    pause_me(delay_at_target);
    %mytarget = plot( c(1,:)+targetCtr(m,1), c(2,:)+targetCtr(m,2),'LineWidth',5);
    plot_image( imgNum, m, targetCtr(m,1), targetCtr(m,2), targetSize );    
    %pause_me(delay_at_target);
    play_tone(4000, 0.01);
    
    % While the handle is free and subject starts moving by himself...
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
            %instantCursor = plot(myXpos,myYpos,'w.','MarkerSize',60);
            instantCursor = plot(myXpos,myYpos,'o','MarkerEdgeColor','k','MarkerFaceColor','w','MarkerSize',20,'LineWidth',3);
            counter = 0;
        else
            counter = counter + 1;            
        end
        
        while pauseFlag   % Updated Mar 2021; pause the game by pressing "Spacebar"
            pauseText = text(-0.04,0.14,"Pausing....",'FontSize',55,'Color','w','FontWeight','bold');
            pause(0.5);   delete(pauseText);
        end
        
        switch( trialFlag )
        % STAGE-1 : Moving towards the target (press any key to exit)
        case 1
            if (aimless_)
                aimless_ = false;
                tic;   % Start timer!
            end       
           % If subject is too weak, still < 7.5cm from the start, we have to give timeout!
            if (dist2Start < 0.075) 
                if (toc > 4.0)   % this is 4-sec timeout!!!
                    aimless_ = true;
                    trialFlag = 3;   % Mouse cursor moves back to the START
                    text(-0.04,0.16,txt4,'FontSize',50,'Color','r','FontWeight','bold');
                    fprintf("   Timeout. Failed to reach to this direction!\n");
                end
            % Note: ensure that subject is able to move beyond a distance > 0.10 m.
            else
                if (timerFlag)
                    %fprintf("   Movement slowing down!\n");
                    tic;     % Start timer
                end
                % If the cursor is close enough to the TARGET, check if the movement 
                % is SLOW enough, almost stopping. Then prepare to HOLD for 1.5 seconds.
                if (speed < 10),   timerFlag = false;   % Update flag to allow tic again
                else,  timerFlag = true;   % Update flag to allow tic again
                end
                if (toc > delay_at_target)
                    % After 1.5 seconds hold, ready to move to the next stage 
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
            end
            if (toc > 0.3)  % just a short delay here
                trialFlag = 3;
                timerFlag = true;    % Update flag to allow new 'tic'   
                fprintf('   Now moving back to START position.\n');
                
                % Ask subjects to relax before returning the hand back to start position
                relax = plot_image([], 11, 0, 0.1, 30);
                pause_me(2.0);
                delete(relax);                    
            end
                
        % STAGE-3 : Moving BACK to the Start position. Remain relax!
        case 3       
            if(timerFlag)
                % This is for generation of minimum jerk trajectory!
                movepos = moveTo(instance,0,0,0.5);
                xt = num2str(movepos(:,1));
                yt = num2str(movepos(:,2));
                timerFlag = false;
            end           
            % Move the handle back to start using minimum jerk trajectory >>>>>>>>
            if (pos_index < length(movepos))
                pos_index = pos_index + 1;
                instance.SetTarget( xt(pos_index,:),yt(pos_index,:),kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0' ); 
            else
                hold_pos(instance);  % >>>>>>>
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
            % Hold for 500msec at the Start position, then move to next trial
            if (toc > 0.5)
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
    
    % Updated: This is to compute KINEMATIC measures ----------------------
    [ t_meanpd_target,t_area_target,t_pd_target,t_pdmaxv_target,t_pd200_target,...
        stpx, stpy, PeakVel ] =  get_Kinematic( trialData, targetCtr(m,:), sample_freq );
   
    toSave2 = [toSave2; [curTrial,dist2Target,t_meanpd_target,t_area_target,t_pd_target,...
                         t_pdmaxv_target,t_pd200_target,stpx, stpy, PeakVel] ];
    
    % We also appendd trajectory data to the Mega Array to be saved!
    toSave = [toSave; trialData]; 
    trialData = double.empty();  
    
    % Clear the figure from old position data. First, obtain the handler to the
    % children part of the figure, then delete the components!
    mychild  = fig.Children.Children;
    delete(mychild(1:length(mychild)-2));

    % CONTINUE TO THE NEXT TRIAL.....
    curTrial = curTrial + 1; 

    if (bailOut)
        break; % Shall bail out if we press any key!
    end
   
end


%% Saving trajectory and trial-outcome data as tables with headers!
% Save only when this is not Practice, and when the data content is not empty.
if (~practice && ~isempty(toSave) && ~isempty(toSave2))
    varNames = {'trial','flag','m','angle','posX','posY','velX','velY','hit','score','elapsed','emerg','force'};
    writetable( array2table(toSave,'VariableNames',varNames), ... % Trajectory data
                strcat(myPath, 'Trial Data\',myresultfile,'.csv'));
    varNames = {'curTrial','dist2Target','t_meanpd_target','t_area_target','t_pd_target','t_pdmaxv_target', ...
                't_pd200_target','stpx','stpy','PeakVel'};
    writetable( array2table(toSave2,'VariableNames',varNames), ... % Trial result data
                strcat(myPath, 'Trial Data\',myresultfile,'_results.csv'));         
end
            
% For safety: Ensure the force is null after quiting the loop!
null_force(instance); 

% Stop TCP connection every time the session ends 
instance.CloseConnection();
fprintf("\nClosing connection to H-man................\n");


%% Indicate code has ended by playing an audio message
[mywav, Fs] = audioread( strcat(myPath,'\Audio\claps3.wav') );
sound(mywav, Fs);
fprintf('\nMotor assessment has finished, bye!!\n');
pause(3.0)
close all; clear; clc;  % Wait to return to MainMenu?
fprintf("\nReturning to Main Menu selection..........\n");


%% Function to detect ESC keyboard press, it returns the flag defined as global.
%  To pause the game, you can press "Spacebar".
function bailOut = KeyPressFcn(~,evnt)
    global bailOut; global pauseFlag;
    %fprintf('key event is: %s\n',evnt.Key);
    if(evnt.Key=="escape")
       bailOut = true;  %fprintf('--> You have pressed wrongly, dear!\n');
    end
    if(evnt.Key=="space")
       pauseFlag = ~pauseFlag; 
       if (pauseFlag), fprintf("Pausing the game now.....\n");
       else, fprintf("Continuing the game now.....\n");
       end
    end
end
