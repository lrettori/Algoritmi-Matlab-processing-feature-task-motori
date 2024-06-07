function [features] = fFmotorHETO_modified(data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne)



%% [MODIFICA] Organizzo le features in una structure, per semplificare la visualizzazione e il confronto con il C#
features.taps = 0; 
features.exc_t = 0; 
features.exc_tSD = 0; 
features.exc_h = 0; 
features.exc_hSD = 0; 
features.wt = 0; 
features.wtSD = 0;
features.wh = 0; 
features.whSD = 0; 
features.IAV = 0; 
features.fTT = 0; 
features.fHH = 0; 
features.hes = 0;


%% Rimozione offset dal segnale giroscopio

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

%% Calcolo frequenza fondamentale del segnale per decidere a quanto filtrare 

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

%% Filtraggio dati per la segmentazione del segnale

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


plot_title = 'fdata_wy';
figure;plot(ts,fdata_wy,'r.-');title(plot_title);


%% SIGNAL SEGMENTATION

% Inizializzazione parametri
THRE  =  20;      %  °/s, al di sotto di questa velocità angolare il piede si considera totalmente appoggiato a terra
TH_t =  3;
% k   =   200;
[~,k] = min(abs(ts-2));
p   =   length(ts);
st  =   1;
tap    = 0;
tap_h  = 0;
tap_t  = 0;
while(k<=p)
    switch(st)
        case 1
            if (fdata_wy(k)<-THRE && tap==0)    %FIRST TAPPING with TOE
                app = k;
    %              hold on; plot(ts(k),fdata_wy(k), 'ko');
                flag = 1;
                while(flag)
                    app = app - 1;
                    if (fdata_wy(app)>-TH_t)
                        tap   = tap + 1;
                        tap_t = tap_t + 1;
                        T_start = app;    %inizia il movimento con wy negativa
                        hold on; plot(ts(T_start),fdata_wy(T_start), 'k*');
                        flag = 0;
                        st = 2;
                        
                    end
                end
            else if(fdata_wy(k)>THRE && tap==0)     %FIRST TAPPING with HEEL
                    app = k;
                    %                hold on; plot(ts(k),fdata_wy(k), 'bo');
                    flag = 1;
                    while(flag)
                        app = app - 1;
                        if (fdata_wy(app)<TH_t)
                            tap   = tap + 1;
                            tap_h = tap_h + 1;
                            T_start = app;    %inizia il movimento con wy positiva
                            hold on; plot(ts(T_start),fdata_wy(T_start), 'b*');
                            flag = 0;
                            st = 3;
                        end
                    end
            end
            end
        case 2
            if (fdata_wy(k)>TH_t  && (ts(k)<(ts(T_start)+10))) %Considero i 10 sec successivi al primo T_start
                if tap_t == 0
                    tap_t = tap_t+1;
                end
                T_TO(tap_t) = k;       %Istanti in cui ho solo la punta appoggiata a terra
                hold on; plot(ts(T_TO),fdata_wy(T_TO), 'mo');
                st = 3;
                tap_t = tap_t+1;
            end
        case 3
            if (fdata_wy(k)<-TH_t  && (ts(k)<(ts(T_start)+10))) %Considero i 10 sec successivi al primo T_start
                if tap_h == 0
                    tap_h = tap_h+1;
                end
                T_HS(tap_h) = k;       %Istanti in cui ho solo il tallone appoggiato a terra
                hold on; plot(ts(T_HS),fdata_wy(T_HS), 'co'); 
                st = 2;
                tap_h = tap_h+1;
            end
    end
    k   =   k+1;
end




if (tap_h == 0 || tap_h == 1 || tap_t == 0 || tap_t == 1 || tap_t == 2 || tap_h == 2)
    % Non faccio niente, tutte le features sono già inizializzate a 0
