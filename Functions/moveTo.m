function output = moveTo(instance, xfinal, yfinal, move_duration)

% Move the H-MAN handle from a start position to a final position. By default, 
% the start position is the current position. Output is an position array.

    sample_freq = 500;
    t = 0: 1/sample_freq : move_duration;

    start_X = instance.current_x*1000; % Unit: mm -> m
    start_Y = instance.current_y*1000; % Unit: mm -> m

    end_X   = xfinal * 1000; % Unit: mm -> m
    end_Y   = yfinal * 1000; % Unit: mm -> m

    out = min_jerk([start_X start_Y 0], [end_X end_Y 0], t);
    %plot(t,out(:,1),'r.')
    
    % Set parameters specifically for minimum jerk production
    %stiff = num2str(5000);  % Stiffness (N/m)  
    %damp  = num2str(20);    % Viscocity (N.s/m2)
    
    %for i = 1:length(out)
        %tic;
        %xt = num2str(round(out(i,1)));
        %yt = num2str(round(out(i,2)));
        %instance.SetTarget(xt,yt,stiff,stiff,'0','0',damp,damp,'0','0','1','0'); 
        %pause(toc)
        %pause(1/sample_freq);
    %end

    output = out; % return

end