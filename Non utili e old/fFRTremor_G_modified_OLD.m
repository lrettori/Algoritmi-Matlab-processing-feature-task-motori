function [features] = fFRTremor_G_modified(directory,filename,ts,data_wx,data_wy,data_wz,fs_daphne,exercise)

% [MODIFICATA] Filtro passa-basso i segnali (prima veniva fatto nel momento
% dell'estrazione dei dati, io l'ho spostata qui dentro)
n = 4;                             %ordine del filtro di Butterworth
ft_daphne = 20;                            %freq di taglio del filtro
wn_daphne = 2*ft_daphne/fs_daphne;                       %freq normalizzata di taglio del filtro
[b,a] = butter(n,wn_daphne);
fdata_wx = filtfilt(b,a,data_wx);   %index finger
fdata_wy = filtfilt(b,a,data_wy);
fdata_wz = filtfilt(b,a,data_wz);

% Trovo gli istanti di inizio e fine esercizio [MODIFICA]
[~,index3sec] = min(abs(ts-3));
[~,index35sec] = min(abs(ts-35));

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
% wx  = fdata_wx(index3sec:index35sec)- mean(fdata_wx(100:200)); %OFFSET
% wy  = fdata_wy(index3sec:index35sec)- mean(fdata_wy(100:200));
% wz  = fdata_wz(index3sec:index35sec)- mean(fdata_wz(100:200));

%%
[d,c]= butter(4,2*0.5/100,'high');    %HP Butterworth filter, ft=0.5Hz, n=4
%filtraggio della velocità angolare (passa alto)
wxHPFilt  = filtfilt(d,c,wx);
wyHPFilt  = filtfilt(d,c,wy);
wzHPFilt  = filtfilt(d,c,wz);
plot_title = strcat(directory,'-',filename);
figure; plot(wxHPFilt,'b.-'); hold on; plot(wyHPFilt,'r.-'); hold on; plot(wzHPFilt,'g.-');title(plot_title);
legend('vel x','vel y','vel z'); xlabel('tempo (s)'); ylabel('velocità angolare (°/s)')
% title('segnale giroscopico corretto da offs_daphneet e filtrato con passa alto')
L    = length(ts(index3sec:index35sec));          %lunghezza del vettore filtrato (L campioni)
NFFT = 2^nextpow2(L);                 %next power of 2 from length of l
%TRASFORMATA DI FOURIER
Wx  = fft(wxHPFilt, NFFT);
Wy  = fft(wyHPFilt, NFFT);
Wz  = fft(wzHPFilt, NFFT);
f = fs_daphne/2*linspace(0,1,NFFT/2+1);      %vettore delle frequenze: asse delle ascisse nel dominio delle frequenze
Pwx = Wx.*conj(Wx)/(L*fs_daphne);            %calcolo densità spettrale di potenza 
Pwy = Wy.*conj(Wy)/(L*fs_daphne);            %potenza media normalizzata
Pwz = Wz.*conj(Wz)/(L*fs_daphne);

% DENSITà SPETTRALE X
[~, locs] = findpeaks(Pwx(1:NFFT/2+1)); %find local peaks in data
Fx  = (f(locs));                          %valore della frequenza in corrispondenza del frame in cui vi è il massimo
Px  = (Pwx(locs));                        %valore dei picchi
[peak  freq] = sort(Px,'descend');               %mette in ordine decrescente tutti i picchi, ricavando la posizione (frame)
indwx = Fx(freq);                        %frequenza nella posizione in cui ci sono i picchi decrescenti
pkswx = abs(peak);                       %picchi in ordine decrescente in modulo del segnale Pwx
%DENSITà SPETTRALE Y
[~, locs] = findpeaks(Pwy(1:NFFT/2+1));
Fy  = (f(locs));
Py  = (Pwy(locs));
[peak  freq] = sort(Py,'descend');
indwy = Fy(freq);
pkswy = abs(peak);                       %il primo valore del vettore è il picco massimo
% DENSITà SPETTRALE Z
[~, locs] = findpeaks(Pwz(1:NFFT/2+1));
Fz  = (f(locs));
Pz  = (Pwz(locs));
[peak  freq] = sort(Pz,'descend');
indwz = Fz(freq);
pkswz = abs(peak);

Peaks = [pkswx(1);pkswy(1);pkswz(1)]; %prende il picco massimo di Pwx, Pwy, Pwz
pksw = max(Peaks);                        %massimo dei massimi
% SPETTRO DI POTENZA
if  pksw == pkswx(1)
    indw = indwx;
    Hpsd_w = dspdata.psd(Pwx(1:NFFT/2+1),'Fs',fs_daphne); 
elseif pksw == pkswy(1)
       indw = indwy;
       Hpsd_w = dspdata.psd(Pwy(1:NFFT/2+1),'Fs',fs_daphne);
elseif pksw == pkswz(1)
       indw = indwz;
       Hpsd_w = dspdata.psd(Pwz(1:NFFT/2+1),'Fs',fs_daphne);
end

features.freqG = indw(1);            %P02: FUNDAMENTAL GYRO FREQUENCY in 32s
freq_range1 = [3.5 7.5];
freq_range2 = [8 12];
features.PwrG    = avgpower(Hpsd_w); %P01: AVERAGE POWER IN GYRO PSD in 32s         
Pwr_w21   = avgpower(Hpsd_w,freq_range1);  
Pwr_w22   = avgpower(Hpsd_w,freq_range2);  

