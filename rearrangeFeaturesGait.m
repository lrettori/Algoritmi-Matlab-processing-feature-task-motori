function featuresRearranged = rearrangeFeaturesGait(featuresLeftHand,featuresRightHand,featuresLeftFoot,featuresRightFoot)

%% Piedi
GTAS_time = (featuresLeftFoot.GT + featuresRightFoot.GT)/2; % media tra i due piedi
GTAS_strides = featuresLeftFoot.GSTRD; % Considero il numero di stride del piede sinistro
GTAS_vel = (featuresLeftFoot.GVEL + featuresRightFoot.GVEL)/2; % media tra i due piedi

FR_GTAS_strLength = featuresRightFoot.GSTRD_L;
FL_GTAS_strLength = featuresLeftFoot.GSTRD_L;

FR_GTAS_strideTime = featuresRightFoot.GSTRDT;
FR_GTAS_strideTimeSD = featuresRightFoot.GSTRDT_SD;
FL_GTAS_strideTime = featuresLeftFoot.GSTRDT;
FL_GTAS_strideTimeSD = featuresLeftFoot.GSTRDT_SD;

FR_GTAS_swingTime = featuresRightFoot.GSWT;
FR_GTAS_swingTimeSD = featuresRightFoot.GSWT_SD;
FL_GTAS_swingTime = featuresLeftFoot.GSWT;
FL_GTAS_swingTimeSD = featuresLeftFoot.GSWT_SD;

FR_GTAS_stanceTime = featuresRightFoot.GSTT;
FR_GTAS_stanceTimeSD = featuresRightFoot.GSTT_SD;
FL_GTAS_stanceTime = featuresLeftFoot.GSTT;
FL_GTAS_stanceTimeSD = featuresLeftFoot.GSTT_SD;

FR_GTAS_relStanceTime = featuresRightFoot.GRS;
FL_GTAS_relStanceTime = featuresLeftFoot.GRS;

FR_GTAS_exc = featuresRightFoot.GEXC;
FR_GTAS_excSD = featuresRightFoot.GEXC_SD;
FL_GTAS_exc = featuresLeftFoot.GEXC;
FL_GTAS_excSD = featuresLeftFoot.GEXC_SD;

featuresRearranged = [GTAS_time, GTAS_strides, GTAS_vel, FR_GTAS_strLength, FL_GTAS_strLength, FR_GTAS_strideTime, FR_GTAS_strideTimeSD, FL_GTAS_strideTime, FL_GTAS_strideTimeSD, ...
                        FR_GTAS_swingTime, FR_GTAS_swingTimeSD, FL_GTAS_swingTime, FL_GTAS_swingTimeSD, FR_GTAS_stanceTime, FR_GTAS_stanceTimeSD, FL_GTAS_stanceTime, ...
                        FL_GTAS_stanceTimeSD, FR_GTAS_relStanceTime, FL_GTAS_relStanceTime, FR_GTAS_exc, FR_GTAS_excSD, FL_GTAS_exc, FL_GTAS_excSD];

%% Mani

HR_GTAS_taps = featuresRightHand.taps;
HL_GTAS_taps = featuresLeftHand.taps;

HR_GTAS_exc = featuresRightHand.exc;
HR_GTAS_excSD = featuresRightHand.excSD;
HL_GTAS_exc = featuresLeftHand.exc;
HL_GTAS_excSD = featuresLeftHand.excSD;

HR_GTAS_wf = featuresRightHand.wf;
HR_GTAS_wfSD = featuresRightHand.wfSD;
HL_GTAS_wf = featuresLeftHand.wf;
HL_GTAS_wfSD = featuresLeftHand.wfSD;

HR_GTAS_wb = featuresRightHand.wb;
HR_GTAS_wbSD = featuresRightHand.wbSD;
HL_GTAS_wb = featuresLeftHand.wb;
HL_GTAS_wbSD = featuresLeftHand.wbSD;

HR_GTAS_IAV = featuresRightHand.IAV;
HL_GTAS_IAV = featuresLeftHand.IAV;

featuresRearranged = [featuresRearranged, HR_GTAS_taps, HL_GTAS_taps, HR_GTAS_exc, HR_GTAS_excSD, HL_GTAS_exc, HL_GTAS_excSD, HR_GTAS_wf, HR_GTAS_wfSD, ...
    HL_GTAS_wf, HL_GTAS_wfSD, HR_GTAS_wb, HR_GTAS_wbSD, HL_GTAS_wb, HL_GTAS_wbSD, HR_GTAS_IAV, HL_GTAS_IAV];



featuresRearranged = featuresRearranged';

end