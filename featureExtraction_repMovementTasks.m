%% Funzione per il calcolo delle feature nei seguenti esercizi:
% THFv, THFa, FTAP, OPCv, OPCa, PSUP, TTHP, HTTP

function features = featureExtraction_repMovementTasks(data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne,exercise,side)

%% Inizializzazione della struct di output, e selezione dell'asse del giroscopio

features.vel10 = 0; 
features.vel10SD = 0; 
features.exc10 = 0; 
features.exc10SD = 0; 
features.dec10B = 0;
features.dec10M = 0; 
features.dec10E = 0; 
% features.hes10 = 0; 
features.int10 = 0; 
% features.frz10 = 0;
features.taps = 0; 
features.exc = 0; 
features.excSD = 0; 
features.wo = 0; 
features.woSD = 0;
features.wc = 0; 
features.wcSD = 0; 
features.IAV = 0; 
% features.hes = 0; 
features.int = 0;
% features.frz = 0; 
features.decB = 0; 
features.decM = 0; 
features.decE = 0;

% Selezione dell'asse del giroscopio considerato, sulla base del task
% motorio
switch exercise
    case {'THFv', 'THFa', 'FTAP', 'OPCv', 'OPCa', 'TTHP', 'HTTP'}
        % Asse y
        gyrDataVector = data_wy;

    case 'PSUP'
        % Asse x
        gyrDataVector = data_wx;
end

%% Rimozione offset dal segnale giroscopio
% Anziché calcolare direttamente la media calcolata tra 1 e 2 
% secondi di acquisizione, cerco di filtrare eventuali false partenze o 
% spike che potrebbero modificare la media calcolata aggiungendo un errore
offset = offsetCalculation(gyrDataVector,ts,1,2);

gyrDataVector = gyrDataVector - offset;

%% Calcolo frequenza fondamentale del segnale per decidere a quanto filtrare 

% Il filtraggio in frequenza viene fatto in modo adattivo
L = length(ts);
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
psd = fft(gyrDataVector,NFFT);
f = fs_daphne/2*linspace(0,1,NFFT/2+1);
% Plot one-sided amplitude spectrum.
spectDensity = psd.*conj(psd)/(L*fs_daphne); % calcolo densità spettrale di potenza
% figure; plot(f,(Pwy(1:NFFT/2+1)),'r.-');
[~, locs] = findpeaks(spectDensity(1:NFFT/2+1)); % cerca i massimi locali dello spettro
F  = (f(locs));
Pw = (spectDensity(locs));
[~,  freq] = sort(Pw,'descend');
inda = F(freq);
fundfreq = inda(1); %frequenza fondamentale del tapping

%% Filtraggio dati per la segmentazione del segnale

% Eseguo un filtraggio sulla frequenza adattiva (f fondamentale tapping + 1
% Hz) con un Butterworth di ordine 4
n = 4;
ft_daphne = fundfreq + 1;
wn_daphne = 2*ft_daphne/fs_daphne;
[b,a] = butter(n,wn_daphne);
gyrDataVectorFiltered1 = filtfilt(b,a,gyrDataVector);

%% SIGNAL SEGMENTATION

% Inizializzazione parametri
% k = 300;
[~,k] = min(abs(ts-3));
p = length(ts);
st = 1;
step = 0;

switch exercise
    case {'THFv', 'THFa', 'FTAP', 'TTHP'}
        THRE=20; TH_t=3;

    case {'OPCv', 'OPCa'}
        THRE=50; TH_t=3; 

    case 'PSUP'
        THRE=50; TH_t=5; 
        if strcmp(side,"SX")
            gyrDataVectorFiltered1 = -gyrDataVectorFiltered1;
        end

    case 'HTTP'
        THRE=15; TH_t=2;
        gyrDataVectorFiltered1 = -gyrDataVectorFiltered1;

end

plot_title = strcat(exercise,'-',side);
figure;plot(ts,gyrDataVectorFiltered1,'b.-');title(plot_title);

