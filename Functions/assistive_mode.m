function assistive_mode( instance, post_X, post_Y )
% This assistive mode is meant to assist patients who are too weak

for k = 20:2:80
    instance.SetTarget(num2str(post_X),num2str(post_Y),...
                       num2str(k),num2str(k),'0','0','0','0','0','0','1','0');     
    pause(0.01)
end

fprintf("     Assistive mode ON!\n");