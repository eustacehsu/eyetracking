%%%%%%%%%%%%%%%%%%%%%%%
%% Adaptive risk function
%% Here is a procedure that estimates a hyperbolic (probability) discount parameter for the user
%% small rewards (%-age chance of $21-35)
%% medium/large rewards (%-age chance of $46-60)
%%%%%%%%%%%%%%%%%%%%%%

%% Eustace Hsu, 2014

function ADDP_risk (subjectID)
%% Set up variables 
ras=[];
ras(1)=0.75;% k for small amounts from behavioral study

ram=[];
ram(1)=0.75; % k for medium amounts 


nTrials=80;
TargetDispTime=0.5;
FeedbackDispTime=0.5;
LAG=2; % lag before main experiment 
TRIAL_DURATION=12;

Black=[0 0 0];
White=[255 255 255];
Yellow=[255 255 0];
Red = [255 0 0];

ppd=42; % pixels per degree
shapesize=2.8*ppd;
RespKey={'1','2','6','7'};
% width=1024; height=768; hz=60;

stat1=zeros(3,1);
stat2=zeros(3,1);

%% Save records 
if nargin<1, subjectID='ls'; end
saveToFile ='Save';
%if nargin<2
%    saveToFile = questdlg('','Save Record?','Save','Display','None','Display');
%end
fun=mfilename; direc=fileparts(which(fun));
if strcmp(saveToFile,'None')
    fid=0;
%elseif strcmp(saveToFile,'Display')
%    fid=1;
else
%    if ~exist('fileName','var'), fileName='junk'; end
    fileName=sprintf('%s_ADDP_risk.rec',subjectID);
    fileName=fullfile(direc, fileName);
    makeCopy4existFile(fileName);
    fid=fopen(fileName,'w+');
%end

fprintf(fid,'Program: %s\n',which(fun));
fprintf(fid,'ClockRandSeed: %10.0f\n',ClockRandSeed);
fprintf(fid,'Subject initials: %s\n',subjectID);

%% Design 

HDrange=[46 60];
meanHD=53;
while 1, HD=round(HDrange(1)+(HDrange(2)-HDrange(1)).*rand((nTrials/2-1),1));
    if mean(HD)==meanHD, break; end; end

LDrange=[21 35];
meanLD=28;
while 1, LD=round(LDrange(1)+(LDrange(2)-LDrange(1)).*rand((nTrials/2-1),1));
    if mean(LD)==meanLD, break; end; end

risk=0.5;

RV=[HD;LD];
RV=Shuffle(RV);
RV=[53;28;RV];

sureamount=[];
%Rachlin's risk discounting formula
theta=(1-risk)/risk; 
sureamount(1)= floor(RV(1)/(1+ram(1)*theta))+1; 
sureamount(2)= floor(RV(2)/(1+ras(1)*theta))+1;

%% Screen setup 
    
doublebuffer=1;
ScreenNumber=max(Screen('Screens'));
    if ScreenNumber==0 %need to use SkipSyncTests for retina macbook pro 
        Screen('Preference','SkipSyncTests',1);
    end

[w rect]=Screen('OpenWindow',ScreenNumber,0,[],32,doublebuffer+1);[xyc(1) xyc(2)]=RectCenter(rect);
width=rect(3);
height = rect(4);

shaperect=CenterRect([0 0 shapesize shapesize],[0 0 width height-10]);

HideCursor;
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);% enable alpha blending with proper blend function for drawing of smoothed points
[xyc(1) xyc(2)]=RectCenter(rect);
Screen('TextStyle',w,1); 
Screen('TextSize',w,55);
Screen('TextFont',w,'Times New Roman');
tasks='Experiment will start soon!\n \n Press any key to start!';
DrawFormattedText(w, tasks, 'center', 'center', [255 255 255]);
Screen('Flip',w); 

%% Experiment 
%WaitSecs(5);
startsec = mlTRSync(1,[],'KbCheck');
%startsec=KbCheck;
fprintf(fid,'Start: %s, %s\n',datestr(now,'ddd'),datestr(now));
fprintf(fid, '%s\n', 'trial riskamt sureamt param ok RT');

endsec=startsec+LAG; 
WaitTill(endsec);

