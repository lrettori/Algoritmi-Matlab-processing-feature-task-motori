%% Plot graphs for all axis of a single sensor
% firstImportRawData is the struct obtained by using the script
% extractRawData
% sensorIndex is an integer from 0 to 7

function PlotSensorGraphs (firstImportRawData, sensorIndices, ts)

for ii = 1:length(sensorIndices)
    firstColumn = sensorIndices(ii) * 6 + 1;
    lastColumn = (sensorIndices(ii) + 1) * 6;

    sensorData = firstImportRawData.data(:, firstColumn : lastColumn);
    time = ts;

    figure; sgtitle(['sensor', num2str(sensorIndices(ii))]);
    subplot(2,3,1); plot(time,sensorData(:,1)); title('Acc_x'); xlabel('time [s]'); ylabel('acc [m/s^2]');
    subplot(2,3,2); plot(time,sensorData(:,2)); title('Acc_y'); xlabel('time [s]'); ylabel('acc [m/s^2]');
    subplot(2,3,3); plot(time,sensorData(:,3)); title('Acc_z'); xlabel('time [s]'); ylabel('acc [m/s^2]');
    subplot(2,3,4); plot(time,sensorData(:,4)); title('Gyr_x'); xlabel('time [s]'); ylabel('ω [deg/s]');
    subplot(2,3,5); plot(time,sensorData(:,5)); title('Gyr_y'); xlabel('time [s]'); ylabel('ω [deg/s]');
    subplot(2,3,6); plot(time,sensorData(:,6)); title('Gyr_z'); xlabel('time [s]'); ylabel('ω [deg/s]');

end

end