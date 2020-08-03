

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------  Notice: Code for SensoriMotor Training Task with Reward  ---------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Clear the workspace and the scren
sca; 
%clear; close all; 
%clearvars;


%% (0) Obtain the filename for the current trial
%[subjID, ~, ~, myresultfile] = collectInfo( mfilename );



%% Robot-related parameters -----------------------------------------------
% Load the H-MAN DLL files
my_pwd = 'C:\Users\rris\Documents\MATLAB\Control library\.dll files\';
Articares = NET.addAssembly(strcat(my_pwd,'\Articares.Core.dll'));
Log = NET.addAssembly(strcat(my_pwd,'\NLog.dll'));

% Connect H-MAN to the workstation
fprintf("Preparing connection to H-man................\n");
instance = ConnectHman();
NLog.Common.InternalLogger.Info('Connection with H-MAN established');

% Robot stiffness and viscuous field!
kxx = num2str(3500); 
kyy = num2str(3500);
kxy = num2str(0); 
kyx = num2str(0);
bxx = num2str(50);  
byy = num2str(20);


% Trial-related parameters -----------------------------------------------
Ntrial = 10;
hitScore  = 0;   % Add +10 for each time hit the target
toshuffle = repmat(1:5,[1 Ntrial/5]);   % We have 5 target directions!!!
eachTrial = Shuffle(toshuffle);
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';
trialData = double.empty();
toSave = double.empty();
lastXpos = 0; lastYpos = 0;

% Define different boolean flags for the experiment
showCursor = true;   % to show mouse cursor during movement?
showReward = true;   % to show score with feedback?

% Create a flag to denote which stages of the movement it is:
%        1: move to a target
%        2: reached the target and stop
%        3: move back to the start
%        4: stay and ready for next trial
trialFlag = 1;

% Define the SIZE of the target!
targetSize = 15;  %>>>>>>>>>>>>>>

% Let's compute the centre of the TARGET locations (convert to mm unit)
targetDist = 0.15;
targetCtr = [[ targetDist*cosd(30);
               targetDist*cosd(60);
               targetDist*cosd(90);
               targetDist*cosd(120);
               targetDist*cosd(150)], ...
             [ targetDist*sind(30);
               targetDist*sind(60);
               targetDist*sind(90);
               targetDist*sind(120);
               targetDist*sind(150)]] ;
ang = [30,60,90,120,150];  % Angle (degree) w.r.t positive X-axis.



%% GAMING DISPLAY: Plot the X,Y data --------------------------------------
% Open an empty figure, remove the toolbar
SetMouse(10,10);  % Place away mouse cursor
fig = figure(1);
set(fig, 'Toolbar', 'none', 'Menubar', 'none');

% Creating a tight margin plot region!
ax = gca;
outerpos = ax.OuterPosition;
ti = ax.TightInset; 
left = outerpos(1) + ti(1)/2;
bottom = outerpos(2) + ti(2)/2;
ax_width = outerpos(3) - ti(1)/2 - ti(3)/2;
ax_height = outerpos(4) - ti(2)/2 - ti(4)/2;
ax.Position = [left bottom ax_width ax_height];

% Load and place background image on the plot!
bg = imread( strcat(myPath,'\Images\background.jpg') );
image(bg,'XData',[-0.2 0.2],'YData',[-0.01 0.2]);
hold on;

