%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    This code was originally written by researchers @ Motor Control Lab (McGill, 2012-2014)   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The estimation of kinematic params is purely done based on the position data and sampling rate!
% In this program we calculate some kinematic characteristics, signed area, Perpendicular Deviation, Path Length, and Initial Angular Deviation

%function [  t_meanpd_endpoint, t_area_endpoint, t_pd_endpoint, t_pdmaxv_endpoint, t_pd100_endpoint, ...
%            t_pd200_endpoint, t_pd300_endpoint, t_pdend_endpoint, t_iadmaxv_endpoint, t_iad100_endpoint, ...
%            t_meanpd_target, t_area_target, t_pd_target, t_pdmaxv_target, t_pd100_target, ...
%            t_pd200_target, t_pd300_target, t_pdend_target, t_iadmaxv_target, t_iad100_target, ...
%            stpx, stpy, PeakVel ]   = get_Kinematic ( pos, targetCtr, Fs_kin )


function [  t_meanpd_target,t_area_target,t_pd_target,t_pdmaxv_target,...
            t_pd200_target,stpx, stpy, PeakVel ]   = get_Kinematic ( pos, targetCtr, Fs_kin )

% Target distance (in metre). It is 15 cm ahead of the starting position.
target_dist = 0.15;

% First, we just want a subset of data while reaching forward only; Flag = 1 !!!!!
flag = 1;

if ~isempty(pos)  % If the position data is sufficient for estimating kinematic params, do that....
    pos1  = pos(pos(:,2)==flag, 5:6);
else
    pos1  = NaN;
end

if ~isnan(pos1)
    
    pos  = pos(pos(:,2)==flag, 5:6);
    L = size(pos,1);
    strx = pos(1,1); %movement start_point
    stry = pos(1,2); %movement start_point
    stpx = pos(L,1); %movement stop_point
    stpy = pos(L,2); %movement stop_point

    % Target position?
    %stop_point to compute deviation relative to target (and not relative to the endpoint of the movement)
    stpx_target = targetCtr(1);
    %stop_point to compute deviation relative to target(and not relative to the endpoint of the movement)
    stpy_target = targetCtr(2);

    area_endpoint(1) = 0;
    pd_endpoint(1) = 0;
    dd_endpoint(1) = 0;

    area_target(1) = 0;
    pd_target(1) = 0;
    dd_target(1) = 0;

    for i=2:L
        datax = pos(i,1);  % Each point of data
        datay = pos(i,2);  % Each point of data
        datax1 = pos(i-1,1);  % Previous point of data
        datay1 = pos(i-1,2);  % Previous point of data
        vector1 = [datax - strx, datay - stry,0]./sqrt(sum([datax - strx, datay - stry].^2));
        vector2_endpoint = [stpx - strx, stpy - stry,0]./sqrt(sum([stpx - strx, stpy - stry].^2));
        vector2_target = [stpx_target - strx, stpy_target - stry,0] ./ sqrt(sum([stpx_target - strx, stpy_target - stry].^2));
    
        theta_endpoint = abs(acos(dot(vector1,vector2_endpoint)));
        theta_target = abs(acos(dot(vector1,vector2_target)));

        if sum(cross(vector1,vector2_endpoint))<0
            theta_endpoint = -theta_endpoint;
        end
    
        if sum(cross(vector1,vector2_target))<0
            theta_target = -theta_target;
        end    
    
        iad_endpoint(i) = theta_endpoint*180/pi; % Initial angular deviation
        lng(i) = sqrt(sum([datax-datax1,datay-datay1].^2)); % distance between two points
        pd_endpoint(i) = sin(theta_endpoint) * sqrt(sum([datax-strx,datay-stry].^2)); % Perpendicular distance
        dd_endpoint(i) = cos(theta_endpoint) * sqrt(sum([datax-strx,datay-stry].^2)); % directional distance
        area_endpoint(i) =(pd_endpoint(i)+pd_endpoint(i-1))*(dd_endpoint(i)-dd_endpoint(i-1))/2;
    
        iad_target(i) = theta_target*180/pi; % Initial angular deviation    
        pd_target(i) = sin(theta_target) * sqrt(sum([datax-strx,datay-stry].^2)); % Perpendicular distance   
        dd_target(i) = cos(theta_target) * sqrt(sum([datax-strx,datay-stry].^2)); % directional distance
        area_target(i) =(pd_target(i)+pd_target(i-1))*(dd_target(i)-dd_target(i-1))/2;

    end


    [dum vel_kin] = gradient(pos,1/Fs_kin);
    vel_resultant = sqrt(vel_kin(:,1) .^2+vel_kin(:,2) .^2);
    [PeakVel PeakVel_loc] =  max(vel_resultant);
    PeakVel_loc;
    plot(sqrt(vel_kin(:,1) .^2+vel_kin(:,2) .^2));

    % If the InMotion robot sampling rate = 400 Hz, then 40th sample = 1/400*20*1000 = 50msec
    % Or, 50 msec can be found at data point of = 50/1000*400 = 20th....

    % With respect to the robot endpoint position........................
    t_area_endpoint = sum(area_endpoint);
    t_pdmaxv_endpoint = pd_endpoint(PeakVel_loc);
    t_pd100_endpoint = pd_endpoint(20);
    t_pd200_endpoint = pd_endpoint(40);
    t_pd300_endpoint = pd_endpoint(60);
    t_pdend_endpoint = pd_endpoint(end);

    [maximum_endpoint dummy_endpoint] = max(abs(pd_endpoint));
    t_pd_endpoint = pd_endpoint(dummy_endpoint);
    t_lng_endpoint = sum(lng);
    t_iadmaxv_endpoint = iad_endpoint(PeakVel_loc); % The initial diviation, at the maximum tangantial velociy
    t_iad100_endpoint = iad_endpoint(40); % The initial diviation, 200ms into the movement
    t_meanpd_endpoint = mean(pd_endpoint);

    % With respect to the target centre...............................
    t_area_target   = sum(area_target);
    t_pdmaxv_target = pd_target(PeakVel_loc);
    t_pd100_target  = pd_target(20);
    t_pd200_target  = pd_target(40);
    t_pd300_target  = pd_target(60);
    t_pdend_target  = pd_target(end);

    [maximum_target dummy_target] = max(abs(pd_target));
    t_pd_target = pd_target(dummy_target);
    t_iadmaxv_target = iad_target(PeakVel_loc); % The initial diviation, at the maximum tangential velociy
    t_iad100_target = iad_target(40); % The initial diviation, 200ms into the movement
    t_meanpd_target = mean(pd_target);

else
    fprintf('   Position data is not sufficient!\n');
    t_meanpd_target = NaN;
    t_area_target   = NaN;
    t_pd_target     = NaN;
    t_pdmaxv_target = NaN;
    t_pd200_target  = NaN;
    stpx            = NaN;
    stpy            = NaN;
    PeakVel         = NaN;
end