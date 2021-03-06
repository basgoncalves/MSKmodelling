%% Description - Basilio Goncalves (2020)
% https://www.researchgate.net/profile/Basilio_Goncalves
% add the contact model and OSIM model to the  uncalibrated CEINMS subject
%-------------------------------------------------------------------------
%% EditCalibratedSubject 

function AdjustDofDListOnly(CEINMSmodel,osimModelFilename,dofList)

fp = filesep;
SubjectXML = xml_read (CEINMSmodel);

import org.opensim.modeling.*

dofToMuscles = containers.Map();
osimModel = Model(osimModelFilename);
osimModel.initSystem();

for i=1:length(dofList)
    currentDofName = dofList{i};
    dofToMuscles(currentDofName) = getMusclesOnDof(currentDofName, osimModel);
end

for iDof=1:length(dofList)
    dof = dofList{iDof};
    SubjectXML.dofSet.dof(iDof).name = dof;
    muscles = dofToMuscles(dof);
    muscleList = [];
    for j = 1:length(muscles)  
            muscleList = [muscleList, ' ', muscles{j}];
    end
    muscleList =  strrep (muscleList, ' obt_internus_r1','');
    muscleList =  strrep (muscleList, ' quad_fem_r','');
    muscleList =  strrep (muscleList, ' obt_internus_l1','');
    muscleList =  strrep (muscleList, ' quad_fem_l','');
    SubjectXML.dofSet.dof(iDof).mtuNameSet = muscleList;
end


%conver the curve data to strings
for k = 1:length({SubjectXML.mtuDefault.curve.xPoints})
    SubjectXML.mtuDefault.curve(k).xPoints = num2str(SubjectXML.mtuDefault.curve(k).xPoints);
    SubjectXML.mtuDefault.curve(k).yPoints = num2str(SubjectXML.mtuDefault.curve(k).yPoints);
end
for k = 1:length({SubjectXML.mtuSet.mtu.name})
    if isfield(SubjectXML.mtuSet.mtu(k),'curve') && ~isempty(SubjectXML.mtuSet.mtu(k).curve)
        SubjectXML.mtuSet.mtu(k).curve.xPoints = num2str(SubjectXML.mtuSet.mtu(k).curve.xPoints);
        SubjectXML.mtuSet.mtu(k).curve.yPoints = num2str(SubjectXML.mtuSet.mtu(k).curve.yPoints);
    end
end

prefXmlWrite.StructItem = false; prefXmlWrite.CellItem = false; % allow arrays of structs to use 'item' notation
xml_write(CEINMSmodel, SubjectXML, 'subject', prefXmlWrite);% save model

cmdmsg(['Subject calibration directories converted to relative path '])
disp(Model)
