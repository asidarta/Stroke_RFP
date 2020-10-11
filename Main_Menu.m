

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------   Note: This is the MAIN INTERFACE to run many different   ------
%------   robotic tasks in H-man.  (Ananda, Aug 2020)              ------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all;

[mywav, Fs] = audioread('C:\Users\rris\Documents\MATLAB\Stroke_RFP\Audio\Opening.mp3');
sound(mywav, Fs);

fprintf("\n------------------------------------------------------------------\n");
fprintf("     Welcome to Act.Sens Main User Interface! (ver. Sept 2020)     \n");
fprintf("------------------------------------------------------------------\n\n");
pause(3);


while (1)
    fprintf("Choose one of the following: \n");
    fprintf("   (1) Motor assessment \n");
    fprintf("   (2) Somatosensory assessment \n");
    fprintf("   (3) Initial warm-up \n");
    fprintf("   (4) Training (treatment or control?) \n");
    fprintf("   (5) Passive training \n");
    fprintf("   (6) Somatosensory assessment-2 \n");
    fprintf("   (7) Quit program\n");
    
    testOption  = input('\nEnter your option: ','s');
    switch (testOption)
        case '1'
            run('motor_assessment.m')    
        case '2'
            run('proprio_assessment.m')
        case '3'
            run('warming_up.m')
        case '4'
            run('motor_task_2.m')
        case '5'
            run('passive_task.m')
        case '6'
            run('proprio_assessment2.m')
        otherwise
            fprintf("\nShutting down. Please wait!\n");
            pause(2);
            quit
    end
end

% Note: This Main Menu script doesn't contain robot communication. For that,
% refer to the "prep_robot.m" inside the individual task script.

