function featuresRearranged = rearrangeFeaturesForComparison(features,exercise)

switch exercise

    case {"THFv", "THFa", "FTAP", "OPCv", "OPCa", "PSUP", "TTHP", "HTTP"}
        featuresRearranged = [features.vel10, features.vel10SD, features.exc10, features.exc10SD, features.dec10B, features.dec10M, features.dec10E, features.int10, features.taps, features.exc, ...
            features.excSD, features.wo, features.woSD, features.wc, features.wcSD, features.IAV, features.int, features.decB, features.decM, features.decE];

    case {"POST", "KINT"}
        featuresRearranged = [features.Perc1A, features.Perc1G, features.Perc2A, features.Perc2G, features.PwrA, features.PwrG, features.freqA, features.freqG, features.IAV];

    case {"HRST", "FRST"}
        for ii = 1:5
            featuresRearranged((ii-1)*9 + 1 : (ii-1)*9 + 9) = [features.Perc1A(ii), features.Perc1G(ii), features.Perc2A(ii), features.Perc2G(ii), features.PwrA(ii), features.PwrG(ii), features.freqA(ii), features.freqG(ii), features.IAV(ii)];
        end

    case "HEHE"
        featuresRearranged = [features.taps, features.fundfreq, features.power, features.fundpeak, features.IAV];

    case "HETO"
        featuresRearranged = [features.taps, features.exc_t, features.exc_tSD, features.exc_h, features.exc_hSD, features.wt, features.wtSD,features.wh, features.whSD, features.IAV, features.fTT, features.fHH, features.hes];

    case "ROTA"
        featuresRearranged = [features.time, features.numbOfStrides, features.frequency, features.stanceTime, features.relStanceTime];
        
    case "STUP"
        featuresRearranged = features.time;

end

featuresRearranged = featuresRearranged';