function b = myfun(src,event)
    % Return the key on the keyboard
    disp(event.Key);
    b = event.Key;
end