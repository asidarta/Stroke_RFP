

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------ Note: Code for PASSIVE Motor Training Task with Reward  ---------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Note: Good for subjects with FMA score < 40 (Chris said).

% Clear the workspace and the screen
sca; 
clear; close all; 
clearvars;

%% (0) Produce filename for the current trial based on user-defined information
%[subjID, ~, myresultfile] = collectInfo( "passive" );



%% Robot-related parameters -----------------------------------------------
% Obtain the instance handler, stiffness, and damping parameters.
[instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();

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

% Sample frequency, timing parameters
sample_freq = 200;  % IMPORTANT that the sample freq remains the same!!!
move_duration = 2.0;
t = 0: 1/sample_freq : move_duration;
curTrial = 1; 
timerFlag = true;
delay_at_target = 1.0;  % Hold at target position (sec)

% Create a flag to denote which stages of the movement it is:
%        1: move to a target
%        2: reached the target and stop
%        3: move back to the start
%        4: stay and ready for next trial
trialFlag = 1;

% Define the SIZE of the target!
targetSize = 15;  %>>>>>>>>>>>>>>



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

% Define the required audio file
[wav1, Fs] = audioread( strcat(myPath,'\Audio\assess.mp3') );

% Text to be displayed as feedback
txt1 = 'Next trial ~';
txt2 = '    Good job!!';
txt3 = 'Current score: ';
txt4 = 'Wrong movement';




%% Main loop: looping through ALL trials! ----------------------------------
pause_me(2.0)
while (~bailOut && curTrial <= Ntrial)
    
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
        if (bailOut)
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
        if (bailOut)
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

% Stop TCP connection 
instance.CloseConnection();
fprintf("\nClosing connection to H-man................\n");


%% Indicate code has ended by playing an audio message
[mywav, Fs] = audioread( strcat(myPath,'\Audio\claps3.wav') );
sound(mywav, Fs);
fprintf('\nProprioception Test finished, bye!!\n');
pause(3.0)
close all; clear; clc;  % Wait to return to MainMenu?
fprintf("\nReturning to Main Menu selection.......\n");


%% Function to detect ESC keyboard press, it returns the flag defined as global.
function bailOut = KeyPressFcn(~,evnt)
    global bailOut
    %fprintf('key event is: %s\n',evnt.Key);
    if(evnt.Key=="escape") 
       bailOut = true;  %fprintf('--> You have pressed wrongly, dear!\n');
    end
end
