
function targetSize ( moveData )

% Estimate the target size
%    input : whole trajectory data during the block
%    output: the estimated size, in mm unit

% Target size is determined by the mean of 2 kinematic parameters, 
% that also defines if a movement is rewarded, whichevery is bigger!
%    *) Distance from target centre
%    *) Lateral deviation w.r.t target centre

if ~isempty(moveData)
    
    temp = mean(moveData,1);
    val1 = ceil(temp(2)*1000);  % Distance from target centre
    val2 = ceil(temp(5)*1000);  % Lateral deviation w.r.t target centre

    mysize = max(val1,val2);
    if (mysize < 10)
        mysize = 10;
    end
    
    fprintf('Note the number into the client file, %d\n', mysize);

end
