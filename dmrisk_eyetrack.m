function dmrisk_eyetrack(subjectID,runNum,ra_S,ra_M)
% function for DM under risk task. When done in eyetracker, command is
% passed in from other function. - Eustace Hsu
% coded to be compatible with SMI eyetracker.
% Takes in 4 inputs:
% subjectID - integer, participant ID
% runNum - run number (1,2)
% ra_S, ra_M - previously obtained Green-Myerson probability discounting parameters for small and medium reward magnitudes.
%   1 is risk-neutral. 
%
% this design proceeds in condition blocks of 6 -- 6 hard trials followed by 6 easy trials (always 3 s, 3 m).
%
% outputs 2 files
%   ##_#behav.rec - behavioral file, each row represents one trial of the task
%   ##_#event.rec - event file, each row gives the timing information of one event of the trial
% 
% 9/7/2014 - change so that it can adjust both parameters after every block

startsec = GetSecs;
% to send a message to iViewX, such as to indicate the image to be presented:
%calllib('iViewXAPI', 'iV_SendImageMessage', 'start MATLAB');

endsec = GetSecs;

ScreenNumber=max(Screen('Screens')); %use external monitor if it exists
%% set up stimuli
nTrials=48; %changing to 48 may be good.

%risk = .5;
lriskrange2=[25 75]; % the mean is 50
mean2=50;
%while 1, lrisk2=round(lriskrange2(1)+(lriskrange2(2)-lriskrange2(1)).*rand(nTrials,1));
%    if mean(lrisk2)==mean2, break;end; end

lrisk2 = [1/4 .3 1/3 .35 .4 .45 .55 .6 .65 2/3 .7 .75];

lrisk=round(100*[Shuffle(lrisk2) Shuffle(lrisk2) Shuffle(lrisk2) Shuffle(lrisk2)])*0.01; %assumes 48 trials

amtrangehigh=[46 60];
meanhigh=53;
% get risky amounts for high
while 1, riskamtshigh=round(amtrangehigh(1)+(amtrangehigh(2)-amtrangehigh(1)).*rand((nTrials/2),1));
    if mean(riskamtshigh)==meanhigh, break; end; end

amtrangelow=[21 35];
meanlow=28;
%get risky amounts for low
while 1, riskamtslow=round(amtrangelow(1)+(amtrangelow(2)-amtrangelow(1)).*rand((nTrials/2),1));
    if mean(riskamtslow)==meanlow, break; end; end

designlow = [];
designhigh = [];

%generate design matrix separately for low and high
for co = 1:2
    for coe = 1:2               
        for p = [-1 1]
            designlow(end+1,:) = [co p coe];
            designhigh(end+1,:) = [co p coe];
        end
    end
end

