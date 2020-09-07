
function pause_me(duration)
% This is a pause function which can detect key-press to bail out

%tic;
elapsed  = 0;
duration = duration * 1000;   % in millisecond!

while elapsed < duration
    if (KbCheck)
        break; % Shall bail out if we press any key!
    end
    elapsed = elapsed + 1;
    pause(0.001);
    %fprintf('Hi\n');
end
