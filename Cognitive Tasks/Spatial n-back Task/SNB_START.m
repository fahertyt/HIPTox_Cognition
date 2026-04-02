
% function SNB_START
%
%% Spatial n-back task using 3x3 grid %%
%
% Dr Tom Faherty, 4th May 2023
% t.b.s.faherty@bham.ac.uk
%
% Participants are presented with a sequence of image locations. Their task
% is to report if the location matches the location presented 'n' trials
% ago. 1 block of 1-back, then 2-back, and finally 3-back.
%
%% SET UP SOME VARIABLES %%

clearvars -except indx subjectInitials visitNumber sessionNumber userHand nback_start practice_carry path_folder;

if exist('indx', 'var') == 0 || indx == 1 % If we are starting with this task
    close all
else
end
clc;

%%% REMOVE BEFORE RUNNING THE EXPERIMENT ON WINDOWS PC %%
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

prompt={'Participant ID [HIP00]', 'Visit Number [0 - 5]', 'Session Number [1 (Pre) / 2 (Post)]', 'User Hand [L / R]', 'n-back [1 / 2 / 3]', 'Practice? [Y / N]'};

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
if exist('userHand', 'var') == 1 % If carry over from previous task
    defaults{4} = userHand;
else
    defaults{4} = 'R';
end
if exist('end_n', 'var') == 1 % If carry over from previous task
    defaults{5} = num2str(end_n);
else
    defaults{5} = '1';
end
if exist('practice_carry', 'var') == 1 % If carry over from previous task
    defaults{6} = practice_carry;
else
    if t(4) > 11
        defaults{6} = 'N';
    else
        defaults{6} = 'Y';
    end
end

if exist('indx', 'var') == 0 || indx == 1 % If we are starting with this task

    ANSWER = inputdlg(prompt, 'Spatial n-back Task', [1, 75], defaults);
    if isempty(ANSWER)
        % User clicked cancel. Bail out! Bail out!
        close all;
        clearvars -except subjectInitials visitNumber sessionNumber userHand nback_start practice_carry path_folder;
        error('User Clicked Cancel')
    elseif upper(ANSWER{1}(1:3)) ~= "HIP" || length(ANSWER{1}) ~= 5
        close all;
        clearvars -except visitNumber sessionNumber nback_start practice_carry path_folder;
        error('Must start with "HIP" and include two characters afterwards')
    elseif upper(ANSWER{4}) ~= 'L' && upper(ANSWER{4}) ~= 'R'
        close all;
        clearvars -except subjectInitials visitNumber sessionNumber nback_start practice_carry path_folder;
        error('Must choose L or R as user hand')
    elseif upper(ANSWER{5}) ~= '1' && upper(ANSWER{5}) ~= '2' && upper(ANSWER{5}) ~= '3'
        close all;
        clearvars -except subjectInitials visitNumber sessionNumber userHand practice_carry path_folder;
        error('Must choose 1, 2, or 3 as n-back value')
    elseif upper(ANSWER{6}) ~= 'Y' && upper(ANSWER{6}) ~= 'N'
        close all;
        clearvars -except indx subjectInitials visitNumber sessionNumber userHand nback_start path_folder;
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
userHand = (ANSWER{4});
nback_start = str2double(ANSWER{5});

if ANSWER{6} == 'Y'
    practice = 1;
    practice_start = 1;
    practice_carry = 'Y';
else
    practice = 0;
    practice_start = 0;
    practice_carry = 'N';
end

%% Keyboard Setup %%

KbName('UnifyKeyNames');
KbCheckList = [KbName('space'), KbName('t'), KbName('g')]; % Set keys which will be recognised
KbCheckResp = [KbName('t'), KbName('g'), KbName('z'), KbName('m')]; % Ensure space cannot be given as a response

%% SET SOME VARIABLES %%

check_accuracy = 0; % Reset accuracy check
block = 1; % Reset block counter
prevPause = 0;  % Reset previous pause

pracTrial = 1; % Reset trial counters
mainTrial = 1; % Reset trial counters

if nback_start == 1
    n = 1; % Reset 'n' value
elseif nback_start == 2
    n = 2; % Reset 'n' value
else
    n = 3; % Reset 'n' value
end
numBlocks = 4 - n;

trials_per_block = 45; % Number of trials per block
numMatches = 8; % Decide how many matches we want in each block

numTrialsPrac = 8;
numMatchesPrac = 2;

showInstructions = 1; % Reset to ensure first block shows instructions

todays_date = string(datetime('now'),'dd/MM/yy');

% Set up screen

WhichScreen = max(Screen('Screens'));
black = BlackIndex(WhichScreen); % Black is 0
white = WhiteIndex(WhichScreen); % White is 255
BackgroundColour = white/2; % Background is set to grey)

