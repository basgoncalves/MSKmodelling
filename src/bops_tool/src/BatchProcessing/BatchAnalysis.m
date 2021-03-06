function BatchAnalysis

bops = load_setup_bops;

analyses = fields(bops.analyses);
for a = 1:length(analyses)
    
    iAnalysis = analyses{a};
    if bops.analyses.(iAnalysis) == 0
        continue;
    else
        fprintf('running %s ... \n',iAnalysis)
    end
    
    for b = 1:length(bops.subjects)
        for c = 1:length(bops.sessions)
            
            iSubject = bops.subjects{b};
            iSession = bops.sessions{c};
            
            load_subject_settings(iSubject,iSession,iAnalysis);                                                     % updates bops settings with current subject and session
            
            write_bops_log(iAnalysis,'start')
            
            fprintf('%s - %s \n',iSubject,iSession)
            
            switch iAnalysis
                case 'c3d2mat';      C3D2MAT_BOPS                                                                   % convert files from .c3d to .mat files (see ..ElaboratedData\dynamicElaboration)
                case 'acquisition';  AcquisitionInterface_BOPS
                case 'elaboration';  runElaboration_BOPS
                case 'scale';        runScale                                                                       % Linear scale model based on marker data
                case 'ik';           runBOPS_IK
                case 'id';           runBOPS_ID
                case 'rra';          runBOPS_RRA
                case 'id_postrra';   runBOPS_ID_postrra
                case 'lucaoptimizer';runBOPS_LucaOptimizer
                case 'handsfield';   runBOPS_Handsfield
                case 'ma';           runBOPS_MA
                case 'cmc';          runBOPS_CMC
                case 'ceinms';       runBOPS_CEINMS
                case 'so';           runBOPS_SO
                case 'jra';          runBOPS_JRA
                otherwise
            end
            write_bops_log;
        end
    end
end

% --------------------------------------------------------------------------------------------------------------- %
% ---------------------------------------------------- FUCNTIONS ------------------------------------------------ %
% --------------------------------------------------------------------------------------------------------------- %
function runScale
%%
bops = load_setup_bops;
subject = load_subject_settings;

StaticInterface_BOPS;                                                                                               % create static elaboration xml
runStaticElaboration(subject.directories.staticElaborations)                                                        % create trc and mot files

Scale               = xml_read(bops.directories.templates.ScaleTool);
ScalePath           = subject.directories.Scale;
setup_scale_file    = [ScalePath fp 'Setup_Scale.xml'];

StaticTRCfile   = [subject.directories.staticElaborations fp 'static_input.trc'];
TRC             = load_trc_file(StaticTRCfile);

SubjectInfo             = subject.subjectInfo;                                                                      % determine subject subject demographics
Scale.ScaleTool.mass    = SubjectInfo.Mass_kg;
Scale.ScaleTool.height  = SubjectInfo.Height_cm*10;
Scale.ScaleTool.age     = SubjectInfo.Age;

% ----------------------------- CHECK MARKERS SCALE TOOL XML -----------------------------------------
trc             = load_trc_file(StaticTRCfile);
trc_markers     = fields(trc);
Measurements    = Scale.ScaleTool.ModelScaler.MeasurementSet.objects.Measurement;
Nmeasuremtns    = length(Measurements);
checkScaleXML   = 0;
pairs_to_check  = {};

for i = 1:Nmeasuremtns                                                                                              % loop through all the body segments to scale
    iName  = Measurements(i).ATTRIBUTE.name;
    MarkerPair = Measurements(i).MarkerPairSet.objects.MarkerPair;
    NmarkerPairs = length(MarkerPair);
    for i = 1:NmarkerPairs
        iMarkerNames  = split(MarkerPair(i).markers,' ');
        if any(~contains(iMarkerNames,trc_markers))
            checkScaleXML = 1;
            pairs_to_check{end+1} = iName;
        end
    end
end

if checkScaleXML == 1                                                                                               % if markers in  current scale tool do not correspond
    msg = ['please check scale tool marker pairs for'];
    for i = 1:length(pairs_to_check)
        msg = [msg sprintf('\n %s',pairs_to_check{i})];
    end
    winopen(bops.directories.templates.ScaleTool);
    msgbox(msg)
    return
end

MarkerSet = Scale.ScaleTool.MarkerPlacer.IKTaskSet.objects.IKMarkerTask;
for i = flip(1:length(MarkerSet))                                                                                   % loop from the last marker so deletes do not affect indexes
    iName = MarkerSet(i).ATTRIBUTE.name;
    if ~contains(trc_markers,iName)
        MarkerSet(i) = [];
    end
end

% -------------------------------------------        define paths
generic_model_file  = relativepath(subject.directories.OSIM_generic,ScalePath);
marker_file         = relativepath(StaticTRCfile,ScalePath);
output_motion_file  = relativepath([subject.directories.staticElaborations fp 'static_output.mot'],ScalePath);
output_marker_file  = relativepath([subject.directories.staticElaborations fp 'static_output.trc'],ScalePath);
time_range          = [TRC.Time TRC.Time];
model_file          = relativepath([subject.directories.OSIM_LinearScaled],ScalePath);
% ------------------------------------------ create scale xml parameters
Scale.ATTRIBUTE.Version         = '30000';
Scale.ScaleTool.ATTRIBUTE.name  = SubjectInfo.ID;

