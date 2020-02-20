function itc_eyetrack_shapes(subjectID, runNum, shapecond, k_S, k_M)
% function for intertemporal choice task separated from eyetracker.
% Separation makes debugging easier. Uncomment %callib code so that study events will sync with eyetracker
% 
% This is an intertemporal choice task; where participants choose between an option to be received immediately,
% and an option to be received after a 120 day delay. Rewards from the two delays are represented by either a 
% square or a diamond around the dollar amount; the shape-to-reward relationship is counterbalanced between participants.
% 
% Amount ranges for each trial are between $21-35 (small) or 46-60 (medium) in 120 days. Immediate amounts are matched to 
% delayed based on hyperbolic parameters k_S and k_M which are previously determined to be best guess of participant's fit.
% Trials are either 'hard' such that the two options should be similarly valuable, or 'easy' such that either the immediate 
% or delayed option should have much higher value. Easy and hard trials occur in blocks of 6.
% this version finalized 2/19/2014

startsec = GetSecs;
% to send a message to iViewX, such as to indicate the image to be presented:
%calllib('iViewXAPI', 'iV_SendImageMessage', formatString(256, int8(sprintf('start MATLAB'))));

endsec = GetSecs;

ScreenNumber=max(Screen('Screens')); %use external monitor if it exists
%% set up stimuli
nTrials = 64;

delay = [0 120];

amtrangehigh=[46 60];
meanhigh=53;
% get 120 day delay amounts for high
while 1, delamtshigh=round(amtrangehigh(1)+(amtrangehigh(2)-amtrangehigh(1)).*rand((nTrials/2),1));
    if mean(delamtshigh)==meanhigh, break; end; end

amtrangelow=[21 35];
meanlow=28;
%get 120 day delay amounts for low
while 1, delamtslow=round(amtrangelow(1)+(amtrangelow(2)-amtrangelow(1)).*rand((nTrials/2),1));
    if mean(delamtslow)==meanlow, break; end; end


designlow = [];
designhigh = [];

%generate design matrix separately for low and high
for co = 1:2
    for coe = 1:2               
        for f = 1:2
            for p = [-1 1]
                designlow(end+1,:) = [co f p coe];
                designhigh(end+1,:) = [co f p coe];
            end
        end
    end
end

designlow = [designlow' designlow']';
designlow(:,end+1) = delamtslow;
designhigh = [designhigh' designhigh']';
designhigh(:,end+1) = delamtshigh;

% magnitude
designlow(:,end+1) = 1;
designhigh(:,end+1) = 2;

design1 = [designlow(designlow(:,1)==1,:)' designhigh(designhigh(:,1)==1,:)']';
design1(:,4)=0;
design2 = [designlow(designlow(:,1)==2,:)' designhigh(designhigh(:,1)==2,:)']';

