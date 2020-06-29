
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------ Code for Test of Proprioception (Joint Position Matching) ---------
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

% Set parameters specifically for minimum jerk production
stiffness = num2str(3000);  % Stiffness (N/m)
damping   = num2str(60);    % Viscocity (N.s/m2)



%% (2) Trial setup
% Set total number of trials and randomise them.
Ntrial = 40;
hitScore  = 0;   % Add +10 for each time hit the target
toshuffle = repmat(1:1,[1 Ntrial/1]);   % We have 5 target directions!!!
eachTrial = Shuffle(toshuffle);
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';

% NOTE: ALL IS OFF DURING THIS TEST!
showCursor = true;    % to show mouse cursor during movement?
showReward = false;   % to show score with feedback?
lastXpos = 0; lastYpos = 0;

% Create a flag to denote which stages of the movement it is:
%        1: move to a target
%        2: reached the target
%        3: move back to the start
%        4: stay and ready for next trial
%        5: ONLY FOR PROPRIO- TEST. THIS IS FOR MOVING TO Reference TARGET!
%        6: ONLY FOR PROPRIO- TEST. THIS IS FOR RETURNING BACK!
trialFlag = 5;

% For saving the kinematic data into a textfile
toSave    = double.empty();
trialData = double.empty();
%sample = 1;


%% (3) Screen and audio preparation for Psychtoolbox!!
% Here we call some default settings...
PsychDefaultSetup(2);
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



%% (5) Core: Presentation loop, looping through ALL trials!
for i = 1:Ntrial
    
    tic;   % this is to calculate elapsed time per loop.....
    k = eachTrial(i); nextTrial = 0;  
    fprintf('\nTRIAL %d: Moving towards the TARGET.\n', i);

    Flag = false;
    pos_index = 0;  % index for min. jerk position

    while (~KbCheck && ~nextTrial)
    tic    
        % Conversion between target screen coordinate (on display) to real world (workspace) 
        target_X = (targetCtr(k,1) - Xoffset)/factorX;   % unit in mm
        target_Y = (targetCtr(k,2) - Yoffset)/factorY;   % unit in mm
        
        % NOTE THIS IS H-MAN POSITION READOUT! ---------------------
        mouseXpos = double(instance.current_x * factorX) + Xoffset;  
        mouseYpos = double(instance.current_y * factorY) + Yoffset;
        
        % Show target circle in green, subjects will close their eyes anyways
        Screen('DrawDots', window, [targetCtr(k,1) targetCtr(k,2)], 30, [0 255 0], [], 2);
        
        % Compute the distance between the mouse CURSOR and the START centre
        dist2Start = sqrt((mouseXpos-dotXpos)^2 + (mouseYpos-dotYpos)^2);

        % Compute the distance between the mouse CURSOR and the TARGET centre
        dist2Target = sqrt((mouseXpos-targetCtr(k,1))^2 + (mouseYpos-targetCtr(k,2))^2); 

        % STAGE 5: THIS IS UNIQUE TO PROPRIOCEPTIVE TEST only. It will play
        % the trajectory of the reference to a target.        
        if (trialFlag == 5)
            if (~Flag)
                % Reset the flag, ensure this section runs once only...
                Flag = true;
                % RELEASE the handle holding force;  >>>>>>>>>>>>>>
                null_force(instance);
            end
            
            % Move the handle back to start using minimum jerk traj >>>>>>>>
            movepos = moveTo(instance,target_X,target_Y,2);
            if (pos_index < length(movepos))
                pos_index = pos_index + 1;
                xt = round(movepos(pos_index,1));
                yt = round(movepos(pos_index,2));
                instance.SetTarget( num2str(xt),num2str(yt),stiffness,stiffness, ...
                                    '0','0',damping,'0','0','0','1','0' ); 
            else
                % After minimum jerk has finished, the handle may not go back exactly since 
                % the robot is quite weak. The robot is quite weak, we ensure the handle 
                % goes back to the START first.
                if (dist2Target >= 10)
                    instance.SetTarget( num2str(target_X*1000),num2str(target_Y*1000),...
                                        '0','0','0','0','0','0','0','0','1','0'); 
                    %fprintf('Stabilizing...\n');
                else
                    % Set hold position of H-man, run only once! >>>>>>>>>>>>>>
                    hold_pos(instance);
                    % Go to the LAST stage
                    trialFlag = 6;
                    pos_index = 0;  % index for min. jerk position
                    fprintf('Moving back to origin\n');
                end
            end
        end
        
        % STAGE 6: Same like Stage-5... It will play the reference trajectory to ORIGIN.        
        if (trialFlag == 6)
            % Move the handle back to start position >>>>>>>>
            movepos = moveTo(instance,0,0,2);
            if (pos_index < length(movepos))
                pos_index = pos_index + 1;
                xt = round(movepos(pos_index,1));
                yt = round(movepos(pos_index,2));
                instance.SetTarget( num2str(xt),num2str(yt),stiffness,stiffness, ...
                                    '0','0',damping,'0','0','0','1','0' ); 
                %Screen('DrawDots', window, [mouseXpos, mouseYpos], 20, [0,0,0], [], 2);
            else
                % After minimum jerk has finished, the handle may not go back exactly since 
                % the robot is quite weak. The robot is quite weak, we ensure the handle 
                % goes back to the START first.
                if (dist2Start >= 10)
                    instance.SetTarget('0','0','1500','1500','0','0','0','0','0','0','1','0'); 
                    %fprintf('Stabilizing...\n');
                else
                    % Set hold position of H-man, run only once! >>>>>>>>>>>>>>
                    hold_pos(instance);
                    % Go to the LAST stage
                    trialFlag = 5;
                    pos_index = 0;  % index for min. jerk position
                    nextTrial = 1;
                    %Screen('DrawText', window, 'Your turn!',  800, 60, [255,255,255,255]);
                    %Screen('Flip', window);
                    % Delay for 2 seconds at the target location..........
                    pause(2);
                end
            end
        end
        
        % Drawing CURSOR showing instantaneous mouse position on the screen, but
        % only when the conditions are met
        if (dist2Start < 35)
            Screen('DrawDots', window, [mouseXpos mouseYpos], 20, dotColor, [], 2);
        elseif (showCursor && dist2Start > 30)
            Screen('DrawDots', window, [mouseXpos mouseYpos], 20, dotColor, [], 2);
        end
        
        % EDIT: I decided to do this to prevent drawing the screen each looping.
        % Rather the drawing occurs for every 3-sample.
        %if (mod(pos_index,10) == 0 )
            % Lastly, flip to the screen to draw all previous commands onto the screen 
            %Screen('Flip', window);
        %else
        pause(0.002);
        %end
        trialData = [ trialData; i, trialFlag, round(targetCtr(k,1)), round(targetCtr(k,2)), ...
                                double(instance.current_x),  double(instance.current_y), ...
                                double(instance.velocity_x), double(instance.velocity_y), ...
                                double(instance.fb_emergency)];

    toc
    end
    
    %elapsed = toc;   % elapsed time per loop
    
end

%plot(trialData(:,5), trialData(:,6), 'r*'); axis([-0.05,0.2,-0.05,0.2]);

%% (7) Final closure and quit.........

% DISCONNECT H-MAN SYSTEM
%instance.StopSystem()

% Clear the screen. "sca" is short hand for "Screen CloseAll"
sca;

% Done.
fprintf('Trials finished, bye!\n');