Scale.ScaleTool.GenericModelMaker.ATTRIBUTE.name    = '';                                                           % GenericModelMaker
Scale.ScaleTool.GenericModelMaker.model_file        = generic_model_file;

Scale.ScaleTool.ModelScaler.ATTRIBUTE.name      = '';                                                               % ModelScaler
Scale.ScaleTool.ModelScaler.marker_file         = marker_file;
Scale.ScaleTool.ModelScaler.time_range          = time_range;
Scale.ScaleTool.ModelScaler.output_scale_file   = relativepath(['.' fp 'Scale_output.xml'],ScalePath);

Scale.ScaleTool.MarkerPlacer.output_motion_file = output_motion_file;                                               % MarkerPlacer
Scale.ScaleTool.MarkerPlacer.output_model_file  = model_file;
Scale.ScaleTool.MarkerPlacer.output_marker_file = output_marker_file;
Scale.ScaleTool.MarkerPlacer.marker_file        = marker_file;
Scale.ScaleTool.MarkerPlacer.IKTaskSet.objects.IKMarkerTask = MarkerSet;
Scale.ScaleTool.MarkerPlacer.time_range         = time_range;

Scale.ScaleTool.COMMENT                     = [];                                                                   % COMMENTS
Scale.ScaleTool.MarkerPlacer.COMMENT        = [];
Scale.ScaleTool.GenericModelMaker.COMMENT   = [];
Scale.ScaleTool.ModelScaler.COMMENT         = [];
Nmeasurments = length([Scale.ScaleTool.ModelScaler.MeasurementSet.objects.Measurement]);
for n=1:Nmeasurments
    Scale.ScaleTool.ModelScaler.MeasurementSet.objects.Measurement(n).COMMENT=[];
    Npairs = length([Scale.ScaleTool.ModelScaler.MeasurementSet.objects.Measurement(n).MarkerPairSet.objects.MarkerPair]);
    for n2=1:Npairs
        Scale.ScaleTool.ModelScaler.MeasurementSet.objects.Measurement(n).MarkerPairSet.objects.MarkerPair(n2).COMMENT=[];
    end
end

root = 'OpenSimDocument';                                                                                           % save xml
Pref = struct;
Pref.StructItem = false;
Pref.CellItem = false;
setupScaleXML = [ScalePath fp 'Setup_Scale.xml'];
Scale = ConvertLogicToString(Scale);
xml_write(setupScaleXML, Scale, root,Pref);
cd(ScalePath)

dos(['scale -S ' setupScaleXML],'-echo');                                                                           % run scale tool

cmdmsg('Model Scaled')

% ---------------------------- print errors -------------------------------------
outlog = [subject.directories.Scale fp 'out.log'];
marker_file = Scale.ScaleTool.MarkerPlacer.marker_file;
output_marker_file = Scale.ScaleTool.MarkerPlacer.output_marker_file;

[TSE,RMSE,MaxError] = plotMarkerErrStatic(outlog,setupScaleXML,marker_file,output_marker_file);
function StaticInterface_BOPS
%%
bops = load_setup_bops;
subject = load_subject_settings;

staticXML               = xml_read(bops.directories.templates.Static);
staticXML.FolderName    = relativepath(subject.directories.Input,bops.directories.mainData);

staticTrials =subject.trials.staticTrials;
if iscell(staticTrials)
    staticXML.TrialName = subject.trials.staticTrials{1};
else
    staticXML.TrialName = subject.trials.staticTrials;
end

data = btk_loadc3d([subject.directories.Input fp staticXML.TrialName '.c3d']);
trc_markers = fields(data.marker_data.Markers);
staticXML.trcMarkers = join(trc_markers,' ');                                                                       % set-up marker set

Njoints = length(staticXML.JCcomputation.Joint);
updateTemplateXML = 0;
for i = 1:Njoints
    
    iJoint      = staticXML.JCcomputation.Joint(i).Name;
    method      = staticXML.JCcomputation.Joint(i).Method;
    OG_markers  = staticXML.JCcomputation.Joint(i).Input.MarkerNames.Marker;
    
    if any(~contains(OG_markers,trc_markers))
        [indx,~] = listdlg('PromptString',['select ' iJoint '-' method ' markers'],'ListString',trc_markers);
        staticXML.JCcomputation.Joint(i).Input.MarkerNames.Marker = trc_markers(indx);
        updateTemplateXML = 1;
    end
end

Pref.StructItem=false;
Pref.CellItem=false;
if updateTemplateXML == 1
    xml_write(bops.directories.templates.Static,staticXML,'static',Pref);                                           % update template XML (in case the new markers were added)
end

xml_write([subject.directories.staticXML],staticXML,'static',Pref);

disp('Static interface complete')
function runBOPS_IK
%%
[bops,subject,elab,acq,trialList,param,rerun] = loadSetupFiles;                                                       % get needed info for the analyes
accuracy = bops.IK.accuracy;

