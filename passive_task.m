

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------ Notice: Code for PASSIVE Motor Training Task with Reward  ---------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Note: Good for subjects with FMA score < 40 (Chris said).

% Clear the workspace and the screen
sca; 
%clear; close all; 
%clearvars;

%% (0) Produce filename for the current trial based on user-defined information
%[subjID, ~, ~, myresultfile] = collectInfo( mfilename );



%% Robot-related parameters -----------------------------------------------
% Load the H-MAN DLL files
my_pwd = 'C:\Users\rris\Documents\MATLAB\Control library\.dll files\';
Articares = NET.addAssembly(strcat(my_pwd,'\Articares.Core.dll'));
Log = NET.addAssembly(strcat(my_pwd,'\NLog.dll'));

% Connect H-MAN to the workstation
fprintf("Preparing connection to H-man................\n");
%instance = ConnectHman();
NLog.Common.InternalLogger.Info('Connection with H-MAN established');

% Robot stiffness and viscuous field!
kxx = num2str(3500); 
kyy = num2str(3500);
kxy = num2str(0); 
kyx = num2str(0);
bxx = num2str(50);  
byy = num2str(20);


%% Are we reading another person's trajectory? If yes, do this!           
% Trial-related parameters -----------------------------------------------
hitScore  = 0;   % Add +10 for each time hit the target
myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';
% Read trajectory file. The content will be replayed to subjects during training
trajReplay = dlmread(strcat(myPath,'\Trial Data\0.csv'));
% Get a subset where the person reach forward to the target!
reach2Target = trajReplay(trajReplay(:,2) == 1, :); 
reachTrial = unique(trajReplay(:,1));
Ntrial     = max(unique(trajReplay(:,1)));

trialData = double.empty();
toSave = double.empty();
lastXpos = instance.current_x; lastYpos = instance.current_y;

% Create a flag to denote which stages of the movement it is:
%        1: move to a target
%        2: reached the target and stop
%        3: move back to the start
%        4: stay and ready for next trial
trialFlag = 1;

% Define the SIZE of the target!
targetSize = 15;  %>>>>>>>>>>>>>>



%% GAMING DISPLAY: Plot the X,Y data --------------------------------------
% Open an empty figure, remove the toolbar.
SetMouse(10,10);  % Place away mouse cursor
fig = figure(1);
set(fig, 'Toolbar', 'none', 'Menubar', 'none');
%child = fig.Children;

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
set(gca,'visible','off')  % This removes the border
hold on;

