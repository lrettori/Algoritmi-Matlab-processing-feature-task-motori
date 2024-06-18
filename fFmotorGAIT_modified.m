function [features] = fFmotorGAIT_modified(dataInput,ts,fs_daphne,limb)


% Inizializzazione features
features.GT = 0;
features.GSTRD = 0;
features.GVEL = 0;
features.GSTRD_L = 0;
% features.GSTRD_H = 0; % non serve per Olimpia
% features.GSTRD_HSD = 0; % non serve per Olimpia
features.GSTRDT = 0;
features.GSTRDT_SD = 0;
features.GSWT = 0;
features.GSWT_SD = 0;
features.GSTT = 0;
features.GSTT_SD = 0;
features.GRS = 0;
features.GEXC = 0;
features.GEXC_SD = 0;
% features.GLAT = 0; % non serve per Olimpia

pathLength = 15; % 15 meters

%% Estrazione dati
data_ax = dataInput(:,1);
data_ay = dataInput(:,2);
data_az = dataInput(:,3);
data_wy = dataInput(:,5);

%% Filtraggio passa-basso
n = 4;
ft_daphne = 3;
wn_daphne = 2*ft_daphne/fs_daphne;
[b,a] = butter(n,wn_daphne);
fdata_ax = filtfilt(b,a,data_ax);
fdata_ay = filtfilt(b,a,data_ay);
fdata_az = filtfilt(b,a,data_az);
fdata_wy = filtfilt(b,a,data_wy);

%% Calcolo inclinazione e rimozione offset
[~,k1sec] = min(abs(ts-1));
[~,k2sec] = min(abs(ts-2));
ax_i = mean(fdata_ax(k1sec:k2sec));
az_i = mean(fdata_az(k1sec:k2sec));
teta_i_rad = atan(ax_i/az_i);       %teta_i è negativo
teta0_deg  = -teta_i_rad*180/pi;    %angolo di inclinazione frontale a riposo rispetto alla verticale assoluta (asse Z)

% Rimozione offset da segnale giroscopio
offset = offsetCalculation(fdata_wy,ts,1,2);
fdata_wy = fdata_wy - offset;

plot_title = strcat('fdata_wy_',limb);
figure; hold on; plot(ts,fdata_wy, 'b.-');title(plot_title,'Interpreter','none');

%% Signal segmentation
THRE = -30; %  °/s, quando supero questa soglia è iniziato il movimento
TH_t = -10; %  °/s, soglia effettiva di T_start    
% k = 301;
[~,k] = min(abs(ts-2.5));
p = length(ts);
st = 1;
step = 0;
while(k<=p)
    switch(st)
        case 1
            if (fdata_wy(k)<THRE)
                app = k;
                flag = 1;
                while(flag)
                    app = app - 1;
                    if (fdata_wy(app)>TH_t)
                        step = step + 1;        %inizia un nuovo passo
                        T_start(step) = app; % heel off
                        hold on; plot(ts(T_start),fdata_wy(T_start), 'go');
                        flag = 0;
                        st = 2;
                    end
                end
            end
        case 2
            if (fdata_wy(k)>TH_t && fdata_wy(k)<fdata_wy(k+1))
                T_TO(step) = k; % toe off
                hold on; plot(ts(T_TO),fdata_wy(T_TO), 'mo');
                st = 3;
            end
        case 3
            if (fdata_wy(k)<-TH_t  && fdata_wy(k)>fdata_wy(k+1))
                T_HS(step) = k; % heel strike
                hold on; plot(ts(T_HS),fdata_wy(T_HS), 'co');
                st = 4;
            end
        case 4
            if (fdata_wy(k)>TH_t && fdata_wy(k)<fdata_wy(k+1))
                T_end(step) = k;
                hold on; plot(ts(T_end),fdata_wy(T_end), 'bo');
                st = 1;
            end
    end
    k = k+1;
end

%% Completamento numero di passi (serve?)

% completo il passo con l'identificazione dell'ultimo T_end 
start = length(T_start);

if length(T_end) < start
   [~,k] = min(abs(ts-10));
   p = length(ts);
   THRE = 30;
   TH_t = 5;
   found = 0;
   while(p >= k)
        if (fdata_wy(p) > THRE)
            app = p;
            flag = 1;
            while(flag)
                app = app + 1;
                if (fdata_wy(app) < TH_t)
                    T_end(start) = app;
                    hold on; plot(ts(T_end),fdata_wy(T_end), 'bo');
                    flag = 0;
                    found = 1;
                    break
                end
            end
        end
        if found == 1
            break
        end
        p = p-1;
   end   
end

