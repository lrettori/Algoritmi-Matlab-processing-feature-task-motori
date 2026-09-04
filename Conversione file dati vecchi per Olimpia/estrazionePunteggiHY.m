%% Estrazione punteggi HY

mainFolder = uigetdir(pwd, 'Seleziona la cartella principale');

% Verifica se la cartella è stata selezionata
if mainFolder == 0
    error('Nessuna cartella selezionata.');
end

% Nome del file Excel di output aggregato
allFile = fullfile(mainFolder, 'HY_ALL.xlsx');

% Controlla se il file esiste, altrimenti lo crea con intestazioni
if ~isfile(allFile)
    infoHeaders = {'patientID', 'HY', 'HY_1', 'HY_2'};
    writecell(infoHeaders, allFile);
end

% Ottieni tutte le sottocartelle nella cartella principale
subFolders = dir(mainFolder);
subFolders = subFolders([subFolders.isdir] & ~startsWith({subFolders.name}, '.'));

% Iterazione su ogni sottocartella
for i = 1:length(subFolders)
    patientID = subFolders(i).name;
    resultsFolder = fullfile(mainFolder, patientID, 'RESULTS');

    % Se esiste il file DOC_SCORE usare quello, altrimenti DOC_EVAL
    docFile = fullfile(resultsFolder, 'DOC_EVAL.txt');

    % Verifica se il file DOC_EVAL.txt esiste
    if ~isfile(docFile)
        fprintf('DOC_EVAL.txt non trovato per il soggetto %s. Saltato.\n', patientID);
        continue;
    end

    % Lettura del file DOC_EVAL.txt
    fileData = fileread(docFile);

    % Estrazione della riga che inizia con "HY ="
    hyLine = regexp(fileData, '^HY\s*=\s*.*', 'match', 'lineanchors', 'dotexceptnewline');
    if isempty(hyLine)
        fprintf('Riga HY non trovata per il soggetto %s. Saltato.\n', patientID);
        continue;
    end

    % Separazione della riga in parole (gestione di spazi e tabulazioni)
    tokens = strsplit(strtrim(regexprep(hyLine{1}, '\s+', ' ')));

    % Determinazione di HYvalue
    if numel(tokens) < 2 || ~isstrprop(tokens{3}, 'digit')
        fprintf('Formato non valido per HY per il soggetto %s. Saltato.\n', patientID);
        continue;
    end

    HYvalue = str2double(tokens{3});
    HY_1 = 'NULL';
    HY_2 = 'NULL';

    % Gestione dei casi in base a HYvalue
    switch HYvalue
        case {0, 3, 4, 5}
            % Nulla da fare, HY_1 e HY_2 rimangono "NULL"
        case 2
            if numel(tokens) > 3
                keyword = tokens{4};
                if any(strcmpi(keyword, {'Equal', 'Eq'}))
                    HY_2 = 1;
                elseif strcmpi(keyword, 'Rx')
                    HY_2 = 2;
                elseif strcmpi(keyword, 'Lx')
                    HY_2 = 3;
                else
                    [HYvalue, HY_1, HY_2] = manualInput(patientID, hyLine);
                end
            else
                [HYvalue, HY_1, HY_2] = manualInput(patientID, hyLine);
            end
        case 1
            if numel(tokens) > 3
                keyword = strjoin(tokens(3:end), ' ');
                if any(strcmpi(keyword, {'1 Rx Equal', '1 Rx Eq'}))
                    HY_1 = 1;
                elseif any(strcmpi(keyword, {'1 Lx Equal', '1 Lx Eq'}))
                    HY_1 = 2;
                elseif any(strcmpi(keyword, {'1 Rx Above', '1 Rx Upper'}))
                    HY_1 = 3;
                elseif any(strcmpi(keyword, {'1 Rx Under', '1 Rx Lower'}))
                    HY_1 = 4;
                elseif any(strcmpi(keyword, {'1 Lx Above', '1 Lx Upper'}))
                    HY_1 = 5;
                elseif any(strcmpi(keyword, {'1 Lx Under', '1 Lx Lower'}))
                    HY_1 = 6;
                else
                    [HYvalue, HY_1, HY_2] = manualInput(patientID, hyLine);
                end
            else
                [HYvalue, HY_1, HY_2] = manualInput(patientID, hyLine);
            end
        otherwise
            [HYvalue, HY_1, HY_2] = manualInput(patientID, hyLine);
    end

    % Preparazione della riga per _ALL.xlsx
    infoRow = {patientID, HYvalue, HY_1, HY_2};

    % Aggiunta della riga al file Excel _ALL.xlsx
    writecell(infoRow, allFile, 'WriteMode', 'append');
end

disp('Processo completato.');

%% Funzione per la richiesta di inserimento manuale

function [HYvalue, HY_1, HY_2] = manualInput(patientID, hyLine)

for ii = 1:length(hyLine)
    string = strcat(hyLine{ii});
end

prompt = {'Inserisci HYvalue:', 'Inserisci HY_1:', 'Inserisci HY_2:'};
dlgtitle = sprintf('Dati mancanti per il paziente %s: stringa HY: %s', patientID, string);
dims = [1 150];
definput = {'', 'NULL', 'NULL'};
answer = inputdlg(prompt, dlgtitle, dims, definput);
if isempty(answer)
    error('Interruzione manuale dell''utente.');
end
HYvalue = str2double(answer{1});
HY_1 = str2double(answer{2});
HY_2 = str2double(answer{3});
end

