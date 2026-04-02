
% function PVT_START
%
%% Simple Psychomotor Vigilance Task %%
%
% Dr Tom Faherty, 4th May 2023
% t.b.s.faherty@bham.ac.uk
%
% Participant task is to respond with a spacebar press when the red dot
% appears. Some dots appear in quick succession (400 - 1800 ms), others are
% seperated by a long break (25 - 35 s)
%
%% SET UP SOME VARIABLES %%

clearvars -except indx window subjectInitials visitNumber sessionNumber practice_carry path_folder;

if exist('indx', 'var') == 0 || indx == 4 % If we are starting with this task
    close all
else
end
clc;

%%% REMOVE BEFORE RUNNING THE EXPERIMENT ON WINDOWS PC %%%
% if ismac == 1
% Screen('Preference', 'SkipSyncTests', 1); % Skip sync tests
% else
% end
%%% REMOVE BEFORE RUNNING THE EXPERIMENT ON WINDOWS PC %%%

rng('default');
rng('shuffle'); % Randomise Random Number Generator

CurrentFolder = pwd;
DriveFolder = pwd; % For debugging; change as necessary

ResultsFolder = pwd; % For debugging; change as necessary
ImageFolder = fullfile(CurrentFolder,'Stimuli');
MainResults = pwd; % For debugging; change as necessary
PracticeResults = pwd; % For debugging; change as necessary
LocalResults = pwd; % For debugging; change as necessary
UploadFolder = pwd; % For debugging; change as necessary

%%%%%%%%%%%%%%%%%%%%

prompt={'Participant ID [HIP00]', 'Visit Number [0 - 5]', 'Session Number [1 (Pre) / 2 (Post)]', 'Practice? [Y / N]'};

t = clock;

if exist('subjectInitials', 'var') == 1 % If carry over from previous task
    defaults{1} = subjectInitials;
else
    defaults{1} = 'HIP';
end
if exist('visitNumber', 'var') == 1 % If carry over from previous task
    defaults{2} = visitNumber;
else
    defaults{2} = '5';
end
if exist('sessionNumber', 'var') == 1 % If carry over from previous task
    defaults{3} = sessionNumber;
else
    if t(4) > 11
        defaults{3} = '2';
    else
        defaults{3} = '1';
    end
end
if exist('practice_carry', 'var') == 1 % If carry over from previous task
    defaults{4} = practice_carry;
else
    if t(4) > 11
        defaults{4} = 'N';
    else
        defaults{4} = 'Y';
    end
end

if exist('indx', 'var') == 0 || indx == 4 % If we are starting with this task

    ANSWER = inputdlg(prompt, 'Psychomotor Vigilance Task', [1, 75], defaults);
    if isempty(ANSWER)
        % User clicked cancel. Bail out! Bail out!
        close all;
        clearvars -except subjectInitials visitNumber sessionNumber practice_carry path_folder;
        error('User Clicked Cancel')
    elseif upper(ANSWER{1}(1:3)) ~= "HIP" || length(ANSWER{1}) ~= 5
        close all;
        clearvars -except visitNumber sessionNumber practice_carry path_folder;
        error('Must start with "HIP" and include two characters afterwards')
    elseif upper(ANSWER{4}) ~= 'Y' && upper(ANSWER{4}) ~= 'N'
        close all;
        clearvars -except subjectInitials visitNumber sessionNumber path_folder;
        error('Must choose Y or N for practice')
    end

else
    ANSWER = defaults;
end

subjectInitials = (ANSWER{1});
visitNumber = (ANSWER{2});
if str2double(visitNumber) == 0
    screeningVisit = 1;
else
    screeningVisit = 0;
end
sessionNumber = (ANSWER{3});
practice = (ANSWER{4}); % Save practice

if practice == 'Y'
    practice = 1;
    practice_carry = 'Y';
else
    practice = 0;
    practice_carry = 'N';
end

%% Keyboard Setup %%

KbName('UnifyKeyNames');
KbCheckList = [KbName('space'), KbName('t'), KbName('g')];

