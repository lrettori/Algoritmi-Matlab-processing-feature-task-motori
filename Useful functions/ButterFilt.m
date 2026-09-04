%% Butterworth filtering
% [filteredSignal] = ButterFilt(inputSignal, order, ft, fs, filterType)
% Filters the inputSignal using the filterType indicated ('high', 'low', or 'bandpass')
% order is the filter order
% ft is the cut-off frequency (or frequencies, for bandpass filter)
% fs is the sampling frequency of the input signal

function [filteredSignal] = ButterFilt(inputSignal, order, ft, fs, filterType)

if (length(ft) == 1 && (filterType == "low" || filterType == "high"))
    % Low-pass or high-pass filter, must have just one cut-off frequency
    wn = 2 * ft / fs;
    [b,a] = butter(order,wn,filterType);
    filteredSignal = filtfilt(b,a,inputSignal);

elseif ((length(ft)) == 2 && filterType == "bandpass")
    wn = 2 .* ft ./ fs;
    [b,a] = butter(order,wn,filterType);
    filteredSignal = filtfilt(b,a,inputSignal);

else

    error("filterType does not match the length of ft vector");
end