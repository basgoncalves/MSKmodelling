function soObj = createStaticOptimizationObj (initial_time, final_time)
% Function to initialize a Static Optimization object for the Analyze Tool

% This file is part of Batch OpenSim Processing Scripts (BOPS).
% Copyright (C) 2015 Alice Mantoan, Monica Reggiani
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Alice Mantoan, Monica Reggiani
% <ali.mantoan@gmail.com>, <monica.reggiani@gmail.com>


%%

import org.opensim.modeling.*

soObj= StaticOptimization();

soObj.setOn(true);
soObj.setStartTime(initial_time);
soObj.setEndTime(final_time);

soObj.setStepInterval(1)
soObj.setInDegrees(true)
soObj.setUseModelForceSet(true)
soObj.setActivationExponent(2)
soObj.setUseMusclePhysiology(true)
soObj.setConvergenceCriterion(0.0001)
soObj.setMaxIterations(100)
