function[features] = fFmotorHE(data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne)

% Questa funzione è stata fortemente modificata dall'originale. Ci sono
% numerose features che andrebbero riviste, per la fase iniziale del
% progetto Olimpia però ci fermiamo a sole 4.


%% [MODIFICA] Organizzo le features in una structure, per semplificare la visualizzazione e il confronto con il C#
% features.vel10 = 0; % feature non estratta in una prima fase
% features.vel10SD = 0;  % feature non estratta in una prima fase
% features.exc10 = 0;  % feature non estratta in una prima fase
% features.exc10SD = 0;  % feature non estratta in una prima fase
% features.dec10B = 0;  % feature non estratta in una prima fase
% features.dec10M = 0;  % feature non estratta in una prima fase
% features.dec10E = 0;  % feature non estratta in una prima fase
% features.hes10 = 0;  % feature non estratta in una prima fase
features.taps = 0;
% features.exc = 0;  % feature non estratta in una prima fase
% features.excSD = 0;  % feature non estratta in una prima fase
% features.vo = 0;  % feature non estratta in una prima fase
% features.voSD = 0;  % feature non estratta in una prima fase
% features.vc = 0;  % feature non estratta in una prima fase
% features.vcSD = 0;  % feature non estratta in una prima fase
% features.IAV = 0;  % feature non estratta in una prima fase
% features.hes = 0;  % feature non estratta in una prima fase
% features.decB = 0;  % feature non estratta in una prima fase
% features.decM = 0;  % feature non estratta in una prima fase
% features.decE = 0;  % feature non estratta in una prima fase
features.fundfreq = 0;
features.power = 0;
features.fundpeak = 0;

%% Rimozione offset dal segnale giroscopio [MODIFICA]

offsetWx = offsetCalculation(data_wx,ts,1,2);
offsetWy = offsetCalculation(data_wy,ts,1,2);
offsetWz = offsetCalculation(data_wz,ts,1,2);

data_wx = data_wx - offsetWx;
data_wy = data_wy - offsetWy;
data_wz = data_wz - offsetWz;

% Vecchia soluzione:
% data_wx = data_wx - mean(data_wx(100:200));
% data_wy = data_wy - mean(data_wy(100:200));
% data_wz = data_wz - mean(data_wz(100:200));

% tetaFF_i_rad  = atan(ax2_i/az2_i);
% tetaFF_i_deg  = tetaFF_i_rad*180/pi; %angolo di inclinazione iniziale

%% Ricerca del T_start, utilizzando i dati del giroscopio lungo l'asse y (da rivedere)
L    = length(ts);
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
psd_wy = fft(data_wy,NFFT);
f = fs_daphne/2*linspace(0,1,NFFT/2+1);
% Plot one-sided amplitude spectrum.
Pwy = psd_wy.*conj(psd_wy)/(L*fs_daphne);                   % calcolo densità spettrale di potenza
% figure; plot(f,(Pwy(1:NFFT/2+1)),'r.-');
[~, locs] = findpeaks(Pwy(1:NFFT/2+1));
F  = (f(locs));
Pw = (Pwy(locs));
[~,  freq] = sort(Pw,'descend');
inda = F(freq);
fundfreq = inda(1); %frequenza fondamentale del tapping

n         =   4;                            %ordine del filtro di Butterworth
ft_daphne =   fundfreq+1;                            %freq di taglio del filtro
wn_daphne =   2*ft_daphne/fs_daphne;        %freq normalizzata di taglio del filtro
[b,a]     =   butter(n,wn_daphne);          %calcolo i coeff del filtro passa basso di butterworth
fdata_ax     =   filtfilt(b,a,data_ax);  %index finger
fdata_ay     =   filtfilt(b,a,data_ay);
fdata_az     =   filtfilt(b,a,data_az);
fdata_wx     =   filtfilt(b,a,data_wx);
fdata_wy     =   filtfilt(b,a,data_wy);
fdata_wz     =   filtfilt(b,a,data_wz);

% SIGNAL SEGMENTATION
% k = 250;
[~,k] = min(abs(ts-2.5));
p   =   length(ts);
% st  =   1;
step    = 0;
THRE = 10; TH_t = 3;

% fdata_wx = fdata_wx - mean(fdata_wx(100:200));   %OFFSET
% fdata_wy = fdata_wy - mean(fdata_wy(100:200));
% fdata_wz = fdata_wz - mean(fdata_wz(100:200)); 
% figure;plot(ts,fdata_wy,'b.-');
% ax_i = mean(fdata_ax(100:200));
% az_i = mean(fdata_az(100:200));
% teta_i_rad = atan(ax_i/az_i);
% teta_i_deg = teta_i_rad*180/pi;

while(k<=p)
    if (fdata_wy(k)>THRE && step==0)
        app = k;
        flag = 1;
        while(flag)
            app = app - 1;
            if (fdata_wy(app)<TH_t)
                step = step + 1;
                T_start = app;
%                 hold on; plot(ts(T_start),fdata_wy(T_start), 'go');
                flag = 0;
            end
        end
    end
    k   =   k+1;
end

% Trovo l'indice del campione acquisito 10 secondi dopo il primo tapping
timeStart = ts(T_start);
timeEnd = timeStart + 10;
[~,T_end] = min(abs(ts - timeEnd));

% T_end = T_start+1000; Vecchia versione, non corretta

accXData_10secCut = data_ax(T_start:T_end);
accYData_10secCut = data_ay(T_start:T_end);
accZData_10secCut = data_az(T_start:T_end);
acc_10secCut = sqrt(accXData_10secCut.^2 + accYData_10secCut.^2 + accZData_10secCut.^2);

