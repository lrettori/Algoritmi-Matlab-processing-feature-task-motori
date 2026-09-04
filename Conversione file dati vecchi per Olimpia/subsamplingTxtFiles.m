% Script per elaborare file TXT in una cartella selezionata
% Sottocampionamento dei segnali con una waitbar

% Aprire una finestra di dialogo per selezionare la cartella
folderPath = uigetdir([], 'Seleziona la cartella contenente i file TXT');
if folderPath == 0
    disp('Nessuna cartella selezionata. Script terminato.');
    return;
end

% Recupera tutti i file .txt nella cartella
fileList = dir(fullfile(folderPath, '*.txt'));

% Verifica se ci sono file nella cartella
if isempty(fileList)
    disp('Nessun file TXT trovato nella cartella selezionata.');
    return;
end

% Creare la cartella "subsampled" per salvare i file elaborati
subsampledFolderPath = fullfile(folderPath, 'subsampled');
if ~exist(subsampledFolderPath, 'dir')
    mkdir(subsampledFolderPath);
end

% Inizializza la waitbar
hWaitbar = waitbar(0, 'Elaborazione dei file in corso...', 'Name', 'Sottocampionamento dei file TXT');

% Itera attraverso tutti i file .txt nella cartella
numFiles = length(fileList);
for i = 1:numFiles
    fileName = fileList(i).name;
    filePath = fullfile(folderPath, fileName);
    
    % Legge il contenuto del file
    fileContent = fileread(filePath);
    lines = splitlines(fileContent);
    
    % Estrai l'header e i dati
    header = lines(1:9); % Le prime 9 righe sono l'header
    dataLines = lines(10:end); % Le righe successive sono i dati
    
    % Modifica la settima riga dell'header per riflettere il nuovo numero di campioni
    originalNumSamples = str2double(extractAfter(header{7}, 'N. Samples'));
    newNumSamples = ceil(originalNumSamples / 2);
    header{7} = sprintf('N. Samples\t%d', newNumSamples);
    
    % Sottocampiona i dati, prendendo una riga ogni due
    dataLines = dataLines(1:2:end);
    
    % Scrivi il nuovo file con i dati sottocampionati nella cartella "subsampled"
    newFilePath = fullfile(subsampledFolderPath, fileName);
    fid = fopen(newFilePath, 'w');
    
    % Scrivi l'header
    for j = 1:length(header)
        fprintf(fid, '%s\n', header{j});
    end
    
    % Scrivi i dati, rispettando il delimitatore tab
    for j = 1:length(dataLines)
        % Splitta la linea per assicurarsi di mantenere il formato
        lineParts = split(dataLines{j}, '\t');
        fprintf(fid, '%s', lineParts{1}); % Timestamp
        for k = 2:length(lineParts)
            fprintf(fid, '\t%s', lineParts{k}); % Altri dati separati da tab
        end
        fprintf(fid, '\n'); % Fine riga
    end
    
    fclose(fid);
    
    % Aggiorna la waitbar
    waitbar(i / numFiles, hWaitbar, sprintf('Elaborazione file %d di %d...', i, numFiles));
end

% Chiudi la waitbar
close(hWaitbar);

disp('Elaborazione completata.');