%% SET SOME VARIABLES %%

numTrialsPrac = 5;
if screeningVisit == 1 % If screening, only complete 20 trials
    numTrialsMain = 20;
else
    numTrialsMain = 85;
end
showInstructions = 1;
fixMinQuick = 400;
fixMaxQuick = 1800;
fixMinSlow = 25000; % 25 s
fixMaxSlow = 35000; % 35 s

todays_date = string(datetime('now'),'dd/MM/yy');

% Set up

WhichScreen = max(Screen('Screens'));
black = BlackIndex(WhichScreen); % Black is 0
white = WhiteIndex(WhichScreen); % White is 255
BackgroundColour = black; % Background is set to black

TextSize = 60;
TextFont = 'Arial';
TextNormal = [255 255 255]; % normal (white) text colour
TextRed = [255 60 0]; % warning text colour

WaitSecs(0.5); % This helps the PsychToolbox sync

windowTry = 0;
windowErr = 0;

if exist('indx', 'var') == 0 || indx == 4 % If we are starting with this task

    while windowTry == windowErr && windowTry < 10
        try
            % PsychImaging('PrepareConfiguration'); % To work on Mac
            % PsychImaging('AddTask','General','UseRetinaResolution') % Use biggest resolution of mac
            window = PsychImaging('OpenWindow', WhichScreen, BackgroundColour, []);  % Open up a screen
            % testRect = [500, 500, 1000, 800]; % for troubleshooting
            % window = PsychImaging('OpenWindow',WhichScreen, 0, testRect);
        catch
            windowErr = windowErr + 1;
        end
        windowTry = windowTry + 1;
    end

else
end

Screen('FillRect', window, BackgroundColour); % Create screen background
Screen('Flip', window);
Priority(MaxPriority(window));
[ScreenXPixels, ScreenYPixels] = Screen('WindowSize', window);
Screen('TextSize', window, 150);

% Set up screen timings

ifi = Screen('GetFlipInterval',window); % How long is a frame in ms
ScreenRefreshRate = 1/ifi; % Calculate refresh rate

% Stimulus timings in s

TargetTime = 0.4; % Time that stim is shown
OverTime = 0.4; % Add 400 ms to catch late responses
FeedbackTime = 0.4; % Time that feedback is shown

% Stimulus timings in frames (for best timings)

NumFramesFeedback = round(FeedbackTime / ifi);

% Randomise short fixation times

FixationTimeShortMill = randi([fixMinQuick,fixMaxQuick], 75 ,1); % Creates fixation time in ms (500, 2000)
FixationTimeShort = FixationTimeShortMill/1000; % Changes fixation time to s

% Randomise long fixation times

FixationTimeLongMill = randi([fixMinSlow,fixMaxSlow],10 ,1); % Creates fixation time in ms (500, 2000)
FixationTimeLong = FixationTimeLongMill/1000; % Changes fixation time to s

