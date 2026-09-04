%% Funzione per eliminare le features sulle prime 10 ripetizioni dal database Olimpia

function [tableOut, labelsOut] = removeColumnsContaining10(tableIn)

    % Controllo input
    if ~istable(tableIn)
        error('Input must be a table');
    end

    varNames = tableIn.Properties.VariableNames;

    % Identificazione colonne che contengono '10'
    idxRemove = contains(varNames, '10');

    % Rimozione colonne
    tableOut = tableIn(:, ~idxRemove);
    labelsOut = tableOut.Properties.VariableNames;

end
