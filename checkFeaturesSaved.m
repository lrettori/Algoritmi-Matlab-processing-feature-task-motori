% Importare nell'array features tutte quelle esportate dal file excel, per
% la verifica della loro corrispondenza con quelle calcolate

% featuresNumber = [20, 20, 20, 20, 20, 20, 9, 45, 9, 20, 50, 20, 13, 45, 41, 5, 1];
featuresNumber = [20, 20, 20, 20, 20, 20, 9, 45, 9, 20, 5, 20, 13, 45]; % Versione senza GTAS, ROTA e STUP
featuresOutput = zeros(sum(featuresNumber), 4);

indexFeaturesOutput = 1;
indexFeaturesInput = 1;
for ii = 1:length(featuresNumber)
    for jj = 1:featuresNumber(ii)
        % Dx Ex1 and Ex2
        featuresOutput(indexFeaturesOutput + jj - 1,1) = features(indexFeaturesInput);
        indexFeaturesInput = indexFeaturesInput + 1;

        featuresOutput(indexFeaturesOutput + jj - 1,2) = features(indexFeaturesInput);
        indexFeaturesInput = indexFeaturesInput + 1;
    end

    if (ii ~= 15 && ii ~= 17)
        for jj = 1:featuresNumber(ii)
            % Sx Ex1 and Ex2
            featuresOutput(indexFeaturesOutput + jj - 1,3) = features(indexFeaturesInput);
            indexFeaturesInput = indexFeaturesInput + 1;

            featuresOutput(indexFeaturesOutput + jj - 1,4) = features(indexFeaturesInput);
            indexFeaturesInput = indexFeaturesInput + 1;
        end
    end

    indexFeaturesOutput = indexFeaturesOutput + featuresNumber(ii);
end
