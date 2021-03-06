function [SESSION, Subject, EMG] = importEMGExist(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as column vectors.
%   Reads data from text file FILENAME for the default selection.
%   
%
% Example:
%   [SESSION,Subject1,EMG1,Subject2,EMG2,Subject3,EMG3,Subject4,EMG4,Subject5,EMG5,Subject6,EMG6,Subject7,EMG7,Subject8,EMG8,Subject9,EMG9,Subject10,EMG10,Subject11,EMG11,Subject12,EMG12,Subject13,EMG13,Subject14,EMG14,Subject15,EMG15,Subject16,EMG16,Subject17,EMG17,Subject18,EMG18,Subject19,EMG19,Subject20,EMG20,Subject21,EMG21]
%   = importfile('emgExists.csv',2, 14);
%
%    See also TEXTSCAN.

%% Initialize variables.
delimiter = ',';
if nargin<=2
     startRow = 2;
     endRow = inf;
end

%% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
     frewind(fileID);
     dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
     for col=1:length(dataArray)
          dataArray{col} = [dataArray{col};dataArrayBlock{col}];
     end
end

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
     raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43]
     % Converts strings in the input cell array to numbers. Replaced non-numeric
     % strings with NaN.
     rawData = dataArray{col};
     for row=1:size(rawData, 1);
          % Create a regular expression to detect and remove non-numeric prefixes and
          % suffixes.
          regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
          try
               result = regexp(rawData{row}, regexstr, 'names');
               numbers = result.numbers;
               
               % Detected commas in non-thousand locations.
               invalidThousandsSeparator = false;
               if any(numbers==',');
                    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                    if isempty(regexp(thousandsRegExp, ',', 'once'));
                         numbers = NaN;
                         invalidThousandsSeparator = true;
                    end
               end
               % Convert numeric strings to numbers.
               if ~invalidThousandsSeparator;
                    numbers = textscan(strrep(numbers, ',', ''), '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
               end
          catch me
          end
     end
end

%% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43]);
rawCellColumns = raw(:, [2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42]);


%% Replace non-numeric cells with 0.0
R = cellfun(@(x) (~isnumeric(x) && ~islogical(x)) || isnan(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {0.0}; % Replace non-numeric cells

%% Allocate imported array to column variable names
SESSION = cell2mat(rawNumericColumns(:, 1));
Subject = rawCellColumns(:, 1);
EMG = cell2mat(rawNumericColumns(:, 2));


