

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------   Note: This is the MAIN INTERFACE to run many different   ------
%------   robotic tasks in H-man.   (Revised by Ananda, Dec 2021)  ------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all;

s = settings;
s.matlab.fonts.codefont.Size.TemporaryValue = 15; % points unit, make Matlab display font bigger!

% NOTE: I declare the working directory as global here so other codes can
% access it without redefining it locally.
global myPath 
myPath = strcat(pwd, '\');  %'C:\Users\rris\Documents\MATLAB\Stroke_RFP\';

% Playing a 'Welcome' audio file.
[mywav, Fs] = audioread(strcat(myPath,'\Audio\Opening.mp3'));
sound(mywav, Fs);
clear mywav Fs;

fprintf("\n------------------------------------------------------------------\n");
fprintf("     Welcome to Act.Sens Main User Interface! (ver. Dec 2021)       \n");
fprintf("------------------------------------------------------------------\n\n");


% UPDATED 3Dec2021 = the connection is established here directly, then fix the handle 
% position (I no longer open/close connection in a test code)
input("Kindly check if the handle is at the centre. If yes, press <Enter> to continue.\n");
[instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();
pause(0.5);
hold_pos(instance);  % >>>>>>>
pause(1.0);

% Keep looping until exit option is selected....
while (1)
    fprintf("\nChoose one of the following: \n");
    fprintf("   (1) Motor assessment \n");
    fprintf("   (2) Somatosensory assessment \n");
    fprintf("   (3) Somatosensory assessment-2 \n");
    fprintf("   (4) Initial warm-up \n");
    fprintf("   (5) Training (treatment or control?) \n");
    %fprintf("   (6) Passive training \n");
    fprintf("   (7) Quit program\n");
    
    % Expect input from the user. Note: even if this is in While-loop, the
    % code will always wait here before continuing.
    testOption  = input('\nEnter your option: ','s');
    
    % Check if variable 'instance' to handle the robot has been created. If yes, reset the connection.
    %if(exist("instance","var")>0)  
    %    instance.CloseConnection(); 
    %end
    
    switch (testOption)
        case '1'
            %run('motor_assessment.m')
            motor_assessment(instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx)
        case '2'
            %run('proprio_assessment.m')
            proprio_assessment(instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx)
        case '3'
            %run('proprio_assessment2.m')
            proprio_assessment2(instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx)
        case '4'
            %run('warming_up.m')
            warming_up(instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx)
        case '5'
            %run('motor_task_2.m')
            motor_task_2(instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx)
        case '6'
            run('passive_task.m')
        case '7'
            fprintf("\nClosing Matlab now. You may now shut down the computer, and")
            fprintf("\nturn off the wireless keyboard and mouse.\n");
            pause(3);
            instance.CloseConnection();   % Close connection with robot
            break%quit   % Quit Matlab. Robot connection automatically off.
        otherwise
            fprintf("\nWrong selection. Try again.\n\n");
    end
    
end

clearTemporaryValue(s.matlab.fonts.codefont.Size);
 



