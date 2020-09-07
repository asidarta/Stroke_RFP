
function null_force(inst)
% This will remove all force settings to the robot. The input is the
% robotic instance from the main code.

targ_X = 0;
targ_Y = 0;
target_gain = 0;

inst.SetTarget( num2str(targ_X), num2str(targ_Y), ...
                '0','0','0','0','0','0','0','0',...
                num2str(target_gain), '0' );
  
fprintf('Setting zero force\n');

end