post=ones(nTrials,1);
post(1:round(nTrials/2))=-1;
post=Shuffle(post);


stat1=zeros(2,1);
stat2=zeros(2,1);

j=1;
k=1;

fontsize=40;
%fontsize=70;
%rectSideLength = 300;
%circleRadius = sqrt((rectSideLength^2)/pi);

for i=1:2
    Priority(MaxPriority(w));
    startt=endsec; endsec=endsec+TRIAL_DURATION;
    
    if  post(i)>0
            %drawCircle(w,[width*3/4 height/2], circleRadius, White);
            Screen('TextStyle',w,1); 
            Screen('TextSize',w,fontsize);
            Screen('TextFont',w,'Times New Roman');
            text=sprintf('100%% chance of $%g',sureamount(i));            
            DrawFormattedText(w, text, width*3/4-fontsize, 'center', White);
    
            Screen(w,'DrawLine', White, xyc(1), xyc(2)-100, xyc(1), xyc(2)+100);
    
            %drawSquare(w,[width/4 height/2], rectSideLength, White);
            Screen('TextStyle',w,1); 
            Screen('TextSize',w,fontsize);
            Screen('TextFont',w,'Times New Roman');
            text=sprintf('%g%% chance of $%g',risk*100,RV(i));
            DrawFormattedText(w, text, width/4-fontsize, 'center', White);
    else
        
            %drawCircle(w,[width/4 height/2], circleRadius, White);
            Screen('TextStyle',w,1);
            Screen('TextSize',w,fontsize);
            Screen('TextFont',w,'Times New Roman');
            text=sprintf('100%% chance of $%g',sureamount(i));
            DrawFormattedText(w, text, width/4-fontsize, 'center', White); 
    
            Screen(w,'DrawLine', White, xyc(1), xyc(2)-60, xyc(1), xyc(2)+60);
    
            %drawSquare(w,[width*3/4 height/2], rectSideLength, White);
            Screen('TextStyle',w,1); 
            Screen('TextSize',w,fontsize);
            Screen('TextFont',w,'Times New Roman');
            text=sprintf('%g%% chance of $%g',risk*100,RV(i));
            DrawFormattedText(w, text, width*3/4-fontsize, 'center', White);
        end
    
    %record response
    t0=Screen('Flip',w,[],1);
    [key, rt]=WaitTill(t0+4,RespKey,1);
    
    %please respond feedback if there is no response after 5s  
    
    
    if ~isempty(key) 
        RT=rt-startt;
        
    elseif isempty(key)  
        
        Screen('TextStyle',w,1); 
        Screen('TextSize',w,65);
        Screen('TextFont',w,'Times New Roman');
        text='Please Respond';
        DrawFormattedText(w, text, 'center', [height*3/4], [255 255 255]);
        Screen('Flip',w,[],1);
        [key, rt]=WaitTill(endsec,RespKey,1);
        
   end       
     
     if isempty(key)

          RT=0;
          Screen('TextStyle',w,1); 
          Screen('TextSize',w,65);
          Screen('TextFont',w,'Times New Roman');
          text='Please Respond';
          DrawFormattedText(w, text, 'center', [height*3/4], [255 0 0]);
          Screen('Flip',w,[],1);
          [key, rt]=WaitTill(endsec+RT,RespKey,1);
    
     end
     
