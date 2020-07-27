

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%----- Notice: Code for Active Motor Test/Training Task with Reward -------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Clear the workspace and the screen
sca; 
%clear; close all; 
%clearvars;


%% (0) Obtain the filename for the current trial
[subjID, ~, ~, myresultfile] = collectInfo( mfilename );



%% (1) H-MAN Robot Setup 
% Load the DLL files
my_pwd = 'C:\Users\rris\Documents\MATLAB\Control library\.dll files\';
Articares = NET.addAssembly(strcat(my_pwd,'\Articares.Core.dll'));
Log = NET.addAssembly(strcat(my_pwd,'\NLog.dll'));

% Connect H-MAN to the workstation
fprintf("Preparing connection to H-man................\n");
%instance = ConnectHman();

% Write in the NLog text file
NLog.Common.InternalLogger.Info('Connection with H-MAN established');

% For Full-HD display = 1920 x 1080, H-Man workspace = 34 x 33 cm, the screen
% coordinate calibration factor would be:
factorX = 100*1920/34;
factorY = -1*100*1080/33;

% Hold handle at the start position, fixed prior to running the code  >>>>>>
% The position of the handle will be taken as ORIGIN (0,0)!
hold_pos(instance);

% Set parameters specifically for minimum jerk production (updated!)
stiffness = num2str(4000);  % Stiffness (N/m)
stiffxy   = num2str(100);
damping   = num2str(50);    % Viscocity (N.s/m2)



%% (2) Trial setup
% Set total number of trials and randomise them.
Ntrial = 40;
hitScore  = 0;   % Add +10 for each time hit the target
toshuffle = repmat(1:5,[1 Ntrial/5]);   % We have 5 target directions!!!
eachTrial = Shuffle(toshuffle);
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';

% Define different boolean flags for the experiment
showCursor = true;   % to show mouse cursor during movement?
showReward = true;   % to show score with feedback?
lastXpos = 0; lastYpos = 0;

% Create a flag to denote which stages of the movement it is:
%        1: move to a target
%        2: reached the target and stop
%        3: move back to the start
%        4: stay and ready for next trial
trialFlag = 1;

% For saving the kinematic data into a textfile
toSave    = double.empty();
trialData = double.empty();


%% (3) Screen and audio preparation for Psychtoolbox!!
% Here we call some default settings...
PsychDefaultSetup(2);
InitializePsychSound;
Screen('Preference', 'SkipSyncTests', 1); 

% Get id screens attached to the machine. The first one by default is the 
% laptop own monitor. Use XOrgConfCreator/Selector to modify the setup.
screens = Screen('Screens');

% Always choose the last external monitor in the register
screenNumber = 0; %max(screens);

% Define black and white luminance (white will be 1 and black 0)
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
bgColor = white / 7;       % Grey for background color

% Open an on screen window and color it grey. This function returns a
% number that identifies the window we have opened "window" and a vector
% "windowRect".
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, bgColor);

% This function call will give use the same information as contained in
% "windowRect"
rect = Screen('Rect', window);

% Get the size of the on screen window in pixels, these are the last two
% numbers in "windowRect" and "rect"
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the inter-frame-interval. This refers to the minimum possible time
% between drawing to the screen
ifi = Screen('GetFlipInterval', window);

% We can also determine the refresh rate of our screen. The
% relationship between the two is: ifi = 1 / hertz
hertz = FrameRate(window);
nominalHertz = Screen('NominalFrameRate', window);

% Here we get the pixel size. This is not the physical size of the pixels
% but the color depth of the pixel in bits
pixelSize = Screen('PixelSize', window);

% Queries the display size in mm as reported by the operating system
[width, height] = Screen('DisplaySize', screenNumber);

% Get the maximum coded luminance level (this should be 1)
maxLum = Screen('ColorRange', window);

% Get the centre coordinate of the window in pixels
[xCenter, yCenter] = RectCenter(windowRect);

% Enable alpha blending for anti-aliasing
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Set the color of our dot according to [RGB] values.
dotColor = [1 1 1];
dotFill  = [bgColor bgColor bgColor];

% Define Formatted Text size to be displayed on the screen
Screen('TextSize', window, 60);


%% (4) Visual components of the display
% Determine the XY position and Size for START DOT in pixels
dotXpos = 0.5 * screenXpixels;
dotYpos = 0.85 * screenYpixels;
dotSizePix = 20;
startpos = [dotXpos-dotSizePix dotYpos-dotSizePix dotXpos+dotSizePix dotYpos+dotSizePix];