for i = 1:length(trialList)
    
    trialName = trialList{i};
    TimeWindow = param.WindowsSelection.Events{i} ./ acq.VideoFrameRate;
    
    trialAnalysisPath = [subject.directories.IK fp trialName];
    mkdir(trialAnalysisPath);
    cd(trialAnalysisPath)
    
    [osimFiles] = getdirosimfiles_BOPS(trialName,trialAnalysisPath);                                        % get directories of opensim files for this trial
    
    copyfile(osimFiles.coordinates,trialAnalysisPath)                                                               % copy files from the dynamic elaboration folder
    copyfile(osimFiles.externalforces,trialAnalysisPath)                                                            % usefull for checking data in the gui easier
    
    IK = xml_read(bops.directories.templates.IKSetup);                                                              % Edit xml file
    IK.InverseKinematicsTool.COMMENT = {};
    IK.InverseKinematicsTool.ATTRIBUTE.name = trialName;
    IK.InverseKinematicsTool.time_range = TimeWindow;
    IK.InverseKinematicsTool.marker_file = osimFiles.IKcoordinates;
    IK.InverseKinematicsTool.model_file = osimFiles.LinearScaledModel;
    IK.InverseKinematicsTool.output_motion_file = osimFiles.IKresults;
    IK.InverseKinematicsTool.results_directory = osimFiles.IK;
    IK.InverseKinematicsTool.accuracy = accuracy;
    
    usedMarkers = regexp(elab.Markers,' ','split')';                                                                % comapre markerset from elab xml with data from trial
    xmlMarkers = IK.InverseKinematicsTool.IKTaskSet.objects.IKMarkerTask;
    for m = 1: length (xmlMarkers)
        nameMarker = xmlMarkers(m).ATTRIBUTE.name;
        if  isempty(find(strcmp(nameMarker, usedMarkers), 1))                                                       % if marker does not exist in current trial
            xmlMarkers(m).apply = 'false';                                                                          % assign to false in the setup ik xml
        else
            xmlMarkers(m).apply = 'true';
        end
    end
    IK.InverseKinematicsTool.IKTaskSet.objects.IKMarkerTask = xmlMarkers;
    
    nComments = length(IK.InverseKinematicsTool.IKTaskSet.objects.IKCoordinateTask);
    for i = 1:nComments
        IK.InverseKinematicsTool.IKTaskSet.objects.IKCoordinateTask(i).COMMENT = {};                                % delete comments so they XML looks more neat
    end
    
    cd(trialAnalysisPath)                                                                                           % write xml and save gait cycle events
    
    root = 'OpenSimDocument';
    Pref.StructItem = false;
    IK = ConvertLogicToString (IK);
    xml_write(osimFiles.IKsetup, IK, root,Pref);
    
    if rerun==0 && isfile(osimFiles.IKresults); continue; end
    import org.opensim.modeling.*
    dos(['ik -S ' osimFiles.IKsetup],'-echo')                                                                       % run analysis
    
end

cmdmsg('IK finished')
function runBOPS_ID
%%
import org.opensim.modeling.*
[bops,subject,elab,acq,trialList,param,rerun] = loadSetupFiles;
tempSetup = bops.directories.templates.IDSetup;

for i = 10:length(trialList)
    
    trialName = trialList{i};
    TimeWindow = param.WindowsSelection.Events{i} ./ acq.VideoFrameRate;
    
    trialAnalysisPath = [subject.directories.ID fp trialName];                                                      % DEFINE ANALYSIS PATH
    mkdir(trialAnalysisPath);
    cd(trialAnalysisPath)
    
    [osimFiles] = getdirosimfiles_BOPS(trialName,trialAnalysisPath);                                                % get directories of opensim files for this trial
    
    copyfile(osimFiles.coordinates,trialAnalysisPath)                                                               % copy files from the dynamic elaboration folder
    copyfile(osimFiles.externalforces,trialAnalysisPath)                                                            % usefull for checking data in the gui easier
    copyfile(osimFiles.IKresults,trialAnalysisPath)
    
    GRFxml              = xml_read(bops.directories.templates.GRF);                                                 % set GRF xml
    nForcePlates        = length(GRFxml.ExternalLoads.objects.ExternalForce);
    deleteForcePlates   = [];
    
    fld = find(strcmp({acq.Trials.Trial.Type},trialName));
    StanceOnFP = acq.Trials.Trial(fld).StancesOnForcePlatforms.StanceOnFP;
    
    for FP = 1:nForcePlates
        if length(StanceOnFP)< FP  || contains(StanceOnFP(FP).leg,'-')
            deleteForcePlates (end+1) = FP;
            continue
        end
        GRFxml.ExternalLoads.objects.ExternalForce(FP).ATTRIBUTE.name = StanceOnFP(FP).leg;
        GRFxml.ExternalLoads.objects.ExternalForce(FP).applied_to_body =  ['calcn_' lower(StanceOnFP(FP).leg(1))];
        GRFxml.ExternalLoads.objects.ExternalForce(FP).isDisabled = 'false';
    end
    GRFxml.ExternalLoads.objects.ExternalForce(deleteForcePlates)= [];
    GRFxml.ExternalLoads.datafile = osimFiles.IDexternalforces;
    GRFxml.ExternalLoads.external_loads_model_kinematics_file = osimFiles.IDcoordinates;
    
    root = 'OpenSimDocument';
    Pref.StructItem = false;
    xml_write(osimFiles.IDgrfxml, GRFxml, root,Pref);
    
    XML                                             = xml_read(tempSetup);                                          % edit setup xml
    XML.InverseDynamicsTool.COMMENT                 = {};
    XML.InverseDynamicsTool.ATTRIBUTE.name          = trialName;
    XML.InverseDynamicsTool.results_directory       = osimFiles.ID;
    XML.InverseDynamicsTool.time_range              = TimeWindow;
    XML.InverseDynamicsTool.coordinates_file        = osimFiles.IDcoordinates;
    XML.InverseDynamicsTool.output_gen_force_file   = osimFiles.IDresults;
    XML.InverseDynamicsTool.model_file              = osimFiles.LinearScaledModel;
    XML.InverseDynamicsTool.external_loads_file     = osimFiles.IDgrfxml;
    
    xml_write(osimFiles.IDsetup, XML, root,Pref);
    
    if rerun==0 && isfile(osimFiles.IDresults); continue; end
    
    
    [~,log_mes] = dos(['id -S ' osimFiles.IDsetup],'-echo');                                                        % run analysis
    disp([trialName ' ID Done.']);
    
