function Plot_MuscleContributions_Average

Dir = getdirFAI;
cd(Dir.Results_Cont2HCF)
load([Dir.Results_JCFFAI fp 'Paper4results.mat']);
load([Dir.Results_JCFFAI fp 'CEINMSdata.mat']);

savedir = ([Dir.Results_JCFFAI fp 'MuscleContributions_Plots']);
if ~exist(savedir); mkdir(savedir); end

muscleGroups =  struct;
muscleGroups.Iliopsoas     = {['iliacus'],['psoas']};
muscleGroups.Hamstrings    = {['bflh'],['bfsh'],['semimem'],['semiten']};
muscleGroups.Gmax          = {['glmax1'],['glmax2'],['glmax3']};
muscleGroups.Gmed          = {['glmed1'],['glmed2'],['glmed3']};
muscleGroups.Gmin          = {['glmin1'],['glmin2'],['glmin3']};
muscleGroups.RecFem        = {['recfem']};
muscleGroups.TFL           = {['tfl']};
muscleGroups.Adductors     = {['addbrev'],['addlong'],['addmagDist'],['addmagIsch'],['addmagMid'],['addmagProx'],['grac']};
muscleGroups.Vasti         = {['vasint'],['vaslat'],['vasmed']};
muscleGroups.Gastroc       = {['gaslat'],['gasmed']};
muscleGroups.Soleus        = {['soleus']};
muscleGroups.Tibilais      = {['tibant']};

muscleGroupsNames  = fields(muscleGroups);

muscleNames = fields(contributions2HCF.hip_x);
n_musc = length(muscleNames);

for isubj = 1:length(Subjects)
    
    curr_subj = Subjects{isubj};
    subj_cols = find(contains(trialType,curr_subj));
    
    force_names = {'Fx' 'Fy' 'Fz' 'Fresultant'};
    
    disp(curr_subj)
    
    sumHCF_subject = CEINMSData.participants;
    sumHCF_subject_col = find(contains(sumHCF_subject,curr_subj));
    
    for iF = 1:length(force_names)
        
        curr_force = force_names{iF};
        force_var = ['hip_' strrep(curr_force,'F','')];
        
        sumHCF = [];
        sumHCF(:,1) = CEINMSData.ContactForces.(force_var).RunStraight1(:,sumHCF_subject_col);             % select sum of HCF (per component) - Run 1
        sumHCF(:,2) = CEINMSData.ContactForces.(force_var).RunStraight2(:,sumHCF_subject_col);             % ... Run 2
        sumHCF = nanmean(sumHCF,2);
        
        N_muscleGroups = length(muscleGroupsNames);
        [ha, pos,FirstCol,LastRow,LastCol] = tight_subplotBG(N_muscleGroups,0, 0.02, 0.05, 0.05,0.95);
        for imusc_group = 1:N_muscleGroups
            musc_cont = [];
            for imusc = 1:n_musc
                curr_muscleGroup = muscleGroupsNames{imusc_group};
                muscles_to_group = muscleGroups.(curr_muscleGroup);
                curr_musc = muscleNames{imusc};
                if ~any(contains(muscles_to_group,curr_musc))
                    continue
                end
                musc_cont(:,end+1) = nanmean(contributions2HCF.(force_var).(curr_musc)(:,subj_cols),2);
            end
            
            axes(ha(imusc_group));hold on;
            plot_muscle_cont = plot(musc_cont);
            plot_HCF = plot(sumHCF,'LineWidth',2,'Color',[0.5 0 0.2]);
            
            title(curr_muscleGroup)
            if any(imusc_group==FirstCol) && ~any(imusc_group==LastRow)
                ylabel('Contribution to HCF (N)')
            elseif ~any(imusc_group==FirstCol) && any(imusc_group==LastRow)
                xlabel('% gait cycle')
            elseif any(imusc_group==FirstCol) && any(imusc_group==LastRow)
                xlabel('% gait cycle')
                ylabel('Contribution to HCF (N)')
            end
            
            legend([muscles_to_group 'All muscles'])
        end
                
        tight_subplot_ticks (ha,LastRow,FirstCol)
        mmfn
        suptitle(curr_force)
        saveas(gcf,[savedir fp [curr_force '_' curr_subj '.jpeg']])
        close all
    end
end


disp('plotting complete')

function mmfn(xlb,ylb)

set(gcf,'Color',[1 1 1]);
grid off
fig=gcf;
N =  length(fig.Children);
for ii = 1:N
    set(fig.Children(ii),'box', 'off')
    if contains(class(fig.Children(ii)),'Axes')
        fig.Children(ii).FontName = 'Times New Roman';
        fig.Children(ii).Title.FontWeight = 'Normal';
    end
end

if nargin>0
    xlabel(xlb)
end

if nargin>1
    ylabel(ylb)
end


