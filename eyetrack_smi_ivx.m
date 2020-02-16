function eyetrack_smi_ivx (subjectID, runNum, k_S, k_M) 
% This runs basically any code on iviewx.
% Variables to be passed in should be determined by experimenter.
% 2/9/2014 Eustace Hsu, with help from smi's code

%% initiate eyetracker
warning('off', 'all');

connected = 0;
ScreenNumber=max(Screen('Screens')); %use external monitor if it exists


% load the iViewX API library
loadlibrary('iViewXAPI.dll', 'iViewXAPI.h');


[pSystemInfoData, pSampleData, pEventData, pAccuracyData, CalibrationData] = InitiViewXAPI();

CalibrationData.method = int32(5);
CalibrationData.visualization = int32(1);
CalibrationData.displayDevice = int32(1);
CalibrationData.speed = int32(0);
CalibrationData.autoAccept = int32(1);
CalibrationData.foregroundBrightness = int32(250);
CalibrationData.backgroundBrightness = int32(230);
CalibrationData.targetShape = int32(2);
CalibrationData.targetSize = int32(20);
CalibrationData.targetFilename = int8('');
pCalibrationData = libpointer('CalibrationStruct', CalibrationData);


disp('Define Logger')
calllib('iViewXAPI', 'iV_SetLogger', int32(1), formatString(256, int8('iViewXSDK_Matlab_Slideshow_Demo.txt')))


disp('Connect to iViewX')
ret = calllib('iViewXAPI', 'iV_Connect', formatString(16, int8('127.0.0.1')), int32(4444), formatString(16, int8('127.0.0.1')), int32(5555))
switch ret
    case 1
        connected = 1;
    case 104
         msgbox('Could not establish connection. Check if Eye Tracker is running', 'Connection Error', 'modal');
    case 105
         msgbox('Could not establish connection. Check the communication Ports', 'Connection Error', 'modal');
    case 123
         msgbox('Could not establish connection. Another Process is blocking the communication Ports', 'Connection Error', 'modal');
    case 200
         msgbox('Could not establish connection. Check if Eye Tracker is installed and running', 'Connection Error', 'modal');
    otherwise
         msgbox('Could not establish connection', 'Connection Error', 'modal');
end


if connected 

	disp('Get System Info Data')
	calllib('iViewXAPI', 'iV_GetSystemInfo', pSystemInfoData)
	get(pSystemInfoData, 'Value')

%set up some sort of while loop here				
	disp('Calibrate iViewX')
	calllib('iViewXAPI', 'iV_SetupCalibration', pCalibrationData)
	calllib('iViewXAPI', 'iV_Calibrate')


	disp('Validate Calibration')
	calllib('iViewXAPI', 'iV_Validate')


	disp('Show Accuracy')
	calllib('iViewXAPI', 'iV_GetAccuracy', pAccuracyData, int32(0))
	get(pAccuracyData, 'Value')
%end while loop
    try
    
    % clear recording buffer
    calllib('iViewXAPI', 'iV_ClearRecordingBuffer');

    % start recording on eyetracker
    calllib('iViewXAPI', 'iV_StartRecording');
    
    %Name of task.
    itc_eyetrack_shapes(subjectID,runNum,k_S,k_M);
    
    % stop recording
		calllib('iViewXAPI', 'iV_StopRecording');

		% save recorded data
		user = formatString(64, int8('User1'));
		description = formatString(64, int8('Description1'));
		ovr = int32(1);

        %name of output file, change this. 
		filename = formatString(256, int8(['C:\Users\iView X\Desktop\Monterosso\Eustace\itc_eyetrack_' subjectID '_' runNum '.idf']));
		calllib('iViewXAPI', 'iV_SaveData', filename, description, user, ovr)
    	catch
		% catch if errors appears
		Screen('CloseAll'); 
		ShowCursor
		s = lasterror
	end


end
    % disconnect from iViewX 
calllib('iViewXAPI', 'iV_Disconnect')

pause(1);
clear all

% unload iViewX API libraray
unloadlibrary('iViewXAPI');