%completo il passo con l'identificazione dell'ultimo T_HS 
tto = length(T_TO);
ths = length(T_HS);
if ths<tto
    thre = 10;
    k1 = T_TO(end);
    p1 = T_end(end);
    % flag1 = 0;
    % found1 = 0;
    
    while (k1 <= p1)
        if (fdata_wy(k1) < thre && fdata_wy(k1) > fdata_wy(k1 + 1) && fdata_wy(k1 + 1) < fdata_wy(k1 + 2))
            T_HS(tto) = k1;
            hold on;
            plot(ts(T_HS), fdata_wy(T_HS), 'co');
            break
        end
        k1 = k1 + 1;
    end
    
    % while(k1<=p1)
    %     if (fdata_wy(k1)<thre && fdata_wy(k1)>fdata_wy(k1+1) && fdata_wy(k1+1)<fdata_wy(k1+2))
    %         app1 = k1;
    %         flag1 = 1;
    %         while(flag1)
    %             %                 app1 = app1 - 1;
    %             %                 if (fdata_wy(app1)<TH_t)
    %             T_HS(tto) = app1;
    %             hold on; plot(ts(T_HS),fdata_wy(T_HS), 'co');
    %             flag1 = 0;
    %             found1 = 1;
    %             break
    %             %                 end
    %         end
    %     end
    %     if found1 == 1
    %         break
    %     end
    %     k1 = k1+1;
    % end
end

%% Feature extraction

