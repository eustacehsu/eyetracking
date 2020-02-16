function emoInduction(subjectID,condition)
% psychtoolbox task
% plays audio and displays images
% images are displayed in black and white. They are luminance-matched using the 
% SHINE toolbox.
% Eustace Hsu, 2015

startsec = GetSecs;
% to send a message to iViewX, such as to indicate the image to be presented:
%calllib('iViewXAPI', 'iV_SendImageMessage', 'start MATLAB');

endsec = GetSecs;

%% colors
Black = [0 0 0];
White = [255 255 255];
Yellow=[255 255 0];
Red = [255 0 0];
darkRed = [127 0 0];
Gray = [127 127 127];
ScreenColor = Gray;
darkGreen = [0 127 0];
fontsize = 70;

%%%%%%%initialize the sound driver, this may be unnecessary%%%%%%
InitializePsychSound;


ScreenNumber=max(Screen('Screens')); %use external monitor if it exists
    
if ScreenNumber==0 %need to use SkipSyncTests for retina macbook pro 
    Screen('Preference','SkipSyncTests',1);
end

%% Save Records
imgFileName=sprintf('%s_emo_images.rec',subjectID);    
fidimg=fopen(imgFileName,'w+');
fprintf(fidimg,'Program: %s\n',which(mfilename));
fprintf(fidimg,'ClockRandSeed: %10.0f\n',ClockRandSeed); %if i do random
fprintf(fidimg,'Subject ID: %s\n',subjectID);
fprintf(fidimg,'Start: %s, %s\n',datestr(now,'ddd'),datestr(now));
fprintf(fidimg, '%s\n', 'trial start end image');

masterFileName=sprintf('%s_emo_event.rec',subjectID);    
fidEvent=fopen(masterFileName,'w+');
fprintf(fidEvent,'Program: %s\n',which(mfilename));
fprintf(fidEvent,'Subject ID: %s\n',subjectID);
fprintf(fidEvent,'Start: %s, %s\n',datestr(now,'ddd'),datestr(now));
fprintf(fidEvent, '%s\n', 'event start end');

%doublebuffer=1;
%[w, rect]=Screen('OpenWindow',ScreenNumber,ScreenColor);
%[xyc(1), xyc(2)]=RectCenter(rect);
%width=rect(3);
%height=rect(4);

%HideCursor;
%Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);% enable alpha blending with proper blend function for drawing of smoothed points

    
imgInterval = 5;

if condition == 1
    dirimg = 'IAPS_pos';
    dirAud = 'audio_pos';
end
imgdir = dir(dirimg);
dirIndex = [imgdir.isdir];
imgFiles = {imgdir(~dirIndex).name}';

audiodir = dir(dirAud);
adirIndex = [audiodir.isdir];
audFiles = {audiodir(~adirIndex).name}';
audPath = strcat(dirAud,'/',char(audFiles(1)));

%imgFiles = Shuffle(imgFiles);
nImg = size(imgFiles,1);
newOrder = Shuffle(1:nImg);
%imgFiles = imgFiles{newOrder};
colorImages = cell(nImg,1);

for i = 1:nImg
    iapsImage = strcat(dirimg,'/',char(imgFiles(i)));
    colorImages{i} = imread(iapsImage);
    %readImage = imread(iapsImage);
end


SHINEimages = lumMatch(colorImages);
meanLuminance = mean(mean(SHINEimages{1}));
newGray = [meanLuminance meanLuminance meanLuminance];
ScreenColor = newGray;
doublebuffer=1;
[w, rect]=Screen('OpenWindow',ScreenNumber,ScreenColor);
[xyc(1), xyc(2)]=RectCenter(rect);
width=rect(3);
height=rect(4);


HideCursor;
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);% enable alpha blending with proper blend function for drawing of smoothed points

drawFixationCross(w,rect,60,Black,5);
tFix=Screen('Flip',w);
% to send a message to iViewX, such as to indicate the image to be presented:
%calllib('iViewXAPI', 'iV_SendImageMessage', 'fixation');


WaitSecs(30);

    [y, freq] = audioread(audPath);
    audiodata = y';
    nrchannels = size(audiodata,1); % Number of rows == number of channels.
    pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
    PsychPortAudio('FillBuffer', pahandle, audiodata);

    % to send a message to iViewX, such as to indicate the image to be presented:
    %calllib('iViewXAPI', 'iV_SendImageMessage', 'audio');
    tAudio = PsychPortAudio('Start', pahandle, 1,[],1); %only because 180 is length of piece
    fprintf(fidEvent,'0 %5.4f %5.4f\n',tFix-startsec,tAudio-startsec);
    WaitSecs(180);
    tAudioEnd=GetSecs;
    WaitSecs(20);
    fprintf(fidEvent,'1 %5.4f %5.4f\n',tAudio-startsec,tAudioEnd-startsec);
trial = 1;
tImgStart = GetSecs;
%for i = 1:nImg
for i = newOrder
    imagePtr = Screen('MakeTexture',w,SHINEimages{i});
    Screen('DrawTexture',w,imagePtr);
    tImg = Screen('Flip',w);
    % to send a message to iViewX, such as to indicate the image to be presented:
    %calllib('iViewXAPI', 'iV_SendImageMessage', fprintf('Image %s',char(imgFiles(i)));

    WaitSecs(imgInterval);
    % fixation
    drawFixationCross(w,rect,60,Black,5);
    tFix=Screen('Flip',w);
    fprintf(fidimg,'%d %5.4f %5.4f %s\n',trial,tImg-startsec,tFix-startsec,char(imgFiles(i)));
    % to send a message to iViewX, such as to indicate the image to be presented:
    %calllib('iViewXAPI', 'iV_SendImageMessage', 'fixation');

    WaitSecs(2);
    
    trial = trial+1;
end
fprintf(fidEvent,'2 %5.4f %5.4f\n',tImgStart-startsec,tFix-startsec);
WaitSecs(30);
fprintf(fidEvent,'3 %5.4f %5.4f\n',tFix-startsec,GetSecs-startsec);
    %[y, freq] = audioread(audPath);
    %audiodata = y';
    %nrchannels = size(audiodata,1); % Number of rows == number of channels.
    %pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
    %PsychPortAudio('FillBuffer', pahandle, audiodata);


ShowCursor;
fclose('all')
Screen('CloseAll');
end
    
   function drawFixationCross(wPtr,rect,crossLength,crossColor,crossWidth)
        % draws fixation cross at center of screen
        % probably written by Jonas Kaplan
        
        % Set Start and end points of lines
        crossLines = [-crossLength, 0; crossLength, 0; 0, -crossLength; 0, crossLength]';
        
        %define center of Screen
        xCenter = rect(3)/2;
        yCenter = rect(4)/2;
        
        %Draw the lines
        Screen('DrawLines',wPtr,crossLines,crossWidth,crossColor,[xCenter,yCenter]);
    end

