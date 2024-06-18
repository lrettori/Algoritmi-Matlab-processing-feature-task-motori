function [features] = fHmotor0_modified(dataInput,ts,fs_daphne,limb)

% Inizializzazione features
features.taps = 0;
features.exc = 0;
features.excSD = 0;
features.wf = 0;
features.wfSD = 0;
features.wb = 0;
features.wbSD = 0;
features.IAV = 0;

%% Estrazione dati
data_ax = dataInput(:,1);
data_ay = dataInput(:,2);
data_az = dataInput(:,3);
data_wz = dataInput(:,6);
% Inverto il segnale del giroscopio lungo z per il braccio destro, per la
% convenzione velocità positiva = rotazione in avanti
if strcmp(limb,'right hand')
    data_wz = - data_wz;
end

%% Filtraggio passa-basso
n = 4;
ft_daphne = 3;
wn_daphne = 2*ft_daphne/fs_daphne;
[b,a] = butter(n,wn_daphne);
fdata_ax = filtfilt(b,a,data_ax);
fdata_ay = filtfilt(b,a,data_ay);
fdata_az = filtfilt(b,a,data_az);
fdata_wz = filtfilt(b,a,data_wz);

%% Rimozione offset
offset = offsetCalculation(fdata_wz,ts,1,2);
fdata_wz = fdata_wz - offset;

%% Signal segmentation
plot_title = strcat('fdata_wz_',limb);
figure; plot(ts,fdata_wz,'g.-'); title(plot_title,'Interpreter','none');

TH_start = 20;
TH_v = 2;
[~,k] = min(abs(ts-2.5));
p = length(ts);
st = 1;
swing = 0;    %oscillazioni con le braccia
arm_f = 0;    %braccio max avanti
arm_b = 0;    %braccio max indietro
while(k<=p)
    switch(st)
        case 1
            if (fdata_wz(k) > TH_start && swing == 0)  % braccio parte in avanti (front)
                app = k;
                flag = 1;
                while(flag)
                    app = app - 1;
                    if (fdata_wz(app) < TH_v)
                        swing = swing + 1;
                        %                             arm_f = arm_f + 1;
                        T_start = app; %inizia il movimento con wz positiva
                        hold on; plot(ts(T_start),fdata_wz(T_start), 'ko');
                        flag = 0;
                        st = 2;
                    end
                end
            else if(fdata_wz(k) < -TH_start && swing == 0)  %braccio parte indietro (back)
                    app = k;
                    flag = 1;
                    while(flag)
                        app = app - 1;
                        if (fdata_wz(app) > -TH_v)
                            swing = swing + 1;
                            T_start = app; %inizia il movimento con wz negativa
                            hold on; plot(ts(T_start),fdata_wz(T_start), 'bo');
                            flag = 0;
                            st = 3;
                        end
                    end
            end
            end
        case 2
            if (fdata_wz(k) < -TH_start)  % braccio parte in avanti (front)
                app = k;
                flag = 1;
                while(flag)
                    app = app - 1;
                    if (fdata_wz(app) > -TH_v && fdata_wz(app)<fdata_wz(app-1))
                        arm_f = arm_f + 1;   %braccio tutto avanti
                        T_front(arm_f) = app;
                        hold on; plot(ts(T_front),fdata_wz(T_front), 'mo');
                        st = 3;
                        flag = 0;
                    end
                end
            end
        case 3
            if (fdata_wz(k) > TH_start)  % braccio parte indietro (back)
                app = k;
                flag = 1;
                while(flag)
                    app = app - 1;
                    if (fdata_wz(app) < TH_v && fdata_wz(app)>fdata_wz(app-1) )
                        arm_b = arm_b + 1;  %braccio tutto indietro
                        T_back(arm_b)  = app;
                        hold on; plot(ts(T_back),fdata_wz(T_back), 'ro');
                        st = 2;
                        flag = 0;
                    end
                end
            end
    end
    k = k+1;
end

%%
if swing > 0
    if ts(T_front(1))<ts(T_back(1)) %PRIMO MOV IN AVANTI
        firstMov = 'front';
        features.taps = arm_f;                                %P01:NUMBER OF TAPPING
        T_end = T_back;

        T_1 = T_front;
        T_2 = T_back;
    else
        firstMov = 'back';
        features.taps = arm_b;                                %P01:NUMBER OF TAPPING
        T_end = T_front;

        T_1 = T_back;
        T_2 = T_front;
    end
    acc_x         = fdata_ax(T_start:T_end(end));
    acc_y         = fdata_ay(T_start:T_end(end));
    acc_z         = fdata_az(T_start:T_end(end));
    acc           = sqrt(acc_x.^2+acc_y.^2+acc_z.^2);
    IAV           = trapz(ts(T_start:T_end(end)),acc);%P08:ESTIMATED ENERGY EXPENDITURE

    for i=1:(features.taps-1)
        wzang         = fdata_wz(T_1(i):(T_2(i)));
        tapp          = ts(T_1(i):(T_2(i)));
        zang          = cumtrapz(tapp, wzang);    %oscillazione piano sagittale
        wzang2        = fdata_wz(T_2(i):(T_1(i+1)));
        tapp2         = ts(T_2(i):(T_1(i+1)));
        zang2         = cumtrapz(tapp2, wzang2);
        zang_r        = zang2+zang(end);
        mzang = (zang_r(end)-zang(1))/(tapp2(end)-tapp(1)); 
        qzang = zang(1)-mzang*tapp(1);
        zang_e = mzang*ts(T_1(i):T_1(i+1))+qzang;
        zang_tot = [zang',(zang_r(2:end))'];
        zang_m = zang_tot-zang_e;
        hold on; plot(ts(T_1(i):T_1(i+1)),zang_m,'k');
        w_1(i)      = mean(wzang);
        w_2(i)     = mean(wzang2);
        zang_sw(i)     = max(abs(zang_m));
    end

    if strcmp(firstMov,'front')
        w_back = w_1;
        w_front = w_2;
    else
        w_back = w_2;
        w_front = w_1;
    end


    %%

    features.exc      = round(mean(zang_sw(2:end-1))*100)/100;       %P02:MEAN ANGULAR AMPLITUDE OF SWING
    features.excSD    = round(std(abs(zang_sw(2:end-1)))*100)/100;   %P03:SD OF ANGULAR AMPLITUDE OF SWING
    features.wf       = round(abs(mean(w_front(2:end-1)))*100)/100;  %P04:MEAN ANGULAR FRONT VELOCITY
    features.wfSD     = round(std(abs(w_front(2:end-1)))*100)/100;   %P05:SD OF MEAN ANGULAR FRONT VELOCITY
    features.wb       = round(abs(mean(w_back(2:end-1)))*100)/100;   %P06:MEAN ANGULAR BACK VELOCITY
    features.wbSD     = round(std(abs(w_back(2:end-1)))*100)/100;    %P07:SD OF MEAN ANGULAR BACK VELOCITY
    features.IAV      = round(IAV*100)/100;                          %P08:ESTIMATED ENERGY EXPENDITURE
end
end