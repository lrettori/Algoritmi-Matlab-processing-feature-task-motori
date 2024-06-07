function [features] = fHTremor_A_modified(directory,filename,ts,data_ax,data_ay,data_az,data_wx,fs_daphne,exercise)

% amp = 0;        %P01: TREMOR AMPLITUDEIAV
% SDamp = 0;      %P02: SD TREMOR AMPLITUDE

% [MODIFICA] filtraggio eseguito qui dentro anziché prima
n = 4;
ft_daphne = 20;
wn_daphne = 2 * ft_daphne / fs_daphne;
[b,a] = butter(n,wn_daphne);
fdata_ax = filtfilt(b,a,data_ax);
fdata_ay = filtfilt(b,a,data_ay);
fdata_az = filtfilt(b,a,data_az);
fdata_wx = filtfilt(b,a,data_wx);

% MODULO DELL'ACCELERAZIONE
acc = sqrt(fdata_ax.^2+fdata_ay.^2+fdata_az.^2);  %acc 3D
plot_title = strcat(directory,'-',filename);
figure; plot(ts, acc, 'b.-');title(plot_title);

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
        if (fdata_wx(p) > THRE)
            app = p;
            flag = 1;
            while(flag)
                app = app + 1;
                if (fdata_wx(app) < TH_t)
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

% if (exercise==char('HRST'))
%     T_end = 1300;
% end

%valori dell'accelerazione dopo i secondi necessari per la calibrazione
ax  = fdata_ax(indexStart:indexStop);
ay  = fdata_ay(indexStart:indexStop);
az  = fdata_az(indexStart:indexStop);  
[d,c]= butter(4,2*0.5/100,'high');    %HP Butterworth filter, ft=0.5Hz, n=4

%filtraggio dei segnali di accelerazione con filtro passa alto
ax  = filtfilt(d,c,ax);
ay  = filtfilt(d,c,ay);
az  = filtfilt(d,c,az);
acc = filtfilt(d,c,acc(indexStart:indexStop));
L    = length(ts(indexStart:indexStop));
NFFT = 2^nextpow2(L);                 %Next power of 2 from length of L

% TRASFORMATA DI FOURIER
Ax  = fft(ax, NFFT);
Ay  = fft(ay, NFFT);
Az  = fft(az, NFFT);
Acc = fft(acc,NFFT);
f = fs_daphne/2*linspace(0,1,NFFT/2+1);
% POTENZA DEL SEGNALE, TEOREMA DI PARSEVAL
Pax = Ax.*conj(Ax)/(L*fs_daphne);
Pay = Ay.*conj(Ay)/(L*fs_daphne);
Paz = Az.*conj(Az)/(L*fs_daphne);
Pacc = Acc.*conj(Acc)/(L*fs_daphne);                   
% figure; plot(f,(Pax(1:NFFT/2+1)),'b.-'), title('a_x power spectral density'), xlabel('Frequency (Hz)');
% figure; plot(f,(Pay(1:NFFT/2+1)),'r.-'), title('a_y power spectral density'), xlabel('Frequency (Hz)');
% figure; plot(f,(Paz(1:NFFT/2+1)),'g.-'), title('a_z power spectral density'), xlabel('Frequency (Hz)');
% figure; plot(f,(Pacc(1:NFFT/2+1)),'k.-'), title('Acceleration power spectral density'), xlabel('Frequency (Hz)');
% potenza x
[pks, locs] = findpeaks(Pax(1:NFFT/2+1));
Fx  = (f(locs));
Px  = (Pax(locs));
[peak  freq] = sort(Px,'descend');
indx2 = Fx(freq);
pksx2 = abs(peak);
% potenza y
[pks, locs] = findpeaks(Pay(1:NFFT/2+1));
Fy  = (f(locs));
Py  = (Pay(locs));
[peak  freq] = sort(Py,'descend');
indy2 = Fy(freq);
pksy2 = abs(peak);
% potenza z
[pks, locs] = findpeaks(Paz(1:NFFT/2+1));
Fz  = (f(locs));
Pz  = (Paz(locs));
[peak  freq] = sort(Pz,'descend');
indz2 = Fz(freq);
pksz2 = abs(peak);
% potenza del modulo del segnale accelerometrico
[pks, locs] = findpeaks(Pacc(1:NFFT/2+1));       %valore e posizione dei picchi
F  = (f(locs));                                  %frequanze in corrispondenza dei picchi della potenza
Pa = (Pacc(locs));                               %picchi della potenza
[peak  freq] = sort(Pa,'descend');                      %picchi in ordine decrescente
inda2 = F(freq);                                 %frequenze in corrispondenza dei picchi in ordine decrescende, inda2(1): frequenza fondamentale
pksa2 = abs(peak);     
features.freqA = inda2(1);                      %P04: FUNDAMENTAL ACC FREQUENCY
% Power Spectral Density (psd)
Hpsd_ax = dspdata.psd(Pax(1:NFFT/2+1),'Fs',fs_daphne);
Hpsd_ay = dspdata.psd(Pay(1:NFFT/2+1),'Fs',fs_daphne);
Hpsd_az = dspdata.psd(Paz(1:NFFT/2+1),'Fs',fs_daphne);
Hpsd_acc = dspdata.psd(Pacc(1:NFFT/2+1),'Fs',fs_daphne);
% figure; plot(Hpsd_acc),title('Hpsd_acc');

%  Average power
features.PwrA    = avgpower(Hpsd_acc);            %P03: AVERAGE POWER IN ACC PSD
Pwr_ax2 = avgpower(Hpsd_ax); %computes the average power in a signal via a rectangle approximation of the integral of the Power Spectral Density (PSD) of such signal
Pwr_ay2 = avgpower(Hpsd_ay);
Pwr_az2 = avgpower(Hpsd_az);

freqrange1 = [3.5 7.5];
freqrange2 = [8 12];
% potenza del segnale accelerometrico nelle due bande scelte
Pwr_a21   = avgpower(Hpsd_acc,freqrange1);
Pwr_a22   = avgpower(Hpsd_acc,freqrange2);
% potenza percentuale rispetto alla potenza media totale
features.Perc1A = Pwr_a21/features.PwrA*100;              %P05: PERCENTAGE ACC POWER IN 3.5-7.5 HZ BAND
features.Perc2A = Pwr_a22/features.PwrA*100;              %P06: PERCENTAGE ACC POWER IN 8-12 HZ BAND

% stima del consumo energetico
acc_x          = fdata_ax(indexStart:indexStop);
acc_y          = fdata_ay(indexStart:indexStop);
acc_z          = fdata_az(indexStart:indexStop);
acc            = sqrt(acc_x.^2+acc_y.^2+acc_z.^2);
features.IAV            = trapz(ts(indexStart:indexStop),acc);  %P07: ESTIMATED ENERGY EXPENDITURE 


end