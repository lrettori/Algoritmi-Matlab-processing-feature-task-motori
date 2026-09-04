%% Calculates the one-sided STFT of the inputSignal, plotting the result if requested

function [s, f, t] = ShortTimeFourierTransform (inputSignal, fs, windowLength, FFTLength, plotYesNo, varargin)

[s, f, t] = stft(inputSignal, fs, Window = hann(windowLength), FFTLength = FFTLength, FrequencyRange = "onesided");

if plotYesNo == "plotYes"
    figure; pcolor(t,f,(abs(s))); shading flat; colorbar;
    xlabel('Time [s]');
    ylabel('Frequency [Hz]');

    % Title definition, if requested
    titleStr = "";

    if nargin >= 6 % if the sensor number has been defined in input
        sensorIndex = varargin{1};
        titleStr = ['sensor', num2str(sensorIndex)];
    end

    if nargin >= 7 % if the type of sensor input (acc, gyr, magnitude, or other)
        extraStr = varargin{2};
        if titleStr ~= ""
            titleStr = [titleStr, ', ', extraStr];
        else
            titleStr = extraStr;
        end
    end

    if titleStr ~= ""
        sgtitle(titleStr);
    end

end

end
