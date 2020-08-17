
function k_mat = channel ( theta, kmax )

% This code produce stiffness for the virtual channel in H-man. 
%       Inputs: channel angle w.r.t X-axis (in degrees), and max. stiffness.
%       Output: stiffness matrix to be used in the H-man command.

%theta = 120;
if  ~exist('kmax','var')
    kmax  = 900;
end

rot_mat = [ cosd(theta) -sind(theta); sind(theta) cosd(theta) ];
stiff   = [ 1 0; 0 kmax ];   % see tha paper for elliptical field.
k_mat   = rot_mat * stiff * rot_mat';

