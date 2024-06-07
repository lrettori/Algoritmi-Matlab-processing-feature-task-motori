function [features] = fFmotorSU_modified(data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne)


%% Rimozione dell'offset per il segnale del giroscopio
offsetWx = offsetCalculation(data_wx,ts,1,2);
offsetWy = offsetCalculation(data_wy,ts,1,2);
offsetWz = offsetCalculation(data_wz,ts,1,2);

wxOffsetRemov = data_wx - offsetWx;
wyOffsetRemov = data_wy - offsetWy;
wzOffsetRemov = data_wz - offsetWz;

%% Modulo accelerazione, normalizzato su g (serve solo al calcolo della frequenza fondamentale (non utilizzata)
acc0 = sqrt(data_ax.^2+data_ay.^2+data_az.^2) - 9.81;

%% FFT e calcolo frequenza fondamentale (non utilizzata)
L = length(ts);
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
psd_acc0 = fft(acc0,NFFT);
f = fs_daphne/2*linspace(0,1,NFFT/2+1);
% Plot one-sided amplitude spectrum.
Pacc0 = psd_acc0.*conj(psd_acc0)/(L*fs_daphne); % calcolo densità spettrale di potenza
% figure; subplot(1,3,1);
% plot(f,(Pacc0(1:NFFT/2+1)),'r.-');
[~, locs] = findpeaks(Pacc0(1:NFFT/2+1));
F = (f(locs));
P0 = (Pacc0(locs));
[~, freq] = sort(P0,'descend');
inda = F(freq);
fundfreq = inda(1); % frequenza fondamentale, non portata in C#

%% Filtraggio passa-basso con frequenza fissa 5 Hz (frequenza fondamentale non utile)
n = 4;                            %ordine del filtro di Butterworth
ft_daphne = 5; %fundfreq+1;              %freq di taglio del filtro
wn_daphne = 2*ft_daphne/fs_daphne;        %freq normalizzata di taglio del filtro
[b,a] = butter(n,wn_daphne);          %calcolo i coeff del filtro passa basso di butterworth
fdata_ax = filtfilt(b,a,data_ax);  %index finger
fdata_ay = filtfilt(b,a,data_ay);
fdata_az = filtfilt(b,a,data_az);
fdata_wx = filtfilt(b,a,wxOffsetRemov);
fdata_wy = filtfilt(b,a,wyOffsetRemov);
fdata_wz = filtfilt(b,a,wzOffsetRemov);

plot_title1 = 'fdata_acc x, y and z';
figure;
subplot(1,2,1);
plot(ts,fdata_ax,'r.-',ts,fdata_ay,'b.-',ts,fdata_az,'g.-');title(plot_title1,'Interpreter','none');

% Calcolo modulo di w, a partire dai dati filtrati, e poi rimuovo il suo
% offset
gyrMod = sqrt(fdata_wx.^2+fdata_wy.^2+fdata_wz.^2);
offsetGyrMod = offsetCalculation(gyrMod,ts,1,2);
gyrModOffsetRemov = gyrMod - offsetGyrMod;
plot_title2 = 'fdata_w x, y and z';
hold on; subplot(1,2,2); plot(ts,gyrModOffsetRemov,'k.-',ts,fdata_wx,'r.-',ts,fdata_wy,'b.-',ts,fdata_wz,'g.-');title(plot_title2,'Interpreter','none');

% Calcolo modulo di acc, a partire dai dati filtrati, e rimuovo il suo
% offset
% facc = sqrt(fdata_ax.^2+fdata_ay.^2+fdata_az.^2)-9.81;
% acc_m = facc - mean(facc(index1sec:index2sec));
% subplot(1,2,2); plot(ts,acc_m,'.-');title(plot_title);


%% Signal segmentation
THRE_st = 30;
TH_st = 5;
% k = 300;
[~,k] = min(abs(ts-3));
p = length(ts);
st = 1;
while(k<=p)
    switch(st)
        case 1
            if (gyrModOffsetRemov(k)>THRE_st)
                app = k;
                flag = 1;
                while(flag)
                    app = app - 1;
                    if (gyrModOffsetRemov(app)<TH_st)
                        T_start = app;
                        flag = 0;
                        subplot(1,2,2);hold on; plot(ts(T_start),gyrModOffsetRemov(T_start),'go');
                        subplot(1,2,1);hold on; plot(ts(T_start),fdata_ax(T_start),'go',ts(T_start),fdata_ay(T_start),'go',ts(T_start),fdata_az(T_start),'go');
                        st = 2;
                    end
                end
            elseif (gyrModOffsetRemov(k)<-THRE_st)
                app = k;
                flag = 1;
                while(flag)
                    app = app - 1;
                    if (gyrModOffsetRemov(app)>-TH_st)
                        T_start = app;
                        flag = 0;
                        subplot(1,2,2);hold on; plot(ts(T_start),gyrModOffsetRemov(T_start),'go');
                        subplot(1,2,1);hold on; plot(ts(T_start),fdata_ax(T_start),'go',ts(T_start),fdata_ay(T_start),'go',ts(T_start),fdata_az(T_start),'go');
                        st = 2;
                    end
                end
            end
        case 2
            break
    end
    k = k+1;
end

THRE_en = 20;
TH_en = 3;
% v = 400;
[~,v] = min(abs(ts-4));
ct = 1;
while(p>=v)
    switch(ct)
        case 1
            if (gyrModOffsetRemov(p)>THRE_en)
                app = p;
                flag = 1;
                while(flag)
                    app = app + 1;
                    if (gyrModOffsetRemov(app)<TH_en)
                        T_end = app;
                        flag = 0;
                        subplot(1,2,2);hold on; plot(ts(T_end),gyrModOffsetRemov(T_end),'ro');
                        subplot(1,2,1);hold on; plot(ts(T_end),fdata_ax(T_end),'ro',ts(T_end),fdata_ay(T_end),'ro',ts(T_end),fdata_az(T_end),'ro');
                        ct = 2;
                    end
                end
            elseif (gyrModOffsetRemov(p)<-THRE_en)
                app = p;
                flag = 1;
                while(flag)
                    app = app + 1;
                    if (gyrModOffsetRemov(app)>-TH_en)
                        T_end = app;
                        flag = 0;
                        subplot(1,2,2);hold on; plot(ts(T_end),gyrModOffsetRemov(T_end),'ro');
                        subplot(1,2,1);hold on; plot(ts(T_end),fdata_ax(T_end),'ro',ts(T_end),fdata_ay(T_end),'ro',ts(T_end),fdata_az(T_end),'ro');
                        ct = 2;
                    end
                end
            end
        case 2
            break
    end
    p = p-1;
end

features.time = ts(T_end)-ts(T_start);  %P01:Time

end