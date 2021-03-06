
% inputs = weights for each coordinate
function adjustTaskXML(TaskFile,hip,knee,ankle,lumbar,arm,elbow,pro,pelvis)


XML = xml_read(TaskFile); % use to change the parameters of the acuator xml
for ii = 1:length(XML.CMC_TaskSet.objects.CMC_Joint)
    if contains(XML.CMC_TaskSet.objects.CMC_Joint(ii).coordinate,'hip')
        XML.CMC_TaskSet.objects.CMC_Joint(ii).weight = hip;
    elseif contains(XML.CMC_TaskSet.objects.CMC_Joint(ii).coordinate,'knee')
         XML.CMC_TaskSet.objects.CMC_Joint(ii).weight = knee;
    elseif contains(XML.CMC_TaskSet.objects.CMC_Joint(ii).coordinate,'ankle')
         XML.CMC_TaskSet.objects.CMC_Joint(ii).weight = ankle;
    elseif contains(XML.CMC_TaskSet.objects.CMC_Joint(ii).coordinate,'lumbar')
         XML.CMC_TaskSet.objects.CMC_Joint(ii).weight = lumbar;
    elseif contains(XML.CMC_TaskSet.objects.CMC_Joint(ii).coordinate,'arm')
         XML.CMC_TaskSet.objects.CMC_Joint(ii).weight = arm;
    elseif contains(XML.CMC_TaskSet.objects.CMC_Joint(ii).coordinate,'elbow')
         XML.CMC_TaskSet.objects.CMC_Joint(ii).weight = elbow;
    elseif contains(XML.CMC_TaskSet.objects.CMC_Joint(ii).coordinate,'pro')
         XML.CMC_TaskSet.objects.CMC_Joint(ii).weight = pro;
    elseif contains(XML.CMC_TaskSet.objects.CMC_Joint(ii).coordinate,'pelvis')
         XML.CMC_TaskSet.objects.CMC_Joint(ii).weight = pelvis;
    end
    XML.CMC_TaskSet.objects.CMC_Joint(ii).active = ['true ' 'false ' 'false'];
end


XML = ConvertLogicToString(XML,'filter_on');
XML = ConvertLogicToString(XML,'on');
XML = ConvertLogicToString(XML,'is_model_control');
XML = ConvertLogicToString(XML,'extrapolate');
XML = ConvertLogicToString(XML,'use_steps');
XML = ConvertLogicToString(XML,'isDisabled');
XML = ConvertLogicToString(XML,'point_is_global');
XML = ConvertLogicToString(XML,'force_is_global');
XML = ConvertLogicToString(XML,'torque_is_global');
XML = ConvertLogicToString(XML,'show_axes');
XML = ConvertLogicToString(XML,'show_axes');


CMC_Joint = XML.CMC_TaskSet.objects.CMC_Joint;
for i = 1:length(CMC_Joint)
    CMC_Joint(i).COMMENT = {};
    
end
XML.CMC_TaskSet.objects.CMC_Joint = CMC_Joint;

root = 'OpenSimDocument';
xml_write(TaskFile, XML,root);

