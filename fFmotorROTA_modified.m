function [features] = fFmotorROTA_modified(side,data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne)

% Inizializzazione features
features.time = 0;
features.numbOfStrides = 0;
features.frequency = 0;
features.stanceTime = 0;
features.relStanceTime = 0;

% Filtraggio passa-basso, frequenza di taglio 5 Hz
n = 4;
ft_daphne = 5;
wn_daphne = 2*ft_daphne/fs_daphne;
[b,a] = butter(n,wn_daphne);
fdata_ax = filtfilt(b,a,data_ax);
fdata_ay = filtfilt(b,a,data_ay);
fdata_az = filtfilt(b,a,data_az);
fdata_wx = filtfilt(b,a,data_wx);
fdata_wy = filtfilt(b,a,data_wy);
fdata_wz = filtfilt(b,a,data_wz);

% Rimozione dell'offset
offset = offsetCalculation(fdata_wz,ts,1,2);
fdata_wz = fdata_wz - offset;

% Segmentazione
THRE = 50;
TH_t = 5;
plot_title = 'fdata_wz';
figure; plot(ts,fdata_wz, 'g.-');title(plot_title,'Interpreter','none');

[~,k] = min(abs(ts-2.5)); % k = 250;
p = length(ts);
st = 1;
step = 0;
while(k<=p)
    if strcmp(side,'SX')
        switch(st)
            case 1
                if (fdata_wz(k) < -THRE) % rotazione antioraria
                    app = k;
                    %hold on; plot(ts(k), fdata_wz(k), 'ko');
                    flag = 1;
                    while(flag)
                        app = app - 1;
                        if (fdata_wz(app) > -TH_t)
                            step = step + 1;
                            T_start(step) = app;
                            hold on; plot(ts(T_start),fdata_wz(T_start), 'ko');
                            flag = 0;
                            st = 2;
                        end
                    end
                end
            case 2
                if (fdata_wz(k)>-TH_t)
                    T_end(step) = k;
                    hold on; plot(ts(T_end),fdata_wz(T_end), 'ro');
                    st = 1;
                end
        end
    elseif strcmp(side,'DX')
        switch(st)
            case 1
                if (fdata_wz(k) > THRE)                % rotazione oraria
                    app = k;
                    %              hold on; plot(ts(k),fdata_wz(k), 'ko');
                    flag = 1;
                    while(flag)
                        app = app - 1;
                        if (fdata_wz(app) < TH_t)
                            step = step + 1;                %inizia un nuovo passo
                            T_start(step) = app;
                            hold on; plot(ts(T_start),fdata_wz(T_start), 'b*');
                            flag = 0;
                            st = 2;
                        end
                    end
                end
            case 2
                if (fdata_wz(k)<TH_t)
                    T_end(step) = k;
                    hold on; plot(ts(T_end),fdata_wz(T_end), 'r*');
                    st = 1;
                end
        end
    end
    k = k+1;
end

if step > 0

    if length(T_end) < length(T_start)
        % Aggiungo ultimo elemento in coda a T_end
        durLastRep = T_end(end) - T_start(end-1);
        T_end(step) = T_start(end) + durLastRep;
    end

    features.time = ts(T_end(end))-ts(T_start(1));    %P01:TIME
    features.numbOfStrides = step;                          %P02:NUMBER OF STRIDES
    features.frequency = step/features.time;                 %P03:FREQUENCY
    if step>1
        for i=1:(step-1)
            t_stop(i) = ts(T_start(i+1))-ts(T_end(i));
        end
    else
        t_stop = 0;
    end
    features.stanceTime = sum(t_stop);                    %P04:STANCE TIME
    features.relStanceTime = features.stanceTime/features.time*100;   %P05:RELATIVE STANCE TIME
    %     RLAT = ts(T_end(end))-ts(300);
end

features.time = round(features.time*100)/100;
features.frequency = round(features.frequency*100)/100;
features.stanceTime = round(features.stanceTime*100)/100;
features.relStanceTime = round(features.relStanceTime*100)/100;
%  RLAT = round(RLAT*100)/100;
end