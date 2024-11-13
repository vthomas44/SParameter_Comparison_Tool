function compareSnpFilesBasedOnUserInput()
    % Step 1: Ask for the number of ports
    numPorts = input('Enter the number of ports: ');
    
    % Step 2: Ask for the number of files to compare
    numFiles = input('Enter the number of files to compare: ');
    
    % Initialize variables to store file data
    sParams = cell(1, numFiles);
    filePaths = cell(1, numFiles);
    
    % Step 3: File selection
    for i = 1:numFiles
        [file, path] = uigetfile(sprintf('*.s%dp', numPorts), sprintf('Select file #%d', i));
        if isequal(file, 0)
            disp('File selection cancelled.');
            return;
        else
            filePaths{i} = fullfile(path, file);
            sParams{i} = sparameters(filePaths{i});
        end
    end
    
    % After files are loaded, create the GUI and automatically plot S11
    createGUI(numPorts, sParams, 'S11', filePaths);
end

function createGUI(numPorts, sParams, defaultSParam, filePaths)
    % Create figure
    fig = uifigure('Name', 'S-Parameters Comparison', 'Position', [100, 100, 800, 600]);
    
    % Axes for plotting
    ax = uiaxes(fig, 'Position', [20, 100, 760, 480]);
    
    % Generate dropdown items based on the number of ports
    spLabels = generateSPLabels(numPorts);
    
    % Dropdown for S-parameter selection
    ddSParam = uidropdown(fig, 'Position', [20, 50, 100, 22], ...
                          'Items', spLabels, 'Value', defaultSParam, ...
                          'ValueChangedFcn', @(dd, event) plotSelectedSParam(dd, sParams, ax, filePaths));
    
    % Button for exporting to Image
    exportImgBtn = uibutton(fig, 'Position', [130, 50, 150, 22], ...
                             'Text', 'Export to Image', ...
                             'ButtonPushedFcn', @(btn,event) exportPlotToImage(ax));
    
    % Automatically plot the default S-parameter (e.g., S11)
    plotSelectedSParam(ddSParam, sParams, ax, filePaths);
end

function exportPlotToImage(ax)
    % Ask user for file name and type
    [file, path] = uiputfile({'*.png';'*.jpg';'*.tif';'*.bmp'}, 'Save Image As');
    if isequal(file, 0) || isequal(path, 0)
        disp('User canceled image export.');
        return;
    end
    
    % Full file path
    fullPath = fullfile(path, file);
    
    % Export the current axes to the selected file
    exportgraphics(ax, fullPath, 'Resolution', 300);
    
    % Notify user
    disp(['Plot exported to image file: ', fullPath]);
end


function spLabels = generateSPLabels(numPorts)
    labels = arrayfun(@(i,j) sprintf('S%d%d', i, j), repmat(1:numPorts, numPorts, 1), repmat((1:numPorts)', 1, numPorts), 'UniformOutput', false);
    spLabels = labels(:)';
end

function plotSelectedSParam(dd, sParams, ax, filePaths)
    selectedParam = dd.Value;
    tokens = regexp(selectedParam, '^S(\d+)(\d+)$', 'tokens');
    
    if isempty(tokens)
        disp('Invalid S-parameter format selected.');
        return;
    end
    
    row = str2double(tokens{1}{1});
    col = str2double(tokens{1}{2});
    
    cla(ax); % Clear previous plots
    hold(ax, 'on');
    
    legendEntries = {}; % Initialize an empty cell array for legend entries
    
    for i = 1:numel(sParams)
        if row <= sParams{i}.NumPorts && col <= sParams{i}.NumPorts
            freq = sParams{i}.Frequencies / 1e9; % Convert frequency to GHz
            sData = squeeze(sParams{i}.Parameters(row, col, :));
            % Extract just the file name from the full path for the legend
            [~, fileName, ext] = fileparts(filePaths{i});
            legendName = [fileName, ext];
            plot(ax, freq, 20*log10(abs(sData)), 'DisplayName', legendName, 'LineWidth', 1.5);
            legendEntries{end+1} = legendName; % Add the file name to the list of legend entries
        else
            disp(['Selected S-parameter ', selectedParam, ' exceeds bounds for File ', num2str(i)]);
        end
    end
    
    hold(ax, 'off');
    % Update the legend after plotting. This ensures the legend is correctly displayed for the new selection.
    legend(ax, legendEntries, 'Interpreter', 'none', 'Location', 'best');
    ax.Title.String = sprintf('Comparison of %s', selectedParam);
    ax.XLabel.String = 'Frequency (GHz)';
    ax.YLabel.String = 'Magnitude (dB)';
    grid(ax, 'on');
end


