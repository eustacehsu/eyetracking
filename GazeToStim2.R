require("stats")
require("lme4")


GazeToStim<-function(
 	LeftEyeData,RightEyeData,
 	targets,radius=210,
 	useEye="combine",useEvents="Fixation",
	screenHorizontal=1680,screenVertical=1050,
 	freq=120,directory="",name=""){
  # Passes in:
  # LeftEyeData, RightEyeData - first column is timing file, 2nd column is category of eye acquisition, 3rd is data
  # EVdata - three columns, 1st column is timing, 2nd is duration, 3rd is weight
  # trialData - timing for trials.
  #	targets - stimuli that can be looked at, should have 3 variables, name, x-coordinate, and y-coordinate
  # useEye - left, right, both, combine (into one)
  # useEvents - which categories of acquisitions to use. Defaults to fixations. This is specifically related to BeGaze output.

  # OUTPUT - data with one added column that identifies whether fixation is on target

  #renaming data makes things easier.
  if (useEye%in%c("combine","both","left")) names(LeftEyeData)<-c("TimeSecs","LEventInfo","LXCoordinate","LYCoordinate")
  if (useEye%in%c("combine","both","right")) names(RightEyeData)<-c("TimeSecs","REventInfo","RXCoordinate","RYCoordinate")


  # return a df with a column as timing, and a column as diameter data.
  # do the combining somewhere else
  if (useEye%in%c("combine","both")) finalData<-meanFix(LeftEyeData,RightEyeData) 
  # left eye only, impute right for blinks?
  if (useEye=="left") finalData<-LeftEyeData
  # right eye only, impute left for blinks?
  if (useEye=="right") finalData<-RightEyeData
  # do we want to be able to output a timecourse for both?

  finalData$fixTarget<-categorizeFixations(LeftEyeData,RightEyeData,useEye,targets,radius)

	finalData
}

meanFix<-function(eye1,eye2){
  # average the time signals from the two eyes. Merge by timing column, even though its prob not necessary (will this take longer?).
  colEye1<-ncol(eye1)
  colEye2<-ncol(eye2)
  eyeX<-merge(eye1[,c(1,(colEye1-1))],eye2[,c(1,(colEye2-1))],by=c("TimeSecs"),all=TRUE) #merge assumes Time is the 1st column  
  eyeY<-merge(eye1[,c(1,colEye1)],eye2[,c(1,colEye2)],by=c("TimeSecs"),all=TRUE) #merge assumes Time is the 1st column
  names(eyeX)<-c("TimeSecs","Eye1X","Eye2X")
  names(eyeY)<-c("TimeSecs","Eye1Y","Eye2Y")
  eyeX$meanEyeX<-rowMeans(eyeX[,2:3])
  eyeY$meanEyeY<-rowMeans(eyeY[,2:3])
  eyes<-merge(eyeX[,c(1,4)],eyeY[,c(1,4)],by=c("TimeSecs"),all=TRUE)
  eyes
}

categorizeFixations<-function(
	LeftEyeData,RightEyeData,useEye="both", targets,radius=210
){
	#eyeData - first column is timing file, last 2 are x-coordinate and y-coordinate
 	#targets - stimuli that can be looked at, should have 3 variables, name, x-coordinate, and y-coordinate

  if(useEye%in%c("combine","both")) eyeData<-merge(LeftEyeData,RightEyeData,by=c("TimeSecs"),all=TRUE)
  nLeftEye<-ncol(LeftEyeData)
 	LeftEyeData$fixated<-NA
  nRightEye<-ncol(RightEyeData)
  RightEyeData$fixated<-NA

 	for (target in 1:nrow(targets)){
    if(useEye%in%c("combine","both")) eyeData$fixated[pythagoreanDistance(eyeData[,c("LXCoordinate","LYCoordinate")],targets[target,2:3])<radius|pythagoreanDistance(eyeData[,c("RXCoordinate","RYCoordinate")],targets[target,2:3])<radius]<-as.character(targets[target,1])
 		#LeftEyeData$fixated[pythagoreanDistance(LeftEyeData[,(nEye-1):nEye],targets[target,2:3])<radius]<-as.character(targets[target,1])
    #RightEyeData$fixated[pythagoreanDistance(RightEyeData[,(nEye-1):nEye],targets[target,2:3])<radius]<-as.character(targets[target,1])
 	}
  eyeData$fixated<-as.factor(eyeData$fixated)



  eyeData$fixated
}

pythagoreanDistance<-function(
	eyeData, target
){
	#takes vectors of x and y-coordinates for gaze and an x and y-coordinate for stimulus, and returns distance between gaze and stimulus
	distance<-sqrt((eyeData[,1]-target[1,1])^2+(eyeData[,2]-target[1,2])^2)
	distance
}

