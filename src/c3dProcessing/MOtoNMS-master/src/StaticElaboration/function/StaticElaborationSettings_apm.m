function [foldersPath,parameters]= StaticElaborationSettings_apm(ConfigFilePath, sessionFolder, staticTrial)
%
% The file is part of matlab MOtion data elaboration TOolbox for
% NeuroMusculoSkeletal applications (MOtoNMS). 
% Copyright (C) 2012-2014 Alice Mantoan, Monica Reggiani
%
% MOtoNMS is free software: you can redistribute it and/or modify it under 
% the terms of the GNU General Public License as published by the Free 
% Software Foundation, either version 3 of the License, or (at your option)
% any later version.
%
% Matlab MOtion data elaboration TOolbox for NeuroMusculoSkeletal applications
% is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
% PARTICULAR PURPOSE.  See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along 
% with MOtoNMS.  If not, see <http://www.gnu.org/licenses/>.
%
% Alice Mantoan, Monica Reggiani
% <ali.mantoan@gmail.com>, <monica.reggiani@gmail.com>

%%

try
    staticSettings=xml_read([ConfigFilePath filesep 'static.xml']);
%     disp(['Running ' ConfigFilePath filesep 'static.xml'])
catch
    disp('static.xml file not found in the specified path')
end

%Acquisition.xml file path reconstruction
i=strfind(ConfigFilePath,'ElaboratedData');
y = regexp(staticSettings.FolderName, sessionFolder);
expression  = staticSettings.FolderName(y:end);
staticSettings.FolderName = regexprep(staticSettings.FolderName, expression, sessionFolder); % Replace old session name with current

% Remove Wrist Joint centre computation
acquisitionPath=[ConfigFilePath(1:(i-1)) staticSettings.FolderName(3:end)];

%Acquisition Info: load acquisition.xml
acquisitionInfo=xml_read([acquisitionPath filesep 'acquisition.xml']);

staticSettings.TrialName = staticTrial;

%Folders Definition
foldersPath=foldersPathsDefinition_apm(acquisitionPath,staticSettings.TrialName,ConfigFilePath);

%Parameters.mat file Generation
parameters=staticParametersGeneration(staticSettings,acquisitionInfo,foldersPath);