if ~isempty(key) 
     RT=rt-startt;    
       
  if str2num(key)<5 && str2num(key)~=0;
     if i==1
         if post(i)>0
            %drawSquare(w,[width/4 height/2], rectSideLength, White);
              Screen('TextStyle',w,1); 
              Screen('TextSize',w,fontsize);
              Screen('TextFont',w,'Times New Roman');
              text=sprintf('%g%% chance of $%g',risk*100,RV(i));
              DrawFormattedText(w, text, width/4-fontsize, 'center', Red);
              ram(end+1)=ram(end)*10^(-1/8);
              %ram(end+1)=ram(end)*10^(-1/100);
              %km(end+1)=km(end)*10^(-1/4);
              ok=2;
              okInd=2;
         else
             %drawCircle(w,[width/4 height/2], circleRadius, White);
             Screen('TextStyle',w,1);
              Screen('TextSize',w,fontsize);
              Screen('TextFont',w,'Times New Roman');
              text=sprintf('100%% chance of $%g',sureamount(i));
              DrawFormattedText(w, text, width/4-fontsize, 'center', Red); 
              ram(end+1)=ram(end)*10^(1/8);
              %ram(end+1)=ram(end)*10^(1/100);
              %CHANGE FOR RISK AVERSION PARAM
              %km(end+1)=km(end)*10^(1/4);
              ok=1;
              okInd=1;
         end
     else
         if post(i)>0
            %drawSquare(w,[width/4 height/2], rectSideLength, White);
              Screen('TextStyle',w,1); 
              Screen('TextSize',w,fontsize);
              Screen('TextFont',w,'Times New Roman');
              text=sprintf('%g%% chance of $%g',risk*100,RV(i));
              DrawFormattedText(w, text, width/4-fontsize, 'center', Red);
              ras(end+1)=ras(end)*10^(-1/8);
              %ras(end+1)=ras(end)*10^(-1/100); 
              %CHANGE FOR RISK AVERSION PARAM
              %ks(end+1)=ks(end)*10^(-1/4);
              ok=2;
              okInd=2;
         else
             %drawCircle(w,[width/4 height/2], circleRadius, White);
             Screen('TextStyle',w,1);
              Screen('TextSize',w,fontsize);
              Screen('TextFont',w,'Times New Roman');
              text=sprintf('100%% chance of $%g',sureamount(i));
              DrawFormattedText(w, text, width/4-fontsize, 'center', Red); 
              ras(end+1)=ras(end)*10^(1/8);
              %ras(end+1)=ks(end)*10^(1/100);
              %ks(end+1)=ks(end)*10^(1/4);
              ok=1;
              okInd=1;
         end
         
         if RV(i+1)<40
            sureamount(end+1)= floor(RV(i+1)/(1+ras(end)*theta))+1;   
         %sureamount(end+1)= floor(RV(i+1)/risk)^(1/ras(end));
         %sureamount(end+1)=floor(DV(i+1)/(1+ks(end)*delay))+1;
         else
             sureamount(end+1)=floor(RV(i+1)/(1+ram(end)*theta))+1;
         %sureamount(end+1)= (RV(i+1)/risk)^(1/ram(end));
         %sureamount(end+1)=floor(DV(i+1)/(1+km(end)*delay))+1; 
         end
      
         
     end
     
         if i==1

         t0=Screen('Flip',w,rt);
         Screen('FillRect',w,[0 0 0]);
         Screen('Flip',w,t0+0.5);
         stat1(okInd)=stat1(okInd)+1;
         WaitTill(endsec);
         fprintf(fid,'%d %d %d %5.4f %d %5.4f\n',i,RV(i),sureamount(i),ram(end-1),ok,RT);
         else
         t0=Screen('Flip',w,rt);
         Screen('FillRect',w,[0 0 0]);
         Screen('Flip',w,t0+0.5);
         stat2(okInd)=stat2(okInd)+1;
         WaitTill(endsec);
         fprintf(fid,'%d %d %d %5.4f %d %5.4f\n',i,RV(i),sureamount(i),ras(end-1),ok,RT);   
         end
         
  end


     if str2num(key)>5
       if i==1
         if post(i)<0
            %drawSquare(w,[width*3/4 height/2], rectSideLength, White);
             Screen('TextStyle',w,1); 
             Screen('TextSize',w,fontsize);
             Screen('TextFont',w,'Times New Roman');
              text=sprintf('%g%% chance of $%g',risk*100,RV(i));
             DrawFormattedText(w, text, [width*3/4-fontsize], 'center', Red);
              ram(end+1)=ram(end)*10^(-1/8);             
             %km(end+1)=km(end)*10^(-1/4);
             ok=2;
             okInd=2;
         else
             %drawCircle(w,[width*3/4 height/2], circleRadius, White);

             Screen('TextStyle',w,1); 
             Screen('TextSize',w,fontsize);
             Screen('TextFont',w,'Times New Roman');
              text=sprintf('100%% chance of $%g',sureamount(i));
             DrawFormattedText(w, text, [width*3/4-fontsize], 'center', Red);
              ram(end+1)=ram(end)*10^(1/8);             
             %km(end+1)=km(end)*10^(1/4);
             ok=1;
             okInd=1;
         end
       else
           if post(i)<0
            %drawSquare(w,[width*3/4 height/2], rectSideLength, White);
             Screen('TextStyle',w,1); 
             Screen('TextSize',w,fontsize);
             Screen('TextFont',w,'Times New Roman');
              text=sprintf('%g%% chance of $%g',risk*100,RV(i));
             DrawFormattedText(w, text, [width*3/4-fontsize], 'center', Red);
             ras(end+1)=ras(end)*10^(-1/8);   
             %ks(end+1)=ks(end)*10^(-1/4);
             ok=2;
             okInd=2;
           else
               %drawCircle(w,[width*3/4 height/2], circleRadius, White);
               Screen('TextStyle',w,1); 
             Screen('TextSize',w,fontsize);
             Screen('TextFont',w,'Times New Roman');
              text=sprintf('100%% chance of $%g',sureamount(i));
             DrawFormattedText(w, text, [width*3/4-fontsize], 'center', Red);
             ras(end+1)=ras(end)*10^(1/8);
             %ks(end+1)=ks(end)*10^(1/4);
             ok=1;
             okInd=1;
         end

         if RV(i+1)<40
             sureamount(end+1)= floor(RV(i+1)/(1+ras(end)*theta))+1;   
            %sureamount(end+1)= (RV(i+1)/risk)^(1/ras(end));
            %sureamount(end+1)= %floor(RV(i+1)/(1+ks(end)*delay))+1;
         else
             sureamount(end+1)= floor(RV(i+1)/(1+ram(end)*theta))+1;
             %sureamount(end+1)= (RV(i+1)/risk)^(1/ram(end));
             %sureamount(end+1)= %floor(RV(i+1)/(1+km(end)*delay))+1; 
         end
      
       end


         if i==1

         t0=Screen('Flip',w,rt);
         Screen('FillRect',w,[0 0 0]);
         Screen('Flip',w,t0+0.5);
         stat1(okInd)=stat1(okInd)+1;
         WaitTill(endsec);
         fprintf(fid,'%d %d %d %5.4f %d %5.4f\n',i,RV(i),sureamount(i),ram(end-1),ok,RT);
         else
         t0=Screen('Flip',w,rt);
         Screen('FillRect',w,[0 0 0]);
         Screen('Flip',w,t0+0.5);
         stat2(okInd)=stat2(okInd)+1;
         WaitTill(endsec);
         fprintf(fid,'%d %d %d %5.4f %d %5.4f\n',i,RV(i),sureamount(i),ras(end-1),ok,RT);   
         end
         
     end
