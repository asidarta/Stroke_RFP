function output = move2centre(xfinal, yfinal, move_duration)

% Move the robot handle from a start position to a chosen centre of workpace
% 17Nov2021 = we want to automatically bring the handle into the centre first. It's bad firmware
% design, for H-MAN the first handle location upon connetced is taken as (0,0).

    fprintf("Moving the robot handle to the centre. Please wait!\n\n");
    
    [instance,kxx,kyy,kxy,kyx,bxx,byy,bxy,byx] = prep_robot();   % First CONNECT to H-MAN...

    sample_freq = 500;  %??
    t = 0: 1/sample_freq : move_duration;

    %start_X = instance.current_x*1000; % Unit: mm -> m
    %start_Y = instance.current_y*1000; % Unit: mm -> m

    % Revised to follow library V2.
    %start_X = instance.hman_data.location_X*1000; % Unit: mm -> m
    %start_Y = instance.hman_data.location_Y*1000; % Unit: mm -> m

    end_X   = xfinal * 1000; % Unit: mm -> m
    end_Y   = yfinal * 1000; % Unit: mm -> m

    out = min_jerk([0 0 0], [end_X end_Y 0], t);
    %plot(t,out(:,1),'r.')
    
    % Set parameters specifically for minimum jerk production
    stiff = num2str(3500);  % Stiffness (N/m)  
    damp  = num2str(20);    % Viscocity (N.s/m2)
    
    for i = 1:length(out)
        tic;
        xt = num2str(round(out(i,1)));
        yt = num2str(round(out(i,2)));
        instance.SetTarget(xt,yt,stiff,stiff,'0','0',damp,damp,'0','0','1','0'); 
        pause(1/sample_freq);
    end

    output = instance;   % Return robot handler
    
end