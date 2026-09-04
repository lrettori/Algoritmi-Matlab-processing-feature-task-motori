function processFoldersAndGenerateDaphneScores()
    % Seleziona la cartella principale tramite finestra di dialogo
    mainFolder = uigetdir(pwd, 'Seleziona la cartella principale');
    if mainFolder == 0
        disp('Operazione annullata.');
        return;
    end

    % Ottieni tutte le sottocartelle nella cartella principale
    folders = dir(mainFolder);
    folders = folders([folders.isdir]);

    % Escludi le cartelle "." e ".."
    folders = folders(~ismember({folders.name}, {'.', '..'}));

    % Ottieni l'elenco dei test dall'esempio di DAPHNE_Scores.txt
    daphneTemplate = readtable('DAPHNE_Scores.txt', 'Delimiter', '\t', 'ReadVariableNames', true);
    testNames = daphneTemplate.TEST_Name;

    % Mappature per DOC_EVAL e DOC_SCORE
    evalMapping = readtable('evalMapping.csv', 'Delimiter', '\t', 'ReadVariableNames', true);
    scoreMapping = readtable('scoreMapping.csv', 'Delimiter', '\t', 'ReadVariableNames', true);

    % Inizializza la barra di caricamento
    totalFolders = numel(folders);
    progressBar = waitbar(0, 'Elaborazione in corso...', 'Name', 'Creazione DAPHNE_Scores.txt');

    % Itera su ciascuna sottocartella
    for i = 1:totalFolders
        waitbar(i / totalFolders, progressBar, sprintf('Elaborazione %d di %d...', i, totalFolders));

        currentFolder = fullfile(mainFolder, folders(i).name);

        % Cerca il file DOC_SCORE.txt o DOC_EVAL.txt nella sottocartella RESULTS
        resultsFolder = fullfile(currentFolder, 'RESULTS');
        if ~isfolder(resultsFolder)
            continue;
        end

        docScorePath = fullfile(resultsFolder, 'DOC_SCORE.txt');
        docEvalPath = fullfile(resultsFolder, 'DOC_EVAL.txt');

        if isfile(docScorePath)
            dataFile = docScorePath;
            mapping = scoreMapping;
            isEval = false;
        elseif isfile(docEvalPath)
            dataFile = docEvalPath;
            mapping = evalMapping;
            isEval = true;
        else
            continue;
        end

        % Leggi e processa i dati dal file selezionato
        scoresTable = processDataFile(dataFile, testNames, mapping, isEval);

        % Trova la cartella di destinazione
        targetFolders = {'1-T0_0', '2-T0_0', '3-T0_0', '4-T0_0', '4-T20_0', '4-T50_0'};
        destinationFolder = '';
        for j = 1:numel(targetFolders)
            potentialFolder = fullfile(currentFolder, targetFolders{j});
            if isfolder(potentialFolder)
                destinationFolder = potentialFolder;
                break;
            end
        end

        if isempty(destinationFolder)
            continue;
        end

        % Scrivi il file DAPHNE_Scores.txt nella cartella di destinazione
        outputPath = fullfile(destinationFolder, 'DAPHNE_Scores.txt');
        writetable(scoresTable, outputPath, 'Delimiter', '\t', 'WriteVariableNames', true);
    end

    % Chiudi la barra di caricamento
    close(progressBar);

    disp('Elaborazione completata.');
end

function scoresTable = processDataFile(dataFile, testNames, mapping, isEval)
    % Legge e processa il file di input per creare DAPHNE_Scores.txt
    fileData = fileread(dataFile);
    lines = strsplit(fileData, '\n');

    % Inizializza una tabella vuota con NaN
    numTests = numel(testNames);
    scores = array2table(nan(numTests, 4), 'VariableNames', {'TEST_Name', 'SX', 'DX', 'GAIT'});
    scores.TEST_Name = testNames;

    % Processa ogni riga e mappa i dati
    i = 1;
    while i <= numel(lines)
        line = strtrim(lines{i});

        if contains(line, ':')
            % Estrai il nome del test e il valore (se presente)
            parts = strsplit(line, ':');
            rawTestName = strtrim(parts{1});

            if contains(rawTestName, {'HRST', 'POST', 'FRST'})
                % Gestione speciale per HRST, POST, FRST
                lxLine = strtrim(lines{i + 1});
                rxLine = strtrim(lines{i + 2});
                lxValue = extractValue(lxLine);
                rxValue = extractValue(rxLine);

                % Determina il nome del test di destinazione (Ex1 o Ex2)
                if contains(rawTestName, {'Ex.1', 'EX_1'}, 'IgnoreCase', true)
                    suffix = '_Ex1';
                elseif contains(rawTestName, {'Ex.2', 'EX_2'}, 'IgnoreCase', true)
                    suffix = '_Ex2';
                else
                    i = i + 3;
                    continue;
                end

                % Mappa i valori sulle righe appropriate
                mappedTestName = strcat(extractBefore(rawTestName, ' '), suffix);
                idx = find(strcmp(testNames, mappedTestName));
                if ~isempty(idx)
                    scores.SX(idx) = lxValue;
                    scores.DX(idx) = rxValue;
                end

                i = i + 3;
                continue;

            elseif contains(rawTestName, 'GTAS') && isEval
                % Gestione speciale per GTAS in DOC_EVAL
                gaitLine = strtrim(lines{i + 1});
                gaitValue = extractValue(gaitLine);

                % Determina il nome del test di destinazione (Ex1 o Ex2)
                if contains(rawTestName, {'Ex.1', 'EX_1'}, 'IgnoreCase', true)
                    mappedTestName = 'GTAS_Ex1';
                elseif contains(rawTestName, {'Ex.2', 'EX_2'}, 'IgnoreCase', true)
                    mappedTestName = 'GTAS_Ex2';
                else
                    i = i + 2;
                    continue;
                end

                idx = find(strcmp(testNames, mappedTestName));
                if ~isempty(idx)
                    scores.GAIT(idx) = gaitValue;
                end

                i = i + 2;
                continue;
            end

            % Cerca nella mappatura per gli altri test
            matchIdx = strcmp(mapping{:, 1}, rawTestName);
            if any(matchIdx)
                mappedTestName = mapping{matchIdx, 2};
                targetColumn = mapping{matchIdx, 3};

                value = extractValue(parts{2});
                idx = find(strcmp(testNames, mappedTestName));
                if ~isempty(idx)
                    scores.(targetColumn{1})(idx) = value;

                    % Regola aggiuntiva per DOC_EVAL: copia valori in GTAS_Ex e ROTA_Ex
                    if strcmp(mappedTestName, 'GTAS_Ex1') && strcmp(targetColumn, 'GAIT')
                        scores.DX(strcmp(testNames, 'ROTA_DX_Ex1')) = value;
                        scores.SX(strcmp(testNames, 'ROTA_SX_Ex1')) = value;
                    elseif strcmp(mappedTestName, 'GTAS_Ex2') && strcmp(targetColumn, 'GAIT')
                        scores.DX(strcmp(testNames, 'ROTA_DX_Ex2')) = value;
                        scores.SX(strcmp(testNames, 'ROTA_SX_Ex2')) = value;
                    end
                end
            end
        end

        i = i + 1;
    end

    scoresTable = scores;
end

function value = extractValue(line)
    % Estrai il valore numerico da una linea del tipo "KEY = VALUE"
    parts = strsplit(line, '=');
    if numel(parts) > 1
        value = str2double(strtrim(parts{2}));
    else
        value = NaN;
    end
end
