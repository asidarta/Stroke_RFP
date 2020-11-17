
%https://www.mathworks.com/matlabcentral/answers/16663-is-it-possible-to-viewing-the-figure-window-on-second-display

function [FigHandle, sizeMP] = figure2(varargin)
% This function displays the plot on the 2nd monitor if available. If
% not it will display on the 1st monitor.
% [EDITED, 2018-06-05, typos fixed]

MP = get(0, 'MonitorPositions');
sizeMP = size(MP,1);    % How many monitors connected??

if sizeMP == 1  % If single monitor
   FigH = figure();%varargin{:});
   
else  % Multiple monitors
   % Catch creation of figure with disabled visibility: 
   indexVisible = find(strncmpi(varargin(1:2:end), 'Vis', 3));
   if ~isempty(indexVisible)
     paramVisible = varargin(indexVisible(end) + 1);
   else
     paramVisible = get(0, 'DefaultFigureVisible');
   end
   %
   Shift    = MP(2, 1:2);
   FigH     = figure(varargin{:}, 'Visible', 'off');
   drawnow;
   set(FigH, 'Units', 'pixels');
   pos      = get(FigH, 'Position');
   pause(0.1);  % See Stefan Glasauer's comment
   set(FigH, 'Position', [pos(1:2) + Shift, pos(3:4)], ...
            'Visible', paramVisible);
end

if nargout ~= 0
   FigHandle = FigH;

end