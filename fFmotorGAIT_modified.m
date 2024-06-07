function [GT,GSTRD,GVEL,GSTRD_L,GSTRD_H,GSTRD_HSD,GSTRDT,GSTRDT_SD,GSWT,...
            GSWT_SD,GSTT,GSTT_SD,GRS,GEXC,GEXC_SD,GLAT] = ...
            fFmotorGAIT(directory,filename,foot,trial,fdata_ax,fdata_ay,fdata_az,...
             fdata_wx,fdata_wy,fdata_wz,ts,fs_daphne,exercise)

ax_i = mean(fdata_ax(200:300));
ay_i = mean(fdata_ay(200:300));
az_i = mean(fdata_az(200:300));
teta_i_rad = atan(ax_i/az_i);       %teta_i è negativo
teta0_deg  = -teta_i_rad*180/pi;    %angolo di inclinazione frontale a riposo rispetto alla verticale assoluta (asse Z)
fdata_wy = fdata_wy - mean(fdata_wy(100:200));
 plot_title = strcat(directory,'-',filename);
%  figure; plot(ts,fdata_ax, 'm.-'); 
%  hold on; plot(ts,fdata_ay, 'c.-');
%  hold on; plot(ts,fdata_az, 'g.-'); 
 figure; %plot(ts,fdata_wx, 'r.-');
  hold on; plot(ts,fdata_wy, 'b.-');title(plot_title);
%    hold on; plot(ts,fdata_wz, 'g.-');
%
% SIGNAL SEGMENTATION
THRE  =  -30;      %  °/s, quando supero questa soglia è iniziato il movimento
TH_t =  -10;        %  °/s, soglia effettiva di T_start    
k   =   301;
p   =   length(ts);
st  =   1;
step    = 0;
while(k<=p)
switch(st)
    case 1
        if (fdata_wy(k)<THRE)
            app = k;
%              hold on; plot(ts(k),fdata_wx(k), 'ko');
            flag = 1;
            while(flag)
                app = app - 1;
                if (fdata_wy(app)>TH_t)
                    step = step + 1;        %inizia un nuovo passo
                    T_start(step) = app;
                    hold on; plot(ts(T_start),fdata_wy(T_start), 'go');
                    flag = 0;
                    st = 2;
                end
            end
        end
    case 2
        if (fdata_wy(k)>TH_t && fdata_wy(k)<fdata_wy(k+1))
            T_TO(step) = k;
            hold on; plot(ts(T_TO),fdata_wy(T_TO), 'mo');
            st = 3;
        end
    case 3
        if (fdata_wy(k)<-TH_t  && fdata_wy(k)>fdata_wy(k+1))
            T_HS(step) = k;
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
k   =   k+1;
end
% completo il passo con l'identificazione dell'ultimo T_end 
start = length(T_start);

if length(T_end)<start
   k = 1000;
   p   =   length(ts);
   THRE=30;TH_t=5;
   found = 0;
   while(p>=k)
        if (fdata_wy(p)>THRE)
            app = p;
            %    hold on; plot(ts(k),fdata2_wy(k), 'ko');
            flag = 1;
            while(flag)
                app = app + 1;
                if (fdata_wy(app)<TH_t)
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
    flag1 = 0;
    found1 = 0;
while(k1<=p1)
        if (fdata_wy(k1)<thre && fdata_wy(k1)>fdata_wy(k1+1) && fdata_wy(k1+1)<fdata_wy(k1+2))
            app1 = k1;
            %    hold on; plot(ts(k),fdata2_wy(k), 'ko');
            flag1 = 1;
            while(flag1)
%                 app1 = app1 - 1;
%                 if (fdata_wy(app1)<TH_t)
                    T_HS(tto) = app1;
                    hold on; plot(ts(T_HS),fdata_wy(T_HS), 'co');
                    flag1 = 0;
                    found1 = 1;
                    break
%                 end
            end
        end
        if found1 == 1
            break
        end
        k1 = k1+1;
end 
end


%FEATURES EXTRACTION
if  (step == 0 || step == 1)        
    GSTRD = 0; GT = 0; GVEL = 0; GSTRD_L = 0; GSTRD_H = 0; GSTRD_HSD = 0; GSTRDT = 0;
    GSTRDT_SD = 0; GSWT = 0; GSWT_SD = 0; GSTT = 0; GSTT_SD = 0; GRS = 0;
    GEXC = 0; GEXC_SD = 0; GLAT = 0;
