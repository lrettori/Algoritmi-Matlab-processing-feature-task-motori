function [features] = fFRTremor_A_modified(directory,filename,ts,data_ax,data_ay,data_az,fs_daphne,exercise)
% Funzione completamente modificata ed ottimizzata rispetto alla versione originale
% Viene utilizzata per i task HRST, FRST, KINT e POST

% [MODIFICATA] Filtro passa-basso i segnali (prima veniva fatto nel momento
% dell'estrazione dei dati, io l'ho spostata qui dentro)
n = 4; % ordine del filtro di Butterworth
ft_daphne = 20; % freq di taglio del filtro
wn_daphne = 2*ft_daphne/fs_daphne; % freq normalizzata di taglio del filtro
[b,a] = butter(n,wn_daphne);
fdata_ax = filtfilt(b,a,data_ax);
fdata_ay = filtfilt(b,a,data_ay);
fdata_az = filtfilt(b,a,data_az);

%% Trovo gli istanti di inizio e fine esercizio [MODIFICA]
% Per esercizi HRST e FRST l'esercizio si svolge tra 3 e 35 secondi
% Per POST tra 3 e 13 secondi
% Per KINT il T_start è 3 secondi, il T_end va trovato

[~,indexStart] = min(abs(ts-3));
if strcmp(exercise,'HRST') || strcmp(exercise,'FRST')
    [~,indexStop] = min(abs(ts-35));
    numbOfTimeIntervals = 5;

elseif strcmp(exercise,'POST')
    [~,indexStop] = min(abs(ts-13));
    numbOfTimeIntervals = 1;

elseif strcmp(exercise,'KINT')
    % Caso KINT
    k = 500;
    p   =   length(ts);
    THRE=100;TH_t=5;
    step = 0;
    while(p>=k)
        if (fdata2_wx(p)>THRE)
            app = p;
            flag = 1;
            while(flag)
                app = app + 1;
                if (fdata2_wx(app)<TH_t)
                    step = step + 1;
                    T_end(step) = app;
                    flag = 0;
                end
            end
        end
        p = p-1;
    end
    indexStop = T_end(1);
    numbOfTimeIntervals = 1;
end

% [MODIFICA] Trovo gli indici relativi agli istanti di inizio/fine dei
% sottointervalli che devo considerare (8s, 16s, 24s, 32s a partire
% dall'inizio dell'intervallo di interesse, quindi 11s, 19s, 27s, 35s)
% Serve per gli esercizi HRST e FRST
[~,index8sec] = min(abs(ts-(8+3)));
[~,index16sec] = min(abs(ts-(16+3)));
[~,index24sec] = min(abs(ts-(24+3)));
[~,index32sec] = min(abs(ts-(32+3)));

accTot = sqrt(fdata_ax.^2+fdata_ay.^2+fdata_az.^2);  %acc 3D
% figure; plot(ts, acc, 'b.-');
[d,c]= butter(4,2*0.5/fs_daphne,'high');    %HP Butterworth filter, ft=0.5Hz, n=4

% Dati filtrati (LP e HP) in tutto l'intervallo di acquisizione
accFilteredTot = filtfilt(d,c,accTot);
lengthTot = length(accFilteredTot);
accFiltered32s = accFilteredTot(indexStart:indexStop);
length32s = length(accFiltered32s);

% acc_x          = fdata_ax(index3sec:index35sec);
% acc_y          = fdata_ay(index3sec:index35sec);
% acc_z          = fdata_az(index3sec:index35sec);
% accIAV         = sqrt(acc_x.^2+acc_y.^2+acc_z.^2);
accIAVtot = sqrt(fdata_ax.^2 + fdata_ay.^2 + fdata_az.^2);

freqrange1 = [3.5 7.5]; 
freqrange2 = [8 12];

if numbOfTimeIntervals == 5
    indexStartIntervals = [indexStart, indexStart, index8sec, index16sec, index24sec];
    indexEndIntervals = [indexStop, index8sec, index16sec, index24sec, index32sec];
else
    indexStartIntervals = indexStart;
    indexEndIntervals = indexStop;
end

features.IAV = zeros(1,numbOfTimeIntervals); 
features.freqA = zeros(1,numbOfTimeIntervals); 
features.PwrA = zeros(1,numbOfTimeIntervals); 
features.Perc1A = zeros(1,numbOfTimeIntervals); 
features.Perc2A = zeros(1,numbOfTimeIntervals);

for i = 1:5
    acc_i = accFilteredTot(indexStartIntervals(i) : indexEndIntervals(i));
    accIAV_i = accIAVtot(indexStartIntervals(i) : indexEndIntervals(i));
    length_i = indexEndIntervals(i) - indexStartIntervals(i) + 1;
    NFFT_i = 2^nextpow2(length_i);
    features.IAV(i) = trapz(ts(indexStartIntervals(i) : indexEndIntervals(i)),accIAV_i);
    Acc_i = fft(acc_i,NFFT_i);
    f_i = fs_daphne/2*linspace(0,1,NFFT_i/2+1);
    Pacc_i = Acc_i.*conj(Acc_i)/(length_i*fs_daphne);
    [~, fundFreqIndex] = max(Pacc_i(1:NFFT_i/2+1));
    features.freqA(i) = f_i(fundFreqIndex);
    
    features.PwrA(i) = (sum(Pacc_i(1:NFFT_i/2+1))) * (fs_daphne/2) / (NFFT_i/2); % Sostituisce la funzione avgpower

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
end

 features.IAV = round(features.IAV*100)/100;
 features.freqA = round(features.freqA*100)/100;
 features.Perc1A = round(features.Perc1A*100)/100;
 features.Perc2A = round(features.Perc2A*100)/100;
end