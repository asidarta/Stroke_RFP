
function [flag, k_matY, b_matY] = channel ( theta, pos, instance, ch_size )

% This code produce stiffness for the virtual channel in H-man. 
%     Inputs: channel angle w.r.t X-axis (degree), current position & channel size (mm).
%     Output: force status (ON/OFF), stiffness and damping matrix.

%theta = 120;
%if  ~exist('kmax','var')
%    kmax = 1500;
%end
if ~exist('ch_size', 'var')
    ch_size = 8;
end


% Create stiffness and damping matrices....
stiff   = [400 0;0 1];      % predefined stiffness value (N/m)
damp    = [30  0;0 15];     % predefined viscous field (N.s/m)

% Define channel angle w.r.t X-axis, in degrees.
%theta = 90;
% Define rotation matrix w.r.t X-axis
rot_mat = [ cosd(theta) -sind(theta); sind(theta) cosd(theta) ];
% Define rotation matrix w.r.t Y-axis >>>
rot_matY = [ cosd(90-theta) -sind(90-theta); sind(90-theta) cosd(90-theta) ];
% Compute stiffness and damping matrix w.r.t Y-axis >>>
k_matY   = rot_matY * stiff * rot_matY';
b_matY   = rot_matY * damp  * rot_matY';


% Rotate incoming X,Y positions
posX = pos(1);  posY = pos(2);
posRot = rot_matY * [posX; posY];

if ( abs(posRot(1)) > ch_size/1000 )  % note unit change!
    flag = true;
    instance.SetTarget( num2str(sign(posRot(1))*ch_size), ...
                        num2str(posRot(2)), ...
                        num2str(k_matY(1,1)), num2str(k_matY(2,2)), ...
                        num2str(-k_matY(1,2)), num2str(-k_matY(2,1)), ...
                        num2str(b_matY(1,1)), num2str(b_matY(2,2)), ...
                        num2str(-b_matY(1,2)), num2str(-b_matY(2,1)),'1','0' );                     
else
    flag = false;
    instance.SetTarget( '0','0','0','0','0','0','0','0','0','0','1','0' ); 
end
