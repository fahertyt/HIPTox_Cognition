
% function merge_ERT
%
%% Script created to merge csv results files for Cognitive Tasks %%
%
% Tom Faherty, 16th March 2023
%
% Loads each individual csv results file and removes unecessary rows before merging together
% Removes unecessary rows and sorts into participant and session order
% Must make sure this script is within the same folder as csv files prior to running
%
%% SET UP SOME VARIABLES %%

allFiles = dir('*.csv');

for n = 1:length(allFiles)

% Set import options (because of issue with incorrect dates otherwise)

currentName = allFiles(n).name;

opts = detectImportOptions(currentName);
opts = setvartype(opts, 'char');

% Convert to table

currentTable = readtable(currentName, 'NumHeaderLines',1, 'DatetimeType', 'text');

% Fix the date issue here

newDates = datetime(currentTable.Date,'InputFormat','dd/MM/yy', 'format', 'dd/MM/yyyy');

currentTable.Date = newDates;

% Now add current table onto the big table!

if n == 1
    newTable = currentTable;
else
    newTable = outerjoin(newTable,currentTable,'MergeKeys', true);
end

clearvars currentTable

end

% Sort into participant, visit, session, then trial order

newTable = sortrows(newTable,[1 2 3 7]);

% Save as xlsx

writetable(newTable, 'Merged_ERT.xlsx')

% End!