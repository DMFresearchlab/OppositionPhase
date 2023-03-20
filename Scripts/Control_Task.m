%Control task
% Coded by Ludovico Saint Amour di Chanaz, version of 12 July 2018 and 
%corrected by Katia Lehongre. 

%Core
close all ;
clearvars;
rng('shuffle')
commandwindow;

WhichPC = 'epimicro'; %'Ludovico'; %'Ludovico' %path to script: 'C:\manips\TaskDesign'

ArduinoPort = 'COM3'; %COM3 Change to '' to activate dummy mode if nothing is connected
%and watch into the connected devices to see on what port the arduino is
%connected

%Name Folders for later Use and address of the Home folder in function of
%the PC
switch WhichPC
    case 'Ludovico'
        Home = 'C:\Users\Ludovico\Documents\MATLAB\TaskDesign_Salpe';
        addpath('C:\Users\Ludovico\Documents\MATLAB\TaskDesign_Salpe\ArduinoPort')
    case 'epimicro'
        Home = 'C:\manips\TaskDesign';
        addpath('C:\MATLAB_toolboxes\ArduinoPort')
end
CloseArduinoPort
Fantasy      = 'FantasyImages';
Task         = 'ImagesTask';
ResultFolder = 'Results';

OpenArduinoPort (ArduinoPort);

%Setup PTB with default settings
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 2);

cd(Home)
%Define number of subject
TotalSubj   = dir('Results/Subj*'); %dir(fullfile('Results','Subj*'))
Subject     = length(TotalSubj)+1;

%Set the keyboard info
spaceKey    = KbName('space');
escapeKey   = KbName('ESCAPE');
key1        = KbName('1');
key2        = KbName('2');
key3        = KbName('3');
key4        = KbName('4');

esc      =0 ;
Triggers =[];
%-------------------------------------------------------------------------
%                               SCREEN SETUP
%-------------------------------------------------------------------------


screenNumber = max(Screen('Screens'));
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white/2;

%open the screen
[window, windowRect] = PsychImaging('OpenWindow',...
    screenNumber, grey, [], 32, 2);
Screen('Flip', window);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xcenter, ycenter] = RectCenter(windowRect);
%frame duration
ifi = Screen ('GetFlipInterval', window);

%Set text size
Screen('TextSize', window, 60);

%Query the maximum priority level
topPriorityLevel= MaxPriority(window);

%Centre coordinates fo the window
[xCenter, yCenter] = RectCenter(windowRect);

%Set the Blend function for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%-------------------------------------------------------------------------
%                             TIMING INFORMATION
%-------------------------------------------------------------------------

%Interstimulus interval time in seconds and frames
isiTimeSecs = 1;
isiTimeFrames = round(isiTimeSecs / ifi);

%Numer of frames to wait before re-drawing
waitframes = 1;

%How long should the image stay up during flicker in time and frames
imageSecs = 1;
imageFrames = round(imageSecs / ifi);

%Duration (in seconds) of the blanks between the images during flicker
blankSecs = 0.25;
blankFrames = round(blankSecs / ifi);

%Make a vector which shows what we do on each frame
presVector = [ones(1, imageFrames) zeros(1, blankFrames)...
    ones(1, imageFrames) .*2 zeros(1, blankFrames)];
numPresLoopFrames = length(presVector);

%-------------------------------------------------------------------------
%                          Define Fixation Cross
%-------------------------------------------------------------------------

% Screen Y fraction for fixation cross
crossFrac = 0.0167;

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = windowRect(4) * crossFrac;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 4;


%-------------------------------------------------------------------------
%                       Get the control task images
%-------------------------------------------------------------------------
fantrand = randperm(50)';
FantasyImages={};
    FantasyFolder = fullfile(Home, Fantasy);
    Files = fullfile(FantasyFolder, sprintf('*.jpg'));
    fantasy = dir(Files);
for k=1:length(fantrand)
    fantasyfilename = fullfile(FantasyFolder, fantasy(fantrand(k)).name);
    FantasyImages = [FantasyImages, fantasyfilename];
end

%--------------------------------------------------------------------------
%                                   TASK
%--------------------------------------------------------------------------
    Triggers = [Triggers; [120 GetSecs]];
    SendArduinoTrigger(120);
    Triggers = [Triggers; [29 GetSecs]];
    SendArduinoTrigger(29);
    Triggers = [Triggers; [4 GetSecs]];
    SendArduinoTrigger(4);
for k=1:40
    DrawFormattedText (window,...
        'New Imagination! Imagine a new sitaution!',...
        'center', 'center', black);
    Screen('Flip', window);
    Triggers = [Triggers; [5 GetSecs]];
    SendArduinoTrigger(5);
    WaitSecs(1);
    
    Screen('FillRect', window, grey);
    Screen('DrawLines', window, allCoords, lineWidthPix, white,...
        [xCenter yCenter], 2);
    Screen ('Flip', window);
    Triggers = [Triggers; [21 GetSecs]];
    SendArduinoTrigger(21);
    WaitSecs(1);
        
    ImageLocation = (FantasyImages{k});
    Image = imread(ImageLocation);
    %Turn image into a texture
    imageTexture = Screen('MakeTexture', window, Image);
   
    %resize the image
    [s1, s2, s3]= size(Image);
    aspectratio = s2/s1;
    imageHeight = screenYpixels;
    imageWidth = imageHeight * aspectratio;
    theRect = [0 0 imageWidth imageHeight];
    dstRect = CenterRectOnPointd(theRect, xcenter, ycenter);
        
    %Draw the image to the screen
    Screen('DrawTextures', window, imageTexture, [], dstRect);
    Screen('Flip', window);
    Triggers = [Triggers; [22 GetSecs]];
    SendArduinoTrigger(22);
    targetduration = 8;
    exittime = GetSecs + targetduration;
    while GetSecs < exittime
        [keyIsDown, secs, KeyCode] = KbCheck;
        if KeyCode (escapeKey)
            esc=1;
            sca;
        end
    end
    
    if k==20
        DrawFormattedText(window, 'Press Space to Continue!',...
            'center', 'center', black);
        Screen('Flip', window);
        Triggers = [Triggers; [100 GetSecs]];
        SendArduinoTrigger(100);
        KbWait;
    end
    
end    
 BehavResults.Control = FantasyImages;
 BehavResults.TriggerCont(:,1) = Triggers(:,1);
 BehavResults.TriggerCont(:,2) = Triggers(:,2);

 
 
filename = sprintf('BehavSubject_%d.mat', Subject);
Day1BehavResults = fullfile (Home, ResultFolder, foldersubj, filename);
%sprintf('%s%sSubject_%d/BehavSubject_%d.mat', Home, ResultFolder, Subject, Subject);
load (Day1BehavResults);


filename = sprintf('BehavSubject_%d.mat', Subject);
path2save = fullfile(Results, filename);
save(path2save, 'BehavResults');

path2sqve = fullfile(Results, sprintf('logfile_control'));
save(path2sqve);