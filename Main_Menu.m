

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------  Notice: This is the MAIN INTERFACE to run many different  ------
%------  robotic tasks in H-man.  (Ananda, Aug 2020)               ------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all;

fprintf("\n-----------------------------------------------------------------\n");
fprintf("     Welcome to Act.Sens Main User Interface! (ver. Aug 2020)     \n");
fprintf("-----------------------------------------------------------------\n\n");

fprintf("Choose one of the following: \n");
fprintf("   (1) Motor assessment \n");
fprintf("   (2) Sensory assessment \n");
fprintf("   (3) Training, intervention \n");
fprintf("   (4) Training, control \n");
fprintf("   (5) Motor warm-up \n");
fprintf("   (6) Passive training \n");



testOption  = input('\nEnter your option: ','s');

switch (testOption)
    case '1'
        run('motor_assessment.m')    
    case '2'
        run('proprio_assessment.m')
    case '3'
        run('motor_task_2.m')
    case '4'
        run('motor_task_2.m')
    case '5'
        run('warming_up.m')
    case '6'
        run('passive_task.m')
    otherwise
end

        
    

