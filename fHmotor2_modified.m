%% exercise identifica il tipo di esercizio 

function [features] = fHmotor2_modified(directory,filename,hand_N,trial,data2_ax,data2_ay,data2_az,...
             data2_wx,data2_wy,data2_wz,ts,fs_daphne,exercise)

%% [MODIFICA] Organizzo le features in una structure, per semplificare la visualizzazione e il confronto con il C#
features.vel10 = 0; 
features.vel10SD = 0; 
features.exc10 = 0; 
features.exc10SD = 0; 
features.dec10B = 0;
features.dec10M = 0; 
features.dec10E = 0; 
features.hes10 = 0; 
features.int10 = 0; 
features.frz10 = 0;
features.taps = 0; 
features.exc = 0; 
features.excSD = 0; 
features.wo = 0; 
features.woSD = 0;
features.wc = 0; 
features.wcSD = 0; 
features.IAV = 0; 
features.hes = 0; 
features.int = 0;
features.frz = 0; 
features.decB = 0; 
features.decM = 0; 
features.decE = 0;

%% Rimozione offset dal segnale giroscopio [MODIFICA]

% Tolgo una media fatta nell'intervallo tra 1 e 2 secondi
[~,index1sec] = min(abs(ts-1));
[~,index2sec] = min(abs(ts-2));

% [MODIFICA] - Anziché calcolare direttamente la media calcolata tra 1 e 2 
% secondi di acquisizione, cerco di filtrare eventuali false partenze o 
% spike che potrebbero modificare la media calcolata aggiungendo un errore
data2_wx_1to2sec = data2_wx(index1sec:index2sec);
data2_wy_1to2sec = data2_wy(index1sec:index2sec);
data2_wz_1to2sec = data2_wz(index1sec:index2sec);

[histCountWx,histValWx] = hist(data2_wx_1to2sec,1000);
[histCountWy,histValWy] = hist(data2_wy_1to2sec,1000);
[histCountWz,histValWz] = hist(data2_wz_1to2sec,1000);

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

offsetWx = mean(data2_wx_1to2sec(data2_wx_1to2sec > peakHistWx - 4 & data2_wx_1to2sec < peakHistWx + 4));
offsetWy = mean(data2_wy_1to2sec(data2_wy_1to2sec > peakHistWy - 4 & data2_wy_1to2sec < peakHistWy + 4));
offsetWz = mean(data2_wz_1to2sec(data2_wz_1to2sec > peakHistWz - 4 & data2_wz_1to2sec < peakHistWz + 4));

data2_wx = data2_wx - offsetWx;
data2_wy = data2_wy - offsetWy;
data2_wz = data2_wz - offsetWz;

% data2_wx = data2_wx - mean(data2_wx(index1sec:index2sec));
% data2_wy = data2_wy - mean(data2_wy(index1sec:index2sec));
% data2_wz = data2_wz - mean(data2_wz(index1sec:index2sec));



% INCLINAZIONE INIZIALE RISPETTO ALLA VERTICALE ASSOLUTA (NON SERVE PER IL
% TAPPING)
% tetaFF_i_rad  = atan(ax2_i/az2_i);
% tetaFF_i_deg  = tetaFF_i_rad*180/pi; %angolo di inclinazione iniziale

%% Calcolo frequenza fondamentale del segnale per decidere a quanto filtrare 

% Il filtraggio in frequenza viene fatto in modo adattivo
L = length(ts);
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
psd_wy = fft(data2_wy,NFFT);
f = fs_daphne/2*linspace(0,1,NFFT/2+1);
% Plot one-sided amplitude spectrum.
Pwy = psd_wy.*conj(psd_wy)/(L*fs_daphne); % calcolo densità spettrale di potenza
% figure; plot(f,(Pwy(1:NFFT/2+1)),'r.-');
[~, locs] = findpeaks(Pwy(1:NFFT/2+1)); % cerca i massimi locali dello spettro
F  = (f(locs));
Pw = (Pwy(locs));
[~,  freq] = sort(Pw,'descend');
inda = F(freq);
fundfreq = inda(1); %frequenza fondamentale del tapping