fixationSeries<-function(fixData,targets,resolveOff=TRUE){
  #takes a dataset with timings, categorized gaze locations (on target, which target),
  #and what eye is doing (fixating, saccading, blinking, etc.), and collapses into an ordering of fixations,
  #with begining, end, duration
  #fixData - dataset where each row is an acquisition, first col is time, 2nd is 
  #targets-name of targets to be coded. anything uncoded is a separate category.
  
  #want to update this to only look at fixations

  fixNumber<-1
  if(fixData[1,"fixTarget"]%in%targets){
    currentFix<-fixData[1,"fixTarget"]
    currentTarget<-fixData[1,"fixTarget"]
    transitionFix<-TRUE
    onTargetN<-1
  } else {
    currentFix<-"Off"
    currentTarget<-"Off"
    transitionFix<-FALSE
    onTargetN<-0
  }
  currentFixStart<-fixData[1,1]
  currentFixEnd<-fixData[1,1]
  fixations<-data.frame()
  for(i in 2:nrow(fixData)){
    if (!is.na(fixData[i,"fixTarget"])&&fixData[i,"fixTarget"]==currentFix){
      currentFixEnd<-fixData[i,1]
    } else if (is.na(fixData[i,"fixTarget"]) || fixData[i,"fixTarget"]!=currentFix){ #indicates that they are no longer looking at same thing
      if (currentFix%in%targets|fixData[i,"fixTarget"]%in%targets){ #looking at new target
        durationFix<-currentFixEnd-currentFixStart #calculate duration
        #make an entry for the completed fixation
        fixations[fixNumber,"Number"]<-fixNumber
        fixations[fixNumber,"Start"]<-currentFixStart
        fixations[fixNumber,"End"]<-currentFixEnd
        fixations[fixNumber,"Duration"]<-durationFix
        #print(currentFix)
        fixations$onTarget[fixNumber]<-as.character(currentFix)
        fixations[fixNumber,"Transition"]<-transitionFix
        fixations[fixNumber,"onTargetN"]<-onTargetN
        #now set up next fixation
        fixNumber<-fixNumber+1
        currentFix<-fixData[i,"fixTarget"]
        if (fixData[i,"fixTarget"]%in%targets){ #fixation is on target
          if (currentFix!=currentTarget){ #indicates a transition to this target
            currentTarget<-currentFix
            transitionFix<-TRUE
            onTargetN<-onTargetN+1
          } else {
            transitionFix<-FALSE
          }
        } else {
          currentFix<-"Off"
          transitionFix<-FALSE
        }
        currentFixStart<-fixData[i,1]
        currentFixEnd<-fixData[i,1]
        #currentTarget<-fixData[i,"fixTarget"]
        #print(currentTarget)
      } else { #looking around off Target, but this can be made to be more specific
        currentFixEnd<-fixData[i,1]
      }
    }
  }
  #end. Enter final fixation.
  #print(currentFix)
  durationFix<-currentFixEnd-currentFixStart
  fixations[fixNumber,"Number"]<-fixNumber
  fixations[fixNumber,"Start"]<-currentFixStart
  fixations[fixNumber,"End"]<-currentFixEnd
  fixations[fixNumber,"Duration"]<-durationFix
  fixations[fixNumber,"onTarget"]<-as.character(currentFix)
  fixations[fixNumber,"Transition"]<-transitionFix
  fixations[fixNumber,"onTargetN"]<-onTargetN 
  if (resolveOff==TRUE){
    fixations<-nonTargetFixations(fixations,targets)
  }
  fixations
}

nonTargetFixations<-function(fix, targets){
  # resolve fixations as in Krajbich et al. 2010, 2011, etc
  # if non-target gaze occurs between two fixes on same target, include non-target as part of fixation to target
  # if non-target gaze occurs between fixes to different targets, leave as is
  fix2<-data.frame()
  fixNumber<-1
  if (fix$onTargetN[1]==0){
    currentFixStart<-fix[1,"Start"]
    currentFixEnd<-fix[1,"End"]
    durationFix<-fix[1,"Duration"]
    currentFix<-fix[1,"onTarget"]
    transitionFix<-fix[1,"Transition"]
    fix2[fixNumber,"Number"]<-fixNumber
    fix2[fixNumber,"Start"]<-currentFixStart
    fix2[fixNumber,"End"]<-currentFixEnd
    fix2[fixNumber,"Duration"]<-durationFix
    fix2[fixNumber,"onTarget"]<-as.character(currentFix)
    fix2[fixNumber,"Transition"]<-FALSE
    fix2[fixNumber,"onTargetN"]<-0

    #set up next one
    fixNumber<-2 
  }
  numOnTarget<-max(fix$onTargetN)
  if (numOnTarget>0){
    #onTargetN<-1
    for (i in 1:numOnTarget){
      targetFix<-subset(fix,onTargetN==i)
      #first row of targetFix is always on target
      currentFix<-targetFix$onTarget[targetFix$Number==min(targetFix$Number)]
      currentFixStart<-targetFix$Start[targetFix$Number==min(targetFix$Number)]
      currentFixEnd<-max(targetFix$End[targetFix$onTarget==currentFix])
      durationFix<-currentFixEnd-currentFixStart
      fix2[fixNumber,"Number"]<-fixNumber
      fix2[fixNumber,"Start"]<-currentFixStart
      fix2[fixNumber,"End"]<-currentFixEnd
      fix2[fixNumber,"Duration"]<-durationFix
      fix2[fixNumber,"onTarget"]<-as.character(currentFix)
      fix2[fixNumber,"Transition"]<-TRUE
      fix2[fixNumber,"onTargetN"]<-i
      fixNumber<-fixNumber+1
      #if last row is off target
      if (targetFix[nrow(targetFix),"onTarget"]=="Off"){
        fix2[fixNumber,"Number"]<-fixNumber
        fix2[fixNumber,"Start"]<-targetFix[nrow(targetFix),"Start"]
        fix2[fixNumber,"End"]<-targetFix[nrow(targetFix),"End"]
        fix2[fixNumber,"Duration"]<-targetFix[nrow(targetFix),"Duration"]
        fix2[fixNumber,"onTarget"]<-targetFix[nrow(targetFix),"onTarget"]
        fix2[fixNumber,"Transition"]<-FALSE
        fix2[fixNumber,"onTargetN"]<-i
        fixNumber<-fixNumber+1
      } 
    }
  }
  fix2
}