end

end

for i=3:nTrials
    
    Priority(MaxPriority(w));
    startt=endsec; endsec=endsec+TRIAL_DURATION;

    if RV(i)>40  % medium amount
        j=j+1;
    else
        k=k+1;
    end
    
        if  post(i)>0
            %drawCircle(w,[width*3/4 height/2], circleRadius, White);
            Screen('TextStyle',w,1); 
            Screen('TextSize',w,fontsize);
            Screen('TextFont',w,'Times New Roman');
              text=sprintf('100%% chance of $%g',sureamount(i));
            DrawFormattedText(w, text, [width*3/4-fontsize], 'center', White);
    
            Screen(w,'DrawLine', White, xyc(1), xyc(2)-60, xyc(1), xyc(2)+60);
    
            %drawSquare(w,[width/4 height/2], rectSideLength, White);
            Screen('TextStyle',w,1); 
            Screen('TextSize',w,fontsize);
            Screen('TextFont',w,'Times New Roman');
              text=sprintf('%g%% chance of $%g',risk*100,RV(i));
            DrawFormattedText(w, text, width/4-fontsize, 'center', White);
        else

            %drawCircle(w,[width/4 height/2], circleRadius, White);
            Screen('TextStyle',w,1);
            Screen('TextSize',w,fontsize);
            Screen('TextFont',w,'Times New Roman');
            text=sprintf('100%% chance of $%g',sureamount(i));
            DrawFormattedText(w, text, width/4-fontsize, 'center', White); 
    
            Screen(w,'DrawLine', White, xyc(1), xyc(2)-60, xyc(1), xyc(2)+60);
    
            %drawSquare(w,[width*3/4 height/2], rectSideLength, White);
            Screen('TextStyle',w,1); 
            Screen('TextSize',w,fontsize);
            Screen('TextFont',w,'Times New Roman');
            text=sprintf('%g%% chance of $%g',risk*100,RV(i));
            DrawFormattedText(w, text, [width*3/4-fontsize], 'center', White);
        end
    
    %record response
    t0=Screen('Flip',w,[],1);
    [key, rt]=WaitTill(t0+4,RespKey,1);
    
    %please respond feedback if there is no response after 5s  
    
    
    if ~isempty(key) 
        RT=rt-startt;
        
    elseif isempty(key)  
        
        Screen('TextStyle',w,1); 
        Screen('TextSize',w,fontsize);
        Screen('TextFont',w,'Times New Roman');
        text='Please Respond';
        DrawFormattedText(w, text, 'center', [height*3/4], [255 255 255]);
        Screen('Flip',w,[],1);
        [key, rt]=WaitTill(endsec,RespKey,1);
        
   end       
     
     if isempty(key)

          RT=0;
          Screen('TextStyle',w,1); 
          Screen('TextSize',w,fontsize);
          Screen('TextFont',w,'Times New Roman');
          text='Please Respond';
          DrawFormattedText(w, text, 'center', [height*3/4], [255 0 0]);
          Screen('Flip',w,[],1);
          [key, rt]=WaitTill(endsec+RT,RespKey,1);
     end
     
 if ~isempty(key) 
         RT=rt-startt; 
         

   if RV(i)>40
       
     if str2num(key)<5 && str2num(key)~=0;
         if post(i)>0

            %drawSquare(w,[width/4 height/2], rectSideLength, White);
             Screen('TextStyle',w,1); 
              Screen('TextSize',w,fontsize);
              Screen('TextFont',w,'Times New Roman');
              text=sprintf('%g%% chance of $%g',risk*100,RV(i));
              DrawFormattedText(w, text, width/4-fontsize, 'center', Red);
              ram(end+1)=ram(end)*10^(-1/8);             
              %km(end+1)=km(end)*10^(-1/4);
              ok=2;
              okInd=2;
         else
             %drawCircle(w,[width/4 height/2], circleRadius, White);
              Screen('TextStyle',w,1);
              Screen('TextSize',w,fontsize);
              Screen('TextFont',w,'Times New Roman');
              text=sprintf('100%% chance of $%g',sureamount(i));
              DrawFormattedText(w, text, width/4-fontsize, 'center', Red); 
              ram(end+1)=ram(end)*10^(1/8);             
              %km(end+1)=km(end)*10^(1/4);
              ok=1;
              okInd=1;
         end
         
         if RV(i+1)>40
             sureamount(end+1)= floor(RV(i+1)/(1+ram(end)*theta))+1;   
            %iamount(end+1)=floor(DV(i+1)/(1+km(end)*delay))+1;
         else
            sureamount(end+1)= floor(RV(i+1)/(1+ras(end)*theta))+1;   
         %iamount(end+1)=floor(DV(i+1)/(1+ks(end)*delay))+1;
         end
         
         t0=Screen('Flip',w,rt);
         Screen('FillRect',w,[0 0 0]);
         Screen('Flip',w,t0+0.5);
         stat1(okInd)=stat1(okInd)+1;
         WaitTill(endsec);
         fprintf(fid,'%d %d %d %5.4f %d %5.4f\n',i,RV(i),sureamount(i),ram(end-1),ok,RT);
     end
     
     if str2num(key)>5
         if post(i)<0
            %drawSquare(w,[width*3/4 height/2], rectSideLength, White);

             Screen('TextStyle',w,1); 
             Screen('TextSize',w,fontsize);
             Screen('TextFont',w,'Times New Roman');
             text=sprintf('%g%% chance of $%g',risk*100,RV(i));
             DrawFormattedText(w, text, [width*3/4-fontsize], 'center', Red);
             ram(end+1)=ram(end)*10^(-1/8);             
             %km(end+1)=km(end)*10^(-1/4);
             ok=2;
             okInd=2;
         else
             %drawCircle(w,[width*3/4 height/2], circleRadius, White);
             Screen('TextStyle',w,1); 
             Screen('TextSize',w,fontsize);
             Screen('TextFont',w,'Times New Roman');
             text=sprintf('100%% chance of $%g',sureamount(i));
             DrawFormattedText(w, text, [width*3/4-fontsize], 'center', Red);
             ram(end+1)=ram(end)*10^(1/8);             
             %km(end+1)=km(end)*10^(1/4);
             ok=1;
             okInd=1;
         end

         if RV(i+1)>40
             sureamount(end+1)= floor(RV(i+1)/(1+ram(end)*theta))+1;   
             %iamount(end+1)=floor(DV(i+1)/(1+km(end)*delay))+1;
         else
             sureamount(end+1)= floor(RV(i+1)/(1+ras(end)*theta))+1;
             %iamount(end+1)=floor(DV(i+1)/(1+ks(end)*delay))+1;
         end
         
            t0=Screen('Flip',w,rt);
            Screen('FillRect',w,[0 0 0]);
            Screen('Flip',w,t0+0.5);
            stat1(okInd)=stat1(okInd)+1;
            WaitTill(endsec);
            fprintf(fid,'%d %d %d %5.4f %d %5.4f\n',i,RV(i),sureamount(i),ram(end-1),ok,RT);
     end

   else
        
        if str2num(key)<5 && str2num(key)~=0;
         if post(i)>0
              Screen('TextStyle',w,1); 
              Screen('TextSize',w,fontsize);
              Screen('TextFont',w,'Times New Roman');
              text=sprintf('%g%% chance of $%g',risk*100,RV(i));
              DrawFormattedText(w, text, width/4-fontsize, 'center', Red);
              ras(end+1)=ras(end)*10^(-1/8);             
              %ks(end+1)=ks(end)*10^(-1/4);
              ok=2;
              okInd=2;
         else
             
             %drawCircle(w,[width/4 height/2], circleRadius, White);
              Screen('TextStyle',w,1);
              Screen('TextSize',w,fontsize);
              Screen('TextFont',w,'Times New Roman');
             text=sprintf('100%% chance of $%g',sureamount(i));
              DrawFormattedText(w, text, width/4-fontsize, 'center', Red); 
              ras(end+1)=ras(end)*10^(1/8);
              %ks(end+1)=ks(end)*10^(1/4);
              ok=1;
              okInd=1;
         end
         
         if RV(i+1)>40
             sureamount(end+1)= floor(RV(i+1)/(1+ram(end)*theta))+1;   
            %iamount(end+1)=floor(DV(i+1)/(1+km(end)*delay))+1;
         else
             sureamount(end+1)= floor(RV(i+1)/(1+ras(end)*theta))+1;   
            %iamount(end+1)=floor(DV(i+1)/(1+ks(end)*delay))+1;
         end
         
         t0=Screen('Flip',w,rt);
         Screen('FillRect',w,[0 0 0]);
         Screen('Flip',w,t0+0.5);
         stat2(okInd)=stat2(okInd)+1;
         WaitTill(endsec);
         fprintf(fid,'%d %d %d %5.4f %d %5.4f\n',i,RV(i),sureamount(i),ras(end-1),ok,RT);
     end
     
     if str2num(key)>5
         if post(i)<0
            %drawSquare(w,[width*3/4 height/2], rectSideLength, White);
             Screen('TextStyle',w,1); 
             Screen('TextSize',w,fontsize);
             Screen('TextFont',w,'Times New Roman');
              text=sprintf('%g%% chance of $%g',risk*100,RV(i));
             DrawFormattedText(w, text, [width*3/4-fontsize], 'center', Red);
             ras(end+1)=ras(end)*10^(-1/4);
             ok=2;
             okInd=2;
         else
             
            %drawCircle(w,[width*3/4 height/2], circleRadius, White);
             Screen('TextStyle',w,1);
             Screen('TextSize',w,fontsize);
             Screen('TextFont',w,'Times New Roman');
             text=sprintf('100%% chance of $%g',sureamount(i));
             DrawFormattedText(w, text, [width*3/4-fontsize], 'center', Red);
             ras(end+1)=ras(end)*10^(1/4);
             ok=1;
             okInd=1;
         end

         if RV(i+1)>40
             sureamount(end+1)= floor(RV(i+1)/(1+ram(end)*theta))+1;   
            %iamount(end+1)=floor(DV(i+1)/(1+km(end)*delay))+1;
         else
             sureamount(end+1)= floor(RV(i+1)/(1+ras(end)*theta))+1;   
            %iamount(end+1)=floor(DV(i+1)/(1+ks(end)*delay))+1;
         end
         
            t0=Screen('Flip',w,rt);
            Screen('FillRect',w,[0 0 0]);
            Screen('Flip',w,t0+0.5);
            stat2(okInd)=stat2(okInd)+1;
            WaitTill(endsec);
            fprintf(fid,'%d %d %d %5.4f %d %5.4f\n',i,RV(i),sureamount(i),ras(end-1),ok,RT);
     end
   end
   
 end 
     
     if j>=8 && k>=8 && (log10(max(ras(k-7:k)))-log10(min(ras(k-7:k))))<=0.5 && (log10(max(ram(j-7:j)))-log10(min(ram(j-7:j))))<=0.5 || GetSecs-startsec>480
        
        
        ramax1=max(ram(j-7:j));
        ramin1=min(ram(j-7:j));
        
        for w=j-7:j
            if ram(w)~=ramax1 && ram(w)~=ramin1
                ramedium1=ram(w);
            elseif ram(w)==ramax1
                ramax1=ram(w);ramedium1=0;
                
            else
                ramin1=ram(w);ramedium1=0;
            end
        end 
        
        if ramedium1~=0
        ramax1=max(ram(j-7:j));
        ramin1=min(ram(j-7:j));
        
        x=[ramax1 ramin1 ramedium1];
        ram_final=geomean(x,2);
        
        else
        ramax1=max(ram(j-7:j));
        ramin1=min(ram(j-7:j));
        
        x=[ramax1 ramin1];
        ram_final=geomean(x,2);
        
        end
        ramax2=max(ras(k-7:k));
        ramin2=min(ras(k-7:k));
        
        for z=k-7:k
            if ras(z)~=ramax2 && ras(z)~=ramin2
                ramedium2=ras(z);
            elseif ras(z)==ramax2
                ramax2=ras(z); ramedium2=0;
            else
                ramin2=ras(z); ramedium2=0;
            end
        end 
        
        if ramedium2~=0
        ramax2=max(ras(k-7:k));
        ramin2=min(ras(k-7:k));
        
        x=[ramax2 ramin2 ramedium2];
        ras_final=geomean(x,2);
        else
        ramax2=max(ras(k-7:k));
        ramin2=min(ras(k-7:k));
        
        x=[ramax2 ramin2];
        ras_final=geomean(x,2); 
        end
        
        break;
    end;
   
