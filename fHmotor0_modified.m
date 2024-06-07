function [features] = fHmotor0_modified(data_ax,data_ay,data_az,data_wz,ts,fs_daphne)

% Inizializzazione features
features.taps=0;
features.exc=0;
features.excSD=0;
features.wf=0;
features.wfSD=0;
features.wb=0;
features.wbSD=0;
features.IAV=0;

%% Filtraggio passa-basso
n = 4;
ft_daphne = 3;
wn_daphne = 2*ft_daphne/fs_daphne;
[b,a] = butter(n,wn_daphne);
fdata_ax = filtfilt(b,a,data_ax);
fdata_ay = filtfilt(b,a,data_ay);
fdata_az = filtfilt(b,a,data_az);
fdata_wz = filtfilt(b,a,data_wz);

%% Rimozione offset (da rivedere)
offset = offsetCalculation(fdata_wz,ts,1,2);
fdata_wz = fdata_wz - offset;

%% Data segmentation
plot_title = 'fdata_wz';
figure; plot(ts,fdata_wz,'g.-'); title(plot_title,'Interpreter','none');

TH_start = 20;
TH_v = 2;
% k   =   250;
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
                        T_start(swing) = app; %inizia il movimento con wz positiva
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
                            T_start(swing) = app; %inizia il movimento con wz positiva
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
            if (fdata_wz(k) > TH_start)  % braccio parte in avanti (front)
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
        features.taps          = arm_f;                                %P01:NUMBER OF TAPPING
        dif_ARMS      = diff(ts(T_front(2:end-1)));
        media_ARMS    = mean(dif_ARMS);
        devst_ARMS    = std(dif_ARMS);
        f_osc         = 1/media_ARMS;
        acc_x         = fdata_ax(T_start(1):T_back(end));
        acc_y         = fdata_ay(T_start(1):T_back(end));
        acc_z         = fdata_az(T_start(1):T_back(end));
        acc           = sqrt(acc_x.^2+acc_y.^2+acc_z.^2);
        IAV           = trapz(ts(T_start(1):T_back(end)),acc);%P08:ESTIMATED ENERGY EXPENDITURE
        for i=1:(features.taps-1)
            wzang         = fdata_wz(T_front(i):(T_back(i)));
            tapp          = ts(T_front(i):(T_back(i)));
            zang          = cumtrapz(tapp, wzang);    %oscillazione piano sagittale
            %          hold on; plot(tapp, zang, 'k');
            wzang2        = fdata_wz(T_back(i):(T_front(i+1)));
            tapp2         = ts(T_back(i):(T_front(i+1)));
            zang2         = cumtrapz(tapp2, wzang2);
            zang_r        = zang2+zang(end);
            %              hold on; plot(tapp2, zang_r, 'k');
            mzang = (zang_r(end)-zang(1))/(tapp2(end)-tapp(1)); qzang = zang(1)-mzang*tapp(1);
            zang_e = mzang*ts(T_front(i):T_front(i+1))+qzang;
            %  %             hold on; plot(ts(T_front(i):T_front(i+1)),zang_e,'g');
            zang_tot = [zang',(zang_r(2:end))'];
            zang_m = zang_tot-zang_e;
            hold on; plot(ts(T_front(i):T_front(i+1)),zang_m,'k');
            w_back(i)      = mean(wzang);
            w_front(i)     = mean(wzang2);
            zang_sw(i)     = max(abs(zang_m));
        end
    else
        features.taps         = arm_b;  %PRIMO MOV INDIETRO
        dif_ARMS     = diff(ts(T_back));
        media_ARMS   = mean(dif_ARMS);
        devst_ARMS   = std(dif_ARMS);
        f_osc        = 1/media_ARMS;
        acc_x        = fdata_ax(T_start(1):T_front(end));
        acc_y        = fdata_ay(T_start(1):T_front(end));
        acc_z        = fdata_az(T_start(1):T_front(end));
        acc          = sqrt(acc_x.^2+acc_y.^2+acc_z.^2);
        IAV          = trapz(ts(T_start(1):T_front(end)),acc);
        for i=1:(features.taps-1)
            wzang         = fdata_wz(T_back(i):(T_front(i)));
            tapp          = ts(T_back(i):(T_front(i)));
            zang          = cumtrapz(tapp, wzang);    %oscillazione piano sagittale
            %          hold on; plot(tapp, zang, 'k');
            wzang2         = fdata_wz(T_front(i):(T_back(i+1)));
            tapp2          = ts(T_front(i):(T_back(i+1)));
            zang2          = cumtrapz(tapp2, wzang2);
            zang_r        = zang2+zang(end);
            %              hold on; plot(tapp2, zang_r, 'k');
            mzang = (zang_r(end)-zang(1))/(tapp2(end)-tapp(1)); qzang = zang(1)-mzang*tapp(1);
            zang_e = mzang*ts(T_back(i):T_back(i+1))+qzang;
            %  %             hold on; plot(ts(T_back(i):T_back(i+1)),zang_e,'g');
            zang_tot = [zang',(zang_r(2:end))'];
            zang_m = zang_tot-zang_e;
            hold on; plot(ts(T_back(i):T_back(i+1)),zang_m,'b');
            w_front(i)    = mean(wzang);
            w_back(i)     = mean(wzang2);
            zang_sw(i)    = max(abs(zang_m));
        end
    end

    features.exc      = round(mean(zang_sw(2:end-1))*100)/100;       %P02:MEAN ANGULAR AMPLITUDE OF SWING
    features.excSD    = round(std(abs(zang_sw(2:end-1)))*100)/100;   %P03:SD OF ANGULAR AMPLITUDE OF SWING
    features.wf       = round(abs(mean(w_front(2:end-1)))*100)/100;  %P04:MEAN ANGULAR FRONT VELOCITY
    features.wfSD     = round(std(abs(w_front(2:end-1)))*100)/100;   %P05:SD OF MEAN ANGULAR FRONT VELOCITY
    features.wb       = round(abs(mean(w_back(2:end-1)))*100)/100;   %P06:MEAN ANGULAR BACK VELOCITY
    features.wbSD     = round(std(abs(w_back(2:end-1)))*100)/100;    %P07:SD OF MEAN ANGULAR BACK VELOCITY
    features.IAV      = round(IAV*100)/100;                          %P08:ESTIMATED ENERGY EXPENDITURE
end
end