end

cmdmsg(['ID finished: ' bops.current.subject ' - ' bops.current.session])
function runBOPS_RRA
[bops,subject,elab,acq,trialList,param,rerun] = loadSetupFiles;                                                       % get needed info for the analyes

for i = 1:length(trialList)
    
    trialName   = trialList{i};
    TimeWindow  = param.WindowsSelection.Events{i} ./ acq.VideoFrameRate;
    initialTime = TimeWindow(1);
    finalTime   = TimeWindow(2);
    
    trialAnalysisPath = [subject.directories.RRA fp trialName];                                                     % DEFINE ANALYSIS PATH
    mkdir(trialAnalysisPath);
    cd(trialAnalysisPath)
    
    [osimFiles] = getdirosimfiles_BOPS(trialName,trialAnalysisPath);                                                % get directories of opensim files for this trial
    
    copyfile(osimFiles.coordinates,trialAnalysisPath)                                                               % copy files from the dynamic elaboration folder
    copyfile(osimFiles.externalforces,trialAnalysisPath)                                                            % usefull for checking data in the gui easier
    copyfile(osimFiles.IKresults,trialAnalysisPath)
    
    copyfile(bops.directories.templates.RRATaks,osimFiles.RRAtasks)
    copyfile(bops.directories.templates.RRAActuators,osimFiles.RRAactuators)
    copyfile(bops.directories.templates.RRASetup,osimFiles.RRAsetup)
    
    adjustTaskXML(osimFiles.RRAtasks,100,100,100,1,1,1,1,100)                                                       % adjustTaskXML(TaskFile,hip,knee,ankle,lumbar,arm,elbow,pro,pelvis)
    
    adjustActuatorXML(osimFiles.RRAactuators,1000,1000,1000,1000,500,500,500,1)                                     % adjustActuatorXML(ActuatorFile,hip,knee,ankle,lumbar,arm,elbow,pro,pelvis)
    
    RRAxml                                                      = xml_read(osimFiles.RRAsetup);
    RRAxml.RRATool.model_file                                   = osimFiles.LinearScaledModel;
    RRAxml.RRATool.ATTRIBUTE.name                               = trialName;
    RRAxml.RRATool.replace_force_set                            = 'true';
    RRAxml.RRATool.solve_for_equilibrium_for_auxiliary_states   = 'true';
    RRAxml.RRATool.results_directory                            = osimFiles.RRA;
    RRAxml.RRATool.output_precision                             = 16;
    RRAxml.RRATool.desired_kinematics_file                      = osimFiles.RRAdesired_kinematics_file;
    RRAxml.RRATool.external_loads_file                          = osimFiles.RRAexternal_loads_file;
    RRAxml.RRATool.force_set_files                              = osimFiles.RRAactuators;
    RRAxml.RRATool.lowpass_cutoff_frequency                     = 6;
    RRAxml.RRATool.task_set_file                                = osimFiles.RRAtasks;
    RRAxml.RRATool.output_model_file                            = osimFiles.RRAmodel;
    RRAxml.RRATool.adjust_com_to_reduce_residuals               = 'true';
    RRAxml.RRATool.adjusted_com_body                            = 'torso';
    RRAxml.RRATool.initial_time                                 = initialTime;
    RRAxml.RRATool.final_time                                   = finalTime;
    RRAxml.RRATool.initial_time_for_com_adjustment              = initialTime;
    RRAxml.RRATool.final_time_for_com_adjustment                = finalTime;
    RRAxml.RRATool.defaults.CMC_Joint.active                    = ['false ' 'false ' 'false'];                      % tranform these from double to string
    RRAxml.RRATool.defaults.PointActuator.point                 = ['0 ' '0 ' '0'];
    RRAxml.RRATool.defaults.PointActuator.direction             = ['-1 ' '0 ' '0'];
    RRAxml.RRATool.defaults.TorqueActuator.axis                 = ['-1 ' '-0 ' '-0'];
    RRAxml.RRATool.use_verbose_printing                         = 'false';
    
    root = 'OpenSimDocument';
    xml_write(osimFiles.RRAsetup, RRAxml,root);
    
    if rerun==0 && isfile(osimFiles.RRA); continue; end
    
    import org.opensim.modeling.*
    cd(osimFiles.RelPath);
    dos(['rra -S ' osimFiles.RRAsetup],'-echo');                                                                      % run analysis
    disp([trialName ' RRA Done.']);
    
end

dirRRA      = subject.directories.RRA;
in_model    = subject.directories.OSIM_LinearScaled;
out_model   = subject.directories.OSIM_RRA;

