
function fig = game_interface( xxx, flag )

% This function will prepare gaming display on the LCD monitor, everything shall 
% mainly be black in color, maximize in size, and there will be a background image
% if selected. Input xxx = figure number; flag = show zombie background

% Open an empty figure, hide the figure title. Should I make the window fullscreen?
fig = figure('numbertitle', 'off');%, 'WindowState', 'fullscreen');
% Hide the unnecessary toolbar
set(fig, 'Toolbar', 'none', 'Menubar', 'none');

% (1) Creating a tight margin plot region!
ax = gca;
outerpos = ax.OuterPosition;
ti = ax.TightInset; 
left = outerpos(1) + ti(1)/2;
bottom = outerpos(2) + ti(2)/2;
ax_width = outerpos(3) - ti(1)/2 - ti(3)/2;
ax_height = outerpos(4) - ti(2)/2 - ti(4)/2;
ax.Position = [left bottom ax_width ax_height];
set(gca,'visible','off')  % This removes the border
hold on;

% (2) Load and place background image on the plot!
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';
if (flag)
    bg = imread( strcat(myPath,'\Images\background.jpg') );
    image(bg,'XData',[-0.2 0.2],'YData',[-0.01 0.2]);
end

% (3) Create circular trace for the START position
c = 0.005*[cos(0:2*pi/100:2*pi);sin(0:2*pi/100:2*pi)];
plot( c(1,:),c(2,:), 'LineWidth',5 ); 

% (4) Setting cosmetic/appearance of the plot
axis([-0.2,0.2,-0.014,0.186]);              % axis limits, adjusted to LCD aspect ratio
set(gcf,'Position', get(0, 'Screensize'));  % control figure size (full screen)
set(gcf,'Color','k');                       % set figure background color black
set(gca,'FontSize', 14);                    % control font in the figure
set(gca,'XColor','k','YColor','k');         % set grid color to black
set(gca,'Color','k');                       % set plot background color black
set(gca,'XTick',[],'YTick',[]);             % remove X/Y ticks
set(gca,'XTickLabel',[],'YTickLabel',[]);   % remove X/Y tick labels
set(gca,'YDir','normal')                    % hack to flip plot elements after image!!
daspect([1 1 1])                            % maintaining aspect ratio
  

disp('Preparing gaming interface on the screen...');