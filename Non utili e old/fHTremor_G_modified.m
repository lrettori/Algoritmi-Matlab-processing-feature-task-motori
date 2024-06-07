function [features] = fHTremor_G_modified(directory,filename,ts,data_wx,data_wy,data_wz,fs_daphne,exercise)


% [MODIFICA] filtraggio eseguito qui dentro anziché prima
n = 4;
ft_daphne = 20;
wn_daphne = 2 * ft_daphne / fs_daphne;
[b,a] = butter(n,wn_daphne);
fdata_wx = filtfilt(b,a,data_wx);
fdata_wy = filtfilt(b,a,data_wy);
fdata_wz = filtfilt(b,a,data_wz);


%% Rimozione dell'offset per il segnale del giroscopio
% Tolgo una media fatta nell'intervallo tra 1 e 2 secondi
[~,index1sec] = min(abs(ts-1));
[~,index2sec] = min(abs(ts-2));

% Filtro eventuali false partenze o spike nei segnali
fdata_wx_1to2sec = fdata_wx(index1sec:index2sec);
fdata_wy_1to2sec = fdata_wy(index1sec:index2sec);
fdata_wz_1to2sec = fdata_wz(index1sec:index2sec);

[histCountWx,histValWx] = hist(fdata_wx_1to2sec,1000);
[histCountWy,histValWy] = hist(fdata_wy_1to2sec,1000);
[histCountWz,histValWz] = hist(fdata_wz_1to2sec,1000);

% Calcolo il picco dell'istogramma per le tre misure, e ricavo l'offset
% come la media dei valori che ricadono in un intervallo pari a +-4 intorno
% a quel valore (false partenze e spike raggiungono valori molto più
% elevati, e quindi vengono filtrati via)
[~,maxPosWx] = max(histCountWx);
[~,maxPosWy] = max(histCountWy);
[~,maxPosWz] = max(histCountWz);

peakHistWx = histValWx(maxPosWx);
peakHistWy = histValWy(maxPosWy);
peakHistWz = histValWz(maxPosWz);

offsetWx = mean(fdata_wx_1to2sec(fdata_wx_1to2sec > peakHistWx - 4 & fdata_wx_1to2sec < peakHistWx + 4));
offsetWy = mean(fdata_wy_1to2sec(fdata_wy_1to2sec > peakHistWy - 4 & fdata_wy_1to2sec < peakHistWy + 4));
offsetWz = mean(fdata_wz_1to2sec(fdata_wz_1to2sec > peakHistWz - 4 & fdata_wz_1to2sec < peakHistWz + 4));

wx = fdata_wx - offsetWx;
wy = fdata_wy - offsetWy;
wz = fdata_wz - offsetWz;

%%
[~,indexStart] = min(abs(ts-3));

if strcmp(exercise,'POST')
    [~,indexStop] = min(abs(ts-13));
    numbOfTimeIntervals = 1;

elseif strcmp(exercise,'KINT')
    % Caso KINT
    k = 500;
    p = length(ts);
    THRE=100;
    TH_t=5;
    step = 0;
    while(p>=k)
        if (wx(p) > THRE)
            app = p;
            flag = 1;
            while(flag)
                app = app + 1;
                if (wx(app) < TH_t)
                    step = step + 1;
                    T_end(step) = app;
                    flag = 0;
                    break;
                end
            end
        end
        p = p-1;
    end
    indexStop = T_end(1);
    numbOfTimeIntervals = 1;
end

wx = wx(indexStart:indexStop);
wy = wy(indexStart:indexStop);
wz = wz(indexStart:indexStop);


[d,c]= butter(4,2*0.5/100,'high');    %HP Butterworth filter, ft=0.5Hz, n=4
%filtraggio della velocità angolare (passa alto)
wx  = filtfilt(d,c,wx);
wy  = filtfilt(d,c,wy);
wz  = filtfilt(d,c,wz);
% figure; plot(wx,'b.-'); hold on; plot(wy,'r.-'); hold on; plot(wz,'g.-');
% legend('vel x','vel y','vel z'); xlabel('tempo (s)'); ylabel('velocità angolare (°/s)')
% title('segnale giroscopico corretto da offset e filtrato con passa alto')
L    = length(ts(indexStart:indexStop));          %lunghezza del vettore filtrato (L campioni)
NFFT = 2^nextpow2(L);                 %next power of 2 from length of l
%TRASFORMATA DI FOURIER
Wx  = fft(wx, NFFT);
Wy  = fft(wy, NFFT);
Wz  = fft(wz, NFFT);
f = fs_daphne/2*linspace(0,1,NFFT/2+1);      %vettore delle frequenze: asse delle ascisse nel dominio delle frequenze