adjustmodelmass_Average(dirRRA,in_model,out_model,trialList);

cmdmsg(['RRA finished: ' bops.current.subject ' - ' bops.current.session])
function runBOPS_LucaOptimizer
%%
[bops,subject,elab,acq,trialList,param,rerun] = loadSetupFiles;                                                       % get needed info for the analyes

if ~isfile(subject.directories.OSIM_LO) || rerun == 1; return; end

reference_model     = subject.directories.OSIM_LinearScaled;
target_model        = subject.directories.OSIM_RRA;
N_eval              = bops.lucaoptimizer.N_eval;

LucaOptimizer_BG(reference_model,target_model,N_eval)

cmdmsg(['LucaOptimizer finished: ' bops.current.subject ' - ' bops.current.session])
function runBOPS_Handsfield
%%
[~,subject,~,~,~,~,rerun] = loadSetupFiles;                                                                          % get needed info for the analyes
if ~isfile(subject.directories.OSIM_LO_HANS) || rerun == 1; return; end
in_model    = subject.directories.OSIM_LO;
out_model   = subject.directories.OSIM_LO_HANS;
mass        = subject.subjectInfo.Mass_kg;
height      = subject.subjectInfo.Height_cm/100;

scaleStrengthHandsfiedReg(in_model,out_model,mass,height)
function runBOPS_MA
%%
[bops,subject,elab,acq,trialList,param,rerun] = loadSetupFiles;
for i = 1:length(trialList)
    
    trialName = trialList{i};
    TimeWindow = param.WindowsSelection.Events{i} ./ acq.VideoFrameRate;
    
    trialAnalysisPath = [subject.directories.MA fp trialName];                                                      % DEFINE ANALYSIS PATH
    mkdir(trialAnalysisPath);
    cd(trialAnalysisPath)
    
    [osimFiles] = getdirosimfiles_BOPS(trialName,trialAnalysisPath);                                                % get directories of opensim files for this trial
    
    copyfile(bops.directories.templates.MASetup,osimFiles.MAsetup)
    
    import org.opensim.modeling.*
    osimModel   = Model(osimFiles.MAmodel);
    analyzeTool = AnalyzeTool(osimFiles.MAsetup);
    
    analyzeTool.setModel(osimModel);
    analyzeTool.setModelFilename(osimModel.getDocumentFileName());
    analyzeTool.setReplaceForceSet(false);
    analyzeTool.setResultsDir(osimFiles.MA);
    analyzeTool.setOutputPrecision(8)
    analyzeTool.setInitialTime(TimeWindow(1));
    analyzeTool.setFinalTime(TimeWindow(2));
    analyzeTool.setSolveForEquilibrium(false)
    analyzeTool.setMaximumNumberOfSteps(20000)
    analyzeTool.setMaxDT(1)
    analyzeTool.setMinDT(1e-008)
    analyzeTool.setErrorTolerance(1e-005)
    analyzeTool.setCoordinatesFileName(osimFiles.IKresults)
    analyzeTool.setExternalLoadsFileName(osimFiles.IDgrfxml)
    analyzeTool.print(osimFiles.MAsetup);
    
    if rerun==0 && isfile(osimFiles.MA_FiberLength); continue; end
    
    disp(trialName)
    analyzeTool.run;
    
