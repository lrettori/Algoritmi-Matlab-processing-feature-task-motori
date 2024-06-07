%% Script temporaneo per l'estrazione dei dati raw dai file txt

filenameData = 'D:\Ricerca UNIFI\Olimpia\Dati\Dati per prove debug\HRST_Ex1 - Copia.txt';
% filenameData = 'D:\Ricerca UNIFI\Olimpia\Dati\Dati per prove debug\HRST_Ex2 - Copia.txt'; % 1_A_D_06101949C60SSSA2
firstImportRawData = importdata(filenameData);
% Estraggo le sole colonne di mio interesse
data_ax = firstImportRawData.data(:,13);
data_ay = firstImportRawData.data(:,14);
data_az = firstImportRawData.data(:,15);
data_wx = firstImportRawData.data(:,16);
data_wy = firstImportRawData.data(:,17);
data_wz = firstImportRawData.data(:,18);

% Setto altri parametri di inizializzazione (DA CONTROLLARE)
directory = 'D:\Ricerca UNIFI\Olimpia\Dati\Dati per prove debug';
filename = 'HRST_Ex1 - Copia';
hand_N = 0; % valore a caso, non sembra serva
trial = 0; % valore a caso, non sembra serva
samples = length(data_ax);
exercise = 'HRST';
% ts = (0:1:samples-1).*1/fs_daphne;
t_time = firstImportRawData.textdata(2:end,1);
for i = 1:length(t_time)
    % Change colon with semicolon, in order to match MatLab notation.
    colon = strfind(t_time{i},':');
    t_time{i}(colon(end)) = '.';
end
t_dur = duration(t_time, "InputFormat","hh:mm:ss.SSS");

ts  = milliseconds(t_dur);
ts  = ((ts - ts(1))/1000)';

% fs_daphne = 111.111; 
timeDiff = diff(ts);
fs_daphne = 1/median(timeDiff);