%% Filtraggio dati per la segmentazione del segnale

% Eseguo un filtraggio sulla frequenza adattiva (f fondamentale tapping + 1
% Hz) con un Butterworth di ordine 4
n         =   4;                            %ordine del filtro di Butterworth
ft_daphne =   fundfreq+1;                            %freq di taglio del filtro (freq fondamentale + 1 Hz)
wn_daphne =   2*ft_daphne/fs_daphne;        %freq normalizzata di taglio del filtro
[b,a]     =   butter(n,wn_daphne);          %calcolo i coeff del filtro passa basso di butterworth
fdata2_ax     =   filtfilt(b,a,data2_ax);  %index finger
fdata2_ay     =   filtfilt(b,a,data2_ay);
fdata2_az     =   filtfilt(b,a,data2_az);
fdata2_wx     =   filtfilt(b,a,data2_wx);
fdata2_wy     =   filtfilt(b,a,data2_wy);
fdata2_wz     =   filtfilt(b,a,data2_wz);

%% SIGNAL SEGMENTATION

% Inizializzazione parametri
k = 300;
p   =   length(ts);
st  =   1;
step    = 0;
if (exercise==char('FTAP'))
    THRE=20; TH_t=3;
elseif (exercise==char('THFF'))
    THRE=20; TH_t=3;
elseif (exercise==char('OPCL'))
    THRE=50; TH_t=3; 
end

plot_title = strcat(directory,'-',filename);
figure;plot(ts,fdata2_wy,'b.-');title(plot_title);

while(k<=p)
    switch(st)
        case 1
            if (step==0)
                if (fdata2_wy(k)>THRE)
                    app = k;
                    %    hold on; plot(ts(k),fdata2_wy(k), 'ko');
                    flag = 1;
                    while(flag)
                        app = app - 1;
                        if (fdata2_wy(app)<TH_t)
                            step = step + 1;
                            T_start(step) = app;
                            hold on; plot(ts(T_start),fdata2_wy(T_start), 'go');
                            flag = 0;
                            st = 2;
                        end
                    end
                end
            else if (fdata2_wy(k)>THRE && (ts(k)<(ts(T_start(1))+10))) %10 s after T_start(1)
                    app = k;
                    flag = 1;
                    while(flag)
                        app = app - 1;
                        if (fdata2_wy(app)<TH_t)
                            step = step + 1;
                            T_start(step) = app;
                            if T_start(step)<T_end(step-1)
                                T_start(step) = T_end(step-1);
                            end
                            hold on; plot(ts(T_start),fdata2_wy(T_start), 'go');
                            flag = 0;
                            st = 2;
                        end
                    end
                end
            end
        case 2
            if (fdata2_wy(k)<TH_t) 
                T_max(step) = k;   %Max amplitude
                hold on; plot(ts(T_max),fdata2_wy(T_max), 'co');
                st = 3;
            end
        case 3
            if (fdata2_wy(k)>-TH_t && fdata2_wy(k)>fdata2_wy(k-1))
                T_end(step) = k;
                hold on; plot(ts(T_end),fdata2_wy(T_end), 'ro');
                st = 1;
            end
    end
    k   =   k+1;
end


if (step == 0 || step == 1 || step == 2) % se faccio 0-1-2 repliche, tutti i parametri vengono quantificati nulli
    % Non faccio niente, tutte le features sono già inizializzate a 0
