%% Magnitude calculation for an input sensor, acceleration or angular velocity

function [magnitude] = MagnitudeCalculation (inputRaw, sensorIndex, acc_or_gyr)

% Selection of the correct sensor data, defined by sensorIndex
firstColumn = sensorIndex * 6 + 1;
lastColumn = (sensorIndex + 1) * 6;


if strcmp(acc_or_gyr,'acc')
    lastColumn = lastColumn - 3;
    sensorData = inputRaw.data(:, firstColumn : lastColumn);

elseif strcmp(acc_or_gyr,'gyr')
    firstColumn = firstColumn + 3;
    sensorData = inputRaw.data(:, firstColumn : lastColumn);

else
    error('Select acc or gyr as type of sensor data input')
end


x = [sensorData(:,1), sensorData(:,2), sensorData(:,3)];
magnitude = vecnorm(x,2,2);

end