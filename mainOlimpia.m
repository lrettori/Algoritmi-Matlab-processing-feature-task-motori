clear
close all

extractRawData;

switch exercise
    case {'FTAP', 'THFv', 'THFa', 'OPCv', 'OPCa', 'PSUP', 'TTHP', 'HTTP'}
%         features = fHmotor2_modified(directory,filename,hand_N,trial,data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne,exercise,side);
        features = featureExtraction_repMovementTasks(data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne,exercise,side);
        
    case {'POST', 'HRST', 'FRST'}
        featuresDx = fAllTremorTasks(ts,data_ax_Dx,data_ay_Dx,data_az_Dx,data_wx_Dx,data_wy_Dx,data_wz_Dx,fs_daphne,exercise);
        featuresSx = fAllTremorTasks(ts,data_ax_Sx,data_ay_Sx,data_az_Sx,data_wx_Sx,data_wy_Sx,data_wz_Sx,fs_daphne,exercise);

    case {'KINT'}
        features = fAllTremorTasks(ts,data_ax,data_ay,data_az,data_wx,data_wy,data_wz,fs_daphne,exercise);

    case 'HETO'
        features = fFmotorHETO_modified(data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne);
    
    case 'HEHE'
        features = fFmotorHE_modified(data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne);
        
    case 'GTAS'
        featuresLeftHand = fHmotor0_modified(data_LH,ts,fs_daphne,'left hand');
        featuresRightHand = fHmotor0_modified(data_RH,ts,fs_daphne,'right hand');
        featuresLeftFoot = fFmotorGAIT_modified(data_LF,ts,fs_daphne,'left foot');
        featuresRightFoot = fFmotorGAIT_modified(data_RF,ts,fs_daphne,'right foot'); 

    case 'ROTA'
        features = fFmotorROTA_modified(side,data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne);
        
    case 'STUP'
        features = fFmotorSU_modified(data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne);
    
end


switch exercise
    case {'POST', 'HRST', 'FRST'}
        featuresRearrangedSx = rearrangeFeaturesForComparison(featuresSx,exercise);
        featuresRearrangedDx = rearrangeFeaturesForComparison(featuresDx,exercise);

    case 'GTAS'
        featuresRearranged = rearrangeFeaturesGait(featuresLeftHand,featuresRightHand,featuresLeftFoot,featuresRightFoot);

    otherwise
        featuresRearranged = rearrangeFeaturesForComparison(features,exercise);
end









% extractRawDataFTAP;
% [features] = fHmotor2_modified(directory,filename,hand_N,trial,data2_ax,data2_ay,data2_az,data2_wx,data2_wy,data2_wz,ts,fs_daphne,exercise);


% extractRawDataHETO;
% [features] = fFmotorHETO_modified(directory,filename,data2_ax,data2_ay,data2_az,data2_wx,data2_wy,data2_wz,ts,fs_daphne);


% extractRawDataHEHE;
% [features] = fFmotorHE_modified(directory,filename,trial,data_ax,data_ay,data_az,data_wx,data_wy,data_wz,ts,fs_daphne,exercise);


% extractRawDataHRST;
% extractRawDataFRST;
% extractRawDataKINT;
% extractRawDataPOST;
% features = fAllTremorTasks(ts,data_ax,data_ay,data_az,data_wx,data_wy,data_wz,fs_daphne,exercise);





% [vel10,vel10SD,exc10,exc10SD,dec10B,dec10M,dec10E,hes10,int10,frz10,...
%           taps,exc,excSD,wo,woSD,wc,wcSD,IAV,hes,int,frz,decB,decM,decE] = fHmotor2(directory,filename,hand_N,trial,data2_ax,data2_ay,data2_az,data2_wx,data2_wy,data2_wz,ts,fs_daphne,exercise);

% [taps,exc_t,exc_tSD,exc_h,exc_hSD,wt,wtSD,wh,whSD,IAV,fHH,fTT,hes] = ...
%     fFmotorHETO_modified(directory,filename,data2_ax,data2_ay,data2_az,data2_wx,data2_wy,data2_wz,ts,fs_daphne);

% [vel10,vel10SD,exc10,exc10SD,dec10B,dec10M,dec10E,hes10,taps,exc,excSD,vo,voSD,vc,vcSD,IAV,hes,decB,decM,decE,fundfreq,power,fundpeak] = ...
%           fFmotorHE_modified(directory,filename,trial,data_ax,data_ay,data_az,data_wx,...
%           data_wy,data_wz,ts,fs_daphne,exercise);




%% Non più utili
% [featuresA] = fFRTremor_A_modified(directory,filename,ts,data_ax,data_ay,data_az,fs_daphne,exercise);
% [featuresG] = fFRTremor_G_modified(directory,filename,ts,data_wx,data_wy,data_wz,fs_daphne,exercise);
% [featuresA] = fHTremor_A_modified(directory,filename,ts,data_ax,data_ay,data_az,data_wx,fs_daphne,exercise);
% [featuresG] = fHTremor_G_modified(directory,filename,ts,data_wx,data_wy,data_wz,fs_daphne,exercise);

% [featuresA2] = fFRTremor_A_modified_OLD(directory,filename,ts,data_ax,data_ay,data_az,fs_daphne,exercise);
% [featuresG2] = fFRTremor_G_modified_OLD(directory,filename,ts,data_wx,data_wy,data_wz,fs_daphne,exercise);
