function [LEJC,REJC,markers_ejc,markersNames_ejc]=EJCcomputation(method,input,protocolMLabels,markers)
% Function for Ankle Joint Center Computation
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

[markersNames_ejc,markers_ejc]= JCmarkersDefintion(input,protocolMLabels,markers,'Elbow');


switch method
    
    case 'EJCMidPoint'
    
        [REJC, LEJC]=MidPoint(markers_ejc);

    %case
    %ADD HERE MORE METHODS
    %...        
    
    otherwise
        error('EJC Method missing')
end

% disp('LEJC and REJC have been computed')

