%% Script to gather data for PLS analysis - Generate X0 matrix of brain variables

%% 1) Make X0 matrix of brain variables  - Build X0 matrix from multiple Excel files
% (N x M matrix, N is #subjects, M is #imaging variables)

% This script reads data from multiple Excel files and creates a wide matrix
% where each folder contributes its own set of columns

clear all; close all; clc;

%% ==================== USER CONFIGURATION SECTION ====================

% Define common root path (change this to your actual root path)
rootPath = 'E:\ConcettiC\PPPD_for_Caps\CAPs_analysis\';  

% Define common subfolder path (the part after the specific folder)
commonSubfolder = 'fromHC_PopMask\K3\R_output\for_cor\';  % 

% Define the Excel filename (same for all folders)
excelFilename = 'CAPs_and_CRF_for_corr.xlsx';  % 

% Define the list of specific folders (one per subject/session)
specificFolders = {'19_Newprepro_woExcMo_CAPsScriptBased_CaudateBilat', ...
    '21_Newprepro_woExcMo_CAPsScriptBased_rTPJ', ...
    '23_Newprepro_woExcMo_CAPsScriptBased_OP2Bilat', ...
    '24_Newprepro_woExcMo_CAPsScriptBased_Hippocampus'};  

% Option 2: Auto-detect folders (uncomment if you want to use this instead)
% folderList = dir(fullfile(rootPath, '*'));
% specificFolders = {folderList([folderList.isdir] & ~ismember({folderList.name}, {'.', '..'})).name};

% Define column indices (based on your description)
% Columns: ID, State, duration_value, ReOccurence_value, ReEntries_value
COL_ID = 1;
COL_STATE = 2;
COL_DURATION = 3;
COL_REOCCURRENCE = 4;
COL_REENTRIES = 5;

% Number of states per ID (in this case always 3)
NUM_STATES = 3;

%% ==================== EXTRACT FOLDER TOKENS ====================

% Extract folder tokens (last part after last underscore)
folderTokens = cell(length(specificFolders), 1);
for f = 1:length(specificFolders)
    parts = strsplit(specificFolders{f}, '_');
    folderTokens{f} = parts{end};
end

% Get unique folder tokens (in case multiple folders share same token)
[uniqueTokens, ~, tokenMap] = unique(folderTokens, 'stable');
numUniqueTokens = length(uniqueTokens);

fprintf('Found %d unique folder tokens:\n', numUniqueTokens);
for t = 1:numUniqueTokens
    fprintf('  Token %d: %s\n', t, uniqueTokens{t});
end
fprintf('\n');

%% ==================== MAIN PROCESSING (WITH FOLDER TRACKING) ====================

% Initialize cell arrays to store all data
allIDs = {};           % Store all IDs
allFolderTokens = {};  % Store folder token for each ID's data
allDataRows = {};      % Store numeric data for each ID (as row vector)

% Counter for number of files processed
numFilesProcessed = 0;

% Loop through each specific folder
for f = 1:length(specificFolders)
    
    % Construct full file path
    fullPath = fullfile(rootPath, specificFolders{f}, commonSubfolder, excelFilename);
    
    % Check if file exists
    if ~exist(fullPath, 'file')
        warning('File not found: %s. Skipping...', fullPath);
    end
    
    fprintf('Processing file %d/%d: %s\n', f, length(specificFolders), fullPath);
    
    % Read the Excel file (only first 5 columns)
    try
        % Read all rows, first 5 columns
        rawData = readtable(fullPath, 'Range', 'A:E', 'VariableNamingRule', 'preserve');
        
        % Extract columns as variables
        IDs = table2cell(rawData(:, COL_ID));
        states = table2array(rawData(:, COL_STATE));
        duration_values = table2array(rawData(:, COL_DURATION));
        reoccurrence_values = table2array(rawData(:, COL_REOCCURRENCE));
        reentries_values = table2array(rawData(:, COL_REENTRIES));
        
        % Verify that number of rows is a multiple of NUM_STATES
        numRows = length(states);
        if mod(numRows, NUM_STATES) ~= 0
            error('In file %s: Number of rows (%d) is not a multiple of %d', ...
                  fullPath, numRows, NUM_STATES);
        end
        
        % Find unique IDs in this file
        uniqueIDs = unique(IDs, 'stable');
        numSubjects = length(uniqueIDs);
        
        % Get folder token for this file
        currentToken = folderTokens{f};
        
        % Reshape data for this file and store
        for subj = 1:numSubjects
            currentID = uniqueIDs{subj};
            
            % Find rows for this subject (should be exactly NUM_STATES rows)
            idx = strcmp(IDs, currentID);
            
            if sum(idx) ~= NUM_STATES
                warning('Subject %s in folder %s has %d rows (expected %d). Skipping...', ...
                        currentID, specificFolders{f}, sum(idx), NUM_STATES);
            end
            
            % Extract data for this subject (should be in order: State1, State2, State3)
            subjDuration = duration_values(idx);
            subjReOccurrence = reoccurrence_values(idx);
            subjReEntries = reentries_values(idx);
            
            % Verify states are in correct order (1,2,3)
            subjStates = states(idx);
            if ~isequal(size(subjStates, 1), NUM_STATES)
                warning('Subject %s in folder %s states not in order. Found: %s', ...
                        currentID, specificFolders{f}, num2str(size(subjStates, 1)));
                % Continue anyway, assuming order is correct
            end
            
            % Build the numeric data row for this subject (excluding ID)
            numericRow = [];
            for s = 1:NUM_STATES
                numericRow = [numericRow, subjDuration(s), subjReOccurrence(s), subjReEntries(s)];
            end
            
            % Store the data
            allIDs = [allIDs; currentID];
            allFolderTokens = [allFolderTokens; currentToken];
            allDataRows = [allDataRows; {numericRow}];
        end
        
        numFilesProcessed = numFilesProcessed + 1;
        
    catch ME
        warning('Error processing file %s: %s', fullPath, ME.message);
        continue;
    end
end

%% ==================== CHECK FOR PROCESSING SUCCESS ====================

if isempty(allIDs)
    error('No data was loaded. Please check your file paths and data.');
end

fprintf('\nTotal files processed: %d\n', numFilesProcessed);
fprintf('Total subject-folder combinations loaded: %d\n', length(allIDs));

%% ==================== CREATE WIDE MATRIX ====================

% Get all unique IDs across all folders
uniqueAllIDs = unique(allIDs, 'stable');
numTotalSubjects = length(uniqueAllIDs);

% Use unique folder tokens (from earlier)
numTotalTokens = length(uniqueTokens);

% Build column names for final wide matrix
% Format: [FolderToken]_[VariableName]
wideVarNames = {'ID'};  % Start with ID column

for tIdx = 1:numTotalTokens
    folderToken = uniqueTokens{tIdx};
    for s = 1:NUM_STATES
        wideVarNames = [wideVarNames, ...
            sprintf('%s_State%d_duration', folderToken, s), ...
            sprintf('%s_State%d_ReOccurrence', folderToken, s), ...
            sprintf('%s_State%d_ReEntries', folderToken, s)];
    end
end

% Initialize wide table with NaN
wideTable = table();
wideTable.ID = uniqueAllIDs;

% Initialize all numeric columns with NaN
numNumericCols = 3 * NUM_STATES * numTotalTokens;
for v = 1:numNumericCols
    wideTable.(wideVarNames{v+1}) = NaN(numTotalSubjects, 1);
end

% Create a mapping from folder token to column indices
tokenToColMap = containers.Map();
for tIdx = 1:numTotalTokens
    folderToken = uniqueTokens{tIdx};
    % Find columns that start with this token
    colPattern = sprintf('%s_', folderToken);
    colIndices = find(startsWith(wideVarNames, colPattern));
    tokenToColMap(folderToken) = colIndices;
end

% Fill in the data
fprintf('\nPopulating wide matrix...\n');
for row = 1:length(allIDs)
    currentID = allIDs{row};
    currentToken = allFolderTokens{row};
    currentData = allDataRows{row};  % This is already a 1x(3*NUM_STATES) vector
    
    % Find the row index in wideTable for this ID
    idRowIdx = find(strcmp(wideTable.ID, currentID));
    
    % Get column indices for this token
    colIndices = tokenToColMap(currentToken);
    
    % Assign data (subtract 1 from colIndices because wideVarNames includes 'ID' as column 1)
    wideTable{idRowIdx, colIndices} = currentData;
end

%% ==================== VERIFY DATA INTEGRITY ====================

% Check if any ID appears multiple times within the same folder
fprintf('\nChecking for duplicate ID-folder combinations...\n');
[idFolderCombos, ~, ~] = unique(strcat(allIDs, '_', allFolderTokens), 'stable');
if length(idFolderCombos) < length(allIDs)
    warning('Duplicate ID-folder combinations found! Some data may have been overwritten.');
end

% Show which IDs have data from which folders
fprintf('\nData coverage summary:\n');
for tIdx = 1:numTotalTokens
    folderToken = uniqueTokens{tIdx};
    colIndices = tokenToColMap(folderToken);
    % Check first column of this token to see if data exists
    firstColData = ~isnan(wideTable{:, colIndices(1)});
    numPresent = sum(firstColData);
    fprintf('  %s: %d/%d subjects (%.1f%%)\n', ...
            folderToken, numPresent, numTotalSubjects, 100*numPresent/numTotalSubjects);
end

%% ==================== CREATE FINAL X0 MATRIX ====================

% Option 1: X0 as numeric matrix (excluding ID column)
X0_numeric = table2array(wideTable(:, 2:end));
N = size(X0_numeric, 1);  % Number of subjects
M = size(X0_numeric, 2);  % Number of variables (3*NUM_STATES * numTotalTokens)

% Option 2: X0 as table with ID (recommended for clarity)
X0_table = wideTable;

% Option 3: X0 as cell array with ID
X0_cell = [wideTable.ID, num2cell(X0_numeric)];

% Choose your preferred format
X0 = X0_numeric;  % Pure numeric matrix
X0_with_ID = X0_table;  % Table format with IDs

%% ==================== DISPLAY RESULTS ====================

fprintf('\n==================== RESULTS ====================\n');
fprintf('Final X0 matrix dimensions: %d subjects x %d variables\n', N, M);
fprintf('Number of numeric variables: %d (excluding ID column)\n', M);
fprintf('Variables per folder: %d\n', 3*NUM_STATES);
fprintf('Total unique folder tokens: %d\n', numTotalTokens);
fprintf('\nColumn names (first 10 shown):\n');
if length(wideVarNames) > 10
    for i = 1:min(10, length(wideVarNames))
        fprintf('  %s\n', wideVarNames{i});
    end
    fprintf('  ... and %d more\n', length(wideVarNames)-10);
else
    for i = 1:length(wideVarNames)
        fprintf('  %s\n', wideVarNames{i});
    end
end

fprintf('\nFirst 5 rows of X0 (as table):\n');
if height(X0_table) > 5
    disp(X0_table(1:5, 1:min(10, width(X0_table))));
    if width(X0_table) > 10
        fprintf('  ... and %d more columns\n', width(X0_table)-10);
    end
else
    disp(X0_table(:, 1:min(10, width(X0_table))));
end

% Show missing data summary
missingCount = sum(isnan(X0_numeric), 'all');
totalElements = numel(X0_numeric);
fprintf('\nMissing data summary:\n');
fprintf('  Total missing values (NaN): %d (%.2f%%)\n', missingCount, 100*missingCount/totalElements);

%% ==================== SAVE RESULTS (OPTIONAL) ====================

% Uncomment to save results
cd('F:\CC_PLSC_Analysis')
 save('X0_wide_matrix.mat', 'X0', 'X0_table', 'X0_cell', 'wideVarNames', 'uniqueTokens');
 writetable(X0_table, 'X0_wide_output.xlsx');

fprintf('\nScript completed successfully!\n');