%     features.taps = 0; features.exc_t = 0; features.exc_tSD = 0; features.exc_h = 0; features.exc_hSD = 0; features.wt = 0; features.wtSD = 0;
%     features.wh = 0; features.whSD = 0; features.IAV = 0; features.fHH = 0; features.fTT = 0; features.hes = 0; %int = 0; frz = 0;
else
    
    ft       =   fundfreq+1.5;                  %Filter cut-off frequency
    wn       =   2*ft/fs_daphne;                %normalized cut-off frequency of the filter
    [d,c]    =   butter(n,wn);                  %calculation of the coefficients of the Butterworth LP filter
    fdata_ax     =   filtfilt(d,c,data_ax);   %wrist
    fdata_ay     =   filtfilt(d,c,data_ay);
    fdata_az     =   filtfilt(d,c,data_az);
    fdata_wx     =   filtfilt(d,c,data_wx);
    fdata_wy     =   filtfilt(d,c,data_wy);
    fdata_wz     =   filtfilt(d,c,data_wz);
    
    acc_x          = fdata_ax(T_start:T_HS(end));
    acc_y          = fdata_ay(T_start:T_HS(end));
    acc_z          = fdata_az(T_start:T_HS(end));
    acc            = sqrt(acc_x.^2+acc_y.^2+acc_z.^2);
    features.IAV      = trapz(ts(T_start:T_HS(end)),acc); %P10:ESTIMATED ENERGY EXPENDITURE
    features.taps     = min(length(T_HS), length(T_TO));     %P01:NUMBER OF TAPPING (HEEL-TOE)
    
    % Parte modificata
    dif_TT     = diff(ts(T_TO(2:end-1)));
    media_TT   = mean(dif_TT);
    features.fTT       = 1/media_TT;            %P11: TOE-TOE FREQUENCY
    dif_HH     = diff(ts(T_HS(2:end-1)));
    media_HH   = mean(dif_HH);
    features.fHH       = 1/media_HH;            %P12: HEEL-HEEL FREQUENCY

%     t_hs = ts(T_HS);
%     t_to = ts(T_TO);
    
    if (ts(T_TO(1))<ts(T_HS(1)))                %Ho appoggiato PRIMA la PUNTA   
        for i=1:(features.taps-1)
            wang_h      = -fdata_wy(T_HS(i):(T_TO(i+1)));  %dal tallone appoggiato a terra alla punta a terra
            tapp_h      = ts(T_HS(i):(T_TO(i+1)));
            ang_h       = cumtrapz(tapp_h, wang_h);
%           hold on; plot(tapp_h, ang_h, 'b.');
            exc_heel(i) = ang_h(end);                     %angolo inclinazione del piede con punta appoggiata a terra e tallone sollevato
            wAngHeelMean(i) = mean(wang_h);

            wang_t      = fdata_wy(T_TO(i):(T_HS(i)));    %dalla punta appoggiata a terra al tallone a terra
            tapp_t      = ts(T_TO(i):(T_HS(i)));
            ang_t       = cumtrapz(tapp_t, wang_t);
%           hold on; plot(tapp_t, ang_t, 'g.');
            exc_toe(i) = ang_t(end);
            wAngToeMean(i) = mean(wang_t);
            %angolo inclinazione del piede con tallone appoggiato a terra e punta sollevata
        end
    elseif (ts(T_TO(1))>ts(T_HS(1)))   %Ho appoggiato PRIMA il TALLONE (ts(T_TO(1)))>(ts(T_HS(1)))
        for i=1:(features.taps-1)
            wang_h      = -fdata_wy(T_HS(i):(T_TO(i)));      %dal tallone appoggiato a terra alla punta a terra
            tapp_h      = ts(T_HS(i):(T_TO(i)));
            ang_h       = cumtrapz(tapp_h, wang_h);
%           hold on; plot(tapp_h, ang_h, 'b.');
            exc_heel(i) = ang_h(end);
            wAngHeelMean(i) = mean(wang_h);

            wang_t      = fdata_wy(T_TO(i):(T_HS(i+1)));    %dalla punta appoggiata a terra al tallone a terra
            tapp_t      = ts(T_TO(i):(T_HS(i+1)));
            ang_t      = cumtrapz(tapp_t, wang_t);