end

         ScreenNumber=max(Screen('Screens'));
         [w rect]=Screen('OpenWindow',ScreenNumber,0,[],32,2);
        Screen('TextStyle',w,1); 
        Screen('TextSize',w,fontsize);
        Screen('TextFont',w,'Times New Roman');
        tasks='Thanks! It is done!';
        DrawFormattedText(w, tasks, 'center', 'center', [255 255 255]);
        tf=Screen('Flip',w); 
        Screen('Flip',w,tf+5);
         figure(1);
         plot(ram,'b');
         title('Theta value for medium amounts');
         figure(2);
         plot(ras,'r');
         title('Theta value for small amounts');
        
         fprintf(fid,'Finish: %s\n', datestr(now));
         fprintf(fid,'Final theta_m: %5.4f\n', ram_final);
         fprintf(fid,'Immediate Delay\n');
         fprintf(fid,'%d %d\n',stat1);
         stat1=stat1*100./j;
         fprintf(fid,'Immediate Delay\n');
         fprintf(fid,'%5.1f %5.1f\n', stat1);
         fprintf(fid,'Final theta_s: %5.4f\n', ras_final);
         fprintf(fid,'Immediate Delay\n');
         fprintf(fid,'%d %d\n',stat2);
         stat2=stat2*100./k;
         fprintf(fid,'Immediate Delay\n');
         fprintf(fid,'%5.1f %5.1f\n', stat2);
        
        Priority(0);
        Screen('CloseAll');
        fclose('all');
end

