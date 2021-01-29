
function fig = game_interface( xxx, flag, imgNum )

% This function will prepare gaming display on the LCD monitor, everything is mostly
% black, maximize in size, and there will be a background image if selected. 
% 
% Input xxx = figure number; flag = show zombie background; imgNum is 0 to 4 ...
%          image number is randomized number so that each block will have different 
%          background/monster/music.
% Open an empty figure, hide the figure title. Should I make the window fullscreen?
%fig = figure('numbertitle', 'off');%, 'WindowState', 'fullscreen');

% What if I want to show it on ANOTHER monitor?!!!
[fig, mm] = use_monitor2();
monitorPos  = get(0, 'MonitorPositions');
newPosition = monitorPos(1,:);
newPosition(1) = newPosition(1) + monitorPos(mm,1);

fig.set('Toolbar', 'none', 'Menubar', 'none');  % hide the unnecessary toolbar
fig.set('Position', newPosition);               % make figure full screen on the 2nd monitor!!
fig.set('Color','k');                           % set figure background color black

% (1) Creating a tight margin plot region!
ax = gca;   hold on;
outerpos = ax.OuterPosition;
ti = ax.TightInset; 
left = outerpos(1) + ti(1)/2;
bottom = outerpos(2) + ti(2)/2;
ax_width = outerpos(3) - ti(1)/2 - ti(3)/2;
ax_height = outerpos(4) - ti(2)/2 - ti(4)/2;
ax.Position = [left bottom ax_width ax_height];

% (2) Setting cosmetic/appearance of the plot
ax.set('visible','off');                   % This removes the border
ax.set('FontSize', 14);                    % control font in the figure
ax.set('XColor','k','YColor','k');         % set grid color to black
ax.set('Color','k');                       % set plot background color black
ax.set('XTick',[],'YTick',[]);             % remove X/Y ticks
ax.set('XTickLabel',[],'YTickLabel',[]);   % remove X/Y tick labels
ax.set('YDir','normal');                   % hack to flip plot elements after image!!
axis([-0.2,0.2,-0.014,0.186]);             % axis limits, adjusted to LCD aspect ratio
daspect([1 1 1]);                          % maintaining aspect ratio

% (3) Load and place background image on the plot!
figure(xxx);
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\Images\';  % working directory!
myPath = strcat(myPath,num2str(imgNum),'\');

if (flag)
    bg = imread( strcat(myPath,'\background.png') );
    image(flipud(bg),'XData',[-0.2 0.2],'YData',[-0.01 0.2]);

    % (4) Create circular trace for the START position
    c = 0.005*[cos(0:2*pi/100:2*pi);sin(0:2*pi/100:2*pi)];
    plot( c(1,:),c(2,:), 'LineWidth',5 ); 
       
    % (5) This is for the background music. Ensure this window doesn't distract
    soundfig = figure(3);  soundfig.WindowState = 'minimized';
    actx = actxcontrol('WMPlayer.ocx.7'); % Create controller
    media = actx.newMedia(strcat(myPath,'\music.mp3')); % Create media object
    actx.CurrentMedia = media;
    actx.settings.playCount = 999; % Play the media 999 times
    % actx.Controls.play;
    % To hide the fig, in this case music won't stop without closing this figure
    soundfig.set('DefaultFigureVisible','on'); 
end

disp('Preparing gaming interface on the screen...');





