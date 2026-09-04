close all
clear

% Caricamento dei dati
path = "C:\Users\loren\OneDrive - unifi.it\Documents\Unifi\Ricerca\1_Explainable AI\Applicazioni\";
filename = "data_motor_features_upperAllCSV_noCorr_noKINT_HRSTred.csv";

featuresTable = readtable(strcat(path, "\", filename));

threshold = 0.85;
% Estraggo solo le feature
X = featuresTable{:, 3:end};   % 171 x 144
featureNames = featuresTable.Properties.VariableNames(3:end);

% % Correlazione di Pearson
% R_all = corr(X, 'Type', 'Pearson', 'Rows', 'pairwise');

% Correlazione di Spearman nel caso di distribuzioni non gaussiane o
% outlier rilevanti
R_all = corr(X, 'Type', 'Spearman', 'Rows', 'pairwise');

figure
h = heatmap(featureNames, featureNames, R_all, ...
    'Colormap', parula, ...
    'ColorLimits', [-1 1]);

title('All Tasks - Both Hands')
h.CellLabelColor = 'none';   % evita sovraffollamento numerico
h.FontSize = 6;



% Preallocazione strutture
hand = strings(size(featureNames));
task = strings(size(featureNames));
feat = strings(size(featureNames));  % nome interno feature

for i = 1:length(featureNames)
    parts = split(featureNames{i}, "_");
    hand(i) = extractBefore(parts{1}, 3);  % HR o HL
    task(i) = parts{2};
    if (length(parts)) < 5
        feat(i) = parts{3};                  % nome feature
    else
        feat(i) = strcat(parts{3},"_",parts{4});      % HRST e FRST
    end
end

baseFeatures = unique(feat, 'stable');
nF = length(baseFeatures);
CorrSummary = cell(nF, nF);

uniqueHands = unique(hand);
uniqueTasks = unique(task);


for hIdx = 1:length(uniqueHands)
    for tIdx = 1:length(uniqueTasks)

        idx = hand == uniqueHands(hIdx) & ...
              task == uniqueTasks(tIdx);

        if sum(idx) > 1

            X_sub = featuresTable{:, find(idx) + 2};
            subNames = featureNames(idx);
            subFeat = feat(idx);

            % ----------------------
            % R = corr(X_sub, 'Type', 'Spearman', 'Rows', 'pairwise');
            % 
            % figure
            % hm = heatmap(subNames, subNames, R, ...
            %     'Colormap', parula, ...
            %     'ColorLimits', [-1 1],'Interpreter','none');
            % 
            % title(sprintf('Task: %s  |  Hand: %s', ...
            %     uniqueTasks(tIdx), uniqueHands(hIdx)))
            % 
            % hm.CellLabelColor = 'none';
            % hm.FontSize = 8;
            % ----------------------



            % ----------------------
            % R = corr(X_sub, 'Type', 'Pearson', 'Rows', 'pairwise');
            R = corr(X_sub, 'Type', 'Spearman', 'Rows', 'pairwise');

            % Solo metà matrice
            R_plot = R;
            R_plot(tril(true(size(R)), -1)) = NaN;
            figure
            h = imagesc(R_plot);
            set(h, 'AlphaData', ~isnan(R_plot))
            
            % imagesc(R)
            colormap(parula)
            clim([-1 1])
            colorbar

            xticks(1:length(subNames))
            yticks(1:length(subNames))
            xticklabels(subNames)
            yticklabels(subNames)

            set(gca, 'TickLabelInterpreter', 'none');

            xtickangle(90)

            title(sprintf('Task: %s  |  Hand: %s', ...
                uniqueTasks(tIdx), uniqueHands(hIdx)))

            axis square
            hold on

            for i = 1:size(R,1)
                for j = 1:size(R,2)

                    % if i ~= j && abs(R(i,j)) > threshold
                    if j > i && abs(R(i,j)) > threshold || abs(R(i,j)) < -threshold

                        text(j, i, sprintf('%.2f', R(i,j)), ...
                            'HorizontalAlignment','center', ...
                            'Color','k', ...
                            'FontSize',8, ...
                            'FontWeight','bold');
                    end

                end
            end

            hold off


            % ciclo solo upper triangle
            for i = 1:length(subFeat)
                for j = i+1:length(subFeat)

                    if abs(R(i,j)) > threshold

                        % indici nella matrice globale
                        row = find(baseFeatures == subFeat(i));
                        col = find(baseFeatures == subFeat(j));

                        entry = sprintf('%s_%s = %.2f', ...
                                uniqueHands(hIdx), ...
                                uniqueTasks(tIdx), ...
                                R(i,j));

                        if isempty(CorrSummary{row,col})
                            CorrSummary{row,col} = entry;
                        else
                            CorrSummary{row,col} = sprintf('%s; %s', ...
                                CorrSummary{row,col}, entry);
                        end

                    end
                end
            end



            % ----------------------


        end
    end
end

CorrTable = cell2table(CorrSummary, ...
'VariableNames', baseFeatures, ...
'RowNames', baseFeatures);

% R_struct = struct;
% 
% for h = 1:length(uniqueHands)
%     for t = 1:length(uniqueTasks)
% 
%         idx = hand == uniqueHands(h) & task == uniqueTasks(t);
% 
%         if sum(idx) > 1   % serve almeno 2 feature
%             X_sub = featuresTable{:, find(idx) + 2};
% 
%             R = corr(X_sub, 'Type', 'Pearson', 'Rows', 'pairwise');
% 
%             fieldName = uniqueHands(h) + "_" + uniqueTasks(t);
%             R_struct.(fieldName) = R;
%         end
%     end
% end

% %% Rimozione duplicati
% threshold = 0.85;
% 
% R = abs(R);  
% R(logical(eye(size(R)))) = 0;  % azzero diagonale
% 
% toRemove = false(1, size(R,1));
% 
% for i = 1:size(R,1)
%     if ~toRemove(i)
%         correlated = find(R(i,:) > threshold);
%         toRemove(correlated) = true;
%     end
% end
% 
% X_filtered = X_sub(:, ~toRemove);
% 