Pwx = Wx.*conj(Wx)/(L*fs_daphne);            %calcolo densità spettrale di potenza 
Pwy = Wy.*conj(Wy)/(L*fs_daphne);            %potenza media normalizzata
Pwz = Wz.*conj(Wz)/(L*fs_daphne);
% figure; plot(f,(Pwx(1:NFFT/2+1)),'b.-'), title('Power Spectral Density(x)'), xlabel('Frequency (Hz)'),ylabel('\omega\_x');
% figure; plot(f,(Pwy(1:NFFT/2+1)),'r.-'), title('Power Spectral Density(y)'), xlabel('Frequency (Hz)'),ylabel('\omega\_y');
% figure; plot(f,(Pwz(1:NFFT/2+1)),'g.-'), title('Power Spectral Density(z)'), xlabel('Frequency (Hz)'),ylabel('\omega\_z');

% DENSITà SPETTRALE X
[~, locs] = findpeaks(Pwx(1:NFFT/2+1)); %find local peaks in data
Fx  = (f(locs));                          %valore della frequenza in corrispondenza del frame in cui vi è il massimo
Px  = (Pwx(locs));                        %valore dei picchi
[peak  freq] = sort(-(Px));               %mette in ordine decrescente tutti i picchi, ricavando la posizione (frame)
indwx2 = Fx(freq);                        %frequenza nella posizione in cui ci sono i picchi decrescenti
pkswx2 = abs(peak);                       %picchi in ordine decrescente in modulo del segnale Pwx
%DENSITà SPETTRALE Y
[~, locs] = findpeaks(Pwy(1:NFFT/2+1));
Fy  = (f(locs));
Py  = (Pwy(locs));
[peak  freq] = sort(-(Py));
indwy2 = Fy(freq);
pkswy2 = abs(peak);                       %il primo valore del vettore è il picco massimo
% DENSITà SPETTRALE Z
[~, locs] = findpeaks(Pwz(1:NFFT/2+1));
Fz  = (f(locs));
Pz  = (Pwz(locs));
[peak  freq] = sort(-(Pz));
indwz2 = Fz(freq);
pkswz2 = abs(peak);

Peaks = [pkswx2(1); pkswy2(1); pkswz2(1)]; %prende il picco massimo di Pwx, Pwy, Pwz
pksw2 = max(Peaks);                        %massimo dei massimi
% SPETTRO DI POTENZA
if  pksw2 == pkswx2(1)
    indw2 = indwx2;
    Hpsd_w = dspdata.psd(Pwx(1:NFFT/2+1),'Fs',fs_daphne); 
else if pksw2 == pkswy2(1)
        indw2 = indwy2;
        Hpsd_w = dspdata.psd(Pwy(1:NFFT/2+1),'Fs',fs_daphne);
    else
        indw2 = indwz2;
         Hpsd_w = dspdata.psd(Pwz(1:NFFT/2+1),'Fs',fs_daphne);
    end
end
features.freqG = indw2(1);           %P02: FUNDAMENTAL GYRO FREQUENCY

freq_range1 = [3.5 7.5];
freq_range2 = [8 12];
features.PwrG    = avgpower(Hpsd_w);     %P01: AVERAGE POWER IN GYRO PSD          
Pwr_w21   = avgpower(Hpsd_w,freq_range1);  %P03: PERCENTAGE ACC POWER IN 3.5-7.5 HZ BAND
Pwr_w22   = avgpower(Hpsd_w,freq_range2);  %P04: PERCENTAGE ACC POWER IN 8-12 HZ BAND

features.Perc1G = Pwr_w21/features.PwrG*100;            
features.Perc2G = Pwr_w22/features.PwrG*100;

end