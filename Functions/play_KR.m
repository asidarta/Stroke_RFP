
function textout = play_KR( myPath )

% This function will randomly select one of the few possible options for
% positive feedback, intermittent method 50% of the time. 
% Here, KR = knowledge of results. The options are:
%     1: "Good job",   2: "Well done",   3: "Excellent"    4-6: NONE


[wav_coin, Fs] = audioread( strcat(myPath,'\Audio\coin2.mp3') );
sound(wav_coin, Fs)

number = randi([1,6],1,1);

switch (number)    % Load the audio file. Then play the sound now...
    case 1
        [wav_out, Fs] = audioread( strcat(myPath,'\Audio\good_job.mp3') );
        sound(wav_out, Fs)
        fprintf('Feedback: Good job!\n');
        %textout = '     Good job!';
    case 2
        [wav_out, Fs] = audioread( strcat(myPath,'\Audio\well_done.mp3') );
        sound(wav_out, Fs)
        fprintf('Feedback: Well done!\n');
        %textout = '     Well done!';
    case 3
        [wav_out, Fs] = audioread( strcat(myPath,'\Audio\nice_move.mp3') );
        sound(wav_out, Fs)
        fprintf('Feedback: Excellent!\n');
        %textout = '     Excellent!';
    otherwise
        fprintf('Feedback: N/A (intermittent)\n');
        %textout = '';
end

textout = '';
%pause_me(2.0);

        
        
        