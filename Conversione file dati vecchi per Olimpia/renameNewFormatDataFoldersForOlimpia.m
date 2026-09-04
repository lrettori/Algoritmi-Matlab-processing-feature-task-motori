function renameNewFormatDataFoldersForOlimpia()
    % Seleziona la cartella principale tramite finestra di dialogo
    mainFolder = uigetdir(pwd, 'Seleziona la cartella principale');
    if mainFolder == 0
        disp('Operazione annullata.');
        return;
    end

    % Ottieni tutte le sottocartelle nella cartella principale
    folders = dir(mainFolder);
    folders = folders([folders.isdir]); % Filtra solo le cartelle

    % Escludi le cartelle "." e ".."
    folders = folders(~ismember({folders.name}, {'.', '..'}));

    % Conta il numero totale di cartelle da elaborare
    totalFolders = numel(folders);

    % Inizializza il contatore per le cartelle rinominate
    renamedCount = 0;

    % Inizializza la barra di caricamento
    progressBar = waitbar(0, 'Elaborazione in corso...', 'Name', 'Rinominazione Cartelle');

    % Loop attraverso ogni sottocartella
    for i = 1:totalFolders
        waitbar(i / totalFolders, progressBar, sprintf('Elaborazione %d di %d...', i, totalFolders));

        % Nome della sottocartella corrente
        currentFolder = folders(i).name;
        currentFolderPath = fullfile(mainFolder, currentFolder);

        % Cerca la cartella "NewFormatData" all'interno di questa sottocartella
        newFormatDataPath = fullfile(currentFolderPath, 'NewFormatData');
        if isfolder(newFormatDataPath)
            % Determina il nuovo nome basato sulle regole
            newName = determineNewName(currentFolder);
            if ~isempty(newName)
                % Rinomina la cartella
                newFolderPath = fullfile(currentFolderPath, newName);
                movefile(newFormatDataPath, newFolderPath);
                renamedCount = renamedCount + 1;
            end
        end
    end

    % Chiudi la barra di caricamento
    close(progressBar);

    % Stampa il numero di cartelle rinominate
    fprintf('Numero totale di cartelle rinominate: %d\n', renamedCount);
end

function newName = determineNewName(folderName)
    % Determina il nuovo nome della cartella "NewFormatData" basato sul nome della cartella genitore
    if startsWith(folderName, '1')
        newName = '1-T0_0';
    elseif startsWith(folderName, '2')
        newName = '2-T0_0';
    elseif startsWith(folderName, '3')
        newName = '3-T0_0';
    elseif startsWith(folderName, '4-T0') || startsWith(folderName, '4T0')
        newName = '4-T0_0';
    elseif startsWith(folderName, '4-T20') || startsWith(folderName, '4T20')
        newName = '4-T20_0';
    elseif startsWith(folderName, '4-T50') || startsWith(folderName, '4T50')
        newName = '4-T50_0';
    else
        newName = '';
    end
end
