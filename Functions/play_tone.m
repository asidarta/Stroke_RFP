function play_tone(freq, duration)
% Generate a tone with a certain frequency and duration...
    amp = 10;     % amplitude
    fs  = 44100;  % sampling frequency
    values=0:1/fs:duration;
    a=amp*sin(2*pi* freq*values);
    sound(a);
