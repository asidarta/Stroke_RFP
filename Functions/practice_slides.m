
mypath = 'C:\Users\ananda.sidarta\Desktop\';
ctrl = input('Is this control group? (1:Yes, 0:No)\n');
xx   = input('Do you want to do some practice? (1:Yes, 0:No)\n');

if xx
    if(ctrl),system(strcat(mypath,'control.gif'));
    else, system(strcat(mypath,'treatment.gif')); end
end