try %try, catch end

    RestrictKeysForKbCheck(KbCheckList);
    ListenChar(2); % Avoid key presses affecting code
    HideCursor; % Remove cursor from screen

    % Load image stimuli

    cd(ImageFolder); % The location where image files are
    all_images = dir('*.png'); % Load all images

    % Set up log file

    RespMat{1,1} = 'Participant ID';
    RespMat{1,2} = 'Visit Number';
    RespMat{1,3} = 'Session Number';
    RespMat{1,4} = 'Date'; % Todays Date
    RespMat{1,5} = 'Laptop name';
    RespMat{2,5} = getenv('COMPUTERNAME');
    RespMat{1,6} = 'Time'; % Time of each trial
    RespMat{1,7} = 'ifi'; % Time of each trial
    RespMat{1,8} = 'Trial number';
    RespMat{1,9} = 'Number of frames fixation';
    RespMat{1,10} = 'Fixation time';
    RespMat{1,11} = 'Trial type';
    RespMat{1,12} = 'Response?'; % 0 = Miss; 1 = Hit
    RespMat{1,13} = 'Start time';
    RespMat{1,14} = 'End time';
    RespMat{1,15} = 'Raw RT'; % End time minus start time
    RespMat{1,16} = 'Repeat?'; % Record any warnings or pauses

    % Open offscreen windows for drawing prior to presentation

    FixationScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
    TargetScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
    FeedbackScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);

    % Set up parameters for offscreen windows

    Screen('TextFont', FixationScreen, TextFont);
    Screen('TextColor', FixationScreen, TextNormal);
    Screen('TextSize', FixationScreen, TextSize);
    Screen('TextFont', TargetScreen, TextFont);
    Screen('TextColor', TargetScreen, TextNormal);
    Screen('TextSize', TargetScreen, TextSize);

    % Load the image files into the workspace

    isRed = regexp({all_images.name}, regexptranslate('wildcard', 'Red*')); % Where is red dot
    redIndex = find(not(cellfun('isempty',isRed)));

    target_dot = all_images(redIndex).name; % Load image
    big_dot = imread(target_dot);
    resized_dot = imresize(big_dot, 0.075);
    TargetPicture = Screen('MakeTexture',window,resized_dot);
    Screen('DrawTexture', TargetScreen, TargetPicture, [], []);

    isCorrect = regexp({all_images.name}, regexptranslate('wildcard', 'Correct*')); % Where is green dot
    correctIndex = find(not(cellfun('isempty',isCorrect)));

    feedback_dot = all_images(correctIndex).name; % Load image
    big_dot2 = imread(feedback_dot);
    resized_dot2 = imresize(big_dot2, 0.075);
    FeedbackPicture = Screen('MakeTexture',window,resized_dot2);
    Screen('DrawTexture', FeedbackScreen, FeedbackPicture, [], []);

    isFix = regexp({all_images.name}, regexptranslate('wildcard', 'Fixation*')); % Where is fixation cross
    fixIndex = find(not(cellfun('isempty',isFix)));

    fixation_image = all_images(fixIndex).name; % Load image
    fix_cross = imread(fixation_image);
    resized_fix = imresize(fix_cross, 0.115);
    FixationPicture = Screen('MakeTexture',window,resized_fix);
    Screen('DrawTexture', FixationScreen, FixationPicture, [], []);

    %% Start of experimental loop %%

    while practice > -1

        check_accuracy = 0; % Reset accuracy check
        trial = 1; % Reset trial counter
        codeWarning = 0; % Reset warning
        codePaused = 0; % Rest pause
        codeTerminated = 0; % Reset termination

        if practice == 1
            numTrials = numTrialsPrac;
            FixationTime = [10, 2, 0.5, 1, 2];
        elseif practice == 0
            fixationCount = 1;
            ShortFixationCell = {};
            numTrials = numTrialsMain;
            shortStim = 3:12;

            for longStim = 1:10
                ShortFixationCell{longStim} = FixationTimeShort(fixationCount:(fixationCount+shortStim(longStim)-1));
                fixationCount = (fixationCount + shortStim(longStim)-1);
            end

            ShortFixationCellShuffled = ShortFixationCell(randperm(numel(ShortFixationCell)));

            % Now we need to make our final array

            trialCount = 1;
            for longStim = 1:10
                FixationTime(trialCount) = FixationTimeLong(longStim);
                FixationTime(trialCount+1:trialCount+length(ShortFixationCellShuffled{longStim})) = ShortFixationCellShuffled{longStim};
                trialCount = trialCount + 1 + length(ShortFixationCellShuffled{longStim});
            end
        end

        while trial < numTrials + 1 % Extra while loop for pauses etc

            while trial < numTrials + 1 && codeTerminated == 0 && codePaused == 0 && codeWarning == 0

                NumFramesFixation = round(FixationTime(trial) / ifi);

                if trial == 1 && showInstructions == 1 % If first trial, show start screen

                    KbReleaseWait;

                    Screen('TextSize', window, TextSize);
                    Screen('TextColor', window, TextNormal);

                    DrawFormattedText(window, 'Please press the spacebar to see the task instructions', 'center', 'center', white)
                    Screen('Flip', window);

                    % Wait for participant to press spacebar

                    while 1
                        [~,~,keyCode] = KbCheck;
                        if keyCode(KbName('space')) == 1
                            break
                        elseif keyCode(KbName('t')) == 1
                            codeTerminated = 1;
                            break
                        end
                    end

                    if codeTerminated == 1
                        break
                    end

                    KbReleaseWait;

                    Screen('TextSize', window, TextSize);
                    Screen('TextColor', window, TextNormal);

                    if practice == 0
                        DrawFormattedText(window, 'Read the following instructions carefully \n \n Press the spacebar as quickly as possible when the red dot appears \n \n The dot will turn white if you are fast enough \n \n Try to be as quick as possible and respond to every red dot \n \n Press the spacebar to begin the task', 'center', 'center', white)
                    else
                        DrawFormattedText(window, 'Read the following instructions carefully \n \n Press the spacebar as quickly as possible when the red dot appears \n \n The dot will turn white if you are fast enough \n \n Try to be as quick as possible and respond to every red dot \n \n Press the spacebar to begin a short practice', 'center', 'center', white)
                    end
                    Screen('Flip', window);

                    % Wait for participant to press spacebar

                    while 1
                        [~,~,keyCode] = KbCheck;
                        if keyCode(KbName('space')) == 1
                            break
                        elseif keyCode(KbName('t')) == 1
                            codeTerminated = 1;
                            break
                        end
                    end
                    showInstructions = 0; % Don't show instructions next time (if appropriate)
                else
                    % Do nothing if not trial 1
                end

                if codeTerminated == 1
                    break
                end

                if trial == 1 || prevPause == 1 || prevWarning == 1 % If this is the first trial... or the previous trial was paused... or a warning
                    Countdown = 5;
                    Screen('Flip',window);
                    for i = 1:Countdown % Countdown
                        DrawFormattedText(window,sprintf('%d',Countdown),'center','center', white);
                        Screen('Flip',window);
                        WaitSecs(1);
                        Countdown = Countdown - 1;
                    end
                    prevPause = 0; % Turn previous pause off
                    prevWarning = 0; % Turn warning off
                else
                    % Do nothing, let the task roll on!
                end

                % Copy windows at the right time (for best timing)

                Screen('Flip', window); % Flip to nothing
                Screen('CopyWindow', FixationScreen, window);
                % Screen('Flip', window);
                % WaitSecs(.01);
                time = Screen('Flip', window);
                for a = 1:NumFramesFixation
                    Screen('CopyWindow', FixationScreen, window);
                    time = Screen('Flip', window, time + .5 *ifi);

                    [~,~,keyCode] = KbCheck;
                    if keyCode(KbName('t')) == 1
                        codeTerminated = 1;
                        break
                    elseif keyCode(KbName('g')) == 1
                        codePaused = 1; % Turn pause on
                        break % Break the current (screen flipping) loop
                    end
                end

                if codeTerminated == 1 || codePaused == 1
                    break
                end

                % If participant is trying to cheat (Keep key pushed down through
                % fixation for an easy win), give them a warning!

                KbCheck;
                if KbCheck == 1
                    codeWarning = 1;
                    break
                end

                keyIsDown = 0;
                ResponseTimeOnset = GetSecs;
                Resp1 = '.';
                Screen('CopyWindow', TargetScreen, window);
                Screen('Flip', window);
                while keyIsDown == 0 && GetSecs - ResponseTimeOnset < (TargetTime)
                    if ~ismember(upper(Resp1(1)),KbCheckList)
                        [keyIsDown, TimeT1Response, keyCode] = KbCheck; % Waiting for key press
                        if keyIsDown
                            kb = KbName(find(keyCode)); % Label key pressed
                            Resp1 = kb(1); % Recode as uppercase
                            if Resp1 == 't'
                                codeTerminated = 1;
                                break
                            elseif Resp1 == 'g'
                                codePaused = 1;
                                break
                            end
                        end
                    end
                end

                if codeTerminated == 1 || codePaused == 1
                    break
                end

                Response(trial) = Resp1(1);
                RespondTime = TimeT1Response;

                if Resp1 == '.' % If no response
                    Resp2 = '.';
                    Screen('CopyWindow', FixationScreen, window);
                    % Screen('Flip', window);
                    while keyIsDown == 0 && GetSecs - ResponseTimeOnset < (TargetTime + OverTime)
                        if ~ismember(upper(Resp2(1)),KbCheckList)
                            [keyIsDown, TimeT2Response, keyCode] = KbCheck; % Waiting for key press
                            if keyIsDown
                                kb = KbName(find(keyCode)); % Label key pressed
                                Resp2 = kb(1); % Recode as uppercase
                                if Resp2 == 't'
                                    codeTerminated = 1;
                                    break
                                elseif Resp2 == 'g'
                                    codePaused = 1;
                                    break
                                end
                            end
                        end
                    end
                    Response(trial) = Resp2(1);
                    RespondTime = TimeT2Response;
                end

                if codeTerminated == 1 || codePaused == 1
                    break
                end

                % Check if a response is given and present feedback if yes

                if Resp1 ~= '.'
                    check_accuracy = 1;
                    for d = 1:NumFramesFeedback % Should amount to 0.3s
                        Screen('CopyWindow', FeedbackScreen, window);
                        time = Screen('Flip', window,time + .5*ifi);
                    end
                else
                    check_accuracy = 0;
                end

                if round((NumFramesFixation*ifi)*1000) < 2500
                    trialType = 'Short';
                else
                    trialType = 'Long';
                end

                this_time = string(datetime('now'),'HH:mm:ss'); % Time start in correct format

                %%%%%%%%%%%%%%%%
                % SAVE RESULTS %
                %%%%%%%%%%%%%%%%

                RespMat{trial+1,1} = subjectInitials;
                RespMat{trial+1,2} = visitNumber;
                RespMat{trial+1,3} = sessionNumber;
                RespMat{trial+1,4} = char(todays_date);
                % Computer number
                RespMat{trial+1,6} = char(this_time);
                RespMat{trial+1,7} = ifi;
                RespMat{trial+1,8} = trial;
                RespMat{trial+1,9} = NumFramesFixation;
                RespMat{trial+1,10} = round((NumFramesFixation*ifi)*1000); % Time in ms
                RespMat{trial+1,11} = trialType;
                RespMat{trial+1,12} = check_accuracy; % 0 = Correct; 1 = Incorrect
                RespMat{trial+1,13} = ResponseTimeOnset;
                RespMat{trial+1,14} = RespondTime;
                RespMat{trial+1,15} = round((RespondTime - ResponseTimeOnset)*1000); % End time minus start time converted to ms

                if isempty(RespMat{trial+1,16})
                    RespMat{trial+1, 16} = 'n';
                else
                end

                trial = trial + 1; % Increase trial count

            end

            while codePaused == 1 % If pause is on, wait for confirmation of restart

                KbReleaseWait;
                Screen('TextSize', window, 60);
                DrawFormattedText(window, 'paused', 'center', 'center', white);
                Screen('Flip', window);

                [~,keyCode,~] = KbWait;
                if keyCode(KbName('g')) == 1
                    KbReleaseWait;
                    prevPause = 1; % Remember pause
                    RespMat{trial+1,16} = 'p'; % Record pause for original trial
                    codePaused = 0; % Restart code
                elseif keyCode(KbName('t')) == 1
                    codeTerminated = 1; % Turn Termination check on
                    codePaused = 0; % Restart code
                end
            end

            while codeWarning == 1
                Screen('TextSize', window, 60);
                DrawFormattedText(window, 'Keys must be released during the fixation cross \n \n This trial will now be repeated', 'center', 'center', TextRed);
                Screen('Flip', window);
                WaitSecs(5);
                prevWarning = 1;
                RespMat{trial+1, 16} = 'w'; % Record warning for original trial
                codeWarning = 0;
            end

            while codeTerminated == 1
                KbReleaseWait;

                Screen('TextSize', window, 60);
                DrawFormattedText(window, 'Are you sure you want to quit? \n \n \n Press ''g'' to resume the task or press ''t'' to terminate', 'center', 'center', white);
                Screen('Flip', window);

                [~,keyCode,~] = KbWait;
                if keyCode(KbName('g')) == 1
                    KbReleaseWait;
                    prevPause = 1; % Remember pause
                    RespMat{trial+1,16} = 'p'; % Record pause for original trial
                    codeTerminated = 0; % Restart code
                    break
                elseif keyCode(KbName('t')) == 1
                    cd(CurrentFolder);
                    Data = dataset(RespMat);
                    if practice == 1 % If practice
                        savename = sprintf('TERMINATE_PRACTICE-%s-%s-%s-%s-PVT.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
                    elseif practice == 0 % If main task
                        savename = sprintf('TERMINATE-%s-%s-%s-%s-PVT.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
                    end
                    cd(ResultsFolder); % The location where the file should be saved
                    export(Data, 'file', savename, 'Delimiter', ',');
                    cd(CurrentFolder);

                    clearvars -except subjectInitials visitNumber sessionNumber practice_carry path_folder;

                    ListenChar(0);
                    error('Terminate task by pressing "t" key; results saved')
                end
            end
        end
        KbReleaseWait;

        %% End %%

        % Save the data to a csv file

        Data = dataset(RespMat);

        if practice == 1 % If practice
            savename = sprintf('PRACTICE-%s-%s-%s-%s-PVT.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));

            cd(PracticeResults); % Cloud location where the file should be saved
            export(Data, 'file', savename, 'Delimiter', ',');
            cd(LocalResults); % Non-cloud location where the file should be saved
            export(Data, 'file', savename, 'Delimiter', ',');

        elseif practice == 0 % If main task
            savename = sprintf('%s-%s-%s-%s-PVT.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));

            cd(MainResults); % Cloud location where the file should be saved for storage
            export(Data, 'file', savename, 'Delimiter', ',');
            cd(UploadFolder); % Cloud location where the file should be saved for upload
            export(Data, 'file', savename, 'Delimiter', ',');
            cd(LocalResults); % Non-cloud location where the file should be saved
            export(Data, 'file', savename, 'Delimiter', ',');

        end

        cd(CurrentFolder);

        KbReleaseWait;
        Screen('TextSize', window, 60);
        Screen('Flip', window); % Added a flip to stop cross being shown with completion text

        if practice == 1
            DrawFormattedText(window, 'Practice finished! \n \n Ask the experimenter now if you have any questions \n \n There will still be feedback (white circle) in the main task \n \n When ready, please press the spacebar to start the main task', 'center', 'center', white)
            Screen('Flip', window);
        elseif practice == 0
            DrawFormattedText(window, 'Task complete! \n \n Please let the experimenter know', 'center', 'center', white);
            Screen('Flip', window);
        else
        end

        trial = 1; % Reset trial num just in case

        % Wait for spacebar press
        while 1
            [~,~,keyCode] = KbCheck;
            if keyCode(KbName('space'))== 1
                break
            end
        end

        practice = practice - 1; % Decrease practice count

    end

catch % Closes psyschtoolbox if there is an error and saves whatever data has been collected so far

    ShowCursor;
    ListenChar(0);
    Screen('CloseAll');

    if exist('RespMat', 'var') == 1

        RespMat{(height(RespMat)+1),1} = 'ERROR'; % Add a row

        Data = dataset(RespMat);
        savename = sprintf('ERROR-%s-%s-%s-%s-PVT.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
        cd(CurrentFolder); % The location where the file should be saved
        export(Data, 'file', savename, 'Delimiter', ',');
        cd(CurrentFolder);

    end

    psychrethrow(psychlasterror); % Tells you the error in the command window

    Priority(0);
    sca

end % End of try, catch,

ShowCursor;

ListenChar(0); % Allow key presses to affect code

if exist('path_folder', 'var') == 1
    cd(path_folder);
    clearvars -except path_folder;
else
    cd(CurrentFolder);
    clear all
end

sca; % Clear screen
close all;
clc;