end
function runBOPS_CMC
[bops,subject,elab,acq,trialList,param,rerun] = loadSetupFiles;
for i = 1:length(trialList)
    
    trialName = trialList{i};
    TimeWindow = param.WindowsSelection.Events{i} ./ acq.VideoFrameRate;
    
    trialAnalysisPath = [subject.directories.CMC fp trialName];                                                      % DEFINE ANALYSIS PATH
    mkdir(trialAnalysisPath);
    cd(trialAnalysisPath)
    
    [osimFiles] = getdirosimfiles_BOPS(trialName,trialAnalysisPath);                                                % get directories of opensim files for this trial
    
    copyfile(bops.directories.templates.CMCSetup,osimFiles.CMCsetup)
    copyfile(bops.directories.templates.CMCControls,osimFiles.CMCControlConstraints)
    copyfile(bops.directories.templates.CMCtasks,osimFiles.CMCtasks)
    copyfile(bops.directories.templates.CMCactuators,osimFiles.CMCactuators)
    copyfile(osimFiles.IKresults,osimFiles.CMC)
       
    CMC = xml_read(osimFiles.CMCsetup);
    CMC.CMCTool.model_file                                  = osimFiles.CMCmodel;
    CMC.CMCTool.force_set_files                             = osimFiles.CMCactuators;
    CMC.CMCTool.results_directory                           = osimFiles.CMCresults;
    CMC.CMCTool.initial_time                                = TimeWindow(1);
    CMC.CMCTool.final_time                                  = TimeWindow(2);
    CMC.CMCTool.replace_force_set                           = 'false';
    CMC.CMCTool.solve_for_equilibrium_for_auxiliary_states  = 'true';
    CMC.CMCTool.use_fast_optimization_target                = 'true';
    CMC.CMCTool.use_verbose_printing                        = 'false';
    CMC.CMCTool.integrator_error_tolerance                  = bops.analyses_settings.cmc.ErrorTolerance;
    CMC.CMCTool.external_loads_file                         = osimFiles.CMCexternal_loads_file;
    CMC.CMCTool.desired_kinematics_file                     = osimFiles.CMCkinematics;
    CMC.CMCTool.task_set_file                               = osimFiles.CMCtasks;
    CMC.CMCTool.constraints_file                            = osimFiles.CMCControlConstraints;
    CMC.CMCTool.cmc_time_window                             = bops.analyses_settings.cmc.cmc_time_window;
    
    CMC.CMCTool.AnalysisSet.objects.Kinematics.coordinates      = 'all';
    CMC.CMCTool.AnalysisSet.objects.Kinematics.on               = 'true';
    CMC.CMCTool.AnalysisSet.objects.Kinematics.start_time       = TimeWindow(1);
    CMC.CMCTool.AnalysisSet.objects.Kinematics.end_time         = TimeWindow(2);
    CMC.CMCTool.AnalysisSet.objects.Kinematics.step_interval    = bops.analyses_settings.cmc.step_interval;
    CMC.CMCTool.AnalysisSet.objects.Kinematics.in_degrees        = 'true';
    
    CMC.CMCTool.AnalysisSet.objects.Actuation.on                = 'true';
    CMC.CMCTool.AnalysisSet.objects.Actuation.start_time        = TimeWindow(1);
    CMC.CMCTool.AnalysisSet.objects.Actuation.end_time          = TimeWindow(2);
    CMC.CMCTool.AnalysisSet.objects.Actuation.step_interval     = bops.analyses_settings.cmc.step_interval;
    CMC.CMCTool.AnalysisSet.objects.Actuation.in_degrees        = 'true';
    
    root = 'OpenSimDocument';
    Pref.StructItem = false;
    cd(trialAnalysisPath)
    xml_write(osimFiles.CMCsetup, CMC, root,Pref);
       
    if rerun==0 && isfile(osimFiles.CMC_force); continue; end
    
    disp(trialName)
    import org.opensim.modeling.*
    
    if bops.osimVersion < 4    
        [~,log_mes] = dos(['cmc -S ' osimFiles.CMCsetup],'-echo');                                                          % run analysis
        disp([trialName ' CMC Done.']);
    else
    end
    
end
function runBOPS_CEINMS
%%
[bops,subject,elab,acq,trialList,param,rerun] = loadSetupFiles;                                                       % get needed info for the analyes

Dir                 = subject.directories;
Temp                = bops.directories.templates;
CEINMSSettings      = subject.ceinms;
SubjectInfo         = subject.subjectInfo;
trialListXML        = generateTrialsXml(Dir,CEINMSSettings,Trials.Dynamic,1);                                % create xml files | last argument 1 = write the xml 0 = do not write xml

generateExecutionXml (Dir,Temp,CEINMSSettings,SubjectInfo ,trialListXML)
if ~exist(CEINMSSettings.outputSubjectFilename,'file')
    if ~exist(CEINMSSettings.subjectFilename)
        copyfile(Temp.CEINMSuncalibratedmodel,CEINMSSettings.subjectFilename)
    end
    
    if ~contains(Trials.CEINMScalibration,Trials.MA) || ~contains(Trials.CEINMScalibration,Trials.IK)
        cmdmsg('trial does have muscle analysis / inverse dynamics, skiping CEINMS calibration')
    end
    
    dofListCell = split(CEINMSSettings.dofList ,' ')';
    convertOsimToSubjectXml(SubjectInfo.ID,CEINMSSettings.osimModelFilename,dofListCell,CEINMSSettings.subjectFilename, Temp.CEINMSuncalibratedmodel)
    AddDannyTendon(CEINMSSettings.subjectFilename)
    AddContactModel(Dir,Temp,CEINMSSettings)
    generateCalibrationSetup_BG(Dir,CEINMSSettings);
    generateCalibrationCfg(Dir,CEINMSSettings, Temp,trialListXML,Trials.CEINMScalibration);
    
    updateLogAnalysis(Dir,'CEINMS Calibration',SubjectInfo,'start')
    disp(['CEINMS calibration running for ' SubjectInfo.ID ' ...'])
    
    
    cd(Dir.CEINMScalibration);
    [~,log] = dos([Dir.CEINMSexePath fp 'CEINMScalibrate -S ' CEINMSSettings.calibrationSetup]);                % run CEINMS calibration
    cmdmsg(['CEINMS calibration complete for ' SubjectInfo.ID])
    
    CheckCalibratedValues(CEINMSSettings.outputSubjectFilename,CEINMSSettings.subjectFilename,SubjectInfo.InstrumentedSide)
    updateLogAnalysis(Dir,'CEINMS Calibration',SubjectInfo,'end')
end

if WalkingCalibration==1; trialList = [Trials.Walking];                                                         % CEINMS execution (EMG assisted)
else; trialList = [Trials.MA]; end

CalibratedSubjectRelativePaths(CEINMSSettings.subjectFilename,Dir.OSIM_LO)
CalibratedSubjectRelativePaths(CEINMSSettings.outputSubjectFilename,Dir.OSIM_LO)
%     CEINMSStaticOpt_BG (Dir,CEINMSSettings,SubjectInfo,trialList) % for static Opt

