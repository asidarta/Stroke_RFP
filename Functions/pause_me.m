function pause_me(duration)

tic;
elapsed = 0;

while elapsed < duration
    if (KbCheck)
        break; % Shall bail out if we press any key!
    end
    elapsed = toc;
    %fprintf('Hi\n');
end
