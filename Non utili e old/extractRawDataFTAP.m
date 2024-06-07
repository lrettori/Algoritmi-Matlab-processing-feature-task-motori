%% Script temporaneo per l'estrazione dei dati raw dai file txt

% Vecchio import dei dati, dove era necessaria una copia del file e la
% cancellazione dell'header
% filenameData = 'D:\Ricerca UNIFI\Olimpia\Dati\Dati per prove debug\FTAP_DX_Ex1 - Copia.txt';
% firstImportRawData = importdata(filenameData);

% firstImportRawData = readtable(filenameData);
% firstImportRawData = firstImportRawData(10:end,2:end);
% firstImportRawData = table2array(firstImportRawData);


% Nuova versione dell'import dei dati, dove rimuovo automaticamente
% l'header. Questo permette l'esecuzione dello script sugli stessi dati
% processati dal programma C#
[filename, pathIn] = uigetfile('*.txt', "Seleziona il file",'D:\Ricerca UNIFI\Olimpia\Dati\Dati pre-Olimpia');
filenameData = strcat(pathIn,filename);
firstImportRawData = importdata(filenameData,'\t', 9);

% Determino le colonne da estrarre, sulla base del lato (dx o sx) sul quale
% è stata effettuata l'acquisizione e del tipo di esercizio
filename = convertCharsToStrings(filename);
title = strsplit(filename,'_');
exercise = title(1);
switch exercise
    case {'FTAP', 'THFv', 'THFa', 'OPCv', 'OPCa', 'KINT', }
        side = title(2);
        if strcmp(side,'DX')
            % RIND
            dataColumns = 13:1:18;
        else
            % LIND
            dataColumns = 31:1:36;
        end

    case 'PSUP'
        side = title(2);
        if strcmp(side,'DX')
            % RWRS
            dataColumns = 19:1:24;
        else
            % LWRS
            dataColumns = 1:1:6;
        end

    case {'POST', 'HRST'}
        % LIND
        dataColumns = 31:1:36;

    case {'TTHP', 'HTTP', 'HEHE', 'HETO', 'ROTA'}
        side = title(2);
        if strcmp(side,'DX')
            % RFTT
            dataColumns = 43:1:48;
        else
            % LFTT
            dataColumns = 37:1:42;
        end

    case 'FRST'
        % LFTT
            dataColumns = 37:1:42;

    case 'STUP'
        % RFTT
            dataColumns = 43:1:48;

    case 'GTAS'
% Nulla per ora
end

% Estraggo le sole colonne di mio interesse per una prima valutazione,
% ossia i dati dell'accelerometro e giroscopio relativi al dito indice
% (esercizi FTAP)
% Si tratta delle colonne 20-22 per l'accelerometro, e 23-25 per il
% giroscopio
data_ax = firstImportRawData.data(:,dataColumns(1));
data_ay = firstImportRawData.data(:,dataColumns(2));
data_az = firstImportRawData.data(:,dataColumns(3));
data_wx = firstImportRawData.data(:,dataColumns(4));
data_wy = firstImportRawData.data(:,dataColumns(5));
data_wz = firstImportRawData.data(:,dataColumns(6));

% Setto altri parametri di inizializzazione (DA CONTROLLARE)
directory = 'D:\Ricerca UNIFI\Olimpia\Dati\Dati per prove debug';
filename = 'S01_FTAP_CL0_RH_01';
hand_N = 0; % valore a caso, non sembra serva
trial = 0; % valore a caso, non sembra serva
samples = length(data_ax);
% ts = (0:1:samples-1).*1/fs_daphne;
t_time = firstImportRawData.textdata(10:end,1);
for i = 1:length(t_time)
    % Change colon with dot, in order to match MatLab notation.
    colon = strfind(t_time{i},':');
    t_time{i}(colon(end)) = '.';
end
t_dur = duration(t_time, "InputFormat","hh:mm:ss.SSS");

ts  = milliseconds(t_dur);
ts  = ((ts - ts(1))/1000)';

% fs_daphne = 111.111; 
timeDiff = diff(ts);
fs_daphne = 1/median(timeDiff);