%     vel10 = 0; vel10SD = 0; exc10 = 0; exc10SD = 0; dec10B = 0; dec10M = 0;
%     dec10E = 0; hes10 = 0; int10 = 0; frz10 = 0; taps = 0; exc = 0; 
%     excSD = 0; wo = 0; woSD = 0; wc = 0; wcSD = 0; IAV = 0; hes = 0; 
%     int = 0; frz = 0; decB = 0; decM = 0; decE = 0;
else
    %% Filtro di nuovo il segnale per il calcolo dei parametri. Tengo in considerazione la freq fondamentale e metto +1.5. Se è sotto 5 Hz, metto cmq 5 Hz.
    ft       =   fundfreq+1.5;                  %Filter cut-off frequency
    if ft < 5
        ft = 5;
    end
    wn       =   2*ft/fs_daphne;                %normalized cut-off frequency of the filter
    [d,c]    =   butter(n,wn);                  %calculation of the coefficients of the Butterworth LP filter
    fdata2_ax     =   filtfilt(d,c,data2_ax);   %wrist
    fdata2_ay     =   filtfilt(d,c,data2_ay);
    fdata2_az     =   filtfilt(d,c,data2_az);
    fdata2_wx     =   filtfilt(d,c,data2_wx);
    fdata2_wy     =   filtfilt(d,c,data2_wy);
    fdata2_wz     =   filtfilt(d,c,data2_wz);
    
    % [MODIFICATA] La seguente parte funziona così:
    % Se T_start è più lunga di entrambi, la adatto riducendone la
    % dimensione (tolgo l'ultimo inizio tap e riduco di uno il valore di
    % taps). Viceversa se è T_end ad essere minore, vuol dire che l'ultimo
    % tap ha raggiunto il punto di massima estensione ma per qualche motivo
    % non è stata registrata la fine, per cui allungo T_end.
    % Inoltre ho cambiato il nome di int in durLastRep e tolto la dicitura
    % int(end) che non ha senso in quanto non è un vettore
    if length(T_end) < length(T_start) && length(T_start) == length(T_max)
        durLastRep = T_end(step-1)-T_start(step-1);
        T_last      = T_start(step) + durLastRep;
        T_end(step) = T_last;
    elseif length(T_start)> length(T_max)
            step = step -1;
            T_start = T_start(1:length(T_max));
    end
    features.taps   = step;