% Create circular target traces
c = 0.005*[cos(0:2*pi/100:2*pi);sin(0:2*pi/100:2*pi)];
%plot( %c(1,:)+targetDist*cosd(30), c(2,:)+targetDist*sind(30), ...
      %c(1,:)+targetDist*cosd(60), c(2,:)+targetDist*sind(60), ... 
      %c(1,:)+targetDist*cosd(90), c(2,:)+targetDist*sind(90), ...
      %c(1,:)+targetDist*cosd(120),c(2,:)+targetDist*sind(120), ...
      %c(1,:)+targetDist*cosd(150),c(2,:)+targetDist*sind(150), ...
plot( c(1,:),c(2,:), 'LineWidth',5 ); 

% Setting cosmetic/appearance of the plot
axis([-0.2,0.2,-0.014,0.186]);
set(gcf,'Position', get(0, 'Screensize'));  % control figure size (full screen)
set(gcf,'Color','k');                       % set figure background color black
set(gca,'FontSize', 14);                    % control font in the figure
set(gca,'XColor','k','YColor','k');         % set grid color to black
set(gca,'Color','k');                       % set plot background color black
set(gca,'XTick',[],'YTick',[]);             % remove X/Y ticks
set(gca,'XTickLabel',[],'YTickLabel',[]);   % remove X/Y tick labels
set(gca,'YDir','normal')                    % hack to flip plot elements after image!!
daspect([1 1 1])                            % maintaining aspect ratio
instantCursor = plot(0, 0, 'k.');  



% Sample frequency, timing parameters 
sample_freq = 200;  % IMPORTANT that the sample freq remains the same!!!
move_duration = 0.8;
t = 0: 1/sample_freq : move_duration;
curTrial = 1; 
timerFlag = true;
delay_at_target = 2.5;  % Hold at target position (sec)


%% Audio and Visual FEEDBACK during training  -------------------------------
% Define the required audio file
[wav1, Fs] = audioread( strcat(myPath,'\Audio\assess.mp3') );

% Text to be displayed as feedback
txt1 = 'Next trial ~';
txt2 = 'Good job!!';
txt3 = 'Current score:';
txt4 = 'Try again...';



%% Main loop: looping through ALL trials! ----------------------------------
pause(2.0);
for curTrial = 1:Ntrial

    % Preparting current target position, then plot the target location.
    m = eachTrial(curTrial);
    nextTrial = false;  
    fprintf('\nTRIAL %d: Moving towards the TARGET.\n', curTrial);
    
    thePoints = [];     % Array for mouse position
    hitFlag   = false;  % Have I hit the target?
    timerFlag = true;   % Can we call the hold timer again?
    aimless_  = true;   % Is the subject unable to reach?
    pos_index = 0;      % index for instantaneous position (min jerk)
    counter   = 0;      % Will be used for displaying cursor purposes
    
    % Plot the TARGET POSITION so as to show the subjects
    pause_me(1.5);
    %mytarget = plot( c(1,:)+targetCtr(m,1), c(2,:)+targetCtr(m,2),'LineWidth',5);
    plot_image( m, c(1,:)+targetCtr(m,1), c(2,:)+targetCtr(m,2), targetSize );    
    pause_me(1.5);

    while (~KbCheck && ~nextTrial)
    
        % Obtain H-MAN handle position in real-time and plot it. Convert to mm unit!
        myXpos = instance.current_x; 
        myYpos = instance.current_y;
        
        % Pause in-between loop
        tstart = tic;   % this is to calculate elapsed time per loop.....
        pause(0.005);
        
        % Compute the mouse speed, based on elapsed time, not sampling rate
        speed = sqrt((myXpos-lastXpos)^2 + (myYpos-lastYpos)^2)*1000;
        % Compute distance between handle-Start in real world coordinate
        dist2Start  = sqrt(myXpos^2 + myYpos^2);

        % This controls how the CURSOR is displayed on the screen.
        if(counter == 10)% && trialFlag == 1)
            delete(instantCursor);   % remove from the plot first, then redraw the cursor
            if (showCursor)
                instantCursor = plot(myXpos,myYpos,'w.','MarkerSize',60);   
            else
                if (dist2Start < 0.02) % beyond a certain distance from the start
                    instantCursor = plot(myXpos,myYpos,'w.','MarkerSize',60);   
                else
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
                % Play BEEP tone and disply MOVE cue...
                aimless_ = false;
                goCue = plot_image(10, 0, 0.1, 30);
                play_tone(1250, 0.2);
                pause_me(1.8);
                delete(goCue);  % delete from the plot after a sufficient time
                tic;   % Start timer!
                null_force(instance);   % RELEASE the handle holding force;
            end
       
            % Compute distance between handle-Target in real world coordinate
            dist2Target = sqrt((myXpos-targetCtr(m,1))^2 + (myYpos-targetCtr(m,2))^2);
            % Record mouse position in in an array
            thePoints = [thePoints; myXpos myYpos];          
        
            % Subject cannot be aimlessly reaching forever
            if (dist2Start < 0.10) 
                if (toc > 6)   % this is 6-sec timeout!
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
                % is almost stopping. Then prepare to HOLD for 2 seconds.
                if (speed < 0.1)
                    timerFlag = false;   % Update flag to allow tic again
                else
                    timerFlag = true;   % Update flag to allow tic again
                end
                if (toc > delay_at_target)
                    if (dist2Target < targetSize/1000)
                        % Increase hit score
                        fprintf('   Target hit. Well done!\n');             
                        hitScore = hitScore + 10;
                        hitFlag = true;  hitCol = 'green';
                    else
                        hitFlag = false; hitCol = 'red';
                        fprintf('   Be more accurate!\n');
                    end
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
            end
            if (toc > 0.3)  % Wait for a while...
                trialFlag = 3;
                timerFlag = true;    % Update flag to allow new 'tic'   
                fprintf('   Now moving back to START position.\n');
                
                % Note: We give INTERMITTENT FEEDBACK (KR and KP)
                if(showReward)            
                    if (hitFlag) 
                        % Play audio feedback. Note: ensure it's called ONCE only!             
                        % Show the text on the screen as positive feedback!
                        txt2  = play_KR(myPath);
                        mymsg = [txt2, newline, txt3, ' ', int2str(hitScore)];
                        text(-0.05,0.18,mymsg,'FontSize',50,'Color',hitCol,'FontWeight','bold');
                    else
                        % No need negative feedback!
                        text(-0.04,0.18,' ');
                    end
                    
                    % This trajectory feedback will always for rewarded/unrewarded trials.
                    % Draw movement trajectory just made together with ideal straight line.
                    mycursor = plot(myXpos,myYpos,'w.','MarkerSize',60); 
                    mytraj  = plot( thePoints(:,1),thePoints(:,2),hitCol,'LineWidth',4 );
                    refline = line([0,targetCtr(m,1)],[0,targetCtr(m,2)],'Color','w','LineWidth',2); 
                    pause_me(delay_at_target);
                    % Using children handler, remove performance feedback after a while!!
                    mychild  = fig.Children.Children
                    delete(mychild(1:3));
                end
            end
                
        % STAGE-3 : Moving BACK to the Start position (press any key to exit)
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
                instance.SetTarget( xt(pos_index,:),yt(pos_index,:),kxx,kyy,...
                                    kxy,kyx,bxx,byy,'0','0','1','0' ); 
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
            end
        
        % STAGE-4 : Now staying at the Start position (press any key to exit)
        case 4
            if (timerFlag)
                tic;   % Start timer
                timerFlag = false;   % Update flag so as to prevent 'tic' again
            end        
            % Hold for 1.5 second then move to next trial
            if (toc > 1.5)
                fprintf('   Ready for the next trial~\n');
                % Update flag so as to allow 'tic'
                timerFlag = true;
                % After time lapse, we are ready to go to the next trial
                nextTrial = true;
                % Go back to first stage
                trialFlag = 1;
                % Delete the old cursor indicator from the figure...
            end   
        end
        
        % The position value at t-1
        lastXpos = myXpos;   lastYpos = myYpos;
        
        % Elapsed time per loop
        elapsed = toc(tstart);
        
        % STAGE-5 : Recording important kinematic data for each trial ................
        %    col-1 : Trial number
        %    col-2 : Stage of movement
        %    col-3,4 : Target position, angle (m)
        %    col-5,6 : handle X,Y position
        %    col-7,8 : handle X,Y velocity
        %    col-9   : Hit target or missed
        %    col-10  : Total score
        %    col-11  : elapsed time per sample
        %    col-12  : Emergency button status
        trialData =  [ trialData; curTrial, trialFlag, m, ang(m), ...
                       double(instance.current_x),  double(instance.current_y), ...
                       double(instance.velocity_x), double(instance.velocity_y), ...
                       hitFlag, hitScore, elapsed, double(instance.fb_emergency)  ];
    end
                   
    % Clear the figure from old position data. First, obtain the handler to the
    % children part of the figure, then delete the components!
    mychild  = fig.Children.Children;
    delete(mychild(1:length(mychild)-1));
    
    % CONTINUE TO THE NEXT TRIAL.....
    t1 = text(-0.03,0.16,txt1,'FontSize',55,'FontWeight','bold','Color','w');
    pause(0.01); 
    curTrial = curTrial + 1; 
    toSave = [toSave; trialData];  % Mega array to be saved...
    trialData = double.empty();    % reset the content of old trialData   

    pause_me(delay_at_target);  
    delete(t1);   % Delete text after showing
    
    if (KbCheck)
        break; % Shall bail out if we press any key!
    end
   
end


%% Saving trial data.........
dlmwrite(strcat(myPath, 'Trial Data\','trialdata.csv'), toSave);


% For safety: Ensure the force is null after quiting the loop!
null_force(instance); 
close all;

% DISCONNECT H-MAN SYSTEM
%instance.StopSystem()

% Done.
fprintf('\nTrials finished, bye!\n');