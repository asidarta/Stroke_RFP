%function myfun
%      close all;
%      h = figure;
%      set(h,'WindowKeyPressFcn',@KeyPressFcn);
%      function KeyPressFcn(~,evnt)
%          fprintf('key event is: %s\n',evnt.Key);
%          if(evnt.Key=="escape")
%              fprintf('--> You have pressed wrongly, dear!\n');
%          end
%      end
%end