%     if length(T_end) < length(T_start)
% %         int = T_end(step-1)-T_start(step-1);
% %         T_last      = T_start(step) + int(end);
%         durLastRep = T_end(step-1)-T_start(step-1);
%         T_last      = T_start(step) + durLastRep;
%         % Fine modifica
%         T_end(step) = T_last;
% %         hold on; plot(ts(T_end),fdata2_wy(T_end), 'ro');
%     end
%     features.taps   = step;                         % P09: NUMBER OF TAPPING IN 10 s
%     if length(T_start)> length(T_max)
%         T_start =T_start(1:length(T_max));
%         features.taps = length(T_start);
%     end


    %% --- Sezione non portata in C# (sembra essere usata solo per debug)
    if features.taps == 11
        repsPeriod     = diff(ts(T_end(1:end)));
    else
        repsPeriod     = diff(ts(T_end(1:end-1)));
    end
    media_FTAP2   = mean(repsPeriod);
    freq          = 1/media_FTAP2;
    
    %% ---
    
    if (step>2 && step<11) % se esegue meno di 11 repliche, metto i valori calcolati sulle prime 10 repliche a 0
        features.vel10 = 0; features.vel10SD = 0;
    else
        for rr=1:10
            T_tap(rr) = ts(T_end(rr+1))-ts(T_start(rr+1));
            vel(rr) = 1/T_tap(rr);
        end
        features.vel10   = mean(vel);  %P01: VELOCITY WITHIN THE FIRST 10 MOVMENTS
        features.vel10SD = std(vel);   %P02: SD OF VELOCITY WITHIN THE FIRST 10 MOVMENTS
    end
    
    %DA QUI PROSEGUO UGUALE
    acc_x          = fdata2_ax(T_start(1):T_end(end));
    acc_y          = fdata2_ay(T_start(1):T_end(end));
    acc_z          = fdata2_az(T_start(1):T_end(end));
    acc            = sqrt(acc_x.^2+acc_y.^2+acc_z.^2);
    features.IAV            = trapz(ts(T_start(1):T_end(end)),acc); %P16: ESTIMATED ENERGY EXPENDITURE
    
    % Ampiezza angolare del movimento
     for i=1:features.taps
        wyang         = fdata2_wy(T_start(i):(T_max(i)));
        tapp          = ts(T_start(i):(T_max(i)));
        yang           = cumtrapz(tapp, wyang);     %la rotazione la vedo nel piano parallelo al tavolo
 %         hold on; plot(tapp, yang, 'k');
        yang_rad      = yang*pi/180;        % No porting in C#
        if i<features.taps
            wyang2         = fdata2_wy(T_max(i):(T_start(i+1)));
            tapp2          = ts(T_max(i):(T_start(i+1)));
            yang2          = cumtrapz(tapp2, wyang2);
            yang_r         = yang2+yang(end);
 %             hold on; plot(tapp2, yang_r, 'k');
            % Correzione lineare del drift
            myang = (yang_r(end)-yang(1))/(tapp2(end)-tapp(1)); 
            qyang = yang(1)-myang*tapp(1);
            yang_e = myang*ts(T_start(i):T_start(i+1))+qyang;
 %             hold on; plot(ts(T_start(i):T_start(i+1)),yang_e,'g'); 
            yang_tot = [yang',(yang_r(2:end))'];
            yang_m = yang_tot-yang_e;
            hold on; plot(ts(T_start(i):T_start(i+1)),yang_m,'k');
         else
            wyang3         = fdata2_wy(T_max(i):(T_end(i)));       %per l'ultimo step
            tapp3          = ts(T_max(i):(T_end(i)));
            yang3          = cumtrapz(tapp3, wyang3);
            yang_r         = yang3+yang(end);
 %             hold on; plot(tapp3, xang_r, 'k'); 
            myang = (yang_r(end)-yang(1))/(tapp3(end)-tapp(1)); 
            qyang = yang(1)-myang*tapp(1);
            yang_e = myang*ts(T_start(i):T_end(i))+qyang;
 %             hold on; plot(ts(T_start(i):T_end(i)),yang_e,'g'); 
            yang_tot = [yang',(yang_r(2:end))'];
            yang_m = yang_tot-yang_e;
            hold on; plot(ts(T_start(i):T_end(i)),yang_m,'k');
        end
        wopen_2(i)      = mean(wyang);
        wclose_2(i)     = mean(wyang2);    
        yang_tap2(i)    = max(abs(yang_m));
     end
     
     if step == 3
         % Pochi step disponibili, non scarto il primo
        features.wo    = abs(mean(wopen_2(1:end-1)));  %P12:MEAN ANGULAR OPENING VELOCITY IN 10s
        features.woSD  = std(abs(wopen_2(1:end-1)));   %P13:SD OF MEAN ANGULAR OPENING VELOCITY IN 10s
        features.wc    = abs(mean(wclose_2(1:end-1))); %P14:MEAN ANGULAR CLOSING VELOCITY IN 10s  
        features.wcSD  = std(abs(wclose_2(1:end-1)));  %P15:SD OF MEAN ANGULAR CLOSING VELOCITY IN 10s  
        features.exc   = mean(yang_tap2(1:end-1));     %P16:MEAN ANGULAR AMPLITUDE OF MOVEMENT IN 10s
        features.excSD = std(yang_tap2(1:end-1));      %P17:SD OF MEAN ANGULAR AMPLITUDE OF MOVEMENT IN 10s
     else
        features.wo    = abs(mean(wopen_2(2:end-1)));  %P12:MEAN ANGULAR OPENING VELOCITY IN 10s
        features.woSD  = std(abs(wopen_2(2:end-1)));   %P13:SD OF MEAN ANGULAR OPENING VELOCITY IN 10s
        features.wc    = abs(mean(wclose_2(2:end-1))); %P14:MEAN ANGULAR CLOSING VELOCITY IN 10s  
        features.wcSD  = std(abs(wclose_2(2:end-1)));  %P15:SD OF MEAN ANGULAR CLOSING VELOCITY IN 10s  
        features.exc   = mean(yang_tap2(2:end-1));     %P16:MEAN ANGULAR AMPLITUDE OF MOVEMENT IN 10s
        features.excSD = std(yang_tap2(2:end-1));      %P17:SD OF MEAN ANGULAR AMPLITUDE OF MOVEMENT IN 10s
     end
    
    
     
    if (step>2 && step<11)
        %exc10 = 0; exc10SD = 0; dec10B = 0; dec10M = 0; dec10E = 0;
        % Non faccio niente, sono già inizializzate a 0
    else
        features.exc10   = (sum(yang_tap2(2:11)))/10;  %P03:MEAN ANGULAR AMPLITUDE OF MOVEMENT WITHIN THE FIRST 10 MOVMENTS
        features.exc10SD = std(yang_tap2(2:11));       %P04:SD OF MEAN ANGULAR AMPLITUDE OF MOVEMENT WITHIN THE FIRST 10 MOVMENTS
         
        % ------------------------ ARRIVARE FINO QUI -----------------

        %CALCOLO RIDUZIONI/INCREMENTI DI AMPIEZZA:
        features.dec10B = 100*((sum(yang_tap2(3:5))/3)/(yang_tap2(2))-1); %P05:PERCENTAGE DEC-INC WITHIN THE 2-4 MOVEMENTS
        features.dec10M = 100*((sum(yang_tap2(6:8))/3)/(yang_tap2(2))-1); %P06:PERCENTAGE DEC-INC WITHIN THE 5-7 MOVEMENTS
        features.dec10E = 100*((sum(yang_tap2(9:11))/3)/(yang_tap2(2))-1);%P07:PERCENTAGE DEC-INC WITHIN THE 8-10 MOVEMENTS
    end


    %% OGNUNA DELLE TRE PARTI SUCCESSIVE E' UGUALE ALLA PRECEDENTE, L'UNICA DIFFERENZA E' CHE SI CICLA OGNI VOLTA SOLO PER UN CERTO NUMERO DI SECONDI
    %% In realtà è sufficiente utilizzare lo stesso vettore yang_tap2, e calcolare le successive feature facendo la media nell'intervallo temporale utile (modificata la parte, la vecchia soluzione è commentata)
    
    amp_0 = yang_tap2(2);       %AMPIEZZA DI RIFERIMENTO SOLO LA PRIMA REPLICA
    
    if features.taps > 5
        T_startFromFirstTap = ts(T_start)-ts(T_start(1));

        temp = find((T_startFromFirstTap - 1) > 0);
        startBegInterval = temp(1);

        temp = find((T_startFromFirstTap - 4) > 0);
        endBegInterval = temp(1);
        startMedInterval = temp(1) + 1;

        temp = find((T_startFromFirstTap - 7) > 0);
        endMedInterval = temp(1);
        startFinInterval = temp(1) + 1;

        temp = find((T_startFromFirstTap - 10) > 0);
        if ~isempty(temp)
            endFinInterval = temp(1);
        else
            endFinInterval = length(T_start);
        end

        amp_init = mean(yang_tap2(startBegInterval : endBegInterval));
        amp_mid = mean(yang_tap2(startMedInterval : endMedInterval));
        amp_fin = mean(yang_tap2(startFinInterval : endFinInterval));

        features.decB = 100*((amp_init/amp_0)-1);  %P18:PERCENTAGE DEC-INC WITHIN THE 1-4 sec
        features.decM  = 100*((amp_mid/amp_0)-1);  %P19:PERCENTAGE DEC-INC WITHIN THE 4-7 sec
        features.decE  = 100*((amp_fin/amp_0)-1);  %P20:PERCENTAGE DEC-INC WITHIN THE 7-10 sec
    else
        features.decB = 0;
        features.decM = 0;
        features.decE = 0;

    end
    