if Logic==1 || ~exist(CEINMSSettings.excitationGeneratorFilename2ndCal)
    RedoSecondCalibration(Dir); % reset the folders as if to match end of first calibration (comment if not needed)
    CEINMSSettings=CEINMSdoubleCalibration_BG(Dir,CEINMSSettings,SubjectInfo,Trials.CEINMScalibration);  % second calibration
end
idx = find(contains(trialList,'walking')| contains(trialList,'baseline')&contains(trialList,'1'));

if contains(SubjectInfo.TestedLeg,'R')
    idx = find(contains(trialList,'baseline')&contains(trialList,'2'));
else
    idx = find(contains(trialList,'baseline')&contains(trialList,'3'));
end

trialList=trialList([idx]);
%     RedoExecutions(Dir)     % reset the simulations folder (comment if not needed)
CEINMSmultipleTrials_BG(Dir,CEINMSSettings,SubjectInfo,trialList(1:end),Logic)
function runBOPS_SO
%%
import org.opensim.modeling.*
[bops,subject,elab,acq,trialList,param,rerun] = loadSetupFiles;
tempSetup = bops.directories.templates.SOSetup;

for i = 1:length(trialList)
    
    warning off
    trialName = trialList{i};
    trialAnalysisPath = [subject.directories.SO fp trialName];                                                      % DEFINE ANALYSIS PATH
    mkdir(trialAnalysisPath);
    cd(trialAnalysisPath)
    
    [osimFiles] = getdirosimfiles_BOPS(trialName,trialAnalysisPath);                                                % get directories of opensim files for this trial
    
    copyfile(bops.directories.templates.SOActuators,osimFiles.SOactuators)
    
    hip     = 1;
    knee    = 1;
    ankle   = 1;
    lumbar  = 100;
    mtp     = 1;
    pelvis  = 500;
    adjustActuatorXML_Gait2392(osimFiles.SOactuators,hip,knee,ankle,lumbar,mtp,pelvis)                              % adjustActuatorXML_Gait2392(ActuatorFile,hip,knee,ankle,lumbar,mtp,pelvis)
    
    xml = xml_read(tempSetup);                                                                                      % setup xml
    xml.AnalyzeTool.ATTRIBUTE.name = '';
    xml.AnalyzeTool.model_file          = osimFiles.SOmodel;
    xml.AnalyzeTool.results_directory   = osimFiles.SO;
    xml.AnalyzeTool.coordinates_file    = osimFiles.SOkinematics;
    xml.AnalyzeTool.external_loads_file = osimFiles.SOexternal_loads_file;
    xml.AnalyzeTool.force_set_files     = osimFiles.SOactuators;
    xml.AnalyzeTool.force_set_files     = '';
    
    motData = load_sto_file(osimFiles.SOkinematics);                                                                % Get mot data to determine time range
    xml.AnalyzeTool.initial_time                                    = motData.time(1);
    xml.AnalyzeTool.final_time                                      = motData.time(end);
    xml.AnalyzeTool.output_precision                                = '4';
    xml.AnalyzeTool.lowpass_cutoff_frequency_for_load_kinematics    = -1;                                           % the default value is -1.0, so no filtering
    xml.AnalyzeTool.replace_force_set                               = 'false';
    
    xml.AnalyzeTool.AnalysisSet.objects.StaticOptimization.on                               = 'true';
    xml.AnalyzeTool.AnalysisSet.objects.StaticOptimization.in_degrees                       = 'true';
    xml.AnalyzeTool.AnalysisSet.objects.StaticOptimization.use_model_force_set              = 'true';
    xml.AnalyzeTool.AnalysisSet.objects.StaticOptimization.use_muscle_physiology            = 'true';
    xml.AnalyzeTool.AnalysisSet.objects.StaticOptimization.optimizer_max_iterations         = 100;
    xml.AnalyzeTool.AnalysisSet.objects.StaticOptimization.optimizer_convergence_criterion  = 0.001;
    
    root = 'OpenSimDocument';
    Pref.StructItem = false;
    xml_write(osimFiles.SOsetup, xml, root,Pref);                                                                   % save setup xml
    
    cd(osimFiles.SO)
    dos(['analyze -S ',osimFiles.SOsetup]);                                                                         % run static optimization tool in OpenSim
end
function runBOPS_JRA
%%
function  [bops,subject,elab,acq,trialList,param,rerun] = loadSetupFiles
%%
bops        = load_setup_bops;
subject     = load_subject_settings;
elab        = xml_read(subject.directories.elaborationXML);                                                         % load elaboration xml
acq         = xml_read(subject.directories.acquisitionXML);                                                         % load acq xml
trialList   = split(elab.Trials,' ')';                                                                              % get trials from xml
param       = parametersGeneration(elab);                                                                           % get parameters from elaboration XML
rerun       = bops.current.rerun;

