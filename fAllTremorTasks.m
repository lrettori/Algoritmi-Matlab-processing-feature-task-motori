function features = fAllTremorTasks(ts,data_ax,data_ay,data_az,data_wx,data_wy,data_wz,fs_daphne,exercise)

% Funzione che racchiude al suo interno le vecchie funzioni fHTremor_A,
% fHTremor_G, fFRTremor_A, fFRTremor_G, fHTremor_A e fHTremor_G
% Calcola cioè tutte le features (relative sia a misure di accelerazione
% che di velocità angolare) per i task HRST, FRST, KINT e POST

%% Filtraggio passa-basso, con frequenza di taglio di 20 Hz
n = 4;
ft_daphne = 20;
wn_daphne = 2 * ft_daphne / fs_daphne;
[b,a] = butter(n,wn_daphne);
fdata_ax = filtfilt(b,a,data_ax);
fdata_ay = filtfilt(b,a,data_ay);
fdata_az = filtfilt(b,a,data_az);
fdata_wx = filtfilt(b,a,data_wx);
fdata_wy = filtfilt(b,a,data_wy);
fdata_wz = filtfilt(b,a,data_wz);
% fdata_ax = data_ax;
% fdata_ay = data_ay;
% fdata_az = data_az;
% fdata_wx = data_wx;
% fdata_wy = data_wy;
% fdata_wz = data_wz;

%% Rimozione dell'offset per il segnale del giroscopio

offsetWx = offsetCalculation(fdata_wx,ts,1,2);
offsetWy = offsetCalculation(fdata_wy,ts,1,2);
offsetWz = offsetCalculation(fdata_wz,ts,1,2);

wxOffsetRemov = fdata_wx - offsetWx;
wyOffsetRemov = fdata_wy - offsetWy;
wzOffsetRemov = fdata_wz - offsetWz;

figure;plot(wxOffsetRemov);hold on;plot(wyOffsetRemov);plot(wzOffsetRemov);
title('Gyroscope data')

%% Trovo gli istanti di inizio e fine esercizio
% Per esercizi HRST e FRST l'esercizio si svolge tra 3 e 35 secondi
% Per POST tra 3 e 13 secondi
% Per KINT il T_start è 3 secondi, il T_end va trovato

[~,indexStart] = min(abs(ts-3));
if strcmp(exercise,'HRST') || strcmp(exercise,'FRST')
    [~,indexStop] = min(abs(ts-35));
    numbOfTimeIntervals = 5;

    % Indici di inizio/fine dei sottointervalli per i task HRST e FRST
    [~,index8sec] = min(abs(ts-(8+3)));
    [~,index16sec] = min(abs(ts-(16+3)));
    [~,index24sec] = min(abs(ts-(24+3)));
    [~,index32sec] = min(abs(ts-(32+3)));

elseif strcmp(exercise,'POST')
    [~,indexStop] = min(abs(ts-13));
    numbOfTimeIntervals = 1;

elseif strcmp(exercise,'KINT')
    % Caso KINT
%     k = 500;
    [~,k] = min(abs(ts-5));
    p = length(ts);
    THRE=100;
    TH_t=9;
    step = 0;
    % Per il calcolo del Tend uso il modulo del giroscopio sui tre assi,
    % per evitare problemi dovuti ad una esecuzione errata del movimento da
    % parte del paziente (serve esclusivamente per trovare il Tend, quindi
    % non modifico il calcolo delle features, ma solo l'intervallo di
    % riferimento)
    wModuleOffsetRemov = sqrt(wxOffsetRemov.^2 + wyOffsetRemov.^2 + wzOffsetRemov.^2);
    flagTendNotFound = 1;

    while(p>=k && flagTendNotFound)
        if (wModuleOffsetRemov(p) > THRE)
            app = p;
            flag = 1;
            while(flag && app < length(ts))
                app = app + 1;
                if (wModuleOffsetRemov(app) < TH_t)
                    step = step + 1;
                    T_end = app;
                    flag = 0;
                    flagTendNotFound = 0;
                    break;
                end
            end
        end
        p = p-1;
    end
    indexStop = T_end;
    numbOfTimeIntervals = 1;

    figure;plot(ts,wModuleOffsetRemov);hold on;
    plot(ts(indexStart),wModuleOffsetRemov(indexStart), 'go');
    plot(ts(indexStop),wModuleOffsetRemov(indexStop), 'ro');