%     amp_0 = yang_tap2(2);       %AMPIEZZA DI RIFERIMENTO SOLO LA PRIMA REPLICA
% if features.taps > 5
%     ss = 1;
%     for s = 1:features.taps
%         if ((T_start(s)>=(T_start(1)+100)) && (T_start(s)<(T_start(1)+400)))
%             w2     = fdata2_wy(T_start(s):(T_max(s)));
%             t2     = ts(T_start(s):(T_max(s)));
%             y2     = cumtrapz(t2, w2);     %la rotazione la vedo nel piano parallelo al tavolo
%             %         hold on; plot(tapp, yang, 'k');
%             y2_rad      = y2*pi/180;
%             if s<features.taps
%                 w22   = fdata2_wy(T_max(s):(T_start(s+1)));
%                 t22   = ts(T_max(s):(T_start(s+1)));
%                 y22   = cumtrapz(t22, w22);
%                 y2_r  = y22+y2(end);
%                 %             hold on; plot(t22, y2_r, 'k');
%                 my2 = (y2_r(end)-y2(1))/(t22(end)-t2(1)); qy2 = y2(1)-my2*t2(1);
%                 y2_e = my2*ts(T_start(s):T_start(s+1))+qy2;
%                 %             hold on; plot(ts(T_start(s):T_start(s+1)),y2_e,'g');
%                 y2_tot = [y2',(y2_r(2:end))'];
%                 y2_m = y2_tot-y2_e;
%                 %             hold on; plot(ts(T_start(s):T_start(s+1)),y2_m,'k');
%             else
%                 wy23 = fdata2_wy(T_max(s):(T_end(s)));       %per l'ultimo step
%                 t23          = ts(T_max(s):(T_end(s)));
%                 y23          = cumtrapz(t23, wy23);
%                 y2_r         = y23+y2(end);
%                 %             hold on; plot(t23, y2_r, 'k');
%                 my2 = (y2_r(end)-y2(1))/(t23(end)-t2(1)); qy2 = y2(1)-my2*t2(1);
%                 y2_e = my2*ts(T_start(s):T_end(s))+qy2;
%                 %             hold on; plot(ts(T_start(s):T_end(s)),y2_e,'g');
%                 y2_tot = [y2',(y2_r(2:end))'];
%                 y2_m = y2_tot-y2_e;
%                 %             hold on; plot(ts(T_start(s):T_end(s)),y2_m,'k');
%             end
%             y2_tap21(ss)    = max(abs(y2_m));
%             ss = ss + 1;
%         end
%     end
%     amp_init = mean(y2_tap21); %AMPIEZZA MEDIA REPLICHE nei SECONDI 1-4
% 
%     pp = 1;
%     for p = 1:features.taps
%         if ((T_start(p)>=(T_start(1)+400)) && (T_start(p)<(T_start(1)+700)))
%             w2     = fdata2_wy(T_start(p):(T_max(p)));
%             t2     = ts(T_start(p):(T_max(p)));
%             y2     = cumtrapz(t2, w2);     %la rotazione la vedo nel piano parallelo al tavolo
%             %         hold on; plot(tapp, yang, 'k');
%             y2_rad      = y2*pi/180;
%             if s<features.taps
%                 w22   = fdata2_wy(T_max(p):(T_start(p+1)));
%                 t22   = ts(T_max(p):(T_start(p+1)));
%                 y22   = cumtrapz(t22, w22);
%                 y2_r  = y22+y2(end);
%                 %             hold on; plot(t22, y2_r, 'k');
%                 my2 = (y2_r(end)-y2(1))/(t22(end)-t2(1)); qy2 = y2(1)-my2*t2(1);
%                 y2_e = my2*ts(T_start(p):T_start(p+1))+qy2;
%                 %             hold on; plot(ts(T_start(s):T_start(s+1)),y2_e,'g');
%                 y2_tot = [y2',(y2_r(2:end))'];
%                 y2_m = y2_tot-y2_e;
%                 %             hold on; plot(ts(T_start(p):T_start(p+1)),y2_m,'k');
%             else
%                 wy23 = fdata2_wy(T_max(p):(T_end(p)));       %per l'ultimo step
%                 t23          = ts(T_max(p):(T_end(p)));
%                 y23          = cumtrapz(t23, wy23);
%                 y2_r         = y23+y2(end);
%                 %             hold on; plot(t23, y2_r, 'k');
%                 my2 = (y2_r(end)-y2(1))/(t23(end)-t2(1)); qy2 = y2(1)-my2*t2(1);
%                 y2_e = my2*ts(T_start(p):T_end(p))+qy2;
%                 %             hold on; plot(ts(T_start(s):T_end(s)),y2_e,'g');
%                 y2_tot = [y2',(y2_r(2:end))'];
%                 y2_m = y2_tot-y2_e;
%                 %             hold on; plot(ts(T_start(p):T_end(p)),y2_m,'k');
%             end
%             y2_tap22(pp)    = max(abs(y2_m));
%             pp = pp + 1;
%         end
%     end
%     amp_mid = mean(y2_tap22); %AMPIEZZA MEDIA REPLICHE nei SECONDI 4-7
% 
%     uu = 1;
%     for u = 1:features.taps
%         if ((T_start(u)>=(T_start(1)+700)) && (T_start(u)<(T_start(1)+1000)))
%             w2     = fdata2_wy(T_start(u):(T_max(u)));
%             t2     = ts(T_start(u):(T_max(u)));
%             y2     = cumtrapz(t2, w2);     %la rotazione la vedo nel piano parallelo al tavolo
%             %         hold on; plot(tapp, yang, 'k');
%             y2_rad      = y2*pi/180;
%             if s<features.taps
%                 w22   = fdata2_wy(T_max(u):(T_start(u+1)));
%                 t22   = ts(T_max(u):(T_start(u+1)));
%                 y22   = cumtrapz(t22, w22);
%                 y2_r  = y22+y2(end);
%                 %             hold on; plot(t22, y2_r, 'k');
%                 my2 = (y2_r(end)-y2(1))/(t22(end)-t2(1)); qy2 = y2(1)-my2*t2(1);
%                 y2_e = my2*ts(T_start(u):T_start(u+1))+qy2;
%                 %             hold on; plot(ts(T_start(s):T_start(s+1)),y2_e,'g');
%                 y2_tot = [y2',(y2_r(2:end))'];
%                 y2_m = y2_tot-y2_e;
%                 %             hold on; plot(ts(T_start(u):T_start(u+1)),y2_m,'k');
%             else
%                 wy23 = fdata2_wy(T_max(u):(T_end(u)));       %per l'ultimo step
%                 t23          = ts(T_max(u):(T_end(u)));
%                 y23          = cumtrapz(t23, wy23);
%                 y2_r         = y23+y2(end);
%                 %             hold on; plot(t23, y2_r, 'k');
%                 my2 = (y2_r(end)-y2(1))/(t23(end)-t2(1)); qy2 = y2(1)-my2*t2(1);
%                 y2_e = my2*ts(T_start(u):T_end(u))+qy2;
%                 %             hold on; plot(ts(T_start(s):T_end(s)),y2_e,'g');
%                 y2_tot = [y2',(y2_r(2:end))'];
%                 y2_m = y2_tot-y2_e;
%                 %             hold on; plot(ts(T_start(u):T_end(u)),y2_m,'k');
%             end
%             y2_tap23(uu)    = max(abs(y2_m));
%             uu = uu + 1;
%         end
%     end
%     amp_fin = mean(y2_tap23(1:end-1)); %AMPIEZZA MEDIA REPLICHE nei SECONDI 7-10
% 
% 
%     features.decB = 100*((amp_init/amp_0)-1);  %P18:PERCENTAGE DEC-INC WITHIN THE 1-4 sec
%     features.decM  = 100*((amp_mid/amp_0)-1);  %P19:PERCENTAGE DEC-INC WITHIN THE 4-7 sec
%     features.decE  = 100*((amp_fin/amp_0)-1);  %P20:PERCENTAGE DEC-INC WITHIN THE 7-10 sec
% else
%     features.decB = 0;
%     features.decM = 0;
%     features.decE = 0;
% end
%% Per il progetto OLIMPIA considero solo le interruzioni, e le definisco come il numero di taps che hanno un tempo di esecuzione molto maggiore o minore rispetto ad un certo valore medio rilevato