%           hold on; plot(tapp_t, ang_t, 'g.');
            exc_toe(i) = ang_t(end);
            wAngToeMean(i) = mean(wang_t);
        end
    end

    features.exc_h   = mean(exc_heel(2:end-1));    %P02:ANGULAR AMPLITUDE OF HEEL
    features.exc_hSD = std(exc_heel(2:end-1));     %P03:SD OF ANGULAR AMPLITUDE OF HEEL
    features.exc_t   = mean(exc_toe(2:end-1));     %P04:ANGULAR AMPLITUDE OF TOE
    features.exc_tSD = std(exc_toe(2:end-1));      %P05:SD OF ANGULAR AMPLITUDE OF TOE
    features.wt      = abs(mean(wAngToeMean(2:end-1))); %P06:MEAN ANGULAR TOE VELOCITY
    features.wtSD    = std(abs(wAngToeMean(2:end-1)));  %P07:SD OF MEAN ANGULAR TOE VELOCITY
    features.wh      = abs(mean(wAngHeelMean(2:end-1))); %P08:MEAN ANGULAR HEEL VELOCITY
    features.whSD    = std(abs(wAngHeelMean(2:end-1)));  %P09:SD OF MEAN ANGULAR HEEL VELOCITY


%% Calcolo esitazioni (modificato)
features.hes = 0;

% Se ho meno di 8 taps lascio tutto a 0 
if features.taps >= 11
    rhythm = dif_TT;
    rhythmSorted = sort(rhythm);
    L = length(rhythm);
    
    % Da rivedere questa parte per il porting degli indici in C#
    if mod(L,2) == 0
        averageRhythm = mean([rhythmSorted(L/2 - 1), rhythmSorted(L/2), rhythmSorted(L/2 + 1), rhythmSorted(L/2 + 2)]);
    else
        averageRhythm = mean([rhythmSorted(L/2 - 1.5), rhythmSorted(L/2 - 0.5), rhythmSorted(L/2 + 0.5), rhythmSorted(L/2 + 1.5), rhythmSorted(L/2 + 2.5)]);
    end
    rhyhtmSD = std(rhythmSorted);
    
    features.hes = sum(rhythm < averageRhythm - 2 * rhyhtmSD) + sum(rhythm > averageRhythm + 2 * rhyhtmSD);
end




% rhytm = sort(dif_TT);
% L = length(rhytm);
% if L<8
%     features.hes = 0;
% else
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
% 
% SDrhytm = std(rhytm);
% thrs_rh1    = median_values + 2*SDrhytm;
% thrs_rh2    = median_values - 2*SDrhytm;
% 
% yy = 1;
% yyy = 1;
% indx_rh1 = [];
% indx_rh2 = [];
% for y = 1:length(rhytm)
%     if (rhytm(y) > thrs_rh1)
%         indx_rh1(yy) = y;
%         yy = yy+1;
%     elseif (rhytm(y) < thrs_rh2)
%         indx_rh2(yyy) = y;
%         yyy = yyy+1;
%     end
% end
% features.hes = length(indx_rh1)+length(indx_rh2);
% 
% end

 features.exc_h = round(features.exc_h*100)/100;
 features.exc_hSD = round(features.exc_hSD*100)/100;
 features.exc_t = round(features.exc_t*100)/100;
 features.exc_tSD = round(features.exc_tSD*100)/100;
 features.wt = round(features.wt*100)/100;
 features.wtSD = round(features.wtSD*100)/100;
 features.wh = round(features.wh*100)/100;
 features.whSD = round(features.whSD*100)/100;
 features.IAV = round(features.IAV*100)/100;
 features.fTT = round(features.fTT*100)/100;
 features.fHH = round(features.fHH*100)/100;
 
end
end