end

%% Filtraggio passa-alto, con frequenza di taglio di 0.5 Hz (1.5 Hz per KINT)

ft = 0.5;
if strcmp(exercise,'KINT')
    ft = 1.5;
end

[d,c]= butter(4,2*ft/fs_daphne,'high');

accTot = sqrt(fdata_ax.^2+fdata_ay.^2+fdata_az.^2);  %acc 3D

% Dati filtrati (LP e HP) in tutto l'intervallo di acquisizione
accFilteredTot = filtfilt(d,c,accTot);
% accFilteredTot = accTot;

wxFilteredTot = filtfilt(d,c,wxOffsetRemov);
wyFilteredTot = filtfilt(d,c,wyOffsetRemov);
wzFilteredTot = filtfilt(d,c,wzOffsetRemov);

%% Definisco le bande di frequenza da analizzare e i sotto-intervalli temporali

freqrange1 = [3.5 7.5];
freqrange2 = [8 12];

if numbOfTimeIntervals == 5
    indexStartIntervals = [indexStart, indexStart, index8sec, index16sec, index24sec];
    indexEndIntervals = [indexStop, index8sec, index16sec, index24sec, index32sec];
else
    indexStartIntervals = indexStart;
    indexEndIntervals = indexStop;
end

%% Inizializzazione delle features

features.IAV = zeros(1,numbOfTimeIntervals);
features.freqA = zeros(1,numbOfTimeIntervals);
features.PwrA = zeros(1,numbOfTimeIntervals);
features.Perc1A = zeros(1,numbOfTimeIntervals);
features.Perc2A = zeros(1,numbOfTimeIntervals);
features.freqG = zeros(1,numbOfTimeIntervals);
features.PwrG = zeros(1,numbOfTimeIntervals);
features.Perc1G = zeros(1,numbOfTimeIntervals);
features.Perc2G = zeros(1,numbOfTimeIntervals);