% NOTE: The way the START dot and H-man handle position are related is as follows. 
% Before running the code, subject hand should be in front of midline which is also
% the middle part of H-man handle (X-pos). When the robot is initialized, the position 
% is taken as (0,0) in real world coordinate, but as (dotXpos,dotYpos) in the display.
Yoffset = dotYpos;
Xoffset = dotXpos;

% Move the mouse position to the START (origin)
SetMouse(dotXpos, dotYpos, window);

% Determine target centre position and size in the pixel coordinates. Note that 
% the distance is in metre. If image is used, you have to ensure it is square.
targetDist = 0.15;    % Note: Unit in metre!!
targetSize = 40;      % Note: Unit in pixel 
targetCtr  = [ dotXpos + [ targetDist*cosd(30);
                         targetDist*cosd(60);
                         targetDist*cosd(90);
                         targetDist*cosd(120);
                         targetDist*cosd(150) ] * factorX, ...
               dotYpos + [ targetDist*sind(30);
                         targetDist*sind(60);
                         targetDist*sind(90);
                         targetDist*sind(120);
                         targetDist*sind(150) ] * factorY ];
         


%% (5) This is to set up the audio feedback part
% Load audio file containing the Welcome Message!
%[wavedata, freq] = psychwavread( strcat(myPath,'\Audio\assess.mp3') );
%nrchannels  = size(wavedata,2); % Number of rows = number of channels.
%repetitions = 1;
%device = [];
%if nrchannels < 2
%    wavedata = [wavedata wavedata];  % Make it stereo audio
%    nrchannels = 2;
%end

% Open the audio device, with default mode [] (==Only playback) and freq which will return 
% a handle to the audio device. Do this once only....
%pahandle = PsychPortAudio('Open', device, [], 0, freq, nrchannels);