while(k<=p)
    switch(st)
        case 1
            if (step==0)
                if (gyrDataVectorFiltered1(k)>THRE)
                    app = k;
                    %    hold on; plot(ts(k),fdata2_wy(k), 'ko');
                    flag = 1;
                    while(flag)
                        app = app - 1;
                        if (gyrDataVectorFiltered1(app)<TH_t)
                            step = step + 1;
                            T_start(step) = app;
                            hold on; plot(ts(T_start),gyrDataVectorFiltered1(T_start), 'go');
                            flag = 0;
                            st = 2;
                        end
                    end
                end
            else if (gyrDataVectorFiltered1(k)>THRE && (ts(k)<(ts(T_start(1))+10))) %10 s after T_start(1)
                    app = k;
                    flag = 1;
                    while(flag)
                        app = app - 1;
                        if (gyrDataVectorFiltered1(app)<TH_t)
                            step = step + 1;
                            T_start(step) = app;
                            if T_start(step)<T_end(step-1)
                                T_start(step) = T_end(step-1);
                            end
                            hold on; plot(ts(T_start),gyrDataVectorFiltered1(T_start), 'go');
                            flag = 0;
                            st = 2;
                        end
                    end
            end
            end
        case 2
            if (gyrDataVectorFiltered1(k)<TH_t)
                T_max(step) = k;   %Max amplitude
                hold on; plot(ts(T_max),gyrDataVectorFiltered1(T_max), 'co');
                st = 3;
            end
        case 3
            if (gyrDataVectorFiltered1(k)>-TH_t && gyrDataVectorFiltered1(k)>gyrDataVectorFiltered1(k-1))
                T_end(step) = k;
                hold on; plot(ts(T_end),gyrDataVectorFiltered1(T_end), 'ro');
                st = 1;
            end
    end
    k   =   k+1;
end