for i = 1:numbOfTimeIntervals
    %% Calcolo features accelerazione
    acc_i = accFilteredTot(indexStartIntervals(i) : indexEndIntervals(i));
    accIAV_i = accTot(indexStartIntervals(i) : indexEndIntervals(i));
    length_i = indexEndIntervals(i) - indexStartIntervals(i) + 1;
    NFFT_i = 2^nextpow2(length_i);
    features.IAV(i) = trapz(ts(indexStartIntervals(i) : indexEndIntervals(i)),accIAV_i);
    Acc_i = fft(acc_i,NFFT_i);
    f_i = fs_daphne/2*linspace(0,1,NFFT_i/2+1);
    Pacc_i = Acc_i.*conj(Acc_i)/(length_i*fs_daphne);
    [~, fundFreqIndex] = max(Pacc_i(1:NFFT_i/2+1));
    features.freqA(i) = f_i(fundFreqIndex);

    features.PwrA(i) = (sum(Pacc_i(1:NFFT_i/2+1))) * (fs_daphne/2) / (NFFT_i/2); % Sostituisce la funzione avgpower

    % figure;plot(f_i,Pacc_i(1:NFFT_i/2+1));title('Spettro segnale di accelerazione');

    indexFreqRange1 = zeros(1,2);
    indexFreqRange2 = zeros(1,2);
    [~,indexFreqRange1(1)] = min(abs(f_i - freqrange1(1)));
    [~,indexFreqRange1(2)] = min(abs(f_i - freqrange1(2)));
    [~,indexFreqRange2(1)] = min(abs(f_i - freqrange2(1)));
    [~,indexFreqRange2(2)] = min(abs(f_i - freqrange2(2)));

    Pwr_a1 = (sum(Pacc_i(indexFreqRange1(1) : indexFreqRange1(2)))) * (fs_daphne/2) / (NFFT_i/2);
    Pwr_a2 = (sum(Pacc_i(indexFreqRange2(1) : indexFreqRange2(2)))) * (fs_daphne/2) / (NFFT_i/2);
    features.Perc1A(i) = Pwr_a1/features.PwrA(i)*100;
    features.Perc2A(i) = Pwr_a2/features.PwrA(i)*100;

    %% Calcolo features velocità angolare
    % Prelevo il sotto-intervallo di interesse
    wxHPFilt_i = wxFilteredTot(indexStartIntervals(i) : indexEndIntervals(i));
    wyHPFilt_i = wyFilteredTot(indexStartIntervals(i) : indexEndIntervals(i));
    wzHPFilt_i = wzFilteredTot(indexStartIntervals(i) : indexEndIntervals(i));
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
    [~, indOfHighestPeak] = max(peaks);

    indexFreqRange1 = zeros(1,2);
    indexFreqRange2 = zeros(1,2);
    [~,indexFreqRange1(1)] = min(abs(f_i - freqrange1(1)));
    [~,indexFreqRange1(2)] = min(abs(f_i - freqrange1(2)));
    [~,indexFreqRange2(1)] = min(abs(f_i - freqrange2(1)));
    [~,indexFreqRange2(2)] = min(abs(f_i - freqrange2(2)));

    switch indOfHighestPeak
        case 1
            features.freqG(i) = f_i(fundFreqIndexX);
            features.PwrG(i) = (sum(Pwx_i(1:NFFT_i/2+1))) * (fs_daphne/2) / (NFFT_i/2); % Sostituisce la funzione avgpower
            Pwr_g1 = (sum(Pwx_i(indexFreqRange1(1) : indexFreqRange1(2)))) * (fs_daphne/2) / (NFFT_i/2);
            Pwr_g2 = (sum(Pwx_i(indexFreqRange2(1) : indexFreqRange2(2)))) * (fs_daphne/2) / (NFFT_i/2);
            % figure;plot(f_i,Pwx_i(1:NFFT_i/2+1));title('Spettro segnale di velocità angolare');

        case 2
            features.freqG(i) = f_i(fundFreqIndexY);
            features.PwrG(i) = (sum(Pwy_i(1:NFFT_i/2+1))) * (fs_daphne/2) / (NFFT_i/2); % Sostituisce la funzione avgpower
            Pwr_g1 = (sum(Pwy_i(indexFreqRange1(1) : indexFreqRange1(2)))) * (fs_daphne/2) / (NFFT_i/2);
            Pwr_g2 = (sum(Pwy_i(indexFreqRange2(1) : indexFreqRange2(2)))) * (fs_daphne/2) / (NFFT_i/2);
            % figure;plot(f_i,Pwy_i(1:NFFT_i/2+1));title('Spettro segnale di velocità angolare');

        case 3
            features.freqG(i) = f_i(fundFreqIndexZ);
            features.PwrG(i) = (sum(Pwz_i(1:NFFT_i/2+1))) * (fs_daphne/2) / (NFFT_i/2); % Sostituisce la funzione avgpower
            Pwr_g1 = (sum(Pwz_i(indexFreqRange1(1) : indexFreqRange1(2)))) * (fs_daphne/2) / (NFFT_i/2);
            Pwr_g2 = (sum(Pwz_i(indexFreqRange2(1) : indexFreqRange2(2)))) * (fs_daphne/2) / (NFFT_i/2);
            % figure;plot(f_i,Pwz_i(1:NFFT_i/2+1));title('Spettro segnale di velocità angolare');

    end
    features.Perc1G(i) = Pwr_g1/features.PwrG(i)*100;
    features.Perc2G(i) = Pwr_g2/features.PwrG(i)*100;
end

features.IAV = round(features.IAV*100)/100;
features.freqA = round(features.freqA*100)/100;
features.Perc1A = round(features.Perc1A*100)/100;
features.Perc2A = round(features.Perc2A*100)/100;
features.freqG = round(features.freqG*100)/100;
features.Perc1G = round(features.Perc1G*100)/100;
features.Perc2G = round(features.Perc2G*100)/100;


end