if step > 1
    features.GSTRD          = length(T_end);                        %P02:NUMBER OF STRIDES
    features.GT             = ts(T_end(end))-ts(T_start(1));        %P01:TIME
    features.GVEL           = pathLength/features.GT;               %P03:MEAN VELOCITY
    
    [~,k] = min(abs(ts-3));
    features.GLAT           = ts(T_start(1))-ts(k);               %P16:LATENCY TIME
    
    if strcmp(limb,'right foot')
        % Tolgo il primo mezzo passo del piede destro
        features.GSTRD = features.GSTRD-1;
        T_start = T_start(2:end);
        T_TO    = T_TO(2:end);
        T_HS    = T_HS(2:end);
        T_end   = T_end(2:end);
    end

    features.GSTRD_L        = pathLength/features.GSTRD;            %P04:MEAN STRIDE LENGTH
    Stride_Time    = diff(ts(T_HS));                                %tempo tra due appoggi successivi del tallone dello stesso piede
    features.GSTRDT         = mean(Stride_Time);                    %P07:STRIDE TIME
    features.GSTRDT_SD      = std(Stride_Time);                     %P08:SD OF STRIDE TIME
    if length(T_TO)>length(T_HS)
        T_TO = T_TO(1:length(T_HS));
    end
    T_Swing        = ts(T_HS(2:end))-ts(T_TO(2:end));               %tempo di volo per passo
    features.GSWT           = mean(T_Swing);                        %P09:SWING TIME
    features.GSWT_SD        = std(T_Swing);                         %P10:SD OF SWING TIME
    T_Stance       = Stride_Time - T_Swing;                         %tempo con piede appoggiato a terra per passo
    features.GSTT           = mean(T_Stance);                       %P11:STANCE TIME
    features.GSTT_SD        = std(T_Stance);                        %P12:SD OF STANCE TIME
    Rel_St         = (T_Stance./features.GSTRDT);                   %tempo di stance relativo
    features.GRS            = mean(Rel_St)*100;                     %P13:RELATIVE STANCE

    %Calcolo dell'angolo di oscillazione alla caviglia nel piano sagittale
    for i=1:features.GSTRD
        wang  = -fdata_wy(T_start(i):T_end(i));
        tapp  = ts(T_start(i):T_end(i));
        ang   = cumtrapz(tapp, wang);
        teta_i_deg(1) = teta0_deg;
        ang_e = teta_i_deg(i) + ang;
        ang_e_rad = ang_e*pi/180;
        hold on; plot(tapp,ang_e, 'k.-');
        if i < features.GSTRD
            ax_i = mean(fdata_ax(T_end(i):T_start(i+1)));
            az_i = mean(fdata_az(T_end(i):T_start(i+1)));
            teta_i_rad = -atan(ax_i/az_i);
            teta_i_deg(i+1) = teta_i_rad*180/pi;                 %calcolo ad ogni passo l'angolo di partenza
            mang = (teta_i_deg(i+1)-ang_e(end))/(ts(T_start(i+1))-ts(T_end(i))); qang = ang_e(end)-mang*ts(T_end(i));
            ang_e2 = mang*ts(T_end(i):T_start(i+1))+qang;
            hold on; plot(ts(T_end(i):T_start(i+1)),ang_e2,'g.-');
            % L1(1)    = 0;
            % L1(i+1)  = length(ang_e)+length(ang_e2)-2;
            % L2       = sum(L1(1:i));
            % L3       = sum(L1);
            % ANG((L2+1):L3,:) = [ang_e(2:end);(ang_e2(2:end)).'];
        else
            % L1(i+1)  = length(ang_e);
            % L2       = sum(L1(1:i));
            % L3       = sum(L1);
            % ANG((L2+1):L3,:) = ang_e;
        end
        Max_ang(i) = max(ang_e);
        Min_ang(i) = min(ang_e);
        Ang(i) = Max_ang(i)-Min_ang(i);
    end
    features.GEXC = mean(Ang(1:end-1));      %P14:ANGULAR EXCURSION
    features.GEXC_SD = std(Ang(1:end-1));    %P15:SD OF ANGULAR EXCURSION



    
    % %Calcolo dei parametri spaziali della camminata (parte da rivedere,
    % al momento non serve per Olimpia quindi la commento)

    % dX_init = 0;
    % dZ_init = 0;
    % for j = 1: features.GSTRD
    %     wang_SW = -fdata_wy(T_start(j):T_end(j));
    %     tapp_SW = ts(T_start(j):T_end(j));
    %     ang_SW  = cumtrapz(tapp_SW, wang_SW);
    %     ang_eSW = -teta_i_deg(j) + ang_SW;
    %     ang_eradSW = ang_eSW*pi/180;
    % 
    %     %Proiezioni delle componenti orizzontali e verticali delle
    %     %accelerazioni nel sistema di riferimento assoluto XYZ
    %     aX = (fdata_az(T_start(j):T_end(j)).*sin(ang_eradSW)-fdata_ax(T_start(j):T_end(j)).*cos(ang_eradSW));
    %     aZ = (fdata_az(T_start(j):T_end(j)).*cos(ang_eradSW)+fdata_ax(T_start(j):T_end(j)).*sin(ang_eradSW))-9.81;
    %     vX = cumtrapz(tapp_SW, aX);
    %     vZ = cumtrapz(tapp_SW, aZ);
    %     mx = (vX(end)-vX(1))/(tapp_SW(end)-tapp_SW(1)); qx = vX(1)-mx*tapp_SW(1);
    %     errlvx = mx*tapp_SW+qx;
    %     vX_e = vX - errlvx';
    %     mz = (vZ(end)-vZ(1))/(tapp_SW(end)-tapp_SW(1)); qz = vZ(1)-mz*tapp_SW(1);
    %     errlvz = mz*tapp_SW+qz;
    %     vZ_e = vZ - errlvz';
    %     dX_e = abs(cumtrapz(tapp_SW, vX_e));
    %     dZ_e = abs(cumtrapz(tapp_SW, vZ_e));
    %     Stride_X(j) = dX_e(end);                               %Horizontal Displacement
    %     Stride_Z(j) = max((dZ_e));                             %Stride Height
    %     STL(j)   = sqrt(Stride_X(j).^2+Stride_Z(j).^2);        %Stride Length
    %     L4(1)    = 0;
    %     L4(j+1)  = length(dX_e);
    %     L5       = sum(L4(1:j));
    %     L6       = sum(L4);
    %     dX_tot((L5+1):L6,:) = dX_e+sum(dX_init(1:j));
    %     dZ_tot((L5+1):L6,:) = dZ_e+sum(dZ_init(1:j));
    %     if j<features.GSTRD
    %         Vx(j)  = Stride_X(j)/(ts(T_start(j+1))-ts(T_start(j))); %Horizontal velocity
    %         Vz(j)  = Stride_Z(j)/(ts(T_start(j+1))-ts(T_start(j))); %Vertical velocity
    %         V(j)   = STL(j)/(ts(T_start(j+1))-ts(T_start(j)));      %Stride Velocity
    %         dX_init(j+1) = dX_e(end);
    %         dZ_init(j+1) = dZ_e(end);
    %         dX_tot((L6+1):end) = dX_e(end);
    %     end
    %     if j<features.GSTRD
    %     end
    % end
    % GLength     = sum(Stride_X);            %Gait Length
    % features.GSTRD_H     = mean(Stride_Z);           %P05:STRIDE HEIGHT
    % features.GSTRD_HSD   = std(Stride_Z);            %P06:SD OF STRIDE HEIGHT
    % GSL         = mean(STL(1:end-1));       %mean Stride Length
    % GVel        = mean(V);                  %mean Gait Velocity

end

features.GT = round(features.GT*100)/100;
features.GVEL = round(features.GVEL*100)/100;
features.GSTRD_L = round(features.GSTRD_L*100)/100;
% features.GSTRD_H = round(features.GSTRD_H*1000)/1000;
% features.GSTRD_HSD = round(features.GSTRD_HSD*1000)/1000;
features.GSTRDT = round(features.GSTRDT*100)/100;
features.GSTRDT_SD = round(features.GSTRDT_SD*100)/100;
features.GSWT = round(features.GSWT*100)/100;
features.GSWT_SD = round(features.GSWT_SD*100)/100;
features.GSTT = round(features.GSTT*100)/100;
features.GSTT_SD = round(features.GSTT_SD*100)/100;
features.GRS = round(features.GRS*100)/100;
features.GEXC = round(features.GEXC*100)/100;
features.GEXC_SD = round(features.GEXC_SD*100)/100;
% features.GLAT = round(features.GLAT*100)/100;
end
