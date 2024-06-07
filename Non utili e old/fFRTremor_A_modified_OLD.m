function[features] = ...
         fFRTremor_A_modified_OLD(directory,filename,ts,data_ax,data_ay,data_az,fs_daphne,exercise)

% amp = 0;        %P01: TREMOR AMPLITUDE
% SDamp = 0;      %P02: SD TREMOR AMPLITUDE
n = 4;                             %ordine del filtro di Butterworth
ft_daphne = 20;                            %freq di taglio del filtro
wn_daphne = 2*ft_daphne/fs_daphne;                       %freq normalizzata di taglio del filtro
[b,a] = butter(n,wn_daphne);
fdata_ax = filtfilt(b,a,data_ax);   %index finger
fdata_ay = filtfilt(b,a,data_ay);
fdata_az = filtfilt(b,a,data_az);
%Analysis 32s
acc = sqrt(fdata_ax.^2+fdata_ay.^2+fdata_az.^2);  %acc 3D
% figure; plot(ts, acc, 'b.-');
[d,c]= butter(4,2*0.5/100,'high');    %HP Butterworth filter, ft=0.5Hz, n=4
acc = filtfilt(d,c,acc(334:3610));   
L    = length(ts(334:3610));
NFFT = 2^nextpow2(L);                 %Next power of 2 from length of L
acc_x          = fdata_ax(334:3610);
acc_y          = fdata_ay(334:3610);
acc_z          = fdata_az(334:3610);
accIAV         = sqrt(acc_x.^2+acc_y.^2+acc_z.^2);
features.IAV            = trapz(ts(334:3610),accIAV);  %P07: ESTIMATED ENERGY EXPENDITURE in 32s

freqrange1 = [3.5 7.5]; 
freqrange2 = [8 12];

Acc = fft(acc,NFFT);            %Fourier transform
f = fs_daphne/2*linspace(0,1,NFFT/2+1);
Pacc = Acc.*conj(Acc)/(L*fs_daphne);   %Signal Power, Parseval Theorem                 
% figure; plot(f,(Pacc(1:NFFT/2+1)),'k.-'), title('Acceleration power spectral density'), xlabel('Frequency (Hz)');
% potenza del modulo del segnale accelerometrico
[~,locs] = findpeaks(Pacc(1:NFFT/2+1));      %valore e posizione dei picchi
F  = (f(locs));                              %frequanze in corrispondenza dei picchi della potenza
Pa = (Pacc(locs));                           %picchi della potenza
[~,freq] = sort(Pa,'descend');               %picchi in ordine decrescente
inda2 = F(freq);                             %frequenze in corrispondenza dei picchi in ordine decrescende, inda2(1): frequenza fondamentale
features.freqA = inda2(1);                      %P04: FUNDAMENTAL ACC FREQUENCY in 32s
% Power Spectral Density (psd)
Hpsd_acc = dspdata.psd(Pacc(1:NFFT/2+1),'Fs',fs_daphne);
% figure; plot(Hpsd_acc),title('Hpsd_acc');
features.PwrA    = avgpower(Hpsd_acc);          %P03: AVERAGE POWER IN ACC PSD in 32s
freqrange1 = [3.5 7.5];
freqrange2 = [8 12];
Pwr_a21   = avgpower(Hpsd_acc,freqrange1);
Pwr_a22   = avgpower(Hpsd_acc,freqrange2);
features.Perc1A = Pwr_a21/features.PwrA*100;             %P05: PERCENTAGE ACC POWER IN 3.5-7.5 HZ BAND in 32s
features.Perc2A = Pwr_a22/features.PwrA*100;             %P06: PERCENTAGE ACC POWER IN 8-12 HZ BAND in 32s

% TS = linspace(1,2401,4);         %Time intervals for analysis
% TE = linspace(800,3200,4);
TS = [1 890 1779 2668];         %Time intervals for analysis
TE = [890 1779 2668 3277];
features.IAV_i = zeros(1,4); features.freqA_i= zeros(1,4); features.PwrA_i= zeros(1,4); features.Perc1A_i= zeros(1,4); features.Perc2A_i= zeros(1,4);
for i=1:4
    acc_i = acc(TS(i):TE(i));
    acciav_i = accIAV(TS(i):TE(i));
    L_i = length(ts((TS(i):TE(i))));
    NFFT_i = 2^nextpow2(L_i);
    features.IAV_i(i) = trapz(ts(TS(i):TE(i)),acciav_i); %P12/P17/P22/P27: ESTIMATED ENERGY EXPENDITURE in 1-8s,9-16s,17-24s,25-32s
    Acc_i = fft(acc_i,NFFT_i);
    f_i = fs_daphne/2*linspace(0,1,NFFT_i/2+1);
    Pacc_i = Acc_i.*conj(Acc_i)/(L_i*fs_daphne);
    [~,locsi] = findpeaks(Pacc_i(1:NFFT_i/2+1));
    Fi  = (f_i(locsi));
    Pai = (Pacc_i(locsi));
    [~,freqi] = sort(Pai,'descend');
    indai   = Fi(freqi);
    features.freqA_i(i) = indai(1);              %P09/P14/P19/P24: FUNDAMENTAL ACC FREQUENCY in 1-8s,9-16s,17-24s,25-32s
    Hpsd_acc_i = dspdata.psd(Pacc_i(1:NFFT_i/2+1),'Fs',fs_daphne);
    features.PwrA_i(i)  = avgpower(Hpsd_acc_i);  %P08/P13/P18/P23: AVERAGE POWER IN ACC PSD in 1-8s,9-16s,17-24s,25-32s
    Pwr_a1i    = avgpower(Hpsd_acc_i,freqrange1);
    Pwr_a2i    = avgpower(Hpsd_acc_i,freqrange2);
    features.Perc1A_i(i) = Pwr_a1i/features.PwrA_i(i)*100; %P10/P15/P20/P25: PERCENTAGE ACC POWER (3.5-7.5HZ) in 1-8s,9-16s,17-24s,25-32s
    features.Perc2A_i(i) = Pwr_a2i/features.PwrA_i(i)*100; %P11/P16/P21/P26: PERCENTAGE ACC POWER (8-12HZ) in 1-8s,9-16s,17-24s,25-32s
end  
 features.IAV = round(features.IAV*100)/100;
 features.freqA = round(features.freqA*100)/100;
 features.Perc1A = round(features.Perc1A*100)/100;
 features.Perc2A = round(features.Perc2A*100)/100;
 features.IAV_i = round(features.IAV_i*100)/100;
 features.freqA_i = round(features.freqA_i*100)/100;
 features.Perc1A_i = round(features.Perc1A_i*100)/100;
 features.Perc2A_i = round(features.Perc2A_i*100)/100;
end