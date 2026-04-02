
% function ERT_START
%
%% Go / No-go task utilising facial expression (happy or fearful) as block targets %%
%
% Dr Tom Faherty, 10th May 2023
% t.b.s.faherty@bham.ac.uk
%
% Participants are presented with one image. Their task is to respond with a spacebar press if
% the image matches the target expression (e.g., happy) and inhibit response if the expression
% does not match the target classifier. Classifier changes in each block
%
%% SET UP SOME VARIABLES %%

clearvars -except indx window subjectInitials visitNumber sessionNumber practice_carry all_images_ERT stim_call fin_block path_folder;

if exist('indx', 'var') == 0 || indx == 3 % If we are starting with this task
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
DriveFolder = 'C:\Users\lab-user\OneDrive - University of Birmingham\HIPTOX\Cognitive Tasks\Expression Recognition Task';
% DriveFolder = pwd; % For debugging

ResultsFolder = fullfile(DriveFolder,'Results');
ImageFolder = fullfile(CurrentFolder,'Stimuli');
MainResults = fullfile(ResultsFolder,'Main');
PracticeResults = fullfile(ResultsFolder,'Practice');
LocalResults = fullfile(path_folder,'Local Results');
UploadFolder = 'C:\Users\lab-user\OneDrive - University of Birmingham\HIPTOX\Cognitive Tasks\2 Upload';

%%%%%%%%%%%%%%%%%%%%

prompt={'Participant ID [HIP00]', 'Visit Number [0 - 5]', 'Session Number [1 (Pre) / 2 (Post)]', 'Start block', 'Practice? [Y / N]'};

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
if exist('fin_block', 'var') == 1 % If carry over from previous task
    defaults{4} = num2str(fin_block);
else
    defaults{4} = '1'; % Can start from other block number only if design already exists
end
if exist('practice_carry', 'var') == 1 % If carry over from previous task
    defaults{5} = practice_carry;
else
    if t(4) > 11
        defaults{5} = 'N';
    else
        defaults{5} = 'Y';
    end
end

if exist('indx', 'var') == 0 || indx == 3 % If we are starting with this task

    ANSWER = inputdlg(prompt, 'Emotion Recognition Task', [1, 75], defaults);
    if isempty(ANSWER)
        % User clicked cancel. Bail out! Bail out!
        close all;
        clearvars -except subjectInitials visitNumber sessionNumber practice_carry all_images_ERT stim_call path_folder;
        error('User Clicked Cancel')
    elseif upper(ANSWER{1}(1:3)) ~= "HIP" || length(ANSWER{1}) ~= 5
        close all;
        clearvars -except visitNumber sessionNumber practice_carry all_images_ERT stim_call path_folder;
        error('Must start with "HIP" and include two characters afterwards')
    elseif str2double(ANSWER{4}) < 1 || str2double(ANSWER{4}) > 4
        close all;
        clearvars -except subjectInitials visitNumber sessionNumber practice_carry all_images_ERT stim_call path_folder;
        error('Must use a number between 1 and 4')
    elseif upper(ANSWER{5}) ~= 'Y' && upper(ANSWER{5}) ~= 'N'
        close all;
        clearvars -except subjectInitials visitNumber sessionNumber all_images_ERT stim_call path_folder;
        error('Must choose Y or N for practice')
    end

    if exist('subjectInitials', 'var') == 1
        if length(ANSWER{1}) ~= length(subjectInitials)% If the participant number is changed
            clearvars all_images_ERT stim_call % Clear the previous design
        else
            if  ANSWER{1} ~= subjectInitials % If the participant number is changed
                clearvars all_images_ERT stim_call % Clear the previous design
            else
            end
        end
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
startBlock = str2double(ANSWER{4});
practice = (ANSWER{5}); % Save practice

if practice == 'Y'
    practice = 1;
    practice_carry = 'Y';
else
    practice = 0;
    practice_carry = 'N';
end

if startBlock > 1
    practice = 0; % Remove practice if the start block is different. This catches human error
end

%% Keyboard Setup %%

KbName('UnifyKeyNames');
KbCheckList = [KbName('space'), KbName('t') ,KbName('g')];

%% SET SOME VARIABLES %%
check_accuracy = 0; % Reset accuracy check
trial = 1; % Reset trial counter
blockTrial = 1; % Reset blockTrial counter
trials_per_block = 44; % Number of trials per block
Numblocks = 4;
numBlocksUsed = 5-startBlock;
block = startBlock;
if mod(startBlock,2) == 1 % % If starting block is even
    if screeningVisit == 1
        block_target = 1;
    else
        block_target = 0;
    end
