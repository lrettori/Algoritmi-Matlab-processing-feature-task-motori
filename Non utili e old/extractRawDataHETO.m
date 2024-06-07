%% Script temporaneo per l'estrazione dei dati raw dai file txt

filenameData = 'D:\Ricerca UNIFI\Olimpia\Dati\Dati per prove debug\HETO_DX_Ex1 - Copia.txt';
firstImportRawData = importdata(filenameData);
% Estraggo le sole colonne di mio interesse
data2_ax = firstImportRawData.data(:,43);
data2_ay = firstImportRawData.data(:,44);
data2_az = firstImportRawData.data(:,45);
data2_wx = firstImportRawData.data(:,46);
data2_wy = firstImportRawData.data(:,47);
data2_wz = firstImportRawData.data(:,48);

% Setto altri parametri di inizializzazione (DA CONTROLLARE)
directory = 'D:\Ricerca UNIFI\Olimpia\Dati\Dati per prove debug';
filename = 'HETO_DX_Ex1 - Copia';
hand_N = 0; % valore a caso, non sembra serva
trial = 0; % valore a caso, non sembra serva
samples = length(data2_ax);
exercise = 'HETO';
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