design1 = [design1(randperm(size(design1,1)),:)']'; %randomize hard trials
design2 = [design2(randperm(size(design2,1)),:)']'; %randomize easy trials

blocks = mod(str2num(subjectID)+str2num(runNum),2);

if blocks == 1
    design = [design1(1:6,:)' design2(1:6,:)' design1(7:12,:)' design2(7:12,:)' design1(13:18,:)' design2(13:18,:)' design1(19:24,:)' design2(19:24,:)' design1(25:30,:)' design2(25:30,:)' design1(31:32,:)' design2(31:32,:)']';
elseif blocks == 0
    design = [design2(1:6,:)' design1(1:6,:)' design2(7:12,:)' design1(7:12,:)' design2(13:18,:)' design1(13:18,:)' design2(19:24,:)' design1(19:24,:)' design2(25:30,:)' design1(25:30,:)' design2(31:32,:)' design1(31:32,:)']';
end


frame = design(:,2);
cond = design(:,1);
post = design(:,3);
condeasy = design(:,4);
delamt = design(:,5);
magnitude = design(:,6);


%% colors
Black = [0 0 0];
White = [255 255 255];
Yellow=[255 255 0];
Red = [255 0 0];
darkRed = [127 0 0];
Gray = [127 127 127];
ScreenColor = Gray;
fontsize = 70;
rectSideLength = 300;
circleRadius = 2*rectSideLength/pi;
shapeWidth=10;

%% initiate screen
ScreenNumber=max(Screen('Screens')); %use external monitor if it exists
    
    if ScreenNumber==0 %need to use SkipSyncTests for retina macbook pro 
        Screen('Preference','SkipSyncTests',1);
    end

    doublebuffer=1;
    [w rect]=Screen('OpenWindow',ScreenNumber,ScreenColor);
    [xyc(1) xyc(2)]=RectCenter(rect);
    width=rect(3);
    height=rect(4);

    HideCursor;
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);% enable alpha blending with proper blend function for drawing of smoothed points

    %Screen('TextStyle',w,1); 
    %Screen('TextSize',w,55);
    %Screen('TextFont',w,'Times New Roman');
    %tasks='Wait for trigger';
    %do i wanna do this?
    %DrawFormattedText(w, tasks, 'center', 'center', Black);
    %Screen('Flip',w);    

    RespKey={'1','2','6','7'};


%% Save records 
if nargin<1, subjectID='ls'; end    
saveToFile ='Save';    
if nargin<2 
    saveToFile = questdlg('','Save Record?','Save','Display','None','Display');    
end

fun=mfilename; direc=fileparts(which(fun));
if strcmp(saveToFile,'None')
    fid=0;    
elseif strcmp(saveToFile,'Display')
    fid=1;    
else    
    if ~exist('fileName','var'), fileName='junk'; end    
    %behavioral file        
    behavFileName=sprintf('%s_shapesbehav_%s.rec',subjectID,runNum);
    %behavFileName=sprintf('output/%s_shapesbehav_%s.rec',subjectID,runNum);
        
    %behavFileName=fullfile(direc, fileName);    
    %makeCopy4existFile(fileName);    
    
    fid=fopen(behavFileName,'w+');
        
    %file for event info         
    eventFileName=sprintf('%s_shapesEvent_%s.rec',subjectID,runNum);        
    %eventFileName=sprintf('output/%s_shapesEvent_%s.rec',subjectID,runNum);        
    fidEvent=fopen(eventFileName,'w+');    
end


fixInterval = 2;
stimInterval = 2;
stat1 = [0 0];
stat2 = [0 0];
stat3 = [0 0];
stat4 = [0 0];

fprintf(fid,'Program: %s, condition %d\n',which(fun),shapecond);
fprintf(fid,'ClockRandSeed: %10.0f\n',ClockRandSeed); %if i do random
fprintf(fid,'Subject ID: %s\n',subjectID);
fprintf(fid,'Start: %s, %s\n',datestr(now,'ddd'),datestr(now));
fprintf(fid, '%s\n', 'trial condition magnitude frame1 frame2 iamount damount delayS delayL k choice RT');

fprintf(fidEvent,'Program: %s\n',which(fun));
fprintf(fidEvent,'ClockRandSeed: %10.0f\n',ClockRandSeed); %if i do random
fprintf(fidEvent,'Subject initials: %s\n',subjectID);


fprintf(fidEvent,'Start: %s, %s\n',datestr(now,'ddd'),datestr(now));
fprintf(fidEvent, '%s\n', 'trial event start end');


% to send a message to iViewX, such as to indicate the image to be presented:
%calllib('iViewXAPI', 'iV_SendImageMessage', formatString(256, int8(sprintf('begin experiment'))));    

    %% loop for running trials
    for i = 1:nTrials
        Priority(MaxPriority(w));
        startt=endsec; %endsec=endsec+trialDuration;
                
        %trial k, but this can get changed
        if magnitude(i)==1
            k_trial=k_S;
        elseif magnitude(i)==2
            k_trial=k_M;
        end
        
        %LL amount
        amountL = delamt(i);
        
        %for easy trials, trial k is either order of magnitude more or less
        %than original trial k
        if condeasy(i) == 1 %should choose LL = larger k
            k_trial = k_trial*10;
        elseif condeasy(i) == 2 %should choose SS = smaller k
            k_trial = k_trial*0.1;
        end
        
        %SS amount
        amountS = round(amountL*1/(1+k_trial*120));
        if amountS == 0
            amountS = 1;
        end
        
        %recalculate trial k
        k_trial = (amountL - amountS)/(120*amountS);
           

        % fixation
        Screen('TextStyle',w,1); 
        Screen('TextSize',w,fontsize);
        Screen('TextFont',w,'Times New Roman');
        DrawFormattedText(w, '$$$', 'center', 'center', Black);
        %drawFixationCross(w,rect,60,Black,10);
        drawCircle(w,[width/2 height/2], circleRadius, Black, shapeWidth);
        t0=Screen('Flip',w);
        % to send a message to iViewX, such as to indicate the image to be presented:
        %calllib('iViewXAPI', 'iV_SendImageMessage', formatString(256, int8(sprintf('fixation'))));
        startevent=t0-startsec;
        WaitSecs(fixInterval);
 
        % default(?) option
        Screen('TextStyle',w,1); 
        Screen('TextSize',w,fontsize);
        Screen('TextFont',w,'Times New Roman');
        if frame(i) == 1 %SU
            if shapecond==1
                drawSquare(w,[width/2 height/2],rectSideLength,Black, shapeWidth);
            elseif shapecond==2
                drawDiamond(w,[width/2 height/2],rectSideLength,Black, shapeWidth);
            end
            text=sprintf('$%g',amountL);
        elseif frame(i) == 2
            if shapecond==1
                drawDiamond(w,[width/2 height/2],rectSideLength,Black, shapeWidth);
            elseif shapecond==2
                drawSquare(w,[width/2 height/2],rectSideLength,Black, shapeWidth);
            end
            text=sprintf('$%g',amountS);
        end        
        
        DrawFormattedText(w, text, 'center', 'center', Black);


        t0=Screen('Flip',w);
        % to send a message to iViewX, such as to indicate the image to be presented:
        %calllib('iViewXAPI', 'iV_SendImageMessage', formatString(256, int8(sprintf('%s',text))));
        fprintf(fidEvent,'%d %d %5.4f %5.4f\n',i,0,startevent,t0-startsec); %don't enter data until fixation has ended
        startevent = t0-startsec;
        WaitSecs(stimInterval);
        
        % fixation
        %drawFixationCross(w,rect,60,Black,10);
        drawCircle(w, [width*3/4 height/2], circleRadius, Black, shapeWidth);
        drawCircle(w, [width/4 height/2], circleRadius, Black, shapeWidth);
        Screen('TextStyle',w,1); 
        Screen('TextSize',w,fontsize);
        Screen('TextFont',w,'Times New Roman');
        DrawFormattedText(w, '$$$', width*3/4-fontsize, 'center', Black);
        DrawFormattedText(w, '$$$', width/4-fontsize, 'center', Black);
        Screen(w,'DrawLine', Black, xyc(1), xyc(2)-100, xyc(1), xyc(2)+100);
        t0 = Screen('Flip',w);
        % to send a message to iViewX, such as to indicate the image to be presented:
        %calllib('iViewXAPI', 'iV_SendImageMessage', formatString(256, int8(sprintf('fixation'))));
        fprintf(fidEvent,'%d %d %5.4f %5.4f\n',i,1,startevent,t0-startsec); %don't enter data until next one has flipped
        startevent = t0-startsec;
        WaitSecs(fixInterval);


        %% choice screen    
        Screen('TextStyle',w,1); 
        Screen('TextSize',w,fontsize);
        Screen('TextFont',w,'Times New Roman');
        if post(i)>0
            if shapecond==1
                drawDiamond(w,[width*3/4 height/2],rectSideLength, Black, shapeWidth);
            elseif shapecond==2
                drawSquare(w,[width*3/4 height/2],rectSideLength,Black, shapeWidth);
            end
            text=sprintf('$%g',amountS);
        elseif post(i)<0
            if shapecond==1
                drawSquare(w,[width*3/4 height/2],rectSideLength, Black, shapeWidth);
            elseif shapecond==2
                drawDiamond(w,[width*3/4 height/2],rectSideLength, Black, shapeWidth);
            end                
            text=sprintf('$%g',amountL);
        end
        DrawFormattedText(w, text, width*3/4-fontsize, 'center', Black);
    
        Screen(w,'DrawLine', Black, xyc(1), xyc(2)-100, xyc(1), xyc(2)+100);
    
        Screen('TextStyle',w,1); 
        Screen('TextSize',w,fontsize);
        Screen('TextFont',w,'Times New Roman');
        if post(i)>0
            if shapecond==1
                drawSquare(w,[width/4 height/2],rectSideLength, Black, shapeWidth);
            elseif shapecond==2
                drawDiamond(w,[width/4 height/2],rectSideLength, Black, shapeWidth);
            end
            text=sprintf('$%g',amountL);
        elseif post(i)<0
            if shapecond==1
                drawDiamond(w,[width/4 height/2],rectSideLength, Black, shapeWidth);
            elseif shapecond==2
                drawSquare(w,[width/4 height/2],rectSideLength, Black, shapeWidth);
            end
            text=sprintf('$%g',amountS);
        end
        %DrawFormattedText(w, text, [width/2-350], 'center', Black);
        DrawFormattedText(w, text, width/4-fontsize, 'center', Black);
 

        t0=Screen('Flip',w,[],1);
        % to send a message to iViewX, such as to indicate the image to be presented:
        %calllib('iViewXAPI', 'iV_SendImageMessage', formatString(256, int8(sprintf('choice'))));
        fprintf(fidEvent,'%d %d %5.4f %5.4f\n',i,2,startevent,t0-startsec); %don't enter data until fixation has ended
        startevent = t0-startsec;

        [key, rt]=WaitTill(t0+16,RespKey,1);
    
        if ~isempty(key) 
            RT=rt-t0;
            fprintf(fidEvent,'%d %d %5.4f %5.4f\n',i,3,startevent,rt-startsec);

            if str2num(key)<5 && str2num(key)~=0 %choose left
                Screen('TextStyle',w,1); 
                Screen('TextSize',w,fontsize);
                Screen('TextFont',w,'Times New Roman');
                if post(i)>0
                    text=sprintf('$%g',amountL);
                    choice = 1;
                elseif post(i)<0
                    text=sprintf('$%g',amountS);
                    choice = 0;
                end
                %DrawFormattedText(w, text, [width/2-350], 'center', Red);
                DrawFormattedText(w, text, width/4-fontsize , 'center', darkRed);

            elseif str2num(key)>5 && str2num(key)~=0 %choose right
                Screen('TextStyle',w,1);
                Screen('TextSize',w,fontsize);
                Screen('TextFont',w,'Times New Roman');            
                if post(i)>0
                    text=sprintf('$%g',amountS);
                    choice = 0;
                elseif post(i)<0
                    text=sprintf('$%g',amountL);
                    choice = 1;
                end
                DrawFormattedText(w, text, width*3/4-fontsize, 'center', darkRed);            
            end            
        end
    
        t0=Screen('Flip',w,rt);
        % to send a message to iViewX, such as to indicate the image to be presented:
        %calllib('iViewXAPI', 'iV_SendImageMessage', formatString(256, int8(sprintf('%s', text))));
        
        WaitSecs(stimInterval);
        if cond(i)==1
            if magnitude(i)==1
                stat1(choice+1) = stat1(choice+1)+1;
            elseif magnitude(i)==2
                stat2(choice+1) = stat2(choice+1)+1;
            end
        elseif cond(i)==2
            if condeasy(i) == 1
                stat3(choice+1) = stat3(choice+1)+1;
            elseif condeasy(i)==2
                stat4(choice+1) = stat4(choice+1)+1;
            end
        end
    
        fprintf(fid,'%d %d %d %d %d %d %d %d %d %5.4f %d %5.4f\n',i,cond(i), magnitude(i),frame(i),post(i), amountS, amountL, 0, 120, k_trial, choice, RT);
        t=GetSecs;
        fprintf(fidEvent,'%d %d %5.4f %5.4f\n',i,4,t0-startsec,t-startsec);
        endsec=GetSecs;
%% close out
    end
    
    fprintf('Hard Choices small\nSure Risky\n');
    fprintf('%d\t%d\n',stat1);
    fprintf('Hard Choices medium\nSure Risky\n');
    fprintf('%d\t%d\n',stat2);
    fprintf('Easy Choices: Choose Risky\nSure Risky\n');
    fprintf('%d\t%d\n',stat3);
    fprintf('Easy Choices: Choose Sure\nSure Risky\n');
    fprintf('%d\t%d\n',stat4);
    
    fclose('all');
    Screen('TextStyle',w,1); 
    Screen('TextSize',w,50);
    Screen('TextFont',w,'Times New Roman');
    text=sprintf('Thank you');
    DrawFormattedText(w, text, 'center', 'center', Black);
    Screen('Flip',w,1);
    WaitSecs(2);
    Screen('CloseAll');
end

    function drawSquare (wPtr, center, sideLength, color, width)
    %draws a square in specified place, with specified length
    Screen('FrameRect',wPtr, color, [center(1)-sideLength/2 center(2)-sideLength/2 center(1)+sideLength/2 center(2)+sideLength/2], width);
    end
    
    function drawDiamond (wPtr, center, sideLength, color, width)
    %draws a sqare at 45 degree angle, with specified length
    squareDiag = sideLength/sqrt(2);
    diamondLines = [-squareDiag, 0; 0, squareDiag; 0, squareDiag; squareDiag, 0; squareDiag, 0; 0 -squareDiag; 0 -squareDiag; -squareDiag, 0]';
    Screen('DrawLines', wPtr, diamondLines, width, color, center);
    end
    
    function drawCircle (wPtr, center, radius, color, width)
        % draws a circle in specified place, with specified length
    Screen('FrameOval', wPtr, color, [center(1)-radius center(2)-radius center(1)+radius center(2)+radius], width);
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