else % If starting block is odd
    if screeningVisit == 1
        block_target = 0;
    else
        block_target = 1;
    end
end
trials_practice = 8; % Number of practice trials

todays_date = string(datetime('now'),'dd/MM/yy');

% Set up screen

WhichScreen = max(Screen('Screens'));
black = BlackIndex(WhichScreen); % Black is 0
white = WhiteIndex(WhichScreen); % White is 255
BackgroundColour = white; % Background is set to white (n.b. white/2 = grey)

TextSize = 60;
TextFont = 'Arial';
TextNormal = [0 0 0]; % normal (black) text colour
TextGreen = [35 230 90]; % correct text colour
TextRed = [255 60 0]; % incorrect text colour

WaitSecs(0.5); % This helps the PsychToolbox sync

windowTry = 0;
windowErr = 0;

if exist('indx', 'var') == 0 || indx == 3 % If we are starting with this task

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
Screen('TextColor', window, TextNormal);

% Set up screen timings

ifi = Screen('GetFlipInterval',window); % How long is a frame in ms
ScreenRefreshRate = 1/ifi; % Calculate refresh rate

% Stimulus timings in s

SetFixationTime = 0.7; % 700 ms
TargetTime = 0.1; % Time that stim is shown
BlankTime = 0.7; % Extra time after response (allowing for responses up to 800ms)
FeedbackTime = 1; % Time that feedback is shown (Practice only, otherwise fixation screen)

FixationTimeMill = randi([550,950],(trials_per_block*Numblocks) ,1); % Creates jittered fixation time in ms
JitFixationTime = FixationTimeMill/1000; % Changes jittered fixation time to s

% Stimulus timings in frames (for best timings)

NumFramesFixation = round(SetFixationTime / ifi);
NumFramesFeedback = round(FeedbackTime / ifi);