acc_x          = fdata_ax(T_start:T_end);
acc_y          = fdata_ay(T_start:T_end);
acc_z          = fdata_az(T_start:T_end);
acc            = sqrt(acc_x.^2+acc_y.^2+acc_z.^2);
features.IAV            = trapz(ts(T_start:T_end),acc); %P16: ESTIMATED ENERGY EXPENDITURE


%% ANALISI IN FREQUENZA: trovo freq.fond. e freq.peak

% fs = 100; [MODIFICA] - non uso una frequenza fissa di 100 Hz ma quella
% passata in input fs_daphne
fs = fs_daphne;
fmin = 0.5; %fundfreq-2;
fmax = ft_daphne;

% Nuova soluzione, filtro passa-banda il vettore modulo acc_10secCut
[d,c] = butter(4,2*[fmin,fmax]/fs,'bandpass');
acc1 = filtfilt(d,c,acc_10secCut);
% Vecchia soluzione, prendo i vettori filtrati (x, y, z), ne calcolo il
% modulo, e poi filtro passa-alto
% [d,c]= butter(4,2*0.5/100,'high');    %HP Butterworth filter, ft=1Hz, n=4
% acc1 = filtfilt(d,c,acc);

L    = length(ts(T_start:T_end));
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Acc = fft(acc1,NFFT);
f = fs/2*linspace(0,1,NFFT/2+1);
Pacc = Acc.*conj(Acc)/(L*fs);                   % calcolo densità spettrale di potenza
% figure; plot(f,(Pacc(1:NFFT/2+1)),'k.-'), title('Acceleration power spectral density'), xlabel('Frequency (Hz)');
[pks, locs] = findpeaks(Pacc(1:NFFT/2+1));
F  = (f(locs));
Pa = (Pacc(locs));
[peak, freq] = sort(Pa,'descend');
inda = F(freq);
features.fundfreq = inda(1); %P21: FUNDAMENTAL FREQUENCY OF PSD
features.fundpeak = peak(1); %P23: FUNDAMENTAL PEAK OF PSD
Hpsd_a = dspdata.psd(Pacc(1:NFFT/2+1),'Fs',fs);
features.power  = avgpower(Hpsd_a); %P22: AVERAGE POWER IN PSD

