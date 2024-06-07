function [features] = fFRTremor_G_modified(directory,filename,ts,data_wx,data_wy,data_wz,fs_daphne,exercise)

% [MODIFICATA] Filtro passa-basso i segnali (prima veniva fatto nel momento
% dell'estrazione dei dati, io l'ho spostata qui dentro)
n = 4; % ordine del filtro di Butterworth
ft_daphne = 20; % freq di taglio del filtro
wn_daphne = 2*ft_daphne/fs_daphne; % freq normalizzata di taglio del filtro
[b,a] = butter(n,wn_daphne);
fdata_wx = filtfilt(b,a,data_wx);
fdata_wy = filtfilt(b,a,data_wy);
fdata_wz = filtfilt(b,a,data_wz);

%% Rimozione offset dal segnale giroscopio [MODIFICA]
% Tolgo una media fatta nell'intervallo tra 1 e 2 secondi
[~,index1sec] = min(abs(ts-1));
[~,index2sec] = min(abs(ts-2));

% [MODIFICA] - Anziché calcolare direttamente la media calcolata tra 1 e 2 
% secondi di acquisizione, cerco di filtrare eventuali false partenze o 
% spike che potrebbero modificare la media calcolata aggiungendo un errore
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
[d,c]= butter(4,2*0.5/100,'high');    %HP Butterworth filter, ft=0.5Hz, n=4
%filtraggio della velocità angolare (passa alto)
wxHPFilt  = filtfilt(d,c,wx);
wyHPFilt  = filtfilt(d,c,wy);
wzHPFilt  = filtfilt(d,c,wz);

plot_title = strcat(directory,'-',filename);
figure; plot(wxHPFilt,'b.-'); hold on; plot(wyHPFilt,'r.-'); hold on; plot(wzHPFilt,'g.-');title(plot_title);
legend('vel x','vel y','vel z'); xlabel('tempo (s)'); ylabel('velocità angolare (°/s)')

%%
% Trovo gli istanti di inizio e fine esercizio [MODIFICA]
[~,index3sec] = min(abs(ts-3));
[~,index35sec] = min(abs(ts-35));

% [MODIFICA] Trovo gli indici relativi agli istanti di inizio/fine dei
% sottointervalli che devo considerare (8s, 16s, 24s, 32s a partire
% dall'inizio dell'intervallo di interesse, quindi 11s, 19s, 27s, 35s)
[~,index8sec] = min(abs(ts-(8+3)));
[~,index16sec] = min(abs(ts-(16+3)));
[~,index24sec] = min(abs(ts-(24+3)));
[~,index32sec] = min(abs(ts-(32+3)));

% length32s = length(ts(index3sec:index35sec)); 
% NFFT = 2^nextpow2(length32s);
freqrange1 = [3.5 7.5]; 
freqrange2 = [8 12];

indexStart = index3sec;
indexStop = index35sec;
indexStartIntervals = [indexStart, indexStart, index8sec, index16sec, index24sec];
indexEndIntervals = [indexStop, index8sec, index16sec, index24sec, index32sec];

features.freqG = zeros(1,5); 
features.PwrG = zeros(1,5); 
features.Perc1G = zeros(1,5); 
features.Perc2G = zeros(1,5);

for i = 1:5
    % Prelevo il sotto-intervallo di interesse
    wxHPFilt_i = wxHPFilt(indexStartIntervals(i) : indexEndIntervals(i));
    wyHPFilt_i = wyHPFilt(indexStartIntervals(i) : indexEndIntervals(i));
    wzHPFilt_i = wzHPFilt(indexStartIntervals(i) : indexEndIntervals(i));
    length_i = indexEndIntervals(i) - indexStartIntervals(i) + 1;

    % FFT
    NFFT_i = 2^nextpow2(length_i);
    Wx_i = fft(wxHPFilt_i,NFFT_i);
    Wy_i = fft(wyHPFilt_i,NFFT_i);
    Wz_i = fft(wzHPFilt_i,NFFT_i);
    f_i = fs_daphne/2*linspace(0,1,NFFT_i/2+1);
    Pwx_i = Wx_i.*conj(Wx_i)/(length_i*fs_daphne);
    Pwy_i = Wy_i.*conj(Wy_i)/(length_i*fs_daphne);
    Pwz_i = Wz_i.*conj(Wz_i)/(length_i*fs_daphne);

    % Trovo il massimo degli spettri lungo i tre assi
    [~, fundFreqIndexX] = max(Pwx_i(1:NFFT_i/2+1));
    [~, fundFreqIndexY] = max(Pwy_i(1:NFFT_i/2+1));
    [~, fundFreqIndexZ] = max(Pwz_i(1:NFFT_i/2+1));

    % Estraggo le features sul picco, basandomi sul picco massimo sui tre
    % assi
    peaks = [Pwx_i(fundFreqIndexX), Pwy_i(fundFreqIndexY), Pwz_i(fundFreqIndexZ)];
    [~, indMaxPeak] = max(peaks);

    indexFreqRange1 = zeros(1,2);
    indexFreqRange2 = zeros(1,2);
    [~,indexFreqRange1(1)] = min(abs(f_i - freqrange1(1)));
    [~,indexFreqRange1(2)] = min(abs(f_i - freqrange1(2)));
    [~,indexFreqRange2(1)] = min(abs(f_i - freqrange2(1)));
    [~,indexFreqRange2(2)] = min(abs(f_i - freqrange2(2)));

    switch indMaxPeak
        case 1
            features.freqG(i) = f_i(fundFreqIndexX);
            features.PwrG(i) = (sum(Pwx_i(1:NFFT_i/2+1))) * (fs_daphne/2) / (NFFT_i/2); % Sostituisce la funzione avgpower
            Pwr_g1 = (sum(Pwx_i(indexFreqRange1(1) : indexFreqRange1(2)))) * (fs_daphne/2) / (NFFT_i/2);
            Pwr_g2 = (sum(Pwx_i(indexFreqRange2(1) : indexFreqRange2(2)))) * (fs_daphne/2) / (NFFT_i/2);

        case 2
            features.freqG(i) = f_i(fundFreqIndexY);
            features.PwrG(i) = (sum(Pwy_i(1:NFFT_i/2+1))) * (fs_daphne/2) / (NFFT_i/2); % Sostituisce la funzione avgpower
            Pwr_g1 = (sum(Pwy_i(indexFreqRange1(1) : indexFreqRange1(2)))) * (fs_daphne/2) / (NFFT_i/2);
            Pwr_g2 = (sum(Pwy_i(indexFreqRange2(1) : indexFreqRange2(2)))) * (fs_daphne/2) / (NFFT_i/2);

        case 3
            features.freqG(i) = f_i(fundFreqIndexZ);
            features.PwrG(i) = (sum(Pwz_i(1:NFFT_i/2+1))) * (fs_daphne/2) / (NFFT_i/2); % Sostituisce la funzione avgpower
            Pwr_g1 = (sum(Pwz_i(indexFreqRange1(1) : indexFreqRange1(2)))) * (fs_daphne/2) / (NFFT_i/2);
            Pwr_g2 = (sum(Pwz_i(indexFreqRange2(1) : indexFreqRange2(2)))) * (fs_daphne/2) / (NFFT_i/2);

    end
    features.Perc1G(i) = Pwr_g1/features.PwrG(i)*100;
    features.Perc2G(i) = Pwr_g2/features.PwrG(i)*100;
end

 features.freqG = round(features.freqG*100)/100;
 features.Perc1G = round(features.Perc1G*100)/100;
 features.Perc2G = round(features.Perc2G*100)/100;
end