% Fill the audio playback buffer with the audio data 'wavedata':
%PsychPortAudio('FillBuffer', pahandle, wavedata');

% Play the content of the audio buffer defined above
%PsychPortAudio('Start', pahandle, repetitions, 0, 1);

Active = 1;

%while Active
%    WaitSecs(5);    % Wait a second...
%    s = PsychPortAudio('GetStatus', pahandle); % Query playback status
%    Active = s.Active;
    % Stop any audio playback once done
%    if (~Active)
%        fprintf("Stop playback!\n");
%        PsychPortAudio('Stop', pahandle);
%    end
%end

% New audio for the positive feedback, it goes through the same subroutines
%[wavedata, freq] = psychwavread( strcat(myPath,'\Audio\coin2.mp3') );
%pahandle = PsychPortAudio('Open', device, [], 0, freq, nrchannels);
%PsychPortAudio('FillBuffer', pahandle, wavedata');




%% (6) Core: Presentation loop, looping through ALL trials!
for curTrial = 1:Ntrial
    
    m = eachTrial(curTrial); nextTrial = false;  
    fprintf('\nTRIAL %d: Moving towards the TARGET.\n', curTrial);

    thePoints = [];     % Array for mouse position
    hitFlag   = false;  % Have I hit the target?
    timerFlag = true;   % Can we call the hold timer again?
    aimless_  = true;   % Is the subject unable to reach?
    pos_index = 0;      % index for instantaneous position

    while (~KbCheck && ~nextTrial)
        
        tstart = tic;   % this is to calculate elapsed time per loop.....
        
        % STAGE-1 : Moving towards the target (press any key to exit)
        % First we load in an image from file according to target location
        if (trialFlag == 1 || trialFlag == 2)
            switch( eachTrial(curTrial) )
                case 1 
                    myImage = 'Images/monster1.png';
                case 2 
                    myImage = 'Images/monster2.png';
                case 3 
                    myImage = 'Images/monster3.png';
                case 4
                    myImage = 'Images/monster4.png';
                otherwise 
                    myImage = 'Images/monster5.png';
            end

            % To place an image onto the screen,  the trick is to include the alpha 
            % component. After that, make an image into a texture.
            [myTarget,~,alpha] = imread( strcat(myPath,myImage) );
            myTarget(:,:,4) = alpha;        
            targetTexture = Screen('MakeTexture', window, myTarget);
        
            % Determine the XY position and Size for TARGET DOT in pixels or show an image
            Screen('DrawTexture', window, targetTexture, [], [targetCtr(m,1)-targetSize
                                                          targetCtr(m,2)-targetSize
                                                          targetCtr(m,1)+targetSize
                                                          targetCtr(m,2)+targetSize], ...
                                                          0, [], 0.9);
            %Screen('DrawTexture', window, targetTexture, [], [200 200 320 300], 0, [], 0.9);
        end
        
        % NOTE THIS IS H-MAN POSITION READOUT! ---------------------
        mouseXpos = double(instance.current_x * factorX) + Xoffset;  
        mouseYpos = double(instance.current_y * factorY) + Yoffset;

        % Compute the distance between the mouse CURSOR and the START centre
        dist2Start = sqrt((mouseXpos-dotXpos)^2 + (mouseYpos-dotYpos)^2);
            
        if (trialFlag == 1)
            if (aimless_)
                tic   % Start timer, for each tic there should be the tic pair!
                % This is a flag to check for aimless reaching
                aimless_ = false;
                % RELEASE the handle holding force;  >>>>>>>>>>>>>>
                null_force(instance);
            end
            
            % Get instantaneous mouse position first
            %[mouseXpos,mouseYpos] = GetMouse;
                        
            % Compute the mouse speed, based on elapsed time, not sampling rate
            speedX = (mouseXpos - lastXpos);   speedY = (mouseYpos - lastYpos);
            speed  = sqrt(speedX^2 + speedY^2);

            % Record mouse position in in an array
            thePoints = [thePoints; mouseXpos mouseYpos];
    
            % Compute the distance between the mouse CURSOR and the TARGET centre
            dist2Target = sqrt((mouseXpos-targetCtr(m,1))^2 + (mouseYpos-targetCtr(m,2))^2);
            
            % Subject cannot be aimlessly reaching forever, there is a 6-sec timeout.
            if (toc > 6)
                fprintf("Timeout. Failed to reach to this direction!\n");
                aimless_ = true;
                trialFlag = 3;   % Mouse cursor moves back to the START
            end
            
            % Note: ensure that subject is able to move beyond a certain distance.
            if (speed < 2 && dist2Start > 300)
                if (timerFlag)
                    tic   % Start timer
                    timerFlag = false;  % Update flag to prevent another 'tic' again
                end
                if (toc > 2)
                    % Hold for 2 seconds and NEAR enough to the target
                    % COMPARE HERE! Is the cursor close enough to the target?
                    if (dist2Target < targetSize)
                        % Increase hit score
                        fprintf('Target hit. Well done!\n');             
                        hitScore = hitScore + 10;
                        hitFlag  = true;
                    else
                        hitFlag  = false;
                        fprintf('Be more accurate!\n');
                    end
                    % Ready to move to the next stage 
                    trialFlag = 2;
                    % Update flag to allow new 'tic'
                    timerFlag = true;   
                else
                    timerFlag = false;  % Update flag to prevent new 'tic'
                end           
            else
                timerFlag = true;  % Update flag to allow another 'tic' again
            end
            
        end
        
        % Drawing CURSOR showing instantaneous mouse position on the screen, but
        % only when the conditions are met
        if (dist2Start < 35)
            Screen('DrawDots', window, [mouseXpos mouseYpos], 20, dotColor, [], 2);
        elseif (showCursor && dist2Start > 30)
            Screen('DrawDots', window, [mouseXpos mouseYpos], 20, dotColor, [], 2);
        end
        
        % Drawing START DOT on the screen using "Screen DrawDots"
        Screen('FrameOval',window, [], startpos, 3); 
        
        % STAGE-2 : Subject now HAS stopped moving at his best
        trajSize = size(thePoints,1);
        
        if (trialFlag == 2)
            if (timerFlag)
                tic   % Start timer
                timerFlag = false;   % Update flag so as to prevent 'tic' again
                if(showReward && hitFlag) 
                    %PsychPortAudio('Start', pahandle, repetitions, 0, 0);
                end
                % Set hold position of H-man, run once! >>>>>>>>>>>>>>
                hold_pos(instance);
            end

            % Note: Do we want to provide scores & positive feedback?
            if(showReward)            
                if (hitFlag) 
                    % Play audio feedback. Note: ensure it's called ONCE only!
                    currentScore = char( strcat('Score:',{' '},int2str(hitScore)) );
                    
                    % Show text on the screen as positive feedback
                    Screen('DrawText', window, 'Good job!',  800, 50, [0,255,0,255]);
                    Screen('DrawText', window, currentScore, 800, 140, [0,255,0,255]);
                else
                    % Show text on the screen as positive feedback
                    Screen('DrawText', window, 'Try again!',  800, 50, [255,0,0,255]);
                end
                
                % This trajectory feedback will always for rewarded/unrewarded trials.
                % Draw the movement trajectory just made together with ideal line.
                for j = 1:trajSize-1
                    Screen('DrawLine', window, [], thePoints(j,1),thePoints(j,2),...
                            thePoints(j+1,1),thePoints(j+1,2), 5);
                end
                
                Screen('DrawLine', window, [90 0 200], dotXpos, dotYpos, ...
                            targetCtr(m,1), targetCtr(m,2), 5);
                %Screen('LineStipple', window, 1, 1, [0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1]);
            end
            
            if (toc > 1) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Hold for 4 seconds on the target, then proceed next to return home
                timerFlag = true;
                trialFlag = 3;
                fprintf('Now moving back to START position.\n');
            end

        end
        
        % STAGE-3 : Moving BACK to the Start position (press any key to exit)
        if (trialFlag == 3)        % Set the cursor position back to START!            
            mouseXpos = dotXpos; mouseYpos = dotYpos;
            %SetMouse(mouseXpos, mouseYpos, window);
            
            % Move the handle back to start using minimum jerk traj >>>>>>>>
            movepos = moveTo(instance,0,0,2);
            if (pos_index < length(movepos))
                pos_index = pos_index + 1;
                xt = round(movepos(pos_index,1));
                yt = round(movepos(pos_index,2));
                instance.SetTarget( num2str(xt),num2str(yt),stiffness,stiffness, ...
                                    stiffxy,stiffxy,damping,damping,'0','0','1','0' ); 
                %Screen('DrawDots', window, [mouseXpos, mouseYpos], 20, [0,0,0], [], 2);
            else
                % After minimum jerk has finished, the handle may not go back exactly since 
                % the robot is quite weak. The robot is quite weak, we ensure the handle 
                % goes back to the START first.
                if (dist2Start >= 10)
                    instance.SetTarget('0','0',stiffness,stiffness,'0','0','0','0','0','0','1','0'); 
                else
                    % Set hold position of H-man, run only once! >>>>>>>>>>>>>>
                    hold_pos(instance);
                    % Go to the LAST stage
                    trialFlag = 4;
                end
            end
        end
        
        % STAGE-4 : Now staying at the Start position (press any key to exit)
        if (trialFlag == 4)
            if (timerFlag)
                tic   % Start timer
                timerFlag = false;   % Update flag so as to prevent 'tic' again
            end
            Screen('DrawText', window, 'Next trial ~', 800, 100, [255,255,255,1]);

            % Hold for 2 seconds then move to next trial
            if (toc > 2)
                fprintf('Ready for the next trial~\n');
                timerFlag = true;
                % After time lapse, we are ready to go to the next trial
                nextTrial = true;
            end
        end
        
        % EDIT: I decided to do this to prevent drawing the screen each looping.
        % Rather the drawing occurs for every 5-sample.
        if (mod(pos_index,5) == 0 || trialFlag ~= 3)
            % Lastly, flip to the screen to draw all previous commands onto the screen 
            Screen('Flip', window);
        else
            %pause(0.002);
        end
        
        % The position value at t-1
        lastXpos = mouseXpos; lastYpos = mouseYpos;
        % Elapsed time per loop
        elapsed = toc(tstart);
        
        % STAGE-5 : Recording important kinematic data for each trial
        %    col-1 : Trial number
        %    col-2 : Stage of movement
        %    col-3,4 : Target position, angle (m)
        %    col-5,6 : handle X,Y position
        %    col-7,8 : handle X,Y velocity
        %    col-9   : Hit target or missed
        %    col-10  : Total score
        %    col-11  : elapsed time per sample
        %    col-12  : Emergency button status
        trialData =  [ trialData; curTrial, trialFlag, m, m, ...
                       double(instance.current_x),  double(instance.current_y), ...
                       double(instance.velocity_x), double(instance.velocity_y), ...
                       hitFlag, hitScore, elapsed, double(instance.fb_emergency) ];
    end
    
    toSave = [toSave; trialData];  % Mega array to be saved...
    trialData = double.empty();  % reset the content of old trialData
    trialFlag = 1;   % reset the trialFlag back to 1 
    
    if(KbCheck)
        break
    end
end

%% Saving trial data.........
dlmwrite(strcat(myPath, 'Trial Data\','trialdata.csv'), toSave);


%% (7) Final closure and quit.........
% For safety: Ensure the force is null after quiting the loop!
null_force(instance);

% DISCONNECT H-MAN SYSTEM
instance.saveData = false;
%instance.StopSystem()

% Close the audio device:
%PsychPortAudio('Close', pahandle);

% Clear the screen. "sca" is short hand for "Screen CloseAll"
sca;

% Done.
fprintf('Trials finished, bye!\n');

