
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------ Notice: Code for Active Motor Test/Training Task ---------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clear the workspace and the screen
sca; 
%clear; close all; 
%clearvars;


%% (1) H-MAN Robot Setup......... 
% Load the DLL files
my_pwd = 'C:\Users\rris\Documents\MATLAB\Control library\.dll files\';
Articares = NET.addAssembly(strcat(my_pwd,'\Articares.Core.dll'));
Log = NET.addAssembly(strcat(my_pwd,'\NLog.dll'));

fprintf("Preparing connection to H-man................\n");

% Connect H-MAN to the workstation
instance = ConnectHman();

% Write in the NLog text file
NLog.Common.InternalLogger.Info('Connection with H-MAN established');

% For Full-HD display = 1920 x 1080, H-Man workspace = 34 x 33 cm, the screen
% coordinate calibration factor would be:
factorX = 100*1920/34;
factorY = -1*100*1080/33;

% Hold handle at the start position, fixed prior to running the code  >>>>>>
% The position of the handle will be taken as ORIGIN (0,0)!
hold_pos(instance);

% Set parameters specifically for minimum jerk production
stiffness = num2str(3000);  % Stiffness (N/m)
stiffxy   = num2str(400);
damping   = num2str(20);    % Viscocity (N.s/m2)



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
%        2: reached the target
%        3: move back to the start
%        4: stay and ready for next trial
trialFlag = 1;

% For saving the kinematic data into a textfile
toSave    = double.empty();
trialData = double.empty();
sample = 1;


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

% Determine the XY position and Size for TARGET DOT in pixels. If we were
% to use an image instead, we then have to specify the image size as a square.
targetDist = 500;
targetSize = 60;   % in pixel!

% Let's compute the centre of the TARGET DOTS.
targetCtr = [ dotXpos + [targetDist*cosd(330);
                         targetDist*cosd(300);
                         targetDist*cosd(270);
                         targetDist*cosd(240);
                         targetDist*cosd(210)], ...
              dotYpos + [targetDist*sind(330);
                         targetDist*sind(300);
                         targetDist*sind(270);
                         targetDist*sind(240);
                         targetDist*sind(210)] ];
                                      

%% (5) This is to set up the audio feedback part
% Load audio file containing the Welcome Message!
[wavedata, freq] = psychwavread( strcat(myPath,'\Audio\assess.mp3') );
nrchannels  = size(wavedata,2); % Number of rows = number of channels.
repetitions = 1;
device = [];
%if nrchannels < 2
%    wavedata = [wavedata wavedata];  % Make it stereo audio
%    nrchannels = 2;
%end

% Open the audio device, with default mode [] (==Only playback) and freq which will return 
% a handle to the audio device. Do this once only....
pahandle = PsychPortAudio('Open', device, [], 0, freq, nrchannels);