% Create circular target traces
c = 0.005*[cos(0:2*pi/100:2*pi);sin(0:2*pi/100:2*pi)];
targetDist = 0.15;
%plot( %c(1,:)+targetDist*cosd(30), c(2,:)+targetDist*sind(30), ...
      %c(1,:)+targetDist*cosd(60), c(2,:)+targetDist*sind(60), ... 
      %c(1,:)+targetDist*cosd(90), c(2,:)+targetDist*sind(90), ...
      %c(1,:)+targetDist*cosd(120),c(2,:)+targetDist*sind(120), ...
      %c(1,:)+targetDist*cosd(150),c(2,:)+targetDist*sind(150), ...
plot(  c(1,:),c(2,:), 'LineWidth',5 ); 

% Setting cosmetic/appearance of the plot
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

% Let's compute the centre of the TARGET positions (convert to mm unit)
targetCtr = [[ targetDist*cosd(30);
               targetDist*cosd(60);
               targetDist*cosd(90);
               targetDist*cosd(120);
               targetDist*cosd(150)] * 1000, ...
             [ targetDist*sind(30);
               targetDist*sind(60);
               targetDist*sind(90);
               targetDist*sind(120);
               targetDist*sind(150)] * 1000] ;
ang = [30,60,90,120,150];  % Angle (degree) w.r.t positive X-axis.


% Sample frequency, timing parameters
sample_freq = 200;  % IMPORTANT that the sample freq remains the same!!!
move_duration = 2.0;
t = 0: 1/sample_freq : move_duration;
curTrial = 1; 
timerFlag = true;
delay_at_target = 1.0;  % Hold at target position (sec)


%% Audio and Visual FEEDBACK during training -------------------------------
% Define the required audio file
[wav1, Fs] = audioread( strcat(myPath,'\Audio\assess.mp3') );

% Text to be displayed as feedback
txt1 = 'Next trial ~';
txt2 = '    Good job!!';
txt3 = 'Current score: ';
txt4 = 'Wrong movement';




%% Main loop: looping through ALL trials! ----------------------------------
pause_me(2.0)
while (~KbCheck && curTrial <= Ntrial)
    
    % (1) Ensure no force first    
    pause_me(1.0);
    null_force(instance);
    fprintf('\nTRIAL %d\n', curTrial);

    % (2) Load the trajectory trial-by-trial...
    out1  = trajReplay(trajReplay(:,1)==curTrial, :);
    out1(length(out1),:) = [];
    angle = ang(unique(out1(:,3)));
    reward_status = unique(out1(out1(:,2)==3,9));
 
    % (3a) Remind subjects to stay relaxed!
    goCue = plot_image(11, 0, 0.1, 30);   pause_me(1.25);
    delete(goCue);  % delete from the plot after a sufficient time

    % (3b) Plot the current TARGET position.
    fprintf('   Presenting target location...\n');
    mytarget = plot_image( unique(out1(:,3)), c(1,:)+targetDist*cosd(angle),...
                           c(2,:)+targetDist*sind(angle), targetSize );

    fprintf('   Presenting trajectory...\n');
    %plot(out1(:,5),out1(:,6),'w.');    

    % Convert position into string for robot command, for trial flag = 1. 
    % Convert to mm unit!
    Xpos = num2str(out1(out1(:,2)==1,5)*1000); 
    Ypos = num2str(out1(out1(:,2)==1,6)*1000);
            
    % (4) Present that trajectory with minimum jerk! Note that I put a
    % pause inside which corresponds to sample duration for the replay!
    for j = 1:length(out1(out1(:,2)==1))
        p1 = plot(instance.current_x, instance.current_y, 'w.', 'MarkerSize', 50);
        xt = Xpos(j,:);  yt = Ypos(j,:);
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0');
        pause(out1(j,11));
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
        delete(p1);
    end
        
    hold_pos(instance);

    % (5) Hold for 2 sec, and show REWARD feedback if any...
    score = unique(out1(out1(:,2)==3,10));
    score = num2str(score);
    if (reward_status)
        mymsg = [txt2, newline, txt3, ' ', score];
        t2 = text(-0.05,0.17,mymsg,'FontSize',49,'Color','g');
        play_KR(myPath);  % Positive feedback
        pause(0.05);
        pause_me(delay_at_target);
    else
        t4 = text(-0.051,0.16,' ','FontSize',55,'Color','r');
    end
    
    % (6) Minimum jerk haptic targets to zero (START) position
    out2 = min_jerk([instance.current_x*1000 instance.current_y*1000 0], [0 0 0], t);
    fprintf('   Moving back to start position...\n');
    pause_me(delay_at_target);
        
    % Convert position into string for robot command.
    Xpos = num2str(out2(:,1)); 
    Ypos = num2str(out2(:,2));
    
    % (7) Move handle back to ORIGIN, zero position 
    for j = 1:length(out2)
%        p2 = plot(instance.current_x, instance.current_y, 'w.', 'MarkerSize', 50);
        xt = Xpos(j,:);  yt = Ypos(j,:);
        instance.SetTarget(xt,yt,kxx,kyy,kxy,kyx,bxx,byy,'0','0','1','0'); 
        pause(1/sample_freq);
%        trialData(j,:) = [ curTrial, trialFlag, round(end_X), round(end_Y), ...
%                           double(instance.current_x),  double(instance.current_y), ...
%                           double(instance.velocity_x), double(instance.velocity_y), ...
%                           double(instance.fb_emergency)];
%        delete(p2);
        if (KbCheck)
            break; % Shall bail out if we press any key!
        end
    end
    
    % Display the trajectory for our info only!
    %plot(out2(:,1)./1000, out2(:,2)./1000, 'g.');
    
    % (8) Clear the figure from old position data. First, obtain the handler to the
    % children part of the figure, then delete the components!
    pause_me(3);
    mychild = fig.Children.Children;
    delete(mychild(1:length(mychild)-2));
    
    % (9) CONTINUE TO THE NEXT TRIAL.....
    t1 = text(-0.03,0.16,txt1,'FontSize',55,'Color','w');
    curTrial = curTrial + 1; 
    pause(0.05); pause_me(2);
    delete(t1);  % Delete text after displaying it

end


%% Saving trial data.........
%dlmwrite(strcat(myPath, 'Trial Data\',myresultfile), toSave);

% For safety: Ensure the force is null after quiting the loop!
null_force(instance); 
close all;

% Stop TCP connection 
instance.CloseConnection();
fprintf("\nClosing connection to H-man................\n");

% Done.
fprintf('\nTrials finished, bye!\n');