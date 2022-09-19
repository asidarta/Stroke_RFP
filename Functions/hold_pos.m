
function hold_pos(inst)
% This function will hold the robot handle in a position. The input is the
% robotic instance from the main code.

%targ_X = inst.current_x*1000; % Unit: mm -> m
%targ_Y = inst.current_y*1000; % Unit: mm -> m

% Updated for library V2.
targ_X = inst.hman_data.location_X*1000; % Unit: mm -> m
targ_Y = inst.hman_data.location_Y*1000; % Unit: mm -> m

% Define stiffness and damping values for hold_position.
k_xx = 3500;
k_yy = 3500;
k_xy = 50;
k_yx = 50;
b_xx = 0;
b_yy = 0;
b_yx = 0;
b_xy = 0;


inst.SetTarget( num2str(targ_X), num2str(targ_Y), ...
                num2str(k_xx), num2str(k_yy), ...
                num2str(k_xy), num2str(k_yx), ...
                num2str(b_xx), num2str(b_yy), ...
                num2str(b_xy), num2str(b_yx), '1', '0' );

fprintf('Setting hold position\n');

end