%% SEGMENTAZIONE DEL SEGNALE
% Filtro tutto il segnale di ingresso con filtro passa-banda
% (precedentemente avevo filtrato passa-basso tutto il segnale, per trovare
% l'inizio del tapping, poi avevo tagliato il segnale, trovato il modulo di
% acc e filtrato passa-alto per trovare le feature. Quando riprendo in mano
% questo algoritmo va ottimizzato, per il momento lo utilizziamo così


fmin = 0.5; %fundfreq-2;
% fmax = features.fundfreq+2;
fmax = features.fundfreq+1; % Correzione 04/09/2026
[h,g] = butter(4,2*[fmin,fmax]/fs,'bandpass');
% [h,g] = butter(4,(2*fmax)/fs,'low');

% acceleration = sqrt(fdata_ax.^2+fdata_ay.^2+fdata_az.^2); % Soluzione originale
acceleration = sqrt(data_ax.^2 + data_ay.^2 + data_az.^2); % Soluzione nuova, prendo i dati non filtrati e poi eseguo un filtraggio passa-banda sul vettore modulo acceleration

acc2 = filtfilt(h,g,acceleration);
% % acc2 = sqrt(fdata_ax.^2+fdata_ay.^2+fdata_az.^2);
% % pp = 0;
% fs_d2   = 1000; %resampling freq Hz
% ts_d2 = ts(1):1/fs_d2:ts(length(ts));
% acc1    = (interp1(ts,acc2,ts_d2,'spline')');  %cubic spline interpolation
% % figure; plot(ts,acc1,'c.-',ts_d2,acc,'b.-');

ts_d2 = ts;
acc1 = acc2;

plot_title = 'acc1';
figure; plot(ts_d2,acc1,'b.-');title(plot_title);
% TH_HE  =  1;      %  °/s, al di sotto di questa velocità angolare il piede si considera totalmente appoggiato a terra
TH_HE  =  0.8; % Correzione 04/09/2026
TH_HE1  =  1;
TH_HEv =  0.2;
k   =   200;
p   =   length(ts_d2);
st = 1;
tap=   0;

while(k<=p)
    switch(st)
        case 1
            if (tap==0 && acc1(k)>TH_HE)
                app = k; flag = 1;
                while(flag)
                    app = app - 1;
                    if (acc1(app)<TH_HEv)
                        tap = tap + 1;
                        T_start_d(tap) = app;
                        hold on; plot(ts_d2(T_start_d),acc1(T_start_d),'go');
                        flag = 0;
                        st = 2;
                    end
                end
            else if (tap~=0 && acc1(k)>TH_HE1 && (ts_d2(k)<(ts_d2(T_start_d(1))+10)))
                    app = k; flag = 1;
                    while(flag)
                        app = app - 1;
                        if (acc1(app)<TH_HEv)
                            tap = tap + 1;
                            T_start_d(tap) = app;
                            if T_start_d(tap)<T_end_d(tap-1)
                                T_start_d(tap) = T_end_d(tap-1);
                            end
                            hold on; plot(ts_d2(T_start_d),acc1(T_start_d),'go');
                            flag = 0;
                            st = 2;
                        end
                    end
            end
            end
        case 2
            if (acc1(k)<TH_HEv)  %valuto i 10 sec successivi al primo T_start
                T_HH_d(tap) = k;   %pollice e indice alla massima distanza
                hold on; plot(ts_d2(T_HH_d),acc1(T_HH_d),'co');
                st = 3;
            end
        case 3
            if (acc1(k)>-TH_HEv && acc1(k)>acc1(k-1))
                T_end_d(tap) = k;
                hold on; plot(ts_d2(T_end_d),acc1(T_end_d),'ro');
                st = 1;
                %                     app = k;
                %                     flag = 1;
                %                     while(flag)
                %                           app = app - 1;
                %                           if (acc(app)<TH_HEv)
                %                               T_end_d(tap_daphne) = app;
                %                               hold on; plot(ts_d2(T_end_d),acc(T_end_d),'ro');
                %                               flag = 0;
                %                               st = 1;
                %                           end
                %                     end
            end
    end
    k   =   k+1;
end

features.taps = tap;





%% Tutta la parte qua sotto sarebbe da rivedere, in prima battuta ci fermiamo a 5 feature calcolate (taps, fundfreq, fundpeak, power e IAV)

% 
% if (tap == 0 || tap == 1 || tap == 2)
%     % Non faccio niente, tutte le features sono già inizializzate a 0
%     %     vel10 = 0; vel10SD = 0; exc10 = 0; exc10SD = 0; dec10B = 0; dec10M = 0;
%     %     dec10E = 0; hes10 = 0; taps = tap; exc = 0;
%     %     excSD = 0; vo = 0; voSD = 0; vc = 0; vcSD = 0; IAV = 0; hes = 0;
%     %     decB = 0; decM = 0; decE = 0;
% 
% else
%     if length(T_end_d)<length(T_start_d)
%         int_d = T_end_d(tap-1)-T_start_d(tap-1);
%         T_last_d      = T_start_d(tap) + int_d(end);
%         T_end_d(tap) = T_last_d;
%         %         hold on; plot(ts_d2(T_end_d),acc1(T_end_d), 'ro');
%     end
% 
% %     features.taps = tap; % P09: NUMBER OF TAPPING IN 10 s [MODIFICA, l'ho
% %     spostato prima dell'if]
% 
%     if (tap>2 && tap<11)
%         features.vel10 = 0; features.vel10SD = 0;
%     else
%         for rr=1:10
%             T_tap(rr) = ts_d2(T_end_d(rr+1))-ts_d2(T_start_d(rr+1));
%             vel(rr) = 1/T_tap(rr);
%         end
%         for gg=1:(features.taps-1)
%             T_rhytm(gg) = ts_d2(T_end_d(gg+1))-ts_d2(T_start_d(gg+1));
%         end
%         features.vel10   = mean(vel);  %P01: VELOCITY WITHIN THE FIRST 10 MOVMENTS
%         features.vel10SD = std(vel);   %P02: SD OF VELOCITY WITHIN THE FIRST 10 MOVMENTS
%     end
% 
% 
%     % CALCOLO LA VELOCITà (PRIMA INTEGRAZIONE)
%     for i=1:tap
%         acc_i         = acc1(T_start_d(i):(T_HH_d(i)));
%         tapp_i        = ts_d2(T_start_d(i):(T_HH_d(i)));
%         v_i           = cumtrapz(tapp_i,acc_i);
%         %          hold on; plot(tapp_i, v_i, 'k');
%         if i<tap
%             acc_i2         = acc1(T_HH_d(i):(T_start_d(i+1)));
%             tapp_i2        = ts_d2(T_HH_d(i):(T_start_d(i+1)));
%             v_i2           = cumtrapz(tapp_i2, acc_i2);
%             v_i_r          = v_i2+v_i(end);
%             %             hold on; plot(tapp_i2, v_i_r, 'k');
%             mv = (v_i_r(end)-v_i(1))/(tapp_i2(end)-tapp_i(1)); qv = v_i(1)-mv*tapp_i(1);
%             v_e = mv*ts_d2(T_start_d(i):T_start_d(i+1))+qv;
%             %             hold on; plot(ts_d2(T_start_d(i):T_start_d(i+1)),v_e,'g');
%             v_tot = [v_i',(v_i_r(2:end))'];
%             v_m = v_tot-v_e;
%             %             hold on; plot(ts_d2(T_start_d(i):T_start_d(i+1)),v_m,'k');
%         else
%             acc_i3        = acc1(T_HH_d(i):(T_end_d(i)));       %per l'ultimo step
%             tapp_i3       = ts_d2(T_HH_d(i):(T_end_d(i)));
%             v_i3          = cumtrapz(tapp_i3, acc_i3);
%             v_i_r      = v_i3+v_i(end);
%             %             hold on; plot(tapp3, xang_r, 'k');
%             mv = (v_i_r(end)-v_i(1))/(tapp_i3(end)-tapp_i(1)); qv = v_i(1)-mv*tapp_i(1);
%             v_e = mv*ts_d2(T_start_d(i):T_end_d(i))+qv;
%             %             hold on; plot(ts_d2(T_start_d(i):T_end_d(i)),v_e,'g');
%             v_tot = [v_i',(v_i_r(2:end))'];
%             v_m = v_tot-v_e;
%             %             hold on; plot(ts_d2(T_start_d(i):T_end_d(i)),v_m,'k');
%         end
%         acc_open(i)      = mean(acc_i);
%         acc_close(i)     = mean(acc_i2);
%         vel(i)           = max(abs(v_m));
%         if i == 1
%             l = length(v_m);
%             v_total(1:l)  = v_m;
%         else
%             l = length(v_m);
%             v_total = [v_total,v_m(2:end)];
%         end
%     end
%     acc_op      = abs(mean(acc_open));
%     acc_cl      = abs(mean(acc_close));
%     velocity    = mean(vel);
%     VELOC       = vel.';
%     vel_tot     = v_total(1:end-1);
% 
% % CALCOLO LO SPOSTAMENTO (SECONDA INTEGRAZIONE)    
%     T_st = T_start_d - T_start_d(1)+1;
%     T_HH = T_HH_d - T_start_d(1)+1;
%     T_en = T_end_d - T_start_d(1);
% %     figure;
%         for i=1:tap
%         vel_i         = vel_tot(T_st(i):(T_HH(i)));
%         t_i           = ts_d2(T_st(i):(T_HH(i)));
%         y_i           = cumtrapz(t_i,vel_i);    
% %          hold on; plot(t_i, y_i, 'r');
%              if i<tap
%                 vel_i2      = -vel_tot(T_HH(i):(T_st(i+1)));
%                 t_i2        = ts_d2(T_HH(i):(T_st(i+1)));
%                 y_i2        = cumtrapz(t_i2, vel_i2);
%                 y_i_r       = y_i2+y_i(end);
% %                  hold on; plot(t_i2, y_i_r, 'k');
%                 my = (y_i_r(end)-y_i(1))/(tapp_i2(end)-t_i(1)); qy = y_i(1)-my*t_i(1);
%                 y_e = my*ts_d2(T_st(i):T_st(i+1))+qy;
% %                  hold on; plot(ts_d2(T_st(i):T_st(i+1)),y_e,'g'); 
%                 y_tot = [y_i,(y_i_r(2:end))];
%                 y_m = y_tot-y_e;
% %                 hold on; plot(ts_d2(T_st(i):T_st(i+1)),y_m,'k');
%              else
%                 vel_i3     = vel_tot(T_HH(i):(T_en(i)));       %per l'ultimo step
%                 t_i3       = ts_d2(T_HH(i):(T_en(i)));
%                 y_i3       = cumtrapz(t_i3, vel_i3);
%                 y_i_r      = y_i3+y_i(end);
% %                  hold on; plot(t_i3, y_i_r, 'k'); 
%                 my = (y_i_r(end)-y_i(1))/(t_i3(end)-t_i(1)); qy = y_i(1)-my*t_i(1);
%                 y_e = my*ts_d2(T_st(i):T_en(i))+qy;
% %                  hold on; plot(ts_d2(T_st(i):T_en(i)),y_e,'g'); 
%                 y_tot = [y_i,(y_i_r(2:end))];
%                 y_m = y_tot-y_e;
% %                 hold on; plot(ts_d2(T_st(i):T_en(i)),y_m,'k');
%             end
%         vel_open(i)      = mean(vel_i);
%         vel_close(i)     = mean(vel_i2);    
%         h_daphne(i)      = max(abs(y_m)); % HEIGHT in meters
%             if i == 1
%                l = length(y_m);
%                y_total(1:l)  = y_m;
%             else
%                l = length(y_m);
%                y_total = [y_total,y_m(2:end)];
%             end         
%         end
%     features.vo      = abs(mean(vel_open(2:end-1)));  %P12: RISING VELOCITY
%     features.voSD    = std(vel_open(2:end-1));        %P13: SD RISING VELOCITY   
%     features.vc      = abs(mean(vel_close(2:end-1))); %P14: LOWERING VELOCITY
%     features.vcSD    = std(vel_close(2:end-1));       %P15: SD RISING VELOCITY 
%     features.h_daphne    = h_daphne(1:end-1);    
%     features.exc         = mean(h_daphne);  %P10: HEIGHT
%     features.excSD       = std(h_daphne);   %P11: HEIGHT SD
%     
%     Y       = h_daphne.';
%     Y_TOT   = y_total(1:end-1);
%         
%     if (features.taps>2 && features.taps<11)
%         features.exc10 = 0; features.exc10SD = 0; features.dec10B = 0; features.dec10M = 0; features.dec10E = 0;
% %     elseif taps == 12
% %             exc10       = (sum(h_daphne(2:10)))/9; %P03:MEAN AMPLITUDE OF MOVEMENT WITHIN THE FIRST 10 MOVMENTS
% %             exc10SD     = std(h_daphne(2:10));      %P04:SD OF MEAN AMPLITUDE OF MOVEMENT WITHIN THE FIRST 10 MOVMENTS
%     else    
%     features.exc10       = (sum(h_daphne(2:11)))/10; %P03:MEAN AMPLITUDE OF MOVEMENT WITHIN THE FIRST 10 MOVMENTS
%     features.exc10SD     = std(h_daphne(2:11));      %P04:SD OF MEAN AMPLITUDE OF MOVEMENT WITHIN THE FIRST 10 MOVMENTS
%     %CALCOLO RIDUZIONI/INCREMENTI DI AMPIEZZA:
%     features.dec10B = 100*((sum(h_daphne(3:5))/3)/(h_daphne(2))-1); %P05:PERCENTAGE DEC-INC WITHIN THE 2-4 MOVEMENTS
%     features.dec10M = 100*((sum(h_daphne(6:8))/3)/(h_daphne(2))-1); %P06:PERCENTAGE DEC-INC WITHIN THE 5-7 MOVEMENTS
%     features.dec10E = 100*((sum(h_daphne(9:11))/3)/(h_daphne(2))-1);%P07:PERCENTAGE DEC-INC WITHIN THE 8-10 MOVEMENTS
%     end
%     
%     amp_0 = h_daphne(2);       %AMPIEZZA DI RIFERIMENTO SOLO LA PRIMA REPLICA (che è la seconda replica effettiva)
%     
%      ss = 1;  
%     for s=1:tap
%         if ((T_start_d(s)>=(T_start_d(1)+1000)) && (T_start_d(s)<(T_start_d(1)+4000)))
%         acc_i         = acc1(T_start_d(s):(T_HH_d(s)));
%         tapp_i        = ts_d2(T_start_d(s):(T_HH_d(s)));
%         v_i           = cumtrapz(tapp_i,acc_i);    
% %          hold on; plot(tapp_i, v_i, 'k');
%          if s<tap
%             acc_i2         = acc1(T_HH_d(s):(T_start_d(s+1)));
%             tapp_i2        = ts_d2(T_HH_d(s):(T_start_d(s+1)));
%             v_i2           = cumtrapz(tapp_i2, acc_i2);
%             v_i_r          = v_i2+v_i(end);
%  %             hold on; plot(tapp_i2, v_i_r, 'k');
%             mv = (v_i_r(end)-v_i(1))/(tapp_i2(end)-tapp_i(1)); qv = v_i(1)-mv*tapp_i(1);
%             v_e = mv*ts_d2(T_start_d(s):T_start_d(s+1))+qv;
%  %             hold on; plot(ts_d2(T_start_d(s):T_start_d(s+1)),v_e,'g'); 
%             v_tot = [v_i',(v_i_r(2:end))'];
%             v_m = v_tot-v_e;
% %             hold on; plot(ts_d2(T_start_d(s):T_start_d(s+1)),v_m,'k');
%          else
%             acc_i3        = acc1(T_HH_d(s):(T_end_d(s)));       %per l'ultimo step
%             tapp_i3       = ts_d2(T_HH_d(s):(T_end_d(s)));
%             v_i3          = cumtrapz(tapp_i3, acc_i3);
%             v_i_r      = v_i3+v_i(end);
%  %             hold on; plot(tapp3, xang_r, 'k'); 
%             mv = (v_i_r(end)-v_i(1))/(tapp_i3(end)-tapp_i(1)); qv = v_i(1)-mv*tapp_i(1);
%             v_e = mv*ts_d2(T_start_d(s):T_end_d(s))+qv;
%  %             hold on; plot(ts_d2(T_start_d(s):T_end_d(s)),v_e,'g'); 
%             v_tot = [v_i',(v_i_r(2:end))'];
%             v_m = v_tot-v_e;
% %             hold on; plot(ts_d2(T_start_d(s):T_end_d(s)),v_m,'k');
%         end
%         acc_open(s)      = mean(acc_i);
%         acc_close(s)     = mean(acc_i2);    
%         vel(s)           = max(abs(v_m));
%         if i == 1
%            l = length(v_m);
%            v_total(1:l)  = v_m;
%         else
%            l = length(v_m);
%            v_total = [v_total,v_m(2:end)];
%         end
%         end
%     end
%     acc_op      = abs(mean(acc_open));
%     acc_cl      = abs(mean(acc_close));        
%     velocity    = mean(vel);  
%     VELOC       = vel.';
%     vel_tot     = v_total(1:end-1);
% 
% % CALCOLO LO SPOSTAMENTO (SECONDA INTEGRAZIONE)    
%     T_st = T_start_d - T_start_d(1)+1;
%     T_HH = T_HH_d - T_start_d(1)+1;
%     T_en = T_end_d - T_start_d(1);
% %     figure;
%         for sa=1:tap
%             if ((T_st(sa)>=(T_st(1)+1000)) && (T_st(sa)<(T_st(1)+4000)))
%         vel_i         = vel_tot(T_st(sa):(T_HH(sa)));
%         t_i           = ts_d2(T_st(sa):(T_HH(sa)));
%         y_i           = cumtrapz(t_i,vel_i);    
% %          hold on; plot(t_i, y_i, 'r');
%              if sa<tap
%                 vel_i2      = -vel_tot(T_HH(sa):(T_st(sa+1)));
%                 t_i2        = ts_d2(T_HH(sa):(T_st(sa+1)));
%                 y_i2        = cumtrapz(t_i2, vel_i2);
%                 y_i_r       = y_i2+y_i(end);
% %                  hold on; plot(t_i2, y_i_r, 'k');
%                 my = (y_i_r(end)-y_i(1))/(tapp_i2(end)-t_i(1)); qy = y_i(1)-my*t_i(1);
%                 y_e = my*ts_d2(T_st(sa):T_st(sa+1))+qy;
% %                  hold on; plot(ts_d2(T_st(sa):T_st(sa+1)),y_e,'g'); 
%                 y_tot = [y_i,(y_i_r(2:end))];
%                 y_m = y_tot-y_e;
% %                 hold on; plot(ts_d2(T_st(sa):T_st(sa+1)),y_m,'k');
%              else
%                 vel_i3     = vel_tot(T_HH(sa):(T_en(sa)));       %per l'ultimo step
%                 t_i3       = ts_d2(T_HH(sa):(T_en(sa)));
%                 y_i3       = cumtrapz(t_i3, vel_i3);
%                 y_i_r      = y_i3+y_i(end);
% %                  hold on; plot(t_i3, y_i_r, 'k'); 
%                 my = (y_i_r(end)-y_i(1))/(t_i3(end)-t_i(1)); qy = y_i(1)-my*t_i(1);
%                 y_e = my*ts_d2(T_st(sa):T_en(sa))+qy;
% %                  hold on; plot(ts_d2(T_st(sa):T_en(sa)),y_e,'g'); 
%                 y_tot = [y_i,(y_i_r(2:end))];
%                 y_m = y_tot-y_e;
% %                 hold on; plot(ts_d2(T_st(sa):T_en(sa)),y_m,'k');
%              end
%         vel_open(ss)      = mean(vel_i);
%         vel_close(ss)     = mean(vel_i2);    
%         h_daphne21(ss)    = max(abs(y_m));
%         ss = ss + 1;
%             end
%         end
%     amp_init = mean(h_daphne21); %AMPIEZZA MEDIA REPLICHE nei SECONDI 1-4 
%         
%          pp = 1;  
%     for p=1:tap
%         if ((T_start_d(p)>=(T_start_d(1)+1000)) && (T_start_d(p)<(T_start_d(1)+4000)))
%         acc_i         = acc1(T_start_d(p):(T_HH_d(p)));
%         tapp_i        = ts_d2(T_start_d(p):(T_HH_d(p)));
%         v_i           = cumtrapz(tapp_i,acc_i);    
% %          hold on; plot(tapp_i, v_i, 'k');
%          if p<tap
%             acc_i2         = acc1(T_HH_d(p):(T_start_d(p+1)));
%             tapp_i2        = ts_d2(T_HH_d(p):(T_start_d(p+1)));
%             v_i2           = cumtrapz(tapp_i2, acc_i2);
%             v_i_r          = v_i2+v_i(end);
%  %             hold on; plot(tapp_i2, v_i_r, 'k');
%             mv = (v_i_r(end)-v_i(1))/(tapp_i2(end)-tapp_i(1)); qv = v_i(1)-mv*tapp_i(1);
%             v_e = mv*ts_d2(T_start_d(p):T_start_d(p+1))+qv;
%  %             hold on; plot(ts_d2(T_start_d(p):T_start_d(p+1)),v_e,'g'); 
%             v_tot = [v_i',(v_i_r(2:end))'];
%             v_m = v_tot-v_e;
% %             hold on; plot(ts_d2(T_start_d(p):T_start_d(p+1)),v_m,'k');
%          else
%             acc_i3        = acc1(T_HH_d(p):(T_end_d(p)));       %per l'ultimo step
%             tapp_i3       = ts_d2(T_HH_d(p):(T_end_d(p)));
%             v_i3          = cumtrapz(tapp_i3, acc_i3);
%             v_i_r      = v_i3+v_i(end);
%  %             hold on; plot(tapp3, xang_r, 'k'); 
%             mv = (v_i_r(end)-v_i(1))/(tapp_i3(end)-tapp_i(1)); qv = v_i(1)-mv*tapp_i(1);
%             v_e = mv*ts_d2(T_start_d(p):T_end_d(p))+qv;
%  %             hold on; plot(ts_d2(T_start_d(p):T_end_d(p)),v_e,'g'); 
%             v_tot = [v_i',(v_i_r(2:end))'];
%             v_m = v_tot-v_e;
% %             hold on; plot(ts_d2(T_start_d(p):T_end_d(p)),v_m,'k');
%         end
%         acc_open(p)      = mean(acc_i);
%         acc_close(p)     = mean(acc_i2);    
%         vel(p)           = max(abs(v_m));
%         if i == 1
%            l = length(v_m);
%            v_total(1:l)  = v_m;
%         else
%            l = length(v_m);
%            v_total = [v_total,v_m(2:end)];
%         end
%         end
%     end
%     acc_op      = abs(mean(acc_open));
%     acc_cl      = abs(mean(acc_close));        
%     velocity    = mean(vel);  
%     VELOC       = vel.';
%     vel_tot     = v_total(1:end-1);
% 
% % CALCOLO LO SPOSTAMENTO (SECONDA INTEGRAZIONE)    
%     T_st = T_start_d - T_start_d(1)+1;
%     T_HH = T_HH_d - T_start_d(1)+1;
%     T_en = T_end_d - T_start_d(1);
% %     figure;
%         for pa=1:tap
%             if ((T_st(pa)>=(T_st(1)+4000)) && (T_st(pa)<(T_st(1)+7000)))
%         vel_i         = vel_tot(T_st(pa):(T_HH(pa)));
%         t_i           = ts_d2(T_st(pa):(T_HH(pa)));
%         y_i           = cumtrapz(t_i,vel_i);    
% %          hold on; plot(t_i, y_i, 'r');
%              if pa<tap
%                 vel_i2      = -vel_tot(T_HH(pa):(T_st(pa+1)));
%                 t_i2        = ts_d2(T_HH(pa):(T_st(pa+1)));
%                 y_i2        = cumtrapz(t_i2, vel_i2);
%                 y_i_r       = y_i2+y_i(end);
% %                  hold on; plot(t_i2, y_i_r, 'k');
%                 my = (y_i_r(end)-y_i(1))/(tapp_i2(end)-t_i(1)); qy = y_i(1)-my*t_i(1);
%                 y_e = my*ts_d2(T_st(pa):T_st(pa+1))+qy;
% %                  hold on; plot(ts_d2(T_st(pa):T_st(pa+1)),y_e,'g'); 
%                 y_tot = [y_i,(y_i_r(2:end))];
%                 y_m = y_tot-y_e;
% %                 hold on; plot(ts_d2(T_st(pa):T_st(pa+1)),y_m,'k');
%              else
%                 vel_i3     = vel_tot(T_HH(pa):(T_en(pa)));       %per l'ultimo step
%                 t_i3       = ts_d2(T_HH(pa):(T_en(pa)));
%                 y_i3       = cumtrapz(t_i3, vel_i3);
%                 y_i_r      = y_i3+y_i(end);
% %                  hold on; plot(t_i3, y_i_r, 'k'); 
%                 my = (y_i_r(end)-y_i(1))/(t_i3(end)-t_i(1)); qy = y_i(1)-my*t_i(1);
%                 y_e = my*ts_d2(T_st(pa):T_en(pa))+qy;
% %                  hold on; plot(ts_d2(T_st(pa):T_en(pa)),y_e,'g'); 
%                 y_tot = [y_i,(y_i_r(2:end))];
%                 y_m = y_tot-y_e;
% %                 hold on; plot(ts_d2(T_st(pa):T_en(pa)),y_m,'k');
%              end
%         vel_open(pp)      = mean(vel_i);
%         vel_close(pp)     = mean(vel_i2);    
%         h_daphne22(pp)    = max(abs(y_m));
%         pp = pp + 1;
%             end
%         end
%     amp_mid = mean(h_daphne22); %AMPIEZZA MEDIA REPLICHE nei SECONDI 4-7 
%  
%     uu = 1;  
%     for u=1:tap
%         if ((T_start_d(u)>=(T_start_d(1)+7000)) && (T_start_d(u)<(T_start_d(1)+10000)))
%         acc_i         = acc1(T_start_d(u):(T_HH_d(u)));
%         tapp_i        = ts_d2(T_start_d(u):(T_HH_d(u)));
%         v_i           = cumtrapz(tapp_i,acc_i);    
% %          hold on; plot(tapp_i, v_i, 'k');
%          if u<tap
%             acc_i2         = acc1(T_HH_d(u):(T_start_d(u+1)));
%             tapp_i2        = ts_d2(T_HH_d(u):(T_start_d(u+1)));
%             v_i2           = cumtrapz(tapp_i2, acc_i2);
%             v_i_r          = v_i2+v_i(end);
%  %             hold on; plot(tapp_i2, v_i_r, 'k');
%             mv = (v_i_r(end)-v_i(1))/(tapp_i2(end)-tapp_i(1)); qv = v_i(1)-mv*tapp_i(1);
%             v_e = mv*ts_d2(T_start_d(u):T_start_d(u+1))+qv;
%  %             hold on; plot(ts_d2(T_start_d(p):T_start_d(p+1)),v_e,'g'); 
%             v_tot = [v_i',(v_i_r(2:end))'];
%             v_m = v_tot-v_e;
% %             hold on; plot(ts_d2(T_start_d(u):T_start_d(u+1)),v_m,'k');
%          else
%             acc_i3        = acc1(T_HH_d(u):(T_end_d(u)));       %per l'ultimo step
%             tapp_i3       = ts_d2(T_HH_d(u):(T_end_d(u)));
%             v_i3          = cumtrapz(tapp_i3, acc_i3);
%             v_i_r      = v_i3+v_i(end);
%  %             hold on; plot(tapp3, xang_r, 'k'); 
%             mv = (v_i_r(end)-v_i(1))/(tapp_i3(end)-tapp_i(1)); qv = v_i(1)-mv*tapp_i(1);
%             v_e = mv*ts_d2(T_start_d(u):T_end_d(u))+qv;
%  %             hold on; plot(ts_d2(T_start_d(p):T_end_d(p)),v_e,'g'); 
%             v_tot = [v_i',(v_i_r(2:end))'];
%             v_m = v_tot-v_e;
% %             hold on; plot(ts_d2(T_start_d(u):T_end_d(u)),v_m,'k');
%         end
%         acc_open(u)      = mean(acc_i);
%         acc_close(u)     = mean(acc_i2);    
%         vel(u)           = max(abs(v_m));
%         if i == 1
%            l = length(v_m);
%            v_total(1:l)  = v_m;
%         else
%            l = length(v_m);
%            v_total = [v_total,v_m(2:end)];
%         end
%         end
%     end
%     acc_op      = abs(mean(acc_open));
%     acc_cl      = abs(mean(acc_close));        
%     velocity    = mean(vel);  
%     VELOC       = vel.';
%     vel_tot     = v_total(1:end-1);
% 
% % CALCOLO LO SPOSTAMENTO (SECONDA INTEGRAZIONE)    
%     T_st = T_start_d - T_start_d(1)+1;
%     T_HH = T_HH_d - T_start_d(1)+1;
%     T_en = T_end_d - T_start_d(1);
% %     figure;
%         for ua=1:tap
%             if ((T_st(ua)>=(T_st(1)+7000)) && (T_st(ua)<(T_st(1)+10000)))
%         vel_i         = vel_tot(T_st(ua):(T_HH(ua)));
%         t_i           = ts_d2(T_st(ua):(T_HH(ua)));
%         y_i           = cumtrapz(t_i,vel_i);    
% %          hold on; plot(t_i, y_i, 'r');
%              if ua<tap
%                 vel_i2      = -vel_tot(T_HH(ua):(T_st(ua+1)));
%                 t_i2        = ts_d2(T_HH(ua):(T_st(ua+1)));
%                 y_i2        = cumtrapz(t_i2, vel_i2);
%                 y_i_r       = y_i2+y_i(end);
% %                  hold on; plot(t_i2, y_i_r, 'k');
%                 my = (y_i_r(end)-y_i(1))/(tapp_i2(end)-t_i(1)); qy = y_i(1)-my*t_i(1);
%                 y_e = my*ts_d2(T_st(ua):T_st(ua+1))+qy;
% %                  hold on; plot(ts_d2(T_st(ua):T_st(ua+1)),y_e,'g'); 
%                 y_tot = [y_i,(y_i_r(2:end))];
%                 y_m = y_tot-y_e;
% %                 hold on; plot(ts_d2(T_st(ua):T_st(ua+1)),y_m,'k');
%              else
%                 vel_i3     = vel_tot(T_HH(ua):(T_en(ua)));       %per l'ultimo step
%                 t_i3       = ts_d2(T_HH(ua):(T_en(ua)));
%                 y_i3       = cumtrapz(t_i3, vel_i3);
%                 y_i_r      = y_i3+y_i(end);
% %                  hold on; plot(t_i3, y_i_r, 'k'); 
%                 my = (y_i_r(end)-y_i(1))/(t_i3(end)-t_i(1)); qy = y_i(1)-my*t_i(1);
%                 y_e = my*ts_d2(T_st(ua):T_en(ua))+qy;
% %                  hold on; plot(ts_d2(T_st(ua):T_en(ua)),y_e,'g'); 
%                 y_tot = [y_i,(y_i_r(2:end))];
%                 y_m = y_tot-y_e;
% %                 hold on; plot(ts_d2(T_st(ua):T_en(ua)),y_m,'k');
%              end
%         vel_open(uu)      = mean(vel_i);
%         vel_close(uu)     = mean(vel_i2);    
%         h_daphne23(uu)    = max(abs(y_m));
%         uu = uu + 1;
%             end
%         end
%     amp_fin = mean(h_daphne23(1:end-1)); %AMPIEZZA MEDIA REPLICHE nei SECONDI 4-7 
%     
%     features.decB  = 100*((amp_init/amp_0)-1); %P18:PERCENTAGE DEC-INC WITHIN THE 1-4 sec
%     features.decM  = 100*((amp_mid/amp_0)-1);  %P19:PERCENTAGE DEC-INC WITHIN THE 4-7 sec
%     features.decE  = 100*((amp_fin/amp_0)-1);  %P20:PERCENTAGE DEC-INC WITHIN THE 7-10 sec
%       
%     features.hes = 0;
%     if (features.taps>2 && features.taps<11)
%         features.hes10 = 0;%int10 = 0; frz10 = 0;
%     else   
% %         int10 = 0;
% %         frz10 = 0; 
%         rhytm = sort(T_rhytm);
%         L = length(rhytm);
%         if mod(L,2) == 0
%             m1 = median(rhytm);
%             m2 = rhytm(L/2-2);
%             m3 = rhytm(L/2+2);
%             m = [m1,m2,m3];
%             median_values = mean(m);
%         else
%             median_values = mean([median(rhytm),rhytm(L/2-0.5),rhytm(L/2-1.5),rhytm(L/2+1.5),rhytm(L/2+2.5)]);
%         end
%         
%         SDrhytm = std(rhytm);
%         thrs_rh1    = median_values + 2*SDrhytm;
%         thrs_rh2    = median_values - 2*SDrhytm;
%          
%         yy = 1;
%         yyy = 1;
%         indx_rh1 = [];
%         indx_rh2 = [];
%         for y = 1:length(rhytm)
%             if (rhytm(y) > thrs_rh1)
%                 indx_rh1(yy) = y;
%                 yy = yy+1;
%             elseif (rhytm(y) < thrs_rh2)
%                 indx_rh2(yyy) = y;
%                 yyy = yyy+1;
%             end
%         end
%         features.hes = length(indx_rh1)+length(indx_rh2);
%         
%         ww = 1;
%         www = 1;
%         indx10_rh1 = [];
%         indx10_rh2 = [];
%         for w = 1:10
%             if (rhytm(w) > thrs_rh1)
%                 indx10_rh1(ww) = w;
%                 ww = ww+1;
%             elseif (rhytm(w) < thrs_rh2)
%                 indx10_rh2(www) = w;
%                 www = www+1;
%             end
%         end
%         features.hes10 = length(indx10_rh1)+length(indx10_rh2);       
%     end  
% end

%  features.vel10   = round(features.vel10*100)/100;
%  features.vel10SD = round(features.vel10SD*100)/100;
%  features.exc10   = round(features.exc10*1000)/1000;
%  features.exc10SD = round(features.exc10SD*1000)/1000;
%  features.dec10B  = round(features.dec10B*100)/100;
%  features.dec10M  = round(features.dec10M*100)/100;
%  features.dec10E  = round(features.dec10E*100)/100;
%  features.exc     = round(features.exc*1000)/1000;
%  features.excSD   = round(features.excSD*1000)/1000;
%  features.vo = round(features.vo*1000)/1000;
%  features.voSD = round(features.voSD*1000)/1000;
%  features.vc = round(features.vc*1000)/1000;   
%  features.vcSD = round(features.vcSD*1000)/1000;
%  features.IAV = round(features.IAV*100)/100;
%  features.decB = round(features.decB*100)/100;
%  features.decM = round(features.decM*100)/100;
%  features.decE = round(features.decE*100)/100;    

%%


 features.fundfreq = round(features.fundfreq*100)/100;
 features.power = round(features.power*100)/100;
 features.fundpeak = round(features.fundpeak*100)/100;

end  
