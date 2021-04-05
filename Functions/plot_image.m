
function myOutput = plot_image(imgNum, ind, xpos, ypos, imgSize)
% Input  = image centre position (x,y), image number, image size, and index.
%          image number is randomized number so that each block will have different 
%          background/monster/music (range: 0 to 4)
% Output = handler to the image 

imgSize = imgSize/1000;     % adjusting the unit (mm -> metre)
global myPath;
%myPath = 'C:\Users\rris\Documents\MATLAB\Stroke_RFP\Images\';  % working directory!
localpath = strcat(myPath, '\Images\', num2str(imgNum), '\');

switch( ind )   % image index
    case 1 
        myImage = 'image1.png'; % Use the common name for all theme, regardless of what theme you selected, e.g. image1, or target1
    case 2 
        myImage = 'image2.png'; %then this will be image2, or target2
    case 3 
        myImage = 'image3.png';
    case 4
        myImage = 'image4.png';
    case 5 
        myImage = 'monster5.png';
    case 9 
        myImage = 'hand.png'; 
    case 10
        myImage = 'move.png';
    case 11
        myImage = 'relax.png';
    case 12
        myImage = 'emoji.png';
    case 21 
        myImage = 'food1.png';
    case 22 
        myImage = 'food2.png';
    case 23 
        myImage = 'food3.png';
    case 24 
        myImage = 'food4.png';  
    otherwise
end

% Load the image file first......
[img, map, alphachannel] = imread( strcat(localpath,myImage) );
%image(img, 'AlphaData', alphachannel);


% Then plot the image on the current figure. Remember to flip!
myOutput = image(flipud(img), 'XData', [xpos-imgSize xpos+imgSize], ...
                              'YData', [ypos-imgSize ypos+imgSize], ...
                              'AlphaData', flipud(alphachannel));
                          