function textout = play_KR( reward )

% This function will randomly select one of the few possible options for
% positive feedback, intermittent method 50% of the time. 
% Here, KR = knowledge of results. The options are:
%     1: "Good job",   2: "Well done",   3: "Excellent"    4-6: NONE

global myPath; %= 'C:\Users\ananda.sidarta\Documents\MATLAB\';
number = randi([1,6],1,1);  % This handles the different possible encouragement

if (reward)
    % For any successful movements, we give this coin sound.
    [wav_coin, Fs] = audioread( strcat(myPath,'\Audio\coin2.mp3') );
    sound(wav_coin, Fs);
    
    % Then, intermittently we play some other positive encouragement.
    switch (number)
    case 1
        [wav_out, Fs] = audioread( strcat(myPath,'\Audio\good_job.mp3') );
        %fprintf('Feedback: Good job!\n');
        %textout = '     Good job!';
    case 2
        [wav_out, Fs] = audioread( strcat(myPath,'\Audio\well_done.mp3') );
        %fprintf('Feedback: Well done!\n');
        %textout = '     Well done!';
    case 3
        [wav_out, Fs] = audioread( strcat(myPath,'\Audio\nice_move.mp3') );
        %fprintf('Feedback: Excellent!\n');
        %textout = '     Excellent!';
    otherwise
        fprintf('Feedback: N/A (intermittent)\n');   wav_out = [];
        %textout = '';
    end
% If unsuccessful, we still provide encouragement to keep trying.
else
    fprintf('Give encouragement....\n');
    switch (number)
    case 1
        [wav_out, Fs] = audioread( strcat(myPath,'\Audio\dont_giveup.mp3') );
    case 2
        [wav_out, Fs] = audioread( strcat(myPath,'\Audio\check_move.mp3') );
    %case 3
    %    [wav_out, Fs] = audioread( strcat(myPath,'\Audio\keep_try.mp3') );
    otherwise
        wav_out = []; Fs = 1000;  % dummy
    end
end

sound(wav_out, Fs);  % Play the audio clip!

textout = '';
%pause_me(1.0);