% Fill the audio playback buffer with the audio data 'wavedata':
%PsychPortAudio('FillBuffer', pahandle, wavedata');

% Play the content of the audio buffer defined above
%PsychPortAudio('Start', pahandle, repetitions, 0, 1);

Active = 1;

while Active
    WaitSecs(5);    % Wait a second...
    s = PsychPortAudio('GetStatus', pahandle); % Query playback status
    Active = s.Active;
    % Stop any audio playback once done
    if (~Active)
        fprintf("Stop playback!\n");
        PsychPortAudio('Stop', pahandle);
    end
end

% New audio for the positive feedback, it goes through the same subroutines
[wavedata, freq] = psychwavread( strcat(myPath,'\Audio\coin2.mp3') );
%pahandle = PsychPortAudio('Open', device, [], 0, freq, nrchannels);
PsychPortAudio('FillBuffer', pahandle, wavedata');



%% (6) Core: Presentation loop, looping through ALL trials!
for i = 1:Ntrial
    
    tic;   % this is to calculate elapsed time per loop.....
    k = eachTrial(i); nextTrial = 0;  
    fprintf('\nTRIAL %d: Moving towards the TARGET.\n', i);

    thePoints = [];     % Array for mouse position
    hitFlag   = false;  % Have I hit the target?
    timerFlag = false;  % Is stay-at-target timer still active?
    aimless_  = true;   % Is the subject unable to reach?
    pos_index = 0;      % index for instantaneous position

    while (~KbCheck && ~nextTrial)
        
        % STAGE-1 : Moving towards the target (press any key to exit)
        % First we load in an image from file according to target location
        if (trialFlag == 1 || trialFlag == 2)
            switch( eachTrial(i) )
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
            Screen('DrawTexture', window, targetTexture, [], [targetCtr(k,1)-targetSize
                                                          targetCtr(k,2)-targetSize
                                                          targetCtr(k,1)+targetSize
                                                          targetCtr(k,2)+targetSize], ...
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
            dist2Target = sqrt((mouseXpos-targetCtr(k,1))^2 + (mouseYpos-targetCtr(k,2))^2);
            
            % Subject cannot be aimlessly reaching forever, there is a 6-sec timeout.
            if (toc > 6)
                fprintf("Timeout. Failed to reach to this direction!\n");
                aimless_ = true;
                trialFlag = 3;   % Mouse cursor moves back to the START
            end
            
            % Note: ensure that subject is able to move beyond a certain distance.
            if (speed < 2 && dist2Start > 300)
                if (~timerFlag)
                    tic   % Start timer
                end
                if (toc > 1.5)
                    % Hold for 1.5 seconds and NEAR enough to the target
                    if (dist2Target < 40)
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
                    timerFlag = false;   
                else
                    timerFlag = true;  % Update flag to allow new 'tic'
                end           
            else
                timerFlag = false;   % Update flag so as to prevent 'tic' again
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
            if (~timerFlag)
                tic   % Start timer
                if(showReward && hitFlag) 
                    PsychPortAudio('Start', pahandle, repetitions, 0, 0);
                end
                % Set hold position of H-man, run once! >>>>>>>>>>>>>>
                hold_pos(instance);
            end
            timerFlag = true;   % Update flag so as to prevent 'tic' again

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
                            targetCtr(k,1), targetCtr(k,2), 5);
                %Screen('LineStipple', window, 1, 1, [0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1]);
            end
            
            if (toc > 1) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Hold for 4 seconds on the target, then proceed next to return home
                timerFlag = false;
                trialFlag = 3;
                fprintf('Now moving back to START position.\n');
            end

        end
        
        % STAGE-3 : Moving BACK to the Start position (press any key to exit)
        if (trialFlag == 3)        % Set the cursor position back to START!            
            mouseXpos = dotXpos; mouseYpos = dotYpos;
            %SetMouse(mouseXpos, mouseYpos, window);
            
            % Move the handle back to start using minimum jerk traj >>>>>>>>
            movepos = moveTo(instance,0,0,3);
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
            if (~timerFlag)
                tic   % Start timer
            end
            timerFlag = true;   % Update flag so as to prevent 'tic' again
            Screen('DrawText', window, 'Next trial ~', 800, 100, [255,255,255,1]);

            % Hold for 2 seconds then move to next trial
            if (toc > 2)
                fprintf('Ready for the next trial~\n');
                timerFlag = false;
                % After time lapse, we are ready to go to the next trial
                trialFlag = 1;
                nextTrial = 1;
            end
        end
        
        % EDIT: I decided to do this to prevent drawing the screen each looping.
        % Rather the drawing occurs for every 5-sample.
        if (mod(pos_index,5) == 0 || trialFlag ~= 3)
            % Lastly, flip to the screen to draw all previous commands onto the screen 
            Screen('Flip', window);
        else
            pause(0.004);
        end
        
        % The position value at t-1
        lastXpos = mouseXpos; lastYpos = mouseYpos;
        
        % STAGE-5 : Recording important kinematic data for each trial
        %    col-1 : Trial number
        %    col-2 : Sample number
        %    col-3 : Stage of movement
        %    col-4,5 : Target X,Y position
        %    col-6,7 : handle X,Y position
        %    col-8,9 : handle X,Y velocity
        %    col-10  : Hit target or missed
        %    col-11  : Emergency button status
        trialData =  [ trialData; i, trialFlag, ...
                       round(targetCtr(k,1)), round(targetCtr(k,2)), ...
                       double(instance.current_x),  double(instance.current_y), ...
                       double(instance.velocity_x), double(instance.velocity_y), ...
                       hitFlag, double(instance.fb_emergency) ];
        sample = sample+1;
    end
    
    elapsed = toc;   % elapsed time per loop
    toSave = [toSave; trialData];  % Mega array to be saved...
    
end



%% (7) Final closure and quit.........
null_force(instance);

% DISCONNECT H-MAN SYSTEM
instance.saveData = false;
%instance.StopSystem()

% Close the audio device:
PsychPortAudio('Close', pahandle);

% Clear the screen. "sca" is short hand for "Screen CloseAll"
sca;

% Done.
fprintf('Trials finished, bye!\n');