designlow = [designlow' designlow' designlow']';
designlow(:,end+1) = riskamtslow;
designhigh = [designhigh' designhigh' designhigh']';
designhigh(:,end+1) = riskamtshigh;
% magnitude
designlow(:,end+1) = 1;
designhigh(:,end+1) = 2;

designlow = [designlow(randperm(size(designlow,1)),:)']'; %randomize low trials
designhigh = [designhigh(randperm(size(designhigh,1)),:)']'; %randomize high trials

% Hard
designlow1 = designlow(designlow(:,1)==1,:);
designhigh1 = designhigh(designhigh(:,1)==1,:);
% design1 = [designlow(designlow(:,1)==1,:)' designhigh(designhigh(:,1)==1,:)']';
designlow1(:,3)=0;
designhigh1(:,3)=0;
% Easy
designlow2 = designlow(designlow(:,1)==2,:);
designhigh2 = designhigh(designhigh(:,1)==2,:);
%design2 = [designlow(designlow(:,1)==2,:)' designhigh(designhigh(:,1)==2,:)']';

%design1 = [design1(randperm(size(design1,1)),:)']'; %randomize hard trials
%design2 = [design2(randperm(size(design2,1)),:)']'; %randomize easy trials

blocks = mod(str2num(subjectID)+str2num(runNum),2);

design = zeros(nTrials,5); %instantiate design with 5 columns
for bl = 0:(nTrials/12-1)
    block1 = [designlow1(bl*3+(1:3),:)' designhigh1(bl*3+(1:3),:)']';
    block1 = [block1(randperm(size(block1,1)),:)']';
    block2 = [designlow2(bl*3+(1:3),:)' designhigh2(bl*3+(1:3),:)']';
    block2 = [block2(randperm(size(block2,1)),:)']';
    if blocks == 1
        design(bl*12+(1:12),:) = [block1' block2']';
    %design = [design1(1:4,:)' design2(1:4,:)' design1(5:8,:)' design2(5:8,:)' design1(9:12,:)' design2(9:12,:)' design1(13:16,:)' design2(13:16,:)']';
    elseif blocks == 0
        design(bl*12+(1:12),:) = [block2' block1']';
    %design = [design2(1:4,:)' design1(1:4,:)' design2(5:8,:)' design1(5:8,:)' design2(9:12,:)' design1(9:12,:)' design2(13:16,:)' design1(13:16,:)']';
    end
end
design(:,end+1) = lrisk;

cond = design(:,1);
post = design(:,2);
condeasy = design(:,3);
riskamts = design(:,4);
magnitude = design(:,5);
risk = design(:,6);

%% colors
Black = [0 0 0];
White = [255 255 255];
Yellow=[255 255 0];
Red = [255 0 0];
darkRed = [127 0 0];
Gray = [127 127 127];
ScreenColor = Gray;
fontsize = 40;
%fontsize = 55;
%rectSideLength = 300;
%circleRadius = sqrt((rectSideLength^2)/pi);

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

    Screen('TextStyle',w,1); 
    Screen('TextSize',w,55);
    Screen('TextFont',w,'Times New Roman');
    tasks='Wait for trigger';
    %do i wanna do this?
    DrawFormattedText(w, tasks, 'center', 'center', Black);
    Screen('Flip',w);    

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
    behavFileName=sprintf('%s_riskbehav%s.rec',subjectID,runNum);
        
    %behavFileName=fullfile(direc, fileName);    
    %makeCopy4existFile(fileName);    
    
    fid=fopen(behavFileName,'w+');
        
    %file for event info         
    eventFileName=sprintf('%s_riskEvent%s.rec',subjectID,runNum);        
    fidEvent=fopen(eventFileName,'w+');    
end


fixInterval = 2;
stimInterval = 2;
stat1 = [0 0];
stat2 = [0 0];
stat3 = [0 0];
stat4 = [0 0];

fprintf(fid,'Program: %s\n',which(fun));
fprintf(fid,'ClockRandSeed: %10.0f\n',ClockRandSeed); %if i do random
fprintf(fid,'Subject ID: %s\n',subjectID);
fprintf(fid,'Start: %s, %s\n',datestr(now,'ddd'),datestr(now));
fprintf(fid, '%s\n', 'trial condition magnitude frame sureamount riskamount param choice RT');

fprintf(fidEvent,'Program: %s\n',which(fun));
fprintf(fidEvent,'ClockRandSeed: %10.0f\n',ClockRandSeed); %if i do random
fprintf(fidEvent,'Subject initials: %s\n',subjectID);


fprintf(fidEvent,'Start: %s, %s\n',datestr(now,'ddd'),datestr(now));
fprintf(fidEvent, '%s\n', 'trial event start end');


% to send a message to iViewX, such as to indicate the image to be presented:
%calllib('iViewXAPI', 'iV_SendImageMessage', 'begin experiment');    

%% Save records 
if nargin<1, subjectID='ls'; end    
saveToFile ='Save';    
%if nargin<2 
%    saveToFile = questdlg('','Save Record?','Save','Display','None','Display');    
%end

fun=mfilename; direc=fileparts(which(fun));
if strcmp(saveToFile,'None')
    fid=0;    
elseif strcmp(saveToFile,'Display')
    fid=1;    
else    
    if ~exist('fileName','var'), fileName='junk'; end    
    %behavioral file        
    behavFileName=sprintf('output/%s_riskBehav%s.rec',subjectID,runNum);
        
    %behavFileName=fullfile(direc, fileName);    
    %makeCopy4existFile(fileName);    
    
    fid=fopen(behavFileName,'w+');
        
    %file for event info         
    eventFileName=sprintf('output/%s_riskEvent%s.rec',subjectID,runNum);        
    fidEvent=fopen(eventFileName,'w+');    
end


fixInterval = 3;
stimInterval = 2;
stat1 = [0 0];
stat2 = [0 0];
stat3 = [0 0];
stat4 = [0 0];

fprintf(fid,'Program: %s\n',which(fun));
fprintf(fid,'ClockRandSeed: %10.0f\n',ClockRandSeed); %if i do random
fprintf(fid,'Subject ID: %s\n',subjectID);
fprintf(fid,'Start: %s, %s\n',datestr(now,'ddd'),datestr(now));
fprintf(fid, '%s\n', 'trial condition magnitude frame sureamount riskamount risk theta choice RT');

fprintf(fidEvent,'Program: %s\n',which(fun));
fprintf(fidEvent,'ClockRandSeed: %10.0f\n',ClockRandSeed); %if i do random
fprintf(fidEvent,'Subject initials: %s\n',subjectID);

fprintf(fidEvent,'Start: %s, %s\n',datestr(now,'ddd'),datestr(now));
fprintf(fidEvent, '%s\n', 'trial event start end');

% to send a message to iViewX, such as to indicate the image to be presented:
%calllib('iViewXAPI', 'iV_SendImageMessage', 'begin experiment');    

    %% loop for running trials
    for i = 1:nTrials
        Priority(MaxPriority(w));
        startt=endsec; %endsec=endsec+trialDuration;
        
        if mod(i,6) == 1 
            SchLL = 0;
            MchLL = 0;
        end
        
        %trial risk aversion param, but this can get changed
        if magnitude(i)==1
            ra_trial=ra_S;
        elseif magnitude(i)==2
            ra_trial=ra_M;
        end
        
        %risky amount
        amountL = riskamts(i);
        
        %Rachlin's theta is amount of risk attached to gamble
        theta=(1-risk(i))/risk(i); 
        
        %sure amount, Rachlin's formula is similar to hyperbolic
        amountS = round(amountL/(1+ra_trial*theta));

        %for easy trials, trial k is either order of magnitude more or less
        %than original trial k
        if condeasy(i) == 1 %should choose risky = risk has higher EV
            ra_trial = ra_trial*5;
            %recalculate sure amount, Rachlin's formula is similar to hyperbolic
            amountS = round(amountL/(1+ra_trial*theta));
        elseif condeasy(i) == 2 %should choose certain, risk has lower EV  
            %NOW recalculate ra param of trial
            ra_trial = ra_trial*0.2;        
            %redo amountL
            amountL = round(amountS*(1+ra_trial*theta));
            if amountS==amountL
                amountL = amountS + 1;
            end
        end

        
        if amountS == 0
            amountS = 1;
        end
        
        %recalculate trial k
        ra_trial = (amountL - amountS)/(theta*amountS);
           

        % fixation
        drawFixationCross(w,rect,60,Black,10);
        t0=Screen('Flip',w);
        % to send a message to iViewX, such as to indicate the image to be presented:
        %calllib('iViewXAPI', 'iV_SendImageMessage', 'fixation');
        startevent=t0-startsec;
        WaitSecs(fixInterval);

        %% choice screen    
        Screen('TextStyle',w,1); 
        Screen('TextSize',w,fontsize);
        Screen('TextFont',w,'Times New Roman');
        if post(i)>0
            text=sprintf('100%% chance of $%g',amountS);
        elseif post(i)<0
            text=sprintf('%g%% chance of $%g',risk(i)*100, amountL);
        end
        DrawFormattedText(w, text, width/2+150, 'center', Black);
    
        Screen(w,'DrawLine', Black, xyc(1), xyc(2)-100, xyc(1), xyc(2)+100);
    
        Screen('TextStyle',w,1); 
        Screen('TextSize',w,fontsize);
        Screen('TextFont',w,'Times New Roman');
        if post(i)>0
            text=sprintf('%g%% chance of $%g',risk(i)*100, amountL);
        elseif post(i)<0
            text=sprintf('100%% chance of $%g', amountS);
        end
        %DrawFormattedText(w, text, [width/2-350], 'center', Black);
        DrawFormattedText(w, text, 150, 'center', Black);
 
        t0=Screen('Flip',w,[],1);
        % to send a message to iViewX, such as to indicate the image to be presented:
        %calllib('iViewXAPI', 'iV_SendImageMessage', 'choice');
        fprintf(fidEvent,'%d %d %5.4f %5.4f\n',i,0,startevent,t0-startsec); %don't enter data until fixation has ended
        startevent = t0-startsec;

        [key, rt]=WaitTill(t0+16,RespKey,1);
    
        if ~isempty(key) 
            RT=rt-t0;
            fprintf(fidEvent,'%d %d %5.4f %5.4f\n',i,1,startevent,rt-startsec);

            if str2num(key)<5 && str2num(key)~=0 %choose left
                Screen('TextStyle',w,1); 
                Screen('TextSize',w,fontsize);
                Screen('TextFont',w,'Times New Roman');
                if post(i)>0
                    text=sprintf('%g%% chance of $%g', risk(i)*100, amountL);
                    choice = 1;
                elseif post(i)<0
                    text=sprintf('100%% chance of $%g',amountS);
                    choice = 0;
                end
                %DrawFormattedText(w, text, [width/2-350], 'center', Red);
                DrawFormattedText(w, text, 150 , 'center', darkRed);

            elseif str2num(key)>5 && str2num(key)~=0 %choose right
                Screen('TextStyle',w,1);
                Screen('TextSize',w,fontsize);
                Screen('TextFont',w,'Times New Roman');            
                if post(i)>0
                    text=sprintf('100%% chance of $%g',amountS);
                    choice = 0;
                elseif post(i)<0
                    text=sprintf('%g%% chance of $%g', risk(i)*100, amountL);
                    choice = 1;
                end
                DrawFormattedText(w, text, width/2+150, 'center', darkRed);            
            end
        else
            rt = GetSecs;
            RT = rt - t0;
            fprintf(fidEvent,'%d %d %5.4f %5.4f\n',i,1,t0-startsec,rt-startsec);
        end
    
        t0=Screen('Flip',w,rt);
        % to send a message to iViewX, such as to indicate the image to be presented:
        %calllib('iViewXAPI', 'iV_SendImageMessage', sprintf('%s', text));
        
        WaitSecs(stimInterval);
        if cond(i)==1
            if magnitude(i)==1
                stat1(choice+1) = stat1(choice+1)+1;
                SchLL = SchLL + choice;
            elseif magnitude(i)==2
                stat2(choice+1) = stat2(choice+1)+1;
                MchLL = MchLL + choice;
            end
            if mod(i,6)==0
                if SchLL == 0 %always chose certain in small
                    ra_S = ra_S*10^(1/8);
                end
                if SchLL == 3 %always chose risky in small
                    ra_S = ra_S*10^(-1/8);
                end
                if MchLL == 0 %always chose certain in medium
                    ra_M = ra_M*10^(1/8);
                end
                if MchLL == 3 %always chose risky in medium
                    ra_M = ra_M*10^(-1/8);
                end
            end
        elseif cond(i)==2
            if condeasy(i) == 1
                stat3(choice+1) = stat3(choice+1)+1;
            elseif condeasy(i)==2
                stat4(choice+1) = stat4(choice+1)+1;
            end
        end
        
    
        fprintf(fid,'%d %d %d %d %d %d %5.4f %5.4f %d %5.4f\n',i, cond(i), magnitude(i), post(i), amountS, amountL, risk(i), ra_trial, choice, RT);
        t=GetSecs;
        fprintf(fidEvent,'%d %d %5.4f %5.4f\n',i,2,t0-startsec,t-startsec);
        endsec=GetSecs;
        
    end
    fprintf('Hard Choices small\nSure Risky\n');
    fprintf('%d\t%d\n',stat1);
    fprintf('Hard Choices medium\nSure Risky\n');
    fprintf('%d\t%d\n',stat2);
    fprintf('Easy Choices: Choose Risky\nSure Risky\n');
    fprintf('%d\t%d\n',stat3);
    fprintf('Easy Choices: Choose Sure\nSure Risky\n');
    fprintf('%d\t%d\n',stat4);
    fprintf('final ra_S: %2.4f\n',ra_S);
    fprintf('final ra_M: %2.4f\n',ra_M);
    
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
    
