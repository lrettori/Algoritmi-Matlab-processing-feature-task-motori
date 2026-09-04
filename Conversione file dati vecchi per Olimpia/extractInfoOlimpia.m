% Selezione della cartella principale
mainFolder = uigetdir(pwd, 'Seleziona la cartella principale');

% Verifica se la cartella è stata selezionata
if mainFolder == 0
    error('Nessuna cartella selezionata.');
end

% Nome del file Excel di output per le informazioni dei singoli soggetti
infoFile = fullfile(mainFolder, 'users.xlsx');
% Nome del file Excel di output aggregato
allFile = fullfile(mainFolder, '_ALL.xlsx');

% Controlla se i file esistono, altrimenti li crea con intestazioni
if ~isfile(infoFile)
    infoHeaders = {'patientID', 'Nome', 'Cognome', '', 'Data di nascita', ...
                   'Luogo di nascita', 'Provincia', 'Stato', 'Codice fiscale', ...
                   '', '', '', '', '', '', 'Altezza (cm)', 'Peso', 'Tipo'};
    writecell(infoHeaders, infoFile);
end

if ~isfile(allFile)
    allHeaders = {'patientID', "Patient's code", '', 'Altezza (cm)', 'Peso', ...
                   'Scarpa','Età', '', 'Session', 'SessionIndex'};
    writecell(allHeaders, allFile);
end

% Ottieni tutte le sottocartelle nella cartella principale
subFolders = dir(mainFolder);
subFolders = subFolders([subFolders.isdir] & ~startsWith({subFolders.name}, '.'));

% Iterazione su ogni sottocartella
for i = 1:length(subFolders)
    patientID = subFolders(i).name;
    resultsFolder = fullfile(mainFolder, patientID, 'RESULTS');

    % Se esiste il file DOC_SCORE usare quello, altrimenti DOC_EVAL
    docFile = fullfile(resultsFolder, 'DOC_SCORE.txt');
    if ~isfile(docFile)
        docFile = fullfile(resultsFolder, 'DOC_EVAL.txt');
    end

    % Verifica se il file DOC_EVAL.txt esiste
    if ~isfile(docFile)
        fprintf('DOC_EVAL.txt non trovato per il soggetto %s. Saltato.\n', patientID);
        continue;
    end

    % Lettura del file DOC_EVAL.txt
    fileData = fileread(docFile);

    % Estrazione delle informazioni richieste

    data = extractBetween(fileData, 'Date:', newline);
    currentDate = datetime(data);

    nome = extractBetween(fileData, 'Name:', newline);
    nome = strtrim(nome{1});

    cognome = extractBetween(fileData, 'Surname:', newline);
    cognome = strtrim(cognome{1});

    dataNascita = extractBetween(fileData, 'Birthday:', newline);
    dataNascita = strtrim(dataNascita{1});
    % Calcolo dell'età
    eta = calculateAge(dataNascita,currentDate);

    luogoNascita = extractBetween(fileData, 'Place:', newline);
    luogoNascita = strtrim(luogoNascita{1});

    scarpa = extractBetween(fileData, 'Shoe number :', newline);
    scarpa = str2double(strtrim(scarpa{1}));

    provincia = 'Provincia non specificata'; % Sostituisci con estrazione reale se disponibile
    stato = 'Italia'; % Modifica se necessario

    codiceFiscale = 'cf'; % Scrivere solo "cf" come richiesto

    altezza = extractBetween(fileData, 'Height :', newline);
    altezza = str2double(strtrim(altezza{1}));
    if altezza < 3
        % Altezza indicata in metri, converto in cm
        altezza = altezza * 100; % Convertire in cm
    end

    peso = extractBetween(fileData, 'Weight :', newline);
    peso = str2double(strtrim(peso{1}));

    tipo = extractBetween(fileData, "Patient's code :", newline);
    tipo = str2double(strtrim(tipo{1}));

    % Preparazione della riga per users.xlsx
    infoRow = {patientID, nome, cognome, '', dataNascita, luogoNascita, provincia, ...
               stato, codiceFiscale, '', '', '', '', '', '', altezza, peso, tipo};
    % Preparazione della riga per _ALL.xlsx
    allRow = {patientID, tipo, '', altezza, peso, scarpa, eta, '', 'T0', 0};

    % Aggiunta della riga al file Excel users.xlsx
    writecell(infoRow, infoFile, 'WriteMode', 'append');
    % Aggiunta della riga al file Excel _ALL.xlsx
    writecell(allRow, allFile, 'WriteMode', 'append');
end

disp('Processo completato.');

% --- Funzioni locali alla fine del file ---
function age = calculateAge(birthDateStr,currentDate)
    % Conversione della stringa in formato datetime
    birthDate = datetime(birthDateStr, 'InputFormat', 'dd/MM/yyyy');    
    % currentDate = datetime('today');
    % Calcolo dell'età
    age = years(currentDate - birthDate);
    age = floor(age); % Arrotondare all'intero inferiore
end



%% File txt Daphne score









