%% Estrazione punteggi WATERLOO

mainFolder = uigetdir(pwd, 'Seleziona la cartella principale');

% Verifica se la cartella è stata selezionata
if mainFolder == 0
    error('Nessuna cartella selezionata.');
end

% Nome del file Excel di output aggregato
allFile = fullfile(mainFolder, 'Waterloo_ALL.xlsx');

% Controlla se il file esiste, altrimenti lo crea con intestazioni
if ~isfile(allFile)
    infoHeaders = {'patientID', 'COUNTSDM', 'Per_countSDM', 'COUNTDDM', 'Per_countDDM', 'COUNTEMM', 'Per_countEMM',...
        'COUNTDSM', 'Per_countDSM', 'COUNTSSM', 'Per_countSSM', 'COUNTSDF', 'Per_countSDF', 'COUNTDDF', 'Per_countDDF',...
        'COUNTSEM', 'Per_countSEM', 'COUNTDSF', 'Per_countDSF', 'COUNTSSF', 'Per_countSSF'};
    writecell(infoHeaders, allFile);
end

% Ottieni tutte le sottocartelle nella cartella principale
subFolders = dir(mainFolder);
subFolders = subFolders([subFolders.isdir] & ~startsWith({subFolders.name}, '.'));

% Iterazione su ogni sottocartella
for i = 1:length(subFolders)
    patientID = subFolders(i).name;
    resultsFolder = fullfile(mainFolder, patientID, 'RESULTS');

    % Selezione del file WATERLOO.txt
    docFile = fullfile(resultsFolder, 'WATERLOO.txt');

    % Verifica se il file DOC_EVAL.txt esiste
    if ~isfile(docFile)
        fprintf('WATERLOO.txt non trovato per il soggetto %s. Saltato.\n', patientID);
        continue;
    end

    % Lettura del file WATERLOO.txt
    fileData = fileread(docFile);

    % Definizione delle chiavi nell'ordine desiderato
    keys = { 'SD_TOT_MANO', 'SD_%_MANO', 'DD_TOT_MANO', 'DD_%_MANO', ...
             'EM_TOT_MANO', 'EM_%_MANO', 'DS_TOT_MANO', 'DS_%_MANO', ...
             'SS_TOT_MANO', 'SS_%_MANO', 'SD_TOT_PIEDE', 'SD_%_PIEDE', ...
             'DD_TOT_PIEDE', 'DD_%_PIEDE', 'EM_TOT_PIEDE', 'EM_%_PIEDE', ...
             'DS_TOT_PIEDE', 'DS_%_PIEDE', 'SS_TOT_PIEDE', 'SS_%_PIEDE' };
    
    values = nan(1, length(keys)); % Inizializza array di numeri con NaN
    
    % Estrazione dei valori per ogni chiave
    for k = 1:length(keys)
        pattern = sprintf('%s:\\s*([\\d\\.]+)', keys{k}); % Uso corretto di \\s
        match = regexp(fileData, pattern, 'tokens', 'once');
        if ~isempty(match)
            values(k) = str2double(match{1});
            values(k) = round(values(k),2);
        end
    end
    
    % Preparazione della riga per il file Excel
    infoRow = [{patientID}, num2cell(values)];

    % Aggiunta della riga al file Excel _ALL.xlsx
    writecell(infoRow, allFile, 'WriteMode', 'append');
end

disp('Processo completato.');