% Lavoro solo con int e int10
features.int = 0;
features.int10 = 0;

% Se ho meno di 11 taps lascio tutto a 0 
if features.taps >= 11
    rhythm = repsPeriod;
    rhythm10 = repsPeriod(1:10);
    rhythmSorted = sort(rhythm);
    L = length(rhythm);
    
    % Da rivedere questa parte per il porting degli indici in C#
    if mod(L,2) == 0
        averageRhythm = mean([rhythmSorted(L/2 - 1), rhythmSorted(L/2), rhythmSorted(L/2 + 1), rhythmSorted(L/2 + 2)]);
    else
        averageRhythm = mean([rhythmSorted(L/2 - 1.5), rhythmSorted(L/2 - 0.5), rhythmSorted(L/2 + 0.5), rhythmSorted(L/2 + 1.5), rhythmSorted(L/2 + 2.5)]);
    end
    rhyhtmSD = std(rhythmSorted);
    
    features.int = sum(rhythm < averageRhythm - 2 * rhyhtmSD) + sum(rhythm > averageRhythm + 2 * rhyhtmSD);
    features.int10 = sum(rhythm10 < averageRhythm - 2 * rhyhtmSD) + sum(rhythm10 > averageRhythm + 2 * rhyhtmSD);
end












% features.hes = 0;
% features.int = 0;
% features.frz = 0; % ignorare
% %     for k= 2:(length(yang_tap2)-1)
% %         if abs(yang_tap2(k)) < abs((yang_tap2(k-1)+yang_tap2(k+1))/2)/4
% %         hes = hes + 1;                %P17:NUMBER OF HESITATION IN 10s (AMPIEZZA <1/4 AMPIEZZA MEDIA tra picco precedente e successivo)
% %         end
% %     end
% if (step>2 && step<11)
%     features.hes10 = 0; features.int10 = 0; features.frz10 = 0;
% else
%     features.int10 = 0;
%     features.frz10 = 0;
%     ang_tap = yang_tap2(2:end-1);
% 
%     %prova calcolo esitazioni con valore mediano e std su tutto il vettore
% 
%     rhytm = sort(dif_FTAP2);
%     L = length(rhytm);
%     if mod(L,2) == 0
%         m1 = median(rhytm);
%         m2 = rhytm(L/2-2);
%         m3 = rhytm(L/2+2);
%         m = [m1,m2,m3];
%         median_values = mean(m);
%     else
%         median_values = mean([median(rhytm),rhytm(L/2-0.5),rhytm(L/2-1.5),rhytm(L/2+1.5),rhytm(L/2+2.5)]);
%     end
% 
%     SDrhytm = std(rhytm);
%     thrs_rh1    = median_values + 2*SDrhytm;
%     thrs_rh2    = median_values - 2*SDrhytm;
% 
%     yy = 1;
%     yyy = 1;
%     indx_rh1 = [];
%     indx_rh2 = [];
%     for y = 1:length(rhytm)
%         if (rhytm(y) > thrs_rh1)
%             indx_rh1(yy) = y;
%             yy = yy+1;
%         elseif (rhytm(y) < thrs_rh2)
%             indx_rh2(yyy) = y;
%             yyy = yyy+1;
%         end
%     end
%     features.hes = length(indx_rh1)+length(indx_rh2);
% 
%     ww = 1;
%     www = 1;
%     indx10_rh1 = [];
%     indx10_rh2 = [];
%     % !!!ATTENZIONE!!! qui è sbagliato, non sto considerando i primi 10
%     % tapping ma i 10 valori più bassi, in quanto rythm è stato ordinato
%     for w = 1:10
%         if (rhytm(w) > thrs_rh1)
%             indx10_rh1(ww) = w;
%             ww = ww+1;
%         elseif (rhytm(w) < thrs_rh2)
%             indx10_rh2(www) = w;
%             www = www+1;
%         end
%     end
%     features.hes10 = length(indx10_rh1)+length(indx10_rh2);
% end

%% Riepilogo finale dei parametri con 2 cifre dopo la virgola
features.vel10 = round(features.vel10*100)/100;
features.vel10SD = round(features.vel10SD*100)/100;
features.exc10 = round(features.exc10*100)/100;
features.exc10SD = round(features.exc10SD*100)/100;
features.dec10B = round(features.dec10B*100)/100;
features.dec10M = round(features.dec10M*100)/100;
features.dec10E = round(features.dec10E*100)/100;
features.exc = round(features.exc*100)/100;
features.excSD = round(features.excSD*100)/100;
features.wo = round(features.wo*100)/100;
features.woSD = round(features.woSD*100)/100;
features.wc = round(features.wc*100)/100;
features.wcSD = round(features.wcSD*100)/100;
features.IAV = round(features.IAV*100)/100;
features.decB = round(features.decB*100)/100;
features.decM = round(features.decM*100)/100;
features.decE = round(features.decE*100)/100;

end
end