else
    GSTRD          = length(T_end);                        %P02:NUMBER OF STRIDES
    GT             = ts(T_end(end))-ts(T_start(1));        %P01:TIME
    GVEL           = 15/GT;                                %P03:MEAN VELOCITY
    GLAT           = ts(T_start(1))-ts(300);               %P16:LATENCY TIME
    if foot == 1
        GSTRD = GSTRD-1;
        T_start = T_start(2:end);
        T_TO    = T_TO(2:end);
        T_HS    = T_HS(2:end);
        T_end   = T_end(2:end);
    end
    GSTRD_L        = 15/GSTRD;                             %P04:MEAN STRIDE LENGTH
%     GF             = GSTRD / GT;                           %frequenza in passi al secondo
    Stride_Time    = diff(ts(T_HS));                       %tempo tra due appoggi successivi del tallone dello stesso piede
    GSTRDT         = mean(Stride_Time);                    %P07:STRIDE TIME
    GSTRDT_SD      = std(Stride_Time);                     %P08:SD OF STRIDE TIME                
    if length(T_TO)>length(T_HS)
        T_TO = T_TO(1:length(T_HS));
    end
    T_Swing        = ts(T_HS(2:end))-ts(T_TO(2:end));      %tempo di volo per passo
    GSWT           = mean(T_Swing);                        %P09:SWING TIME
    GSWT_SD        = std(T_Swing);                         %P10:SD OF SWING TIME
    T_Stance       = Stride_Time - T_Swing;                %tempo con piede appoggiato a terra per passo
    GSTT           = mean(T_Stance);                       %P11:STANCE TIME
    GSTT_SD        = std(T_Stance);                        %P12:SD OF STANCE TIME
    Rel_St         = (T_Stance./GSTRDT);                   %tempo di stance relativo
    GRS            = mean(Rel_St)*100;                     %P13:RELATIVE STANCE

    %Calcolo dell'angolo di oscillazione alla caviglia nel piano sagittale
    for i=1:GSTRD
        wang  = -fdata_wy(T_start(i):T_end(i));
        tapp  = ts(T_start(i):T_end(i));
        ang   = cumtrapz(tapp, wang);
        teta_i_deg(1) = teta0_deg;
        ang_e = teta_i_deg(i) + ang;
        ang_e_rad = ang_e*pi/180;
        hold on; plot(tapp,ang_e, 'k.-');
        if i<GSTRD
            ax_i = mean(fdata_ax(T_end(i):T_start(i+1)));
            az_i = mean(fdata_az(T_end(i):T_start(i+1)));
            teta_i_rad = -atan(ax_i/az_i);
            teta_i_deg(i+1) = teta_i_rad*180/pi;                 %calcolo ad ogni passo l'angolo di partenza
            mang = (teta_i_deg(i+1)-ang_e(end))/(ts(T_start(i+1))-ts(T_end(i))); qang = ang_e(end)-mang*ts(T_end(i));
            ang_e2 = mang*ts(T_end(i):T_start(i+1))+qang;
            hold on; plot(ts(T_end(i):T_start(i+1)),ang_e2,'g.-');
            L1(1)    = 0;
            L1(i+1)  = length(ang_e)+length(ang_e2)-2;
            L2       = sum(L1(1:i));
            L3       = sum(L1);
            ANG((L2+1):L3,:) = [ang_e(2:end);(ang_e2(2:end)).'];
        else
            L1(i+1)  = length(ang_e);
            L2       = sum(L1(1:i));
            L3       = sum(L1);
            ANG((L2+1):L3,:) = ang_e;
        end
         Max_ang(i) = max(ang_e);
         Min_ang(i) = min(ang_e);
         Ang(i) = Max_ang(i)-Min_ang(i);
    end
    GEXC = mean(Ang(1:end-1));      %P14:ANGULAR EXCURSION
    GEXC_SD = std(Ang(1:end-1));    %P15:SD OF ANGULAR EXCURSION
    %   figure; 

%Calcolo dei parametri spaziali della camminata
    dX_init = 0;
    dZ_init = 0;
    for j = 1: GSTRD
        wang_SW = -fdata_wy(T_start(j):T_end(j));
        tapp_SW = ts(T_start(j):T_end(j));
        ang_SW  = cumtrapz(tapp_SW, wang_SW);
        ang_eSW = -teta_i_deg(j) + ang_SW;
        ang_eradSW = ang_eSW*pi/180;
        %Proiezioni delle componenti orizzontali e verticali delle
        %accelerazioni nel sistema di riferimento assoluto XYZ
        aX = (fdata_az(T_start(j):T_end(j)).*sin(ang_eradSW)-fdata_ax(T_start(j):T_end(j)).*cos(ang_eradSW));
        aZ = (fdata_az(T_start(j):T_end(j)).*cos(ang_eradSW)+fdata_ax(T_start(j):T_end(j)).*sin(ang_eradSW))-9.81;
    %     figure; plot(tapp_SW,aX,'g',tapp_SW,aZ,'k');
        vX = cumtrapz(tapp_SW, aX);
        vZ = cumtrapz(tapp_SW, aZ);
%     %     figure; plot(tapp_SW,vX,'g.',tapp_SW,vZ,'k.');
        mx = (vX(end)-vX(1))/(tapp_SW(end)-tapp_SW(1)); qx = vX(1)-mx*tapp_SW(1);
        errlvx = mx*tapp_SW+qx;
        vX_e = vX - errlvx';
        mz = (vZ(end)-vZ(1))/(tapp_SW(end)-tapp_SW(1)); qz = vZ(1)-mz*tapp_SW(1);
        errlvz = mz*tapp_SW+qz;
        vZ_e = vZ - errlvz';
%     %     hold on; plot(tapp_SW,vX_e,'g*',tapp_SW,vZ_e,'k*');
% %         dX = cumtrapz(tapp_SW, vX);  
% %         dZ = cumtrapz(tapp_SW, vZ);
%     %     figure; plot(tapp_SW,dX,'g.-',tapp_SW,dZ,'k.-');    
        dX_e = abs(cumtrapz(tapp_SW, vX_e));  
        dZ_e = abs(cumtrapz(tapp_SW, vZ_e));
%     %     hold on; plot(tapp_SW,dX_e,'g*-',tapp_SW,dZ_e,'k*-');
        Stride_X(j) = dX_e(end);                               %Horizontal Displacement
        Stride_Z(j) = max((dZ_e));                             %Stride Height
        STL(j)   = sqrt(Stride_X(j).^2+Stride_Z(j).^2);        %Stride Length
                L4(1)    = 0;
                L4(j+1)  = length(dX_e);
                L5       = sum(L4(1:j));
                L6       = sum(L4);
        dX_tot((L5+1):L6,:) = dX_e+sum(dX_init(1:j));
        dZ_tot((L5+1):L6,:) = dZ_e+sum(dZ_init(1:j));
        if j<GSTRD
            Vx(j)  = Stride_X(j)/(ts(T_start(j+1))-ts(T_start(j))); %Horizontal velocity
            Vz(j)  = Stride_Z(j)/(ts(T_start(j+1))-ts(T_start(j))); %Vertical velocity
            V(j)   = STL(j)/(ts(T_start(j+1))-ts(T_start(j)));      %Stride Velocity
            dX_init(j+1) = dX_e(end);
            dZ_init(j+1) = dZ_e(end);            
            dX_tot((L6+1):end) = dX_e(end);
        end 
% %         subplot(2,1,1);hold on; plot(ts(T_start(j):T_end(j)),dX_tot((L5+1):L6,:));
        if j<GSTRD
% %             hold on; plot(ts(T_end(j):T_start(j+1)),dX_tot(L6:end),'g-');
        end
%         subplot(2,1,2);hold on; plot(dX_tot,dZ_tot,'r.-');
    end
GLength     = sum(Stride_X);            %Gait Length
GSTRD_H     = mean(Stride_Z);           %P05:STRIDE HEIGHT
GSTRD_HSD   = std(Stride_Z);            %P06:SD OF STRIDE HEIGHT
GSL         = mean(STL(1:end-1));       %mean Stride Length
GVel        = mean(V);                  %mean Gait Velocity

end
 GT = round(GT*100)/100;
 GVEL = round(GVEL*100)/100;
 GSTRD_L = round(GSTRD_L*100)/100;
 GSTRD_H = round(GSTRD_H*1000)/1000;
 GSTRD_HSD = round(GSTRD_HSD*1000)/1000;
 GSTRDT = round(GSTRDT*100)/100;
 GSTRDT_SD = round(GSTRDT_SD*100)/100;
 GSWT = round(GSWT*100)/100;
 GSWT_SD = round(GSWT_SD*100)/100;
 GSTT = round(GSTT*100)/100;
 GSTT_SD = round(GSTT_SD*100)/100;
 GRS = round(GRS*100)/100;
 GEXC = round(GEXC*100)/100;
 GEXC_SD = round(GEXC_SD*100)/100;
 GLAT = round(GLAT*100)/100;
end