features.Perc1G = Pwr_w21/features.PwrG*100;  %P03: PERCENTAGE GYRO POWER IN (3.5-7.5HZ) in 32s           
features.Perc2G = Pwr_w22/features.PwrG*100;  %P04: PERCENTAGE GYRO POWER IN (8-12HZ) in 32s

% TS = linspace(1,2401,4);         %Time intervals for analysis
% TE = linspace(800,3200,4);
TS = [334 1223 2112 3001];
TE = [1223 2112 3001 3610];
features.freqG_i= zeros(1,4); features.PwrG_i= zeros(1,4); features.Perc1G_i= zeros(1,4); features.Perc2G_i= zeros(1,4);
for i=1:4
    wx_i = wxHPFilt(TS(i):TE(i));
    wy_i = wyHPFilt(TS(i):TE(i));
    wz_i = wzHPFilt(TS(i):TE(i));
%     wx_i  = filtfilt(d,c,wx_i);
%     wy_i  = filtfilt(d,c,wy_i);
%     wz_i  = filtfilt(d,c,wz_i);
    L_i = length(ts((TS(i):TE(i))));
    NFFT_i = 2^nextpow2(L_i);
    Wx_i = fft(wx_i,NFFT_i);
    Wy_i = fft(wy_i,NFFT_i);
    Wz_i = fft(wz_i,NFFT_i);
    f_i = fs_daphne/2*linspace(0,1,NFFT_i/2+1);
    Pwx_i = Wx_i.*conj(Wx_i)/(L_i*fs_daphne);            %calcolo densità spettrale di potenza 
    Pwy_i = Wy_i.*conj(Wy_i)/(L_i*fs_daphne);            %potenza media normalizzata
    Pwz_i = Wz_i.*conj(Wz_i)/(L_i*fs_daphne);

    [~, locsi] = findpeaks(Pwx_i(1:NFFT_i/2+1)); %find local peaks in X data
    Fxi  = (f_i(locsi));                       
    Pxi  = (Pwx_i(locsi));                    
    [peaki  freqi] = sort(Pxi,'descend');   
    indwxi = Fxi(freqi);                     
    pkswxi = abs(peaki);                      
    %DENSITà SPETTRALE Y
    [~, locsi] = findpeaks(Pwy_i(1:NFFT_i/2+1)); %find local peaks in Y data
    Fyi  = (f_i(locsi));
    Pyi  = (Pwy_i(locsi));
    [peaki  freqi] = sort(Pyi,'descend');
    indwyi = Fyi(freqi);
    pkswyi = abs(peaki);                       
    % DENSITà SPETTRALE Z
    [~, locsi] = findpeaks(Pwz_i(1:NFFT_i/2+1)); %find local peaks in Z data
    Fzi  = (f_i(locsi));
    Pzi  = (Pwz_i(locsi));
    [peaki  freqi] = sort(Pzi,'descend');
    indwzi = Fzi(freqi);
    pkswzi = abs(peaki);
    
    Peaks_i = [pkswxi(1);pkswyi(1);pkswzi(1)]; 
    pkswi = max(Peaks_i);                       
    % SPETTRO DI POTENZA
    if  pkswi == pkswxi(1)
        indwi = indwxi;
        Hpsd_wi = dspdata.psd(Pwx_i(1:NFFT_i/2+1),'Fs',fs_daphne);
    elseif pkswi == pkswyi(1)
        indwi = indwyi;
        Hpsd_wi = dspdata.psd(Pwy_i(1:NFFT_i/2+1),'Fs',fs_daphne);
    elseif pkswi == pkswzi(1)
        indwi = indwzi;
        Hpsd_wi = dspdata.psd(Pwz_i(1:NFFT_i/2+1),'Fs',fs_daphne);
    end

    features.freqG_i(i) = indwi(1);           %P09/P14/P19/P24: FUNDAMENTAL ACC FREQUENCY in 1-8s,9-16s,17-24s,25-32s
    features.PwrG_i(i)  = avgpower(Hpsd_wi);  %P08/P13/P18/P23: AVERAGE POWER IN ACC PSD in 1-8s,9-16s,17-24s,25-32s
    Pwr_g1i    = avgpower(Hpsd_wi,freq_range1);
    Pwr_g2i    = avgpower(Hpsd_wi,freq_range2);
    features.Perc1G_i(i) = Pwr_g1i/features.PwrG_i(i)*100; %P10/P15/P20/P25: PERCENTAGE ACC POWER (3.5-7.5HZ) in 1-8s,9-16s,17-24s,25-32s
    features.Perc2G_i(i) = Pwr_g2i/features.PwrG_i(i)*100; %P11/P16/P21/P26: PERCENTAGE ACC POWER (8-12HZ) in 1-8s,9-16s,17-24s,25-32s
end 
 features.freqG = round(features.freqG*100)/100;
 features.Perc1G = round(features.Perc1G*100)/100;
 features.Perc2G = round(features.Perc2G*100)/100;
 features.freqG_i = round(features.freqG_i*100)/100;
 features.Perc1G_i = round(features.Perc1G_i*100)/100;
 features.Perc2G_i = round(features.Perc2G_i*100)/100;
end