try %try, catch end

    RestrictKeysForKbCheck(KbCheckList);
    ListenChar(2); % Avoid key presses affecting code
    HideCursor;

    % Create image arrays

    cd(ImageFolder); % The location where image files are

    if exist('stim_call', 'var') == 1 % If carry over from previous task

    else

        all_images_ERT = dir('*.jpg'); % Load all images
        all_images_ERT = all_images_ERT(randperm(length(all_images_ERT))); % Randomise order

    end

    fixation_image = dir('*.bmp'); % Load fixation cross

    while practice > -1

        codeWarning = 0; % Reset warning
        codePaused = 0; % Rest pause
        codeTerminated = 0; % Reset termination

        if exist('stim_call', 'var') == 1 % If carry over from previous task

        else

            if practice == 1 % If practice
                readyPrac = 0;
                while readyPrac == 0
                    evenCheck = 0;
                    prac_array = {};
                    for praci = 1:trials_practice
                        prac_array{praci} = all_images_ERT(praci).name;
                    end

                    for checkPrac = 1:trials_practice
                        if prac_array{checkPrac}(6) == 'H'
                            evenCheck = evenCheck + 1;
                        else
                        end
                    end

                    if evenCheck > 4 || evenCheck < 4
                        all_images_ERT = all_images_ERT(randperm(length(all_images_ERT))); % Randomise order
                        readyPrac = 0; % Reset and try again
                    else
                        readyPrac = 1;
                    end
                end
            elseif practice == 0 % If main task

                % Randomise Stim again

                all_images_ERT = all_images_ERT(randperm(length(all_images_ERT))); % Randomise order

                % Create index of stimuli features

                for i = 1:length(all_images_ERT)
                    Expression_Matrix(i) = contains(all_images_ERT(i).name, '_F'); % 0 = Happy; 1 = Fearful
                    Gender_Matrix(i) = contains(all_images_ERT(i).name, 'M'); % 0 = Female; 1 = Male
                    Mouth_Matrix(i) = contains(all_images_ERT(i).name, 'C.'); % 0 = Open; 1 = Closed
                    Ethnicity_Matrix(i) = contains(all_images_ERT(i).name, ["A","B"]); % 0 = A/B; 1 = W/H
                end

                % For consistency: 0 Male and 1 Female

                Gender_Matrix(:) = ~Gender_Matrix;

                % Create truth table

                N = 4;
                L = 2^N;
                stim_type_matrix = zeros(L,N);
                for i = 1:N
                    temp = [zeros(L/2^i,1); ones(L/2^i,1)];
                    stim_type_matrix(:,i) = repmat(temp,2^(i-1),1);
                end

                % Start identification loop

                for loop = 1:16 % 16 is amount of possible combinations re. gender, expression, mouth, and ethnicity (2x2x2x2)

                    % Reset counter for next loop
                    z = 1;

                    for n = 1:length(all_images_ERT) % For all 264 images
                        if Expression_Matrix(n) == stim_type_matrix(loop,1) % expression criteria
                            if Gender_Matrix(n) == stim_type_matrix(loop,2) % gender criteria
                                if Mouth_Matrix(n) == stim_type_matrix(loop,3) % mouth criteria
                                    if Ethnicity_Matrix(n) == stim_type_matrix(loop,4) % ethnicity criteria
                                        current_array(loop,z) = n; % Save index of image in a new array. Each row should correspond to each matrix line
                                        z = z+1; % increase counter to ensure no images are overwritten
                                    end
                                end
                            end
                        end
                    end
                end

                % Set 8 block start images

                start_array = zeros(1,8);
                start_array_expression = zeros(1,8);
                for b = 1:8
                    start_array(b) = [current_array(b*2,11)];
                    start_array_expression(b) = [stim_type_matrix(b*2,1)];
                end

                % Set up 4 arrays (because 4 blocks)

                new_array = [];
                pick_startValue = ones(16,1);
                array_startValue = 1;
                stim_call = {};

                for v = 1:(Numblocks/2) % Repeat array population 2 times (for 4 blocks)
                    for target = 0:1 % Populate happy array first
                        cond_cycle = 1; % Reset conditions cycle
                        for cond_cycle = 1:16 % Cycle through all conditions
                            if stim_type_matrix(cond_cycle,1) == target % If the condition is a target
                                multiplier = 2; % include double the stimuli in the array
                            else
                                multiplier = 1;
                            end
                            if mod(cond_cycle,2) == 1 % if condition matrix number is odd (W/H images)
                                multiplier = multiplier*2; % Take double the images
                            end % do not change multiplier
                            picked_stim = []; % Reset collected values
                            picked_stim = current_array(cond_cycle,pick_startValue(cond_cycle,1):pick_startValue(cond_cycle,:)+multiplier-1);
                            pick_startValue(cond_cycle,1) = pick_startValue(cond_cycle,1)+multiplier; % remember the position of the last stim taken
                            new_array(1, array_startValue:array_startValue+multiplier-1) = picked_stim;
                            new_array(2, array_startValue:array_startValue+multiplier-1) = stim_type_matrix(cond_cycle,1);
                            array_startValue = array_startValue + multiplier;
                        end
                        array_startValue = 1; % Reset array start value

                        stim_call{(v*2)+target-1,1} = new_array(1,:); % Bind current stim into cell
                        stim_call{(v*2)+target-1,2} = new_array(2,:);
                        stim_call{(v*2)+target-1,3} = target; % Save target

                        swap = randperm(length(new_array(1,:))); % Randperm, reset each loop

                        stim_call{(v*2)+target-1,1} = stim_call{(v*2)+target-1,1}(swap);
                        stim_call{(v*2)+target-1,2} = stim_call{(v*2)+target-1,2}(swap);

                        novel_swap = randperm(8); % Set up randomiser for first 8 trials
                        new_order_start = start_array(novel_swap);
                        new_order_start_expression = start_array_expression(novel_swap);

                        % Bind start stim into cell

                        stim_call{(v*2)+target-1,1}(9:44) = stim_call{(v*2)+target-1,1}(1:36);% Shift array along 8
                        stim_call{(v*2)+target-1,2}(9:44) = stim_call{(v*2)+target-1,2}(1:36); % Shift array along 8
                        stim_call{(v*2)+target-1,1}(1:8) = new_order_start; % Replace first 8
                        stim_call{(v*2)+target-1,2}(1:8) = new_order_start_expression; % Replace first 8

                        new_array = []; % Reset new array
                    end
                end
            end

            % Target reset
            target = 0;

        end

        % Set up log file

        RespMat{1,1} = 'Participant ID';
        RespMat{1,2} = 'Visit number';
        RespMat{1,3} = 'Session number';
        RespMat{1,4} = 'Date'; % Todays Date
        RespMat{1,5} = 'Laptop name';
        RespMat{2,5} = getenv('COMPUTERNAME');
        RespMat{1,6} = 'Time'; % Time of each trial
        RespMat{1,7} = 'Trial number';
        RespMat{1,8} = 'Block number';
        RespMat{1,9} = 'Block trial number';
        RespMat{1,10} = 'Trial type'; % 0 = No-go; 1 = Go
        RespMat{1,11} = 'Target classifier'; % 0 = Happy; 1 = Fearful
        RespMat{1,12} = 'Stimulus expression'; % 0 = Happy; 1 = Fearful
        RespMat{1,13} = 'Stimulus gender'; % 0 = Male; 1 = Female
        RespMat{1,14} = 'Stimulus mouth'; % 0 = Open; 1 = Closed
        RespMat{1,15} = 'Stimuli ethnicity'; % 0 = A; 1 = B; 2 = W; 3 = H
        RespMat{1,16} = 'Filename'; % Image name
        RespMat{1,17} = 'Correct response'; % 0 = No-go; 1 = Go
        RespMat{1,18} = 'KeyCode Output'; % '.' = No response; 's' = Response
        RespMat{1,19} = 'FA Hit CR or Miss?'; % 0 = False Alarm; 1 = Hit; 2 = Correct Rejection; 3 = Miss
        RespMat{1,20} = 'Correct?'; % 0 = Correct; 1 = Incorrect
        RespMat{1,21} = 'Start time';
        RespMat{1,22} = 'End time';
        RespMat{1,23} = 'Raw RT'; % End time minus start time
        RespMat{1,24} = 'Repeat?'; % Record any warnings or pauses

        %% Start of experimental loop %%

        while block < Numblocks + 1
            if block < 2 % If first block, show start screen

                Screen('TextSize', window, 60);

                StartText = sprintf('Please press the spacebar to see task instructions');
                StartTextBounds = Screen('TextBounds', window, StartText);
                Screen('DrawText',window,StartText, ScreenXPixels*.5-StartTextBounds(3)*.5, ScreenYPixels*.5-StartTextBounds(4)*.5, black);
                Screen('Flip', window);
                while 1
                    [~,~,keyCode] = KbCheck;
                    if keyCode(KbName('space'))==1
                        break
                    elseif keyCode(KbName('t')) == 1
                        codeTerminated = 1;
                        break
                    end
                end
            end

            KbReleaseWait;

            % Create block instruction text

            hText = 'happy';
            fText = 'fearful';

            if block_target == 0 % Block target is happy
                targetText = hText;
                distractorText = fText;
            else % Block target is fearful
                targetText = fText;
                distractorText = hText;
            end

            if practice == 1
                finalText = 'a short practice';
                targetText = hText;
                distractorText = fText;
            elseif practice == 0
                finalText = 'the block';
            end

            Screen('TextSize', window, 60);

            StartText = sprintf('Read the following instructions carefully');
            BlockNotesText2 = sprintf('If a %s\t face is presented, press the spacebar as quickly as possible', targetText);
            BlockNotesText3 = sprintf('Otherwise, do not respond');
            BlockNotesText4 = sprintf('Try to be as quick and accurate as possible');
            if practice == 1
                BlockNotesText5 = sprintf('Press the spacebar to begin a short practice');
            elseif practice == 0
                BlockNotesText5 = sprintf('Press the spacebar to begin the block');
            end
            BlockNotesBounds1 = Screen('TextBounds', window, StartText);
            BlockNotesBounds2 = Screen('TextBounds', window, BlockNotesText2);
            BlockNotesBounds3 = Screen('TextBounds', window, BlockNotesText3);
            BlockNotesBounds4 = Screen('TextBounds', window, BlockNotesText4);
            BlockNotesBounds5 = Screen('TextBounds', window, BlockNotesText5);
            Screen('DrawText', window, StartText, ScreenXPixels*.5-BlockNotesBounds1(3)*.5, ScreenYPixels*.3-BlockNotesBounds1(4)*.5, black);
            Screen('DrawText', window, BlockNotesText2, ScreenXPixels*.5-BlockNotesBounds2(3)*.5, ScreenYPixels*.4-BlockNotesBounds2(4)*.5, black);
            Screen('DrawText', window, BlockNotesText3, ScreenXPixels*.5-BlockNotesBounds3(3)*.5, ScreenYPixels*.5-BlockNotesBounds3(4)*.5, black);
            Screen('DrawText', window, BlockNotesText4, ScreenXPixels*.5-BlockNotesBounds4(3)*.5, ScreenYPixels*.6-BlockNotesBounds4(4)*.5, black);
            Screen('DrawText', window, BlockNotesText5, ScreenXPixels*.5-BlockNotesBounds5(3)*.5, ScreenYPixels*.7-BlockNotesBounds5(4)*.5, black);
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

            % Start block
            if practice == 1
                totalTrials = trials_practice;
                thisManyTrials = trials_practice;
            elseif practice == 0
                totalTrials = trials_per_block * (numBlocksUsed - Numblocks + block);
                thisManyTrials = trials_per_block;
            end

            while trial < totalTrials + 1
                while blockTrial < thisManyTrials + 1 && codePaused == 0 && codeWarning == 0 && codeTerminated == 0 % Whilst nothing is happening to stop the code running

                    % Get time

                    this_time = string(datetime('now'),'HH:mm:ss'); % Time start in correct format

                    % Stimulus timings in frames (for best timings)

                    NumFramesJitFixation = round(JitFixationTime(trial) / ifi);

                    % Open offscreen windows for drawing prior to presentation

                    FixationScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    TargetScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    BlankScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);
                    FeedbackScreen = Screen('OpenOffscreenWindow',WhichScreen, BackgroundColour);

                    % Set up parameters for offscreen windows

                    Screen('TextFont', FixationScreen, TextFont);
                    Screen('TextColor', FixationScreen, TextNormal);
                    Screen('TextSize', FixationScreen, TextSize);
                    Screen('TextFont', TargetScreen, TextFont);
                    Screen('TextColor', TargetScreen, TextNormal);
                    Screen('TextSize', TargetScreen, TextSize);
                    Screen('TextFont', BlankScreen, TextFont);
                    Screen('TextColor', BlankScreen, TextNormal);
                    Screen('TextSize', BlankScreen, TextSize);

                    % Load the current image file into the workspace

                    if practice == 1
                        current_image = all_images_ERT(blockTrial).name;
                    elseif practice == 0
                        current_image = all_images_ERT(stim_call{block, 1}(blockTrial)).name; % Load image
                    end
                    big_image = imread(current_image);
                    resized_image = imresize(big_image, 0.3);
                    TargetPicture = Screen('MakeTexture',window,resized_image);
                    Screen('DrawTexture', TargetScreen, TargetPicture, [], []);

                    % Draw fixation screen

                    fix_cross = imread(fixation_image.name);
                    resized_fix = imresize(fix_cross, 0.15);
                    FixationPicture = Screen('MakeTexture',window,resized_fix);
                    Screen('DrawTexture', FixationScreen, FixationPicture, [], []);

                    % Set up whether a response is needed %

                    if practice == 1

                        if current_image(6) == 'H' % If current image is a target (practice only)
                            correct_response = 1; % Looking for Hit
                        else
                            correct_response = 0; % Looking for Correct Rejection
                        end

                    else

                        if stim_call{block,2}(blockTrial) == block_target % If current image is a target
                            correct_response = 1; % Looking for Hit
                        else
                            correct_response = 0; % Looking for Correct Rejection
                        end
                    end

                    if blockTrial == 1 || prevWarning == 1 || prevPause == 1 % If first trial or repeat trial
                        Countdown = 5;
                        for i = 1:Countdown % Countdown
                            DrawFormattedText(window,sprintf('%d',Countdown),'center','center', black);
                            Screen('Flip',window);
                            WaitSecs(1);
                            Countdown = Countdown - 1;
                        end
                        prevWarning = 0;
                        prevPause = 0;
                    end

                    % Ensure participant has let go of any keys

                    KbReleaseWait;

                    % Copy windows at the right time (for best timing)

                    Screen('CopyWindow', FixationScreen, window);
                    time = Screen('Flip', window);
                    for a = 1:NumFramesJitFixation % Should amount to 0.8s for total 1000 ms
                        Screen('CopyWindow', FixationScreen, window);
                        time = Screen('Flip', window, time + .5 *ifi);

                        [~,~,keyCode] = KbCheck;
                        if keyCode(KbName('t')) == 1
                            codeTerminated = 1;
                            KbReleaseWait;
                            break
                        elseif keyCode(KbName('g')) == 1
                            codePaused = 1; % Turn pause on
                            KbReleaseWait;
                            break
                        end
                    end

                    % If participant is trying to cheat (Keep key pushed down through
                    % fixation for an easy win), give them a warning!

                    KbCheck;
                    if KbCheck == 1
                        codeWarning = 1;
                    end

                    if codeTerminated == 1 || codePaused == 1 || codeWarning == 1
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
                                Resp1 = kb(1); % Recode as first letter
                                if Resp1 == 't'
                                    codeTerminated = 1;
                                    break
                                elseif Resp1 == 'g'
                                    codePaused = 1; % Turn pause on
                                    break
                                end
                            end
                        end
                    end

                    if codeTerminated == 1 || codePaused == 1
                        break
                    end

                    KbReleaseWait;
                    keyIsDown = 0; % Reset if key has been pressed
                    ResponseTimeCont = GetSecs;
                    Resp2 = '.';
                    Screen('CopyWindow', BlankScreen, window);
                    Screen('Flip', window);
                    while keyIsDown == 0 && GetSecs - ResponseTimeCont < BlankTime % While there is still blank time remaining
                        if ~ismember(upper(Resp2(1)),KbCheckList)
                            [keyIsDown, TimeT2Response, keyCode] = KbCheck; % Waiting for key press
                            if keyIsDown
                                kb = KbName(find(keyCode)); % Label key pressed
                                Resp2 = kb(1); % Recode as uppercase
                                if Resp2 == 't'
                                    codeTerminated = 1;
                                    break
                                elseif Resp2 == 'g'
                                    codePaused = 1; % Turn pause on
                                    break
                                end
                            end
                        end
                    end

                    if codeTerminated == 1 || codePaused == 1
                        break
                    end

                    % Save response as first key pressed

                    if Resp1 ~= '.'
                        Response(trial) = Resp1(1);
                        RespondTime = TimeT1Response;
                    elseif Resp1 == '.'
                        Response(trial) = Resp2(1);
                        RespondTime = TimeT2Response;
                    end

                    %%%%%%%%%%%%%%%%%%
                    % CHECK ACCURACY %
                    %%%%%%%%%%%%%%%%%%

                    % Check for accuracy when response is given

                    % 0 = False Alarm
                    % 1 = Hit
                    % 2 = Correct Rejection
                    % 3 = Miss

                    if Response(trial) == '.'
                        if correct_response == 0 % No-go trial
                            check_accuracy = 2; % Correct Rejection
                            count_accuracy = 1;
                        elseif correct_response == 1 % Go trial
                            check_accuracy = 3; % Miss
                            count_accuracy = 0;
                        end
                    else
                        if correct_response == 0 % No-go trial
                            check_accuracy = 0; % False Alarm
                            count_accuracy = 0;
                        elseif correct_response == 1 % Go trial
                            check_accuracy = 1; % Hit
                            count_accuracy = 1;
                        end
                    end

                    % If practice, present feedback

                    Screen('TextFont', FeedbackScreen, TextFont);
                    Screen('TextSize', FeedbackScreen, TextSize);
                    if practice == 1
                        if count_accuracy == 1
                            DrawFormattedText(FeedbackScreen, 'Correct', 'center', 'center', TextGreen);
                        elseif count_accuracy == 0
                            DrawFormattedText(FeedbackScreen, 'Incorrect', 'center', 'center', TextRed);
                        end
                    else
                        Screen('DrawTexture', FeedbackScreen, FixationPicture, [], []); % Draw fixation cross if main task
                    end

                    KbReleaseWait;

                    for d = 1:NumFramesFeedback % Should amount to 0.8s
                        Screen('CopyWindow', FeedbackScreen, window);
                        time = Screen('Flip', window,time + .5*ifi);

                        [~,~,keyCode] = KbCheck;
                        if keyCode(KbName('t')) == 1
                            codeTerminated = 1;
                            break
                        elseif keyCode(KbName('g')) == 1
                            codePaused = 1; % Turn pause on
                            break
                        end
                    end

                    if codeTerminated == 1 || codePaused == 1
                        break
                    end


                    % Identify face ethnicity

                    if current_image(1) == "A"
                        stim_ethnicity = 0;
                    elseif current_image(1) == "B"
                        stim_ethnicity = 1;
                    elseif current_image(1) == "H"
                        stim_ethnicity = 2;
                    elseif current_image(1) == "W"
                        stim_ethnicity = 3;
                    end

                    % Identify expression

                    if current_image(6) == "H"
                        stim_expression = 0;
                    elseif current_image(6) == "F"
                        stim_expression = 1;
                    end

                    % Identify mouth

                    if current_image(7) == "O"
                        stim_mouth = 0;
                    elseif current_image(7) == "C"
                        stim_mouth = 1;
                    end

                    % Identify gender

                    if current_image(2) == "M"
                        stim_gender = 0;
                    elseif current_image(2) == "F"
                        stim_gender = 1;
                    end

                    KbReleaseWait;

                    Screen('Close');

                    %%%%%%%%%%%%%%%%
                    % SAVE RESULTS %
                    %%%%%%%%%%%%%%%%

                    RespMat{trial+1,1} = subjectInitials;
                    RespMat{trial+1,2} = visitNumber;
                    RespMat{trial+1,3} = sessionNumber;
                    RespMat{trial+1,4} = char(todays_date);
                    % Computer number
                    RespMat{trial+1,6} = char(this_time);
                    RespMat{trial+1,7} = trial;
                    RespMat{trial+1,8} = startBlock + block - 1;
                    RespMat{trial+1,9} = blockTrial;
                    RespMat{trial+1,10} = correct_response; % 0 = No-go; 1 = Go
                    RespMat{trial+1,11} = block_target; % 0 = Happy; 1 = Fearful
                    RespMat{trial+1,12} = stim_expression; % 0 = Fearful; 1 = Happy
                    RespMat{trial+1,13} = stim_gender; % 0 = Male; 1 = Female
                    RespMat{trial+1,14} = stim_mouth; % 0 = Open; 1 = Closed
                    RespMat{trial+1,15} = stim_ethnicity; % 0 = A; 1 = B; 2 = W; 3 = H
                    RespMat{trial+1,16} = current_image;
                    RespMat{trial+1,17} = correct_response; % 0 = Correct Rejection; 1 = Hit
                    RespMat{trial+1,18} = Response(trial); % Response key
                    RespMat{trial+1,19} = check_accuracy; % 0 = False Alarm; 1 = Hit; 2 = Correct Rejection; 3 = Miss
                    RespMat{trial+1,20} = count_accuracy; % 0 = Correct; 1 = Incorrect
                    RespMat{trial+1,21} = ResponseTimeOnset;
                    RespMat{trial+1,22} = RespondTime;
                    RespMat{trial+1,23} = round((RespondTime - ResponseTimeOnset)*1000); % End time minus start time converted to ms

                    if isempty(RespMat{trial+1,24})
                        RespMat{trial+1, 24} = 'n';
                    else
                    end

                    trial = trial + 1; % Increase trial count
                    blockTrial = blockTrial + 1; % Increase blockTrial count

                end

                % What do we do if the code is paused or a warning has been given


                while codePaused == 1 % If pause is on, wait for confirmation of restart

                    KbReleaseWait;
                    Screen('TextSize', window, 60);
                    DrawFormattedText(window, 'paused', 'center', 'center', black);
                    Screen('Flip', window);

                    [~,keyCode,~] = KbWait;
                    if keyCode(KbName('g')) == 1
                        KbReleaseWait;
                        prevPause = 1; % Remember pause
                        RespMat{trial+1,24} = 'p'; % Record pause for original trial
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
                    RespMat{trial+1, 24} = 'w'; % Record warning for original trial
                    codeWarning = 0;
                end

                while codeTerminated == 1
                    KbReleaseWait;

                    Screen('TextSize', window, 60);
                    DrawFormattedText(window, 'Are you sure you want to quit? \n \n \n Press ''g'' to resume the task or press ''t'' to terminate', 'center', 'center', black);
                    Screen('Flip', window);

                    [~,keyCode,~] = KbWait;
                    if keyCode(KbName('g')) == 1
                        KbReleaseWait;
                        prevPause = 1; % Remember pause
                        RespMat{trial+1,24} = 'p'; % Record pause for original trial
                        codeTerminated = 0; % Restart code
                        break
                    elseif keyCode(KbName('t')) == 1
                        cd(CurrentFolder);
                        Data = dataset(RespMat);
                        if practice == 1 % If practice
                            savename = sprintf('TERMINATE_PRACTICE-%s-%s-%s-%s-ERT.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
                        elseif practice == 0 % If main task
                            savename = sprintf('TERMINATE-%s-%s-%s-%s-ERT.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
                        end
                        cd(ResultsFolder); % The location where the file should be saved
                        export(Data, 'file', savename, 'Delimiter', ',');
                        cd(CurrentFolder);

                        fin_block = block;

                        clearvars  -except subjectInitials visitNumber sessionNumber practice_carry all_images_ERT stim_call fin_block path_folder CurrentFolder;

                        ListenChar(0);
                        error('Terminate task by pressing "t" key; results saved')
                    end
                end

                if blockTrial == thisManyTrials + 1
                    blockTrial = 1; % Reset blockTrial count
                end
            end

            KbReleaseWait;

            if practice ~= 1
                if block < Numblocks && screeningVisit == 0

                    BlockNotesText = sprintf('Block %d of %d complete', block, Numblocks);
                    BlockNotesText2 = sprintf('Take a break and press the spacebar to move on');
                    BlockNotesBounds1 = Screen('TextBounds', window, BlockNotesText);
                    BlockNotesBounds2 = Screen('TextBounds', window, BlockNotesText2);
                    Screen('DrawText', window, BlockNotesText, ScreenXPixels*.5-BlockNotesBounds1(3)*.5, ScreenYPixels*.4-BlockNotesBounds1(4)*.5, black);
                    Screen('DrawText', window, BlockNotesText2, ScreenXPixels*.5-BlockNotesBounds2(3)*.5, ScreenYPixels*.6-BlockNotesBounds2(4)*.5, black);
                    Screen('Flip', window);

                    KbReleaseWait;

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

                KbReleaseWait;
                if screeningVisit == 1
                    block = Numblocks + 1;
                else
                    block = block + 1; % Move to next block
                end
                if block_target == 0 % Change target expression
                    block_target = 1;
                else
                    block_target = 0;
                end

            else
                % If practice, go to last block
                block = Numblocks + 1;
            end
        end
        %% End %%

        % Save the data to a csv file

        ShowCursor;
        ListenChar(0);
        Data = dataset(RespMat);

        if practice == 1 % If practice
            savename = sprintf('PRACTICE-%s-%s-%s-%s-ERT.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));

            cd(PracticeResults); % Cloud location where the file should be saved
            export(Data, 'file', savename, 'Delimiter', ',');
            cd(LocalResults); % Non-cloud location where the file should be saved
            export(Data, 'file', savename, 'Delimiter', ',');

        elseif practice == 0 % If main task
            savename = sprintf('%s-%s-%s-%s-ERT.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));

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

        if practice == 1
            DrawFormattedText(window, 'Practice finished! \n \n Ask the experimenter now if you have any questions \n \n Please note, there will be no feedback for the main task \n \n When ready, please press the spacebar to see the first instruction for the main task', 'center', 'center', black)
            Screen('Flip', window);
        elseif practice == 0
            DrawFormattedText(window, 'Task complete! \n \n Please let the experimenter know', 'center', 'center', black);
            Screen('Flip', window);
        else
        end

        % Wait for spacebar press
        while 1
            [~,~,keyCode] = KbCheck;
            if keyCode(KbName('space'))== 1
                break
            end
        end

        check_accuracy = 0; % Reset accuracy check
        block = 1; % Reset block counter
        trial = 1; % Reset trial counter
        blockTrial = 1; % Reset blocktrial counter
        HideCursor;
        ListenChar(2);
        practice = practice - 1; % Decrease practice count
        cd(ImageFolder); % Go to the image folder for main task

    end % End of 'while' practice loop

catch % Closes psyschtoolbox if there is an error and saves whatever data has been collected so far

    ShowCursor;
    ListenChar(0);
    Screen('CloseAll');

    if exist('RespMat', 'var') == 1 % If there are results to save

        RespMat{(height(RespMat)+1),1} = 'ERROR'; % Add a row

        Data = dataset(RespMat);
        savename = sprintf('ERROR-%s-%s-%s-%s-ERT.csv', subjectInitials, visitNumber, sessionNumber, string(datetime('now'),'ddMMyy-HHmm'));
        cd(CurrentFolder); % The location where the file should be saved
        export(Data, 'file', savename, 'Delimiter', ',');
        cd(CurrentFolder);

    end

    psychrethrow(psychlasterror); % Tells you the error in the command window

    Priority(0);
    sca;

end % End of try, catch,

if exist('path_folder', 'var') == 1
    cd(path_folder);
    clearvars -except indx window subjectInitials visitNumber sessionNumber practice_carry all_images_ERT stim_call PVTFolder fin_block path_folder;
else
    cd(CurrentFolder);
    ShowCursor;
    ListenChar(0)
    clear all
    sca;
    close all;
end

clc;