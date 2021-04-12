

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------   Note: This is the MAIN INTERFACE to run many different   ------
%------   robotic tasks in H-man.   (Revised by Ananda, Apr 2021)  ------
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

fprintf("\n------------------------------------------------------------------\n");
fprintf("     Welcome to Act.Sens Main User Interface! (ver. Feb 2021)       \n");
fprintf("------------------------------------------------------------------\n\n");
pause(1.5);

% Keep looping until exit option is selected....
while (1)
    fprintf("Choose one of the following: \n");
    fprintf("   (1) Motor assessment \n");
    fprintf("   (2) Somatosensory assessment \n");
    fprintf("   (3) Somatosensory assessment-2 \n");
    fprintf("   (4) Initial warm-up \n");
    fprintf("   (5) Training (treatment or control?) \n");
    %fprintf("   (6) Passive training \n");
    fprintf("   (7) Quit program\n");
    
    testOption  = input('\nEnter your option: ','s');
    switch (testOption)
        case '1'
            run('motor_assessment.m')    
        case '2'
            run('proprio_assessment.m')
        case '3'
            run('proprio_assessment2.m')
        case '4'
            run('warming_up.m')
        case '5'
            run('motor_task_2.m')
        case '6'
            run('passive_task.m')
        case '7'
            fprintf("\nClosing Matlab now. You may now shut down the computer, and")
            fprintf("\nturn off the wireless keyboard and mouse.\n");
            pause(5);
            quit
        otherwise
            fprintf("\nWrong selection. Try again.\n\n");
    end
end

clearTemporaryValue(s.matlab.fonts.codefont.Size);

% Note: This Main Menu script doesn't contain robot communication. For that,
% refer to the "prep_robot.m" inside the individual task script.