if step > 2
    %% Filtro di nuovo il segnale per il calcolo dei parametri. Tengo in considerazione la freq fondamentale e metto +1.5. Se è sotto 5 Hz, metto cmq 5 Hz.
    ft       =   fundfreq+1.5;                  %Filter cut-off frequency
    if ft < 5
        ft = 5;
    end
    wn       =   2*ft/fs_daphne;                %normalized cut-off frequency of the filter
    [d,c]    =   butter(n,wn);                  %calculation of the coefficients of the Butterworth LP filter
    fdata2_ax     =   filtfilt(d,c,data_ax);   %wrist
    fdata2_ay     =   filtfilt(d,c,data_ay);
    fdata2_az     =   filtfilt(d,c,data_az);
    gyrDataVectorFiltered = filtfilt(d,c,gyrDataVector);


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
    features.taps   = step; %% taps

    
    if features.taps == 11
        repsPeriod     = diff(ts(T_end(1:end)));
    else
        repsPeriod     = diff(ts(T_end(1:end-1)));
    end
    media_FTAP2   = mean(repsPeriod);
    freq          = 1/media_FTAP2;

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

    acc_x          = fdata2_ax(T_start(1):T_end(end));
    acc_y          = fdata2_ay(T_start(1):T_end(end));
    acc_z          = fdata2_az(T_start(1):T_end(end));
    acc            = sqrt(acc_x.^2+acc_y.^2+acc_z.^2);
    features.IAV            = trapz(ts(T_start(1):T_end(end)),acc); %P16: ESTIMATED ENERGY EXPENDITURE

    % Ampiezza angolare del movimento
    for i=1:features.taps
        wyang         = gyrDataVectorFiltered(T_start(i):(T_max(i)));
        tapp          = ts(T_start(i):(T_max(i)));
        yang           = cumtrapz(tapp, wyang);     %la rotazione la vedo nel piano parallelo al tavolo
        if i<features.taps
            wyang2         = gyrDataVectorFiltered(T_max(i):(T_start(i+1)));
            tapp2          = ts(T_max(i):(T_start(i+1)));
            yang2          = cumtrapz(tapp2, wyang2);
            yang_r         = yang2+yang(end);

            % Correzione lineare del drift
            myang = (yang_r(end)-yang(1))/(tapp2(end)-tapp(1));
            qyang = yang(1)-myang*tapp(1);
            yang_e = myang*ts(T_start(i):T_start(i+1))+qyang;

            yang_tot = [yang',(yang_r(2:end))'];
            yang_m = yang_tot-yang_e;
            hold on; plot(ts(T_start(i):T_start(i+1)),yang_m,'k');
        else
            wyang3         = gyrDataVectorFiltered(T_max(i):(T_end(i)));       %per l'ultimo step
            tapp3          = ts(T_max(i):(T_end(i)));
            yang3          = cumtrapz(tapp3, wyang3);
            yang_r         = yang3+yang(end);

            myang = (yang_r(end)-yang(1))/(tapp3(end)-tapp(1));
            qyang = yang(1)-myang*tapp(1);
            yang_e = myang*ts(T_start(i):T_end(i))+qyang;

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

    if step>=11
        features.exc10   = (sum(yang_tap2(2:11)))/10;  %P03:MEAN ANGULAR AMPLITUDE OF MOVEMENT WITHIN THE FIRST 10 MOVMENTS
        features.exc10SD = std(yang_tap2(2:11));       %P04:SD OF MEAN ANGULAR AMPLITUDE OF MOVEMENT WITHIN THE FIRST 10 MOVMENTS

        % Riduzioni/incrementi di ampiezza
        features.dec10B = 100*((sum(yang_tap2(3:5))/3)/(yang_tap2(2))-1); %P05:PERCENTAGE DEC-INC WITHIN THE 2-4 MOVEMENTS
        features.dec10M = 100*((sum(yang_tap2(6:8))/3)/(yang_tap2(2))-1); %P06:PERCENTAGE DEC-INC WITHIN THE 5-7 MOVEMENTS
        features.dec10E = 100*((sum(yang_tap2(9:11))/3)/(yang_tap2(2))-1);%P07:PERCENTAGE DEC-INC WITHIN THE 8-10 MOVEMENTS
    end


    %% Parte modificata, è sufficiente usare sempre il vettore yang_tap2 e calcolare le feature facendo la media su un intervallo temporale diverso per i tre casi 
    
    % Ampiezza prima replica (riferimento)
    amp_0 = yang_tap2(2);

    if features.taps > 5
        T_startFromFirstTap = ts(T_start)-ts(T_start(1));

        % Calcolo gli indici degli estremi dei 3 sotto-intervalli (alcuni 
        % potrebbero non essere presenti, ad esempio se i dati raccolti 
        % hanno problemi e l'esercizio dura meno di 10 secondi)
        indicesBegInterval = find((T_startFromFirstTap - 1) >= 0 & (T_startFromFirstTap - 4) < 0);
        indicesMedInterval = find((T_startFromFirstTap - 4) >= 0 & (T_startFromFirstTap - 7) < 0);
        indicesFinInterval = find((T_startFromFirstTap - 7) >= 0 & (T_startFromFirstTap - 10) < 0);

        if ~isempty(indicesBegInterval)
            amp_init = mean(yang_tap2(indicesBegInterval));
            features.decB = 100*((amp_init/amp_0)-1);  %P18:PERCENTAGE DEC-INC WITHIN THE 1-4 sec
        end
        if ~isempty(indicesMedInterval)
            amp_mid = mean(yang_tap2(indicesMedInterval));
            features.decM = 100*((amp_mid/amp_0)-1);  %P18:PERCENTAGE DEC-INC WITHIN THE 1-4 sec
        end
        if ~isempty(indicesFinInterval)
            amp_fin = mean(yang_tap2(indicesFinInterval));
            features.decE = 100*((amp_fin/amp_0)-1);  %P18:PERCENTAGE DEC-INC WITHIN THE 1-4 sec
        end

%         temp4 = find((T_startFromFirstTap - 4) > 0);
%         endBegInterval = temp4(1);
%         startMedInterval = temp4(1) + 1;
% 
%         temp7 = find((T_startFromFirstTap - 7) > 0);
%         endMedInterval = temp7(1);
%         startFinInterval = temp7(1) + 1;
% 
%         temp10 = find((T_startFromFirstTap - 10) > 0);
%         if ~isempty(temp10)
%             endFinInterval = temp10(1);
%         else
%             endFinInterval = length(T_start);
%         end
% 
%         amp_init = mean(yang_tap2(startBegInterval : endBegInterval));
%         amp_mid = mean(yang_tap2(startMedInterval : endMedInterval));
%         amp_fin = mean(yang_tap2(startFinInterval : endFinInterval));

%         features.decB = 100*((amp_init/amp_0)-1);  %P18:PERCENTAGE DEC-INC WITHIN THE 1-4 sec
%         features.decM = 100*((amp_mid/amp_0)-1);  %P19:PERCENTAGE DEC-INC WITHIN THE 4-7 sec
%         features.decE = 100*((amp_fin/amp_0)-1);  %P20:PERCENTAGE DEC-INC WITHIN THE 7-10 sec

    else
        % Non necessario, essendo inizializzati a 0
%         features.decB = 0;
%         features.decM = 0;
%         features.decE = 0;
    end


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