TextSize = 60;
TextFont = 'Arial';
TextNormal = [255 255 255]; % normal (white) text colour
TextRed = [255 60 0]; % missed response text colour

WaitSecs(0.5); % This helps the PsychToolbox sync

windowTry = 0;
windowErr = 0;

if exist('indx', 'var') == 0 || indx == 1 % If we are starting with this task

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
Screen('TextSize', window, 60);

% Set up stim size

sizeValue = 0.4;

% Set up screen timings

ifi = Screen('GetFlipInterval',window); % How long is a frame in ms
ScreenRefreshRate = 1/ifi; % Calculate refresh rate

% Stimulus timings in s

BlankTime = 0.6; % Time between stim
TargetTime = 1; % Time that stim is shown
ResponseTime = 21; % Waiting for response
FeedbackTime = 1; % 1 s

% Stimulus timings in frames (for best timings)

NumFramesBlank = round(BlankTime / ifi);
NumFramesTarget = round(TargetTime / ifi);
NumFramesFeedback = round(FeedbackTime / ifi);

% Set response keys

if userHand == 'R'
    sameKey = 'm';
    diffKey = 'z';
elseif userHand == 'L'
    sameKey = 'z';
    diffKey = 'm';
end

try %try, catch end

    RestrictKeysForKbCheck(KbCheckList);
    ListenChar(2); % Avoid key presses affecting code
    HideCursor;

    % Create image arrays

    cd(ImageFolder); % The location where image files are
    locationImages = [dir('Top*.jpg'); dir('Bottom*.jpg'); dir('Centre*.jpg')]; % Load all location images
    blank_image = dir('Blank.jpg'); % Load blank grid
    correct_image = dir('FeedbackCorrect.jpg'); % Load correct grid
    incorrect_image = dir('FeedbackIncorrect.jpg'); % Load incorrect grid
    slow_image = dir('FeedbackSlow.jpg'); % Load incorrect (slow) grid

    % Create all image orders

    if practice_start == 1 % If practice is turned on, create practice arrays

        for N = n:numBlocks+n-1 % Count 'n' upwards from chosen n-back value

            % Create location presentation order for number of blocks

            numLocations = 1:length(locationImages); % Create list of locations to choose from

            trialList = nan(numTrialsPrac,1); % Create block trial list

            z = 0; % Reset iteration count
            pracListCompleted = 0; % Reset the while loop

            while not(pracListCompleted)

                z = z + 1;

                for trialIteration = 1:numTrialsPrac

                    trialList(trialIteration) = randsample(numLocations,1); % Pick a random stimulus

                end

                % Note down location of matches

                trialList_shifted = [nan(N,1);trialList(1:numel(trialList)-N)];
                nback_check = [trialList trialList_shifted];
                matchLocations = find(diff(nback_check,1,2) == 0);

                % Check if conditions are met

                if numel(matchLocations) == numMatchesPrac % If we have the correct number of matches
                    pracListCompleted = 1; % Move on
                else
                    pracListCompleted = 0; % Start loop again
                end

                if z > 5000 % If too many iterations are attempted
                    error('Trial types could not be computed. Try again')
                end
            end

            % Populate design

            pracDesign(N-n+1).matchLocations = matchLocations;
            pracDesign(N-n+1).imageOrder = trialList;

        end

    end

    % Create location presentation order for main blocks

    for N = n:numBlocks+n-1 % Count 'n' upwards from chosen n-back value

        numLocations = 1:length(locationImages); % Create list of locations to choose from

        trialList = nan(trials_per_block,1); % Create block trial list

        i = 0; % Reset iteration count
        listCompleted = 0; % Reset the while loop

        while not(listCompleted)

            i = i + 1;

            for trialIteration = 1:trials_per_block

                trialList(trialIteration) = randsample(numLocations,1); % Pick a random stimulus

            end

            % Note down location of matches

            trialList_shifted = [nan(N,1);trialList(1:numel(trialList)-N)];
            nback_check = [trialList trialList_shifted];
            matchLocations = find(diff(nback_check,1,2) == 0);

            % Check if conditions are met

            if numel(matchLocations) == numMatches % If we have the correct number of matches
                if sum(diff(matchLocations) == 1 | diff(matchLocations) == 2) > 0 % Force gaps between matches
                    listCompleted = 0; % Try again matey
                else
                    listCompleted = 1; % Move on
                end
            else
                listCompleted = 0; % Start loop again
            end

            if i > 5000 % If too many iterations are attempted
                error('Trial types could not be computed. Try again')
            end
        end

        % Populate design

        mainDesign(N-n+1).matchLocations = matchLocations;
        mainDesign(N-n+1).imageOrder = trialList;

    end

    % Set up log file

    RespMat{1,1} = 'Participant ID';
    RespMat{1,2} = 'Visit number';
    RespMat{1,3} = 'Session number';
    RespMat{1,4} = 'User hand';
    RespMat{1,5} = 'Date'; % Todays Date
    RespMat{1,6} = 'Laptop name';
    RespMat{2,6} = getenv('COMPUTERNAME');
    RespMat{1,7} = 'Time'; % Time of each trial
    RespMat{1,8} = 'Trial number';
    RespMat{1,9} = 'Block number';
    RespMat{1,10} = 'Block trial number';
    RespMat{1,11} = 'n'; % Should be the same as block
    RespMat{1,12} = 'Trial type'; % 0 = Different; 1 = Same as 'n' back
    RespMat{1,13} = 'Stimulus x-coordinate'; % 1, 2, 3
    RespMat{1,14} = 'Stimulus y-coordinate'; % 1, 2, 3
    RespMat{1,15} = 'Filename'; % Image name
    RespMat{1,16} = 'Correct response'; % 0 = Different; 1 = Same
    RespMat{1,17} = 'Response'; % 0 = Different; 1 = Same
    RespMat{1,18} = 'Correct?'; % 0 = Correct; 1 = Incorrect
    RespMat{1,19} = 'Start time';
    RespMat{1,20} = 'End time';
    RespMat{1,21} = 'Raw RT'; % End time minus start time

    if practice_start == 1
        RespMatP = RespMat; % Create practice response matrix
    end
    RespMatM = RespMat; % Create main task response matrix

    %% Start of experimental loop %%

    codePaused = 0; % Reset pause
    codeTerminated = 0; % Reset termination clause
    blockTrial = 1;

    while block < (numBlocks*(practice_start+1))+1
        if block < 2 % If first block
            if showInstructions == 1 % If we haven't seen the start screen

                Screen('TextSize', window, 60);
                Screen('TextColor', window, white);

                StartText = sprintf('Please press the spacebar to see task instructions');
                StartTextBounds = Screen('TextBounds', window, StartText);
                Screen('DrawText',window,StartText, ScreenXPixels*.5-StartTextBounds(3)*.5, ScreenYPixels*.5-StartTextBounds(4)*.5), white;
                Screen('Flip', window);
                while 1
                    [~,~,keyCode] = KbCheck;
                    if keyCode(KbName('space')) == 1
                        break
                    elseif keyCode(KbName('t')) == 1
                        codeTerminated = 1;
                        break
                    end
                end
            end
        end

        if codeTerminated == 1
            break
        end

        KbReleaseWait;

        clearvars design % Reset design

        if n == 1
            thisBlock = 1;
        elseif n == 3
            thisBlock = numBlocks;
        elseif n == 2
            if numBlocks == 3
                thisBlock = 2;
            else
                thisBlock = 1;
            end
        end

        % Start block
        if practice == 1
            thisManyTrials = numTrialsPrac;
            design = pracDesign(thisBlock);
            trial = pracTrial; % Count total trials from last practice trial
        elseif practice == 0
            thisManyTrials = trials_per_block;
            design = mainDesign(thisBlock);
            trial = mainTrial; % Count total trials from last main trial
        end

        % Start block
        while blockTrial < (thisManyTrials + 1) && codeTerminated == 0 && codePaused == 0 % Present images

            if blockTrial == 1 % If first trial

                Screen('TextSize', window, 60);

                StartText = sprintf('Please read the following instructions');
                if n == 1
                    BlockNotesText2 = sprintf('Press the ''%s'' key if the current location is the same as presented just before', upper(sameKey));
                    BlockNotesText3 = sprintf('Otherwise, press the ''%s'' key if the current location is different', upper(diffKey));
                else
                    BlockNotesText2 = sprintf('Press the ''%s'' key if the current location is the same as %s positions back in the sequence', upper(sameKey), num2str(n));
                    BlockNotesText3 = sprintf('Otherwise, press the ''%s'' key if the current location is different to %s locations previously', upper(diffKey), num2str(n));
                end
                BlockNotesText4 = sprintf('Try and be as accurate as possible');
                if practice == 1
                    BlockNotesText5 = sprintf('Press the spacebar to begin a short practice');
                elseif practice == 0
                    BlockNotesText5 = sprintf('Press the spacebar to begin this ''block'' of 45 trials');
                end
                BlockNotesBounds1 = Screen('TextBounds', window, StartText);
                BlockNotesBounds2 = Screen('TextBounds', window, BlockNotesText2);
                BlockNotesBounds3 = Screen('TextBounds', window, BlockNotesText3);
                BlockNotesBounds4 = Screen('TextBounds', window, BlockNotesText4);
                BlockNotesBounds5 = Screen('TextBounds', window, BlockNotesText5);
                Screen('DrawText', window, StartText, ScreenXPixels*.5-BlockNotesBounds1(3)*.5, ScreenYPixels*.3-BlockNotesBounds1(4)*.5), white;
                Screen('DrawText', window, BlockNotesText2, ScreenXPixels*.5-BlockNotesBounds2(3)*.5, ScreenYPixels*.4-BlockNotesBounds2(4)*.5), white;
                Screen('DrawText', window, BlockNotesText3, ScreenXPixels*.5-BlockNotesBounds3(3)*.5, ScreenYPixels*.5-BlockNotesBounds3(4)*.5), white;
                Screen('DrawText', window, BlockNotesText4, ScreenXPixels*.5-BlockNotesBounds4(3)*.5, ScreenYPixels*.6-BlockNotesBounds4(4)*.5), white;
                Screen('DrawText', window, BlockNotesText5, ScreenXPixels*.5-BlockNotesBounds5(3)*.5, ScreenYPixels*.7-BlockNotesBounds5(4)*.5), white;
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
            end

            if codeTerminated == 1
                break
            end

            % Get time

            this_time = string(datetime('now'),'HH:mm:ss'); % Time start in correct format

            % Open offscreen windows for drawing prior to presentation

            BlankScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
            TargetScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
            ResponseScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
            FeedbackScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);

            % Set up parameters for offscreen windows

            Screen('TextFont', BlankScreen, TextFont);
            Screen('TextColor', BlankScreen, TextNormal);
            Screen('TextSize', BlankScreen, TextSize);
            Screen('TextFont', TargetScreen, TextFont);
            Screen('TextColor', TargetScreen, TextNormal);
            Screen('TextSize', TargetScreen, TextSize);
            Screen('TextFont', ResponseScreen, TextFont);
            Screen('TextColor', ResponseScreen, TextNormal);
            Screen('TextSize', ResponseScreen, TextSize);
            Screen('TextFont', FeedbackScreen, TextFont);
            Screen('TextSize', FeedbackScreen, 75);

            % Load the current image file into the workspace

            current_location = locationImages(design.imageOrder(blockTrial)).name; % Load image
            big_image = imread(current_location);
            resized_image = imresize(big_image, sizeValue);
            TargetPicture = Screen('MakeTexture',window,resized_image);
            Screen('DrawTexture', TargetScreen, TargetPicture, [], []);

            % Draw blank screen

            blank_grid = imread(blank_image.name);
            resized_blank = imresize(blank_grid, sizeValue);
            BlankPicture = Screen('MakeTexture',window,resized_blank);
            Screen('DrawTexture', BlankScreen, BlankPicture, [], []);

            % Draw response screen

            Screen('DrawTexture', ResponseScreen, BlankPicture, [], []);
            if userHand == 'L'
                if n == 1
                    ResponseText = sprintf('''%s'' = Same as previous              OR          ''%s'' = Different to previous', upper(sameKey), upper(diffKey));
                else
                    ResponseText = sprintf('''%s'' = Same as %s locations back              OR          ''%s'' = Different to %s locations back', upper(sameKey), num2str(n), upper(diffKey), num2str(n));
                end
            else
                if n == 1
                    ResponseText = sprintf('''%s'' = Different to previous          OR              ''%s'' = Same as previous', upper(diffKey), upper(sameKey));
                else
                    ResponseText = sprintf('''%s'' = Different to %s locations back          OR              ''%s'' = Same as %s locations back', upper(diffKey), num2str(n), upper(sameKey), num2str(n));
                end
            end
            ResponseTextBounds = Screen('TextBounds', window, ResponseText);
            Screen('DrawText', ResponseScreen, ResponseText, ScreenXPixels*0.5-ResponseTextBounds(3)*.5, ScreenYPixels*0.875, white);

            if blockTrial == 1 % If first trial
                if prevPause == 1
                    if practice == 0
                        RespMatM{trial+1,21} = 'r'; % Record r for restart
                    end
                    prevPause = 0;
                end

                Countdown = 5;
                for i = 1:Countdown % Countdown
                    DrawFormattedText(window,sprintf('%d',Countdown),'center','center', white);
                    Screen('Flip',window);
                    WaitSecs(1);
                    Countdown = Countdown - 1;
                end
            end

            % Ensure participant has let go of any keys

            KbReleaseWait;

            % Copy windows at the right time (for best timing)

            Screen('CopyWindow', BlankScreen, window);
            time = Screen('Flip', window);
            for a = 1:NumFramesBlank % Should amount to 1 s
                Screen('CopyWindow', BlankScreen, window);
                time = Screen('Flip', window, time + .5 *ifi);

                [~,~,keyCode] = KbCheck;
                if keyCode(KbName('t')) == 1
                    codeTerminated = 1;
                    break
                elseif keyCode(KbName('g')) == 1
                    codePaused = 1;
                    break
                end
            end

            if codeTerminated == 1 || codePaused == 1
                break
            end

            KbReleaseWait; % Do not progress if key is being pressed

            RestrictKeysForKbCheck(KbCheckResp);

            if blockTrial > n % Only ask for a response if trial > n-back number

                ResponseTimeOnset = GetSecs;
                keyIsDown = 0; % To ensure we only take the first response
                Resp1 = '.';
                Screen('CopyWindow', TargetScreen, window);
                Screen('Flip', window);
                while keyIsDown == 0 && GetSecs - ResponseTimeOnset < (TargetTime)
                    if ~ismember(upper(Resp1(1)),KbCheckResp)
                        [keyIsDown, TimeResponse, keyCode] = KbCheck; % Waiting for key press
                        if keyIsDown
                            kb = KbName(find(keyCode)); % Label key pressed
                            if iscell(kb) % If two keys have been recorded
                                kb = kb{1};
                            end
                            Resp1 = kb;
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

                while GetSecs - ResponseTimeOnset < (TargetTime)
                    % If response is recorded, keep in limbo
                end

                if Resp1 == '.' % If no response recorded, show response probe
                    keyIsDown = 0; % We keep this screen only until a response is recorded
                    Resp2 = '.';
                    Screen('CopyWindow', ResponseScreen, window);
                    Screen('Flip', window);
                    while keyIsDown == 0 && GetSecs - ResponseTimeOnset < (ResponseTime)
                        if ~ismember(upper(Resp2(1)),KbCheckResp)
                            [keyIsDown, TimeResponse, keyCode] = KbCheck; % Waiting for key press
                            if keyIsDown
                                kb = KbName(find(keyCode)); % Label key pressed
                                if iscell(kb) % If two keys have been recorded
                                    kb = kb{1};
                                end
                                Resp2 = kb;
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
                else % If Resp1 has been recorded
                    Resp2 = Resp1; % Save first response as Resp2 for ease
                end
                % Save response as first key pressed

                if codeTerminated == 1 || codePaused == 1
                    break
                end

                Response{trial} = upper(Resp2);
                RespondTime = TimeResponse;

            else % If blocktrial < n just show stim and blank

                Screen('CopyWindow', TargetScreen, window);
                time = Screen('Flip', window);
                for a = 1:NumFramesTarget % Should amount to 1 s
                    Screen('CopyWindow', TargetScreen, window);
                    time = Screen('Flip', window, time + .5 *ifi);

                    [~,~,keyCode] = KbCheck;
                    if keyCode(KbName('t')) == 1
                        codeTerminated = 1;
                        break
                    elseif keyCode(KbName('g')) == 1
                        codePaused = 1;
                        break
                    end
                end

                if codeTerminated == 1 || codePaused == 1
                    break
                end

                Screen('CopyWindow', BlankScreen, window);
                time = Screen('Flip', window);
                for a = 1:NumFramesBlank % Should amount to 600 ms
                    Screen('CopyWindow', BlankScreen, window);
                    time = Screen('Flip', window, time + .5 *ifi);

                    [~,~,keyCode] = KbCheck;
                    if keyCode(KbName('t')) == 1
                        codeTerminated = 1;
                        break
                    elseif keyCode(KbName('g')) == 1
                        codePaused = 1;
                        break
                    end
                end

                if codeTerminated == 1 || codePaused == 1
                    break
                end

                Response{trial} = 'NA'; % Report no response asked
            end

            if sum(design.matchLocations == blockTrial) > 0 % If current trial is a match
                trial_type = 1; % Same as n-back
                correct_response = upper(sameKey);
            else
                trial_type = 0; % Different to n-back
                correct_response = upper(diffKey);
            end

            %%%%%%%%%%%%%%%%%%
            % CHECK ACCURACY %
            %%%%%%%%%%%%%%%%%%

            % Check for accuracy when response is given

            % 0 = Correct
            % 1 = Incorrect
            % 2 = Miss

            if Response{trial} == '.'
                check_accuracy = 2; % Miss
            elseif Response{trial} == "NA"
                check_accuracy = 3; % Not required
            elseif Response{trial} == correct_response % If response is correct
                check_accuracy = 1;
            else
                check_accuracy = 0; % Incorrect
            end

            % Identify x-coordinate

            if regexp(current_location, regexptranslate('wildcard', '*Left')) == 1
                x_coordinate = 1;
            elseif regexp(current_location, regexptranslate('wildcard', '*Mid')) == 1
                x_coordinate = 2;
            elseif regexp(current_location, regexptranslate('wildcard', '*Right')) == 1
                x_coordinate = 3;
            end

            % Identify y-coordinate

            if regexp(current_location, regexptranslate('wildcard', 'Top*')) == 1
                y_coordinate = 1;
            elseif regexp(current_location, regexptranslate('wildcard', 'Centre*')) == 1
                y_coordinate = 2;
            elseif regexp(current_location, regexptranslate('wildcard', 'Bottom*')) == 1
                y_coordinate = 3;
            end

            if practice == 1
                if blockTrial > n % Only show feedback if appropriate
                    Screen('TextFont', ResponseScreen, TextFont);
                    Screen('TextSize', ResponseScreen, TextSize);
                    if check_accuracy == 1
                        feedback_grid = imread(correct_image.name);
                    elseif check_accuracy == 0
                        feedback_grid = imread(incorrect_image.name);
                    elseif check_accuracy == 2
                        feedback_grid = imread(slow_image.name);
                    end
                    resized_blank = imresize(feedback_grid, sizeValue);
                    FeedbackPicture = Screen('MakeTexture',window,resized_blank);
                    Screen('DrawTexture', FeedbackScreen, FeedbackPicture, [], []);

                    Screen('CopyWindow', FeedbackScreen, window);
                    time = Screen('Flip', window);
                    for a = 1:NumFramesFeedback % Should amount to 1 s
                        Screen('CopyWindow', FeedbackScreen, window);
                        time = Screen('Flip', window, time + .5 *ifi);

                        [~,~,keyCode] = KbCheck;
                        if keyCode(KbName('t')) == 1
                            codeTerminated = 1;
                            break
                        elseif keyCode(KbName('g')) == 1
                            codePaused = 1;
                            break
                        end
                    end
                end
            end

            if codeTerminated == 1 || codePaused == 1
                break
            end

            Screen('Close');

            %%%%%%%%%%%%%%%%%
            % STORE RESULTS %
            %%%%%%%%%%%%%%%%%

            % Store practice results

            if practice == 1

                RespMatP{trial+1,1} = subjectInitials;
                RespMatP{trial+1,2} = visitNumber;
                RespMatP{trial+1,3} = sessionNumber;
                RespMatP{trial+1,4} = userHand;
                RespMatP{trial+1,5} = char(todays_date);
                % Computer number
                RespMatP{trial+1,7} = char(this_time);
                RespMatP{trial+1,8} = trial;
                RespMatP{trial+1,9} = thisBlock;
                RespMatP{trial+1,10} = blockTrial;
                RespMatP{trial+1,11} = n;
                RespMatP{trial+1,12} = trial_type; % 0 = Different; 1 = Same as 'n' back
                RespMatP{trial+1,13} = x_coordinate; % 1 2 3
                RespMatP{trial+1,14} = y_coordinate; % 1 2 3
                RespMatP{trial+1,15} = current_location; % Image name
                RespMatP{trial+1,16} = correct_response; % 0 = Different; 1 = Same;
                RespMatP{trial+1,17} = Response{trial}; % 'M' or 'Z' or '.'
                RespMatP{trial+1,18} = check_accuracy; % 0 = Incorrect; 1 = Correct; 2 = Missed; 3 = Too early

                if blockTrial > n % Only record a response time if trial > n

                    RespMatP{trial+1,19} = ResponseTimeOnset;
                    RespMatP{trial+1,20} = RespondTime;
                    RespMatP{trial+1,21} = round((RespondTime - ResponseTimeOnset)*1000); % End time minus start time converted to ms

                end

                trial = trial + 1; % Increase trial count
                pracTrial = trial; % Save the pracTrial
                blockTrial = blockTrial + 1; % Increase blockTrial count?

            elseif practice == 0

                RespMatM{trial+1,1} = subjectInitials;
                RespMatM{trial+1,2} = visitNumber;
                RespMatM{trial+1,3} = sessionNumber;
                RespMatM{trial+1,4} = userHand;
                RespMatM{trial+1,5} = char(todays_date);
                % Computer number
                RespMatM{trial+1,7} = char(this_time);
                RespMatM{trial+1,8} = trial;
                RespMatM{trial+1,9} = thisBlock;
                RespMatM{trial+1,10} = blockTrial;
                RespMatM{trial+1,11} = n;
                RespMatM{trial+1,12} = trial_type; % 0 = Different; 1 = Same as 'n' back
                RespMatM{trial+1,13} = x_coordinate; % 1 2 3
                RespMatM{trial+1,14} = y_coordinate; % 1 2 3
                RespMatM{trial+1,15} = current_location; % Image name
                RespMatM{trial+1,16} = correct_response; % 0 = Different; 1 = Same;
                RespMatM{trial+1,17} = Response{trial}; % 'M' or 'Z' or '.'
                RespMatM{trial+1,18} = check_accuracy; % 0 = Incorrect; 1 = Correct; 2 = Missed; 3 = Too early

                if blockTrial > n % Only record a response time if trial > n

                    RespMatM{trial+1,19} = ResponseTimeOnset;
                    RespMatM{trial+1,20} = RespondTime;
                    RespMatM{trial+1,21} = round((RespondTime - ResponseTimeOnset)*1000); % End time minus start time converted to ms

                end

                trial = trial + 1; % Increase trial count
                mainTrial = trial; % Save the mainTrial
                blockTrial = blockTrial + 1; % Increase blockTrial count?

            end

        end % End of blockTrial loop

        if codeTerminated == 1 || codePaused == 1
            KbReleaseWait;
            RestrictKeysForKbCheck(KbCheckList); % Reset key check in case we want to start again

            Screen('TextSize', window, 60);
            DrawFormattedText(window, 'Task paused \n \n \n Press ''g'' to restart the current block or press ''t'' to terminate the task', 'center', 'center', white);
            Screen('Flip', window);

            [~,keyCode,~] = KbWait;
            if keyCode(KbName('g')) == 1
                KbReleaseWait;
                prevPause = 1; % Remember pause

                if practice == 0
                    mainTrial = mainTrial - blockTrial + 1;
                elseif practice == 1
                    pracTrial = pracTrial - blockTrial + 1;
                end
                trial = trial - blockTrial + 1;

                codePaused = 0; % Restart code
                codeTerminated = 0; % Restart code
            elseif keyCode(KbName('t')) == 1

                KbReleaseWait;
                ListenChar(0);

                if exist('RespMatP', 'var') == 1 % If there is practice data to save

                    Data = dataset(RespMatP);
                    savename = sprintf('TERMINATED_PRACTICE-%s-%s-%s-%s-SNB.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
                    cd(ResultsFolder); % The location where the file should be saved
                    export(Data, 'file', savename, 'Delimiter', ',');

                end

                if exist('RespMatM', 'var') == 1 % If there is real data to save

                    Data = dataset(RespMatM);
                    savename = sprintf('TERMINATED-%s-%s-%s-%s-SNB.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
                    cd(ResultsFolder); % The location where the file should be saved
                    export(Data, 'file', savename, 'Delimiter', ',');

                end

                cd(CurrentFolder);

                end_n = n;

                clearvars -except subjectInitials visitNumber sessionNumber userHand nback_start practice_carry end_n path_folder CurrentFolder;

                error('Terminate task by pressing "t" key; results saved')
            end
        else

            %% Set up for next block %%

            if screeningVisit == 1
                endScreenN = 2;
            else
                endScreenN = 3;
            end

            KbReleaseWait;
            RestrictKeysForKbCheck(KbCheckList);
            Screen('TextSize', window, 60);

            if practice_start == 1 % If there was practice set
                if practice == 1
                    StartText = sprintf('%d-back practice finished!', n);
                    BlockNotesText2 = sprintf('Ask the experimenter now if you have any questions');
                    BlockNotesText3 = sprintf('Please note there will be no feedback in the main part of the %d-back task', n);
                    BlockNotesText4 = sprintf(' ');
                    BlockNotesText5 = sprintf('Press the spacebar for a reminder of the %d-back instructions', n);
                elseif practice == 0
                    if n < endScreenN
                        StartText = sprintf('%d-back task finished!', n);
                        BlockNotesText2 = sprintf(' ');
                        BlockNotesText3 = sprintf('Please let the experimenter know');
                        BlockNotesText4 = sprintf(' ');
                        BlockNotesText5 = sprintf('Press the spacebar for instructions to the next part of the task');
                    elseif n == endScreenN
                        StartText = sprintf('All parts of the task complete!');
                        BlockNotesText2 = sprintf(' ');
                        BlockNotesText3 = sprintf('Please let the experimenter know');
                        BlockNotesText4 = sprintf(' ');
                        BlockNotesText5 = sprintf(' ');
                    end
                end
            elseif practice_start == 0 % If no practice was set
                if n < endScreenN
                    StartText = sprintf('%d-back finished!', n);
                    BlockNotesText2 = sprintf(' ');
                    BlockNotesText3 = sprintf('Please let the experimenter know');
                    BlockNotesText4 = sprintf(' ');
                    BlockNotesText5 = sprintf('Press the spacebar for instructions to the next part of the task');
                elseif n == endScreenN
                    StartText = sprintf('Task complete!');
                    BlockNotesText2 = sprintf(' ');
                    BlockNotesText3 = sprintf('Please let the experimenter know');
                    BlockNotesText4 = sprintf(' ');
                    BlockNotesText5 = sprintf(' ');
                end
            end

            BlockNotesBounds1 = Screen('TextBounds', window, StartText);
            BlockNotesBounds2 = Screen('TextBounds', window, BlockNotesText2);
            BlockNotesBounds3 = Screen('TextBounds', window, BlockNotesText3);
            BlockNotesBounds4 = Screen('TextBounds', window, BlockNotesText4);
            BlockNotesBounds5 = Screen('TextBounds', window, BlockNotesText5);
            Screen('DrawText', window, StartText, ScreenXPixels*.5-BlockNotesBounds1(3)*.5, ScreenYPixels*.3-BlockNotesBounds1(4)*.5), white;
            Screen('DrawText', window, BlockNotesText2, ScreenXPixels*.5-BlockNotesBounds2(3)*.5, ScreenYPixels*.4-BlockNotesBounds2(4)*.5), white;
            Screen('DrawText', window, BlockNotesText3, ScreenXPixels*.5-BlockNotesBounds3(3)*.5, ScreenYPixels*.5-BlockNotesBounds3(4)*.5), white;
            Screen('DrawText', window, BlockNotesText4, ScreenXPixels*.5-BlockNotesBounds4(3)*.5, ScreenYPixels*.6-BlockNotesBounds4(4)*.5), white;
            Screen('DrawText', window, BlockNotesText5, ScreenXPixels*.5-BlockNotesBounds5(3)*.5, ScreenYPixels*.7-BlockNotesBounds5(4)*.5), white;
            Screen('Flip', window);

            % Wait for spacebar press
            while 1
                [~,~,keyCode] = KbCheck;
                if keyCode(KbName('space'))== 1
                    break
                elseif keyCode(KbName('t')) == 1
                    codeTerminated = 1;
                    break
                end
            end

            KbReleaseWait;

            block = block + 1; % Move to next block
            if practice == 0 % If this block was not practice
                n = n + 1; % Increase 'n'
            end

            if practice_start == 1 % If practice was selected at first
                if practice == 1
                    practice = 0;
                elseif practice == 0
                    practice = 1;
                end
            end

        end

        blockTrial = 1; % Reset blockTrial
        check_accuracy = 0; % Reset accuracy check
        showInstructions = 0; % Do not show spacebar press again unecessarily

        cd(ImageFolder); % Go to the image folder for main task

        if screeningVisit == 1
            if n == 3
                block = 10;
            end
        end

    end % End of 'while' block loop

    %% End %%

    % Save the data to csv file(s)

    ShowCursor;
    ListenChar(0);

    if practice_start == 1 % If there was practice
        Data = dataset(RespMatP);
        savename = sprintf('PRACTICE-%s-%s-%s-%s-SNB.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
        cd(PracticeResults); % Cloud location where the file should be saved
        export(Data, 'file', savename, 'Delimiter', ',');
        cd(LocalResults); % Non-cloud location where the file should be saved
        export(Data, 'file', savename, 'Delimiter', ',');
        cd(CurrentFolder);
    end

    Data = dataset(RespMatM);
    savename = sprintf('%s-%s-%s-%s-SNB.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
    cd(MainResults); % Cloud location where the file should be saved for storage
    export(Data, 'file', savename, 'Delimiter', ',');
    cd(UploadFolder); % Cloud location where the file should be saved for upload
    export(Data, 'file', savename, 'Delimiter', ',');
    cd(LocalResults); % Non-cloud location where the file should be saved
    export(Data, 'file', savename, 'Delimiter', ',');
    cd(CurrentFolder);

catch % Closes psyschtoolbox if there is an error and saves whatever data has been collected so far

    ShowCursor;
    ListenChar(0);
    Screen('CloseAll');

    if exist('RespMatP', 'var') == 1 % If there is practice data to save

        RespMatP{(height(RespMatP)+1),1} = 'ERROR'; % Add a row

        Data = dataset(RespMatP);
        savename = sprintf('ERROR_PRACTICE-%s-%s-%s-%s-SNB.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
        cd(CurrentFolder); % The location where the file should be saved
        export(Data, 'file', savename, 'Delimiter', ',');

    end

    if exist('RespMatM', 'var') == 1 % If there is real data to save

        RespMatM{(height(RespMatM)+1),1} = 'ERROR'; % Add a row

        Data = dataset(RespMatM);
        savename = sprintf('ERROR-%s-%s-%s-%s-SNB.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
        cd(CurrentFolder); % The location where the file should be saved
        export(Data, 'file', savename, 'Delimiter', ',');

    end

    cd(CurrentFolder);

    psychrethrow(psychlasterror); % Tells you the error in the command window

    Priority(0);
    sca;

end % End of try, catch,

if exist('path_folder', 'var') == 1
    cd(path_folder);
    clearvars -except indx window subjectInitials visitNumber sessionNumber userHand nback_start practice_carry FITFolder end_n path_folder;
else
    cd(CurrentFolder);
    ShowCursor;
    ListenChar(0)
    clear all
    sca;
    close all;
end

clc;