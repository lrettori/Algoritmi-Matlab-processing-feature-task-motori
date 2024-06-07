%% Testing filtering in frequency domain (for C# implementation)

filename = "D:\Ricerca UNIFI\Olimpia\OLIMPIA_Michelangelo_local\Data_prove\Lorenzo\FTAP_DX_Ex1.txt";
dataImported = importdata(filename);
rawData = dataImported.data(:,35);
n = 4;
% ft_daphne = 12.5;
% fs_daphne = 100;

% Cerco la frequenza di campionamento, come l'inverso del valore mediano di
% diff(time) (come fatto su C#)
t_time = dataImported.textdata(2:end,1);
for ii = 1:length(t_time)
    % Change colon with semicolon, in order to match MatLab notation.
    colon = strfind(t_time{ii},':');
    t_time{ii}(colon(end)) = '.';
end
t_dur = duration(t_time, "InputFormat","hh:mm:ss.SSS");
timeVector = milliseconds(t_dur);
timeVector  = (timeVector - timeVector(1))/1000;
timeDiff = diff(timeVector);
medianTimeDiff = median(timeDiff);
fs_daphne = 1/medianTimeDiff;

wn_daphne = 2*ft_daphne/fs_daphne;
% Definisco un vettore dei tempi, approssimando un po' (utilizzo la
% frequenza di campionamento definita fs_daphne, che in realtà non è
% proprio esatta)
ts = (0:1:length(rawData)-1).*1/fs_daphne;











% %% Primo filtraggio, versione Matlab
% [b,a] = butter(n,wn_daphne);
% filteredData = filtfilt(b,a,rawData);
% % filteredData = filter(b,a,rawData);
% 
% %% Secondo filtraggio, effettuato nel dominio della frequenza, costruendo
% % manualmente la risposta in frequenza del filtro di Butterworth
% L = length(rawData);
% NFFT = 2^nextpow2(L);
% % Faccio FFT del segnale 
% dataFreqDomain = fft(rawData,NFFT);
% f = fs_daphne/2*linspace(0,1,NFFT/2);
% filterFDT = 1./sqrt(1+(f/ft_daphne).^(2*n));
% 
% filteredSignal = zeros(NFFT,1);
% for ii = 1:NFFT/2
%     filteredSignal(ii) = dataFreqDomain(ii) * filterFDT(ii);
%     filteredSignal(NFFT - ii) = dataFreqDomain(NFFT - ii + 1) * filterFDT(ii);
% end
% 
% % filteredSignal = filterFDT' .* dataFreqDomain(1:NFFT/2+1);
% ifftSignal = ifft(ifftshift(filteredSignal,NFFT));
% ifftSignalReconv = real(ifftSignal);
% 
% % ifftSignalReconv = abs(ifftSignal(1:NFFT/2));

% %% Plot figure for comparison
% figure;plot(ts, filteredData);hold on;
% plot(ts,ifftSignalReconv(1:length(ts)))





