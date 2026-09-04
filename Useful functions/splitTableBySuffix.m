%% Presa in ingresso una tabella con tutte le feature relative ad acquisizioni motorie (dataset Olimpia), restituisce due tabelle, dividendo le features relative alla prima e alla seconda acquisizione
function [table_1, table_2, labels1, labels2] = splitTableBySuffix(tableIn)

    % Controllo input
    if ~istable(tableIn)
        error('Input must be a table');
    end

    varNames = tableIn.Properties.VariableNames;

    % Identificazione colonne che terminano con _1 e _2
    idx1 = endsWith(varNames, '_1');
    idx2 = endsWith(varNames, '_2');

    % Creazione tabelle di output mantenendo tutte le righe
    table_1 = tableIn(:, idx1);
    table_2 = tableIn(:, idx2);
    labels1 = table_1.Properties.VariableNames;
    labels2 = table_2.Properties.VariableNames;

end