function outputTrialList = generateTrialsXml(Dir,CEINMSSettings,trialList,PrintXML)
%% select only the trials that have been completely processed
mkdir(Dir.CEINMStrials); %outputDir
outputTrialList ={};
disp('Generating Trial XML files ...')
for trialIdx=1:length(trialList)
    currentTrial = char(trialList(trialIdx));
    
    trialFilename = [Dir.CEINMStrials fp currentTrial '.xml'];
    lmtMaDir = [Dir.MA fp currentTrial];
    
    if exist([lmtMaDir fp '_MuscleAnalysis_FiberForce.sto'])
        outputTrialList{end+1} = trialFilename;
        disp (['Generating ' currentTrial])
        lmtFile = relativepath(getFile(lmtMaDir, '_Length'),Dir.CEINMStrials);
        maData = getMomentArmsFiles(lmtMaDir, '_MomentArm_' ,Dir.CEINMStrials);
        emgFile = relativepath(getFile([Dir.dynamicElaborations fp currentTrial], 'emg'),Dir.CEINMStrials);
        
        if contains(CEINMSSettings.osimModelFilename,'_rra_')
            extTorqueFile = relativepath(getFile([Dir.ID fp currentTrial], 'inverse_dynamics_RRA'),Dir.CEINMStrials);
        else
            extTorqueFile = relativepath(getFile([Dir.ID fp currentTrial], 'inverse_dynamics'),Dir.CEINMStrials);
        end
        motionFile = relativepath(getFile([Dir.IK fp currentTrial], 'IK.mot'),Dir.CEINMStrials);
        externalLoadsFile = relativepath(getFile([Dir.ID fp currentTrial], 'grf.xml'),Dir.CEINMStrials);
        XML = xml_read(getFile([Dir.IK fp currentTrial], 'setup_IK'));
        TimeWindow = XML.InverseKinematicsTool.time_range;
        %         TimeWindow(2) = TimeWindow(2) + 0.02;
        
        if ~exist('PrintXML') || PrintXML==1
            writeTrial(trialFilename, lmtFile, emgFile, maData, extTorqueFile, motionFile,externalLoadsFile,TimeWindow);
        end
    end
end

disp('Trial XML files generated')

function generateExecutionXml (Dir,Temp,CEINMSSettings,SubjectInfo,trialList)
%%
if ~exist(CEINMSSettings.excitationGeneratorFilename)
    copyfile(Temp.CEINMSexcitationGenerator,CEINMSSettings.excitationGeneratorFilename)
end

[~,Adjusted,Synt] = createExcitationGenerator_FAIS(Dir,CEINMSSettings,SubjectInfo);

model = CEINMSSettings.nmsModel_exe;
temp_cfg_exe    = Temp.CEINMScfgExe;
file_out        = CEINMSSettings.exeCfg;
dofList         = CEINMSSettings.dofList;
writeExecutionCFGxml_BG(model,temp_cfg_exe,file_out,dofList,Adjusted,Synt)                                          % generate the execution configuration xml

for ii = 1: length(trialList)                                                                                       % generate the execution setup xml (one for each trial)
    
    trialName                           = strrep(split(trialList{ii},fp),'.xml','');
    trialName                           = trialName{end};
    setupxml                            = xml_read(Temp.CEINMSsetupExe);
    setupxml.subjectFile                = relativepath(CEINMSSettings.outputSubjectFilename, Dir.CEINMSsetup);
    setupxml.inputDataFile              = relativepath([Dir.CEINMStrials fp trialName '.xml'],Dir.CEINMSsetup);
    setupxml.outputDirectory            = relativepath([Dir.CEINMSsimulations fp trialName], Dir.CEINMSsetup);
    setupxml.executionFile              = relativepath(CEINMSSettings.exeCfg, Dir.CEINMSsetup);
    setupxml.excitationGeneratorFile    =  relativepath(CEINMSSettings.excitationGeneratorFilename, Dir.CEINMSsetup);
    
    Pref.StructItem = false;
    cd(Dir.CEINMSsetup)
    xml_write([trialName '.xml'], setupxml, 'ceinms' ,Pref);
end

disp('CEINMS files created - time for CALIBRATIOOOOOOON')

function [quality,Adjusted,Synt] = createExcitationGenerator_FAIS(Dir,CEINMSSettings,SubjectInfo)
%%
load ([Dir.Elaborated fp 'BadTrials.mat'])

quality  = mean(cell2mat(BadTrials),2); % calculate the mean accross trials
dofList = split(CEINMSSettings.dofList ,' ')';
S = getOSIMVariablesFAI(SubjectInfo.TestedLeg,CEINMSSettings.osimModelFilename,dofList);

exctGern = xml_read(CEINMSSettings.excitationGeneratorFilename);
Adjusted =[]; Synt=[];
for m = 1:length(exctGern.mapping.excitation)
    muscle = exctGern.mapping.excitation(m).ATTRIBUTE.id;
    if ~contains(muscle,S.AllMuscles)
        continue
    end
    
    if ~isempty(exctGern.mapping.excitation(m).input)
        row = [];
        for k = 1:length(exctGern.mapping.excitation(m).input)
            row = [row find(strcmp(strtrim(allMuscles),exctGern.mapping.excitation(m).input(k).CONTENT))];
        end
        if ~isempty(row) && mean(quality(row)) == 0
            Adjusted = [Adjusted muscle ' '];
        elseif ~isempty(row) && mean(quality(row)) > 0
            Synt = [Synt muscle ' '];
            exctGern.mapping.excitation(m).input = [];
        else
            Synt = [Synt muscle ' '];
        end
    else
        Synt = [Synt muscle ' '];
    end
end


xml_write(CEINMSSettings.excitationGeneratorFilename,exctGern,'excitationGenerator');

disp('Adjusted Muscles')
disp(Adjusted)
disp('Synthesised Muscles')
disp(Synt)
disp(' ')
disp(['EMGS signals not used'; allMuscles(quality>0)])
disp(' ')
