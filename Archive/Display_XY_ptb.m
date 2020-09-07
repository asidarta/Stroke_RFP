
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This code will let the subject moves the handle in null field, then
%  display the instantaenous cursor position in space.
%  NOTE: We make use of PsychToolBox functions for the graphical display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clear the workspace and the screen
sca; 
clc; clear; close all; 
clearvars;


% Load the DLL files
my_pwd = 'C:\Users\rris\Documents\MATLAB\Control library\.dll files\';
Articares = NET.addAssembly(strcat(my_pwd,'\Articares.Core.dll'));
Log = NET.addAssembly(strcat(my_pwd,'\NLog.dll'));

% Connect H-MAN to the workstation
instance = ConnectHmanV1();

% Write in the NLog text file
NLog.Common.InternalLogger.Info('Connection with H-MAN established');

% For Full-HD display = 1920 * 1080, H-Man workspace = 34 cm * 33 cm, the 
% screen coordinate calibration factor would be:
factorX = 100*1920/34;
factorY = -1*100*1080/33;

% I decided to apply an offset to make the handle as close as possible to
% the body. The screen offset (in pixel) will be display height 1080 - Yoffset.
Yoffset = 980;

% Here we call some default settings...
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1); 

% Get id screens attached to the machine. The first one by default is the 
% laptop own monitor. Use XOrgConfCreator/Selector to modify the setup.
screens = Screen('Screens');

% Always choose the last external monitor in the register
screenNumber = 0 %max(screens);

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
Screen('TextSize', window, 40);


%% Visual components of the display
% Determine the XY position and Size for START DOT in pixels
dotXpos = 0.5 * screenXpixels;
dotYpos = 0.85 * screenYpixels;
dotSizePix = 20;
startpos = [dotXpos-dotSizePix dotYpos-dotSizePix dotXpos+dotSizePix dotYpos+dotSizePix];


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
                     
 while (1) 
     
    mouseXpos = double(instance.current_x * factorX) + dotXpos;
    mouseYpos = double(instance.current_y * factorY) + dotYpos;

    % Lastly, flip to the screen to draw all previous commands onto the screen 
    Screen('DrawDots', window, [mouseXpos mouseYpos], 20, dotColor, [], 2);
    pause(0.01);
    Screen('Flip', window);
    
 end
 
 % Stop H-man talking....
instance.StopSystem();