
function Plot_Mean_CP_ID

fp = filesep;

DirElaboratedData = uigetdir('select folder with elaborated session');                      % Escolher pasta session1_barefoot   
cd(DirElaboratedData)
dirID = [DirElaboratedData fp 'inverseDynamics'];
dirSession = [DirElaboratedData fp 'session_data'];
[~,session_name] = DirUp(DirElaboratedData,1);
[~,subject] = DirUp(DirElaboratedData,2);
dirC3d = [DirUp(DirElaboratedData,3) fp 'InputData' fp subject fp session_name];

eventDir = [DirUp(DirElaboratedData,3) fp 'events.xlsx'];
events = importdata(eventDir);
event_labels = events(1,:);
col_trial   = contains(event_labels,'trial');
col_leg     = contains(event_labels,'leg');
col_start   = contains(event_labels,'start');
col_finish  = contains(event_labels,'finish');

events = events(2:end,:);                                                                                           % Tirar de comentário se já for a segunda vez a

Trials = dir(dirID);
nTrials = length(Trials);

coor = {['hip_flexion'],['hip_adduction'],['hip_rotation'],['knee_angle'],['ankle_angle']};
groupData = struct;
data_column = struct;
for c = 1:length(coor)
    groupData.(coor{c}) = [];
    data_column.(coor{c}) = [];
end

trialName_all = {};
trial_leg = {};
for i = 3:nTrials
    
    trialName   = Trials(i).name;
    trial_data  = load_sto_file([dirID fp trialName fp 'inverse_dynamics.sto']);
    
    row_trial = find(contains(events(:,col_trial),trialName));
    leg = events{row_trial,col_leg};
    
    if contains(leg,'-')
        continue                                                                                                     % segue para proxima iteracao
    end
    
    c3dfilepath = [dirC3d fp trialName '.c3d'];
    c3dfilepath = strrep(c3dfilepath,'__','_');
    
    try    data = btk_loadc3d(c3dfilepath);
    catch; continue
    end
    
    if contains(leg,'r')
        event_1 = 'Right_Foot_Strike';
        event_2 = 'Right_Foot_Off';
    elseif contains(leg,'l')
        event_1 = 'Left_Foot_Strike';
        event_2 = 'Left_Foot_Off';
    end
    
    t1 = data.Events.Events.(event_1);
    t2 = data.Events.Events.(event_2);
    
    start = find(round(trial_data.time,4)==round(t1,4));
    finish = find(round(trial_data.time,4)==round(t2,4));
    
    % add to events.xlsx
    events{row_trial,col_start}  = round(t1,4);
    events{row_trial,col_finish} = round(t2,4);
    
    coor_trial = strcat(coor,['_' leg '_moment']);
    
    for c = 1:length(coor)
        data_column = trial_data.(coor_trial{c})(start:finish,1);
        groupData.(coor{c})(:,end+1) = TimeNorm(data_column,100);
    end
    
    trialName_all{end+1} = trialName;                                                                               % add names of trials to a single variable
    trial_leg{end+1}     = leg;
end

% xlswrite(eventDir,events)

ha = tight_subplotBG(1,5,0.05,0.05,0.1,[9 376 1904 432]); % ha = tight_subplotBG(Nh, Nw, gap, marg_h, marg_w,Size (ha = handle axis)

nTrials = length(trialName_all);
Colors = cell(nTrials,1);
Colors(contains(trial_leg,'r'),:) = {[1 0 0]};          % make colors for right leg = red
Colors(contains(trial_leg,'l'),:) = {[0 0 1]};          % make colors for left leg = blue
Colors = flip(Colors);

pos_x = [0.05:0.15:0.65];
fld = fields(groupData);
Titles = {'hip flexion (flexion+)','hip frontaal (adduction +)','hip transverse (internal +)','knee sagittal (flexion +)','ankle sagittal (dorsiflex +)'};

for i = 1:5
    ha(i).Position = [pos_x(i) 0.05 0.12 0.9];
    axes(ha(i))
    plot(groupData.(fld{i}))
    colorPlot (ha(i),Colors)
    title(Titles{i})
    if i == 1
        ylabel('internal moment (Nm)')
        lg = legend(trialName_all);
        lg.Position = [0.82 0.2 0.14 0.2];
    end
end

mmfn_inspect

function TimeNormalizedData = TimeNorm (Data,fs)

TimeNormalizedData=[];

for col = 1: size (Data,2)
    
    currentData = Data(:,col);
    currentData(isnan(currentData))=[];
    if length(currentData)<3
        TimeNormalizedData(1:101,col)= NaN;
        continue
    end
    
    timeTrial = 0:1/fs:size(currentData,1)/fs;
    timeTrial(end)=[];
    Tnorm = timeTrial(end)/101:timeTrial(end)/101:timeTrial(end);
    
    TimeNormalizedData(1:101,col)= interp1(timeTrial,currentData,Tnorm)';
end


function colorPlot (ha,Colors)  
% ha = handle axes
hp = ha.Children;                       % plot handle

for i = 1:length(hp)
   hp(i).Color = (Colors{i}); 
end