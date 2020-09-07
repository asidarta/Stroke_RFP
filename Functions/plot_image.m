
function myOutput = plot_Image(ind, xpos, ypos, imgSize)
% Input  = image centre position (x,y), image size, and index.
% Output = handler to the image 


imgSize = imgSize/1000;     % adjusting the unit (mm -> metre)!

myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\Images\';

switch( ind )   % image index
    case 1 
        myImage = 'monster1.png';
    case 2 
        myImage = 'monster2.png';
    case 3 
        myImage = 'monster3.png';
    case 4
        myImage = 'monster4.png';
    case 5 
        myImage = 'monster5.png';
    case 10
        myImage = 'move.png';
    case 11
        myImage = 'relax.png';
    otherwise
end

% Load the image file first......
[img, map, alphachannel] = imread( strcat(myPath,myImage) );
%image(img, 'AlphaData', alphachannel);


% Then plot the image on the current figure. Remember to flip!
myOutput = image(flipud(img), 'XData', [xpos-imgSize xpos+imgSize], ...
                              'YData', [ypos-imgSize ypos+imgSize], ...
                              'AlphaData', flipud(alphachannel));
