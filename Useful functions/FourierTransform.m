%% FFT calculation and plot

function FourierTransform (inputSignal, fs, plotYesNo)

nSamples = length(inputSignal);
NFFT = 2^nextpow2(nSamples);

% Windowing
w = hann(nSamples);
U = sum(w.^2);

% FFT calculation with windowing
X = fft(w .* inputSignal, NFFT);

% two-sided PSD (periodogram)
P2 = (abs(X).^2) / (fs * U);

% single-sided PSD
P1 = P2(1:NFFT/2+1);
P1(2:end-1) = 2*P1(2:end-1);

% Frequency vector
fVec = fs*(0:(NFFT/2))/NFFT;

if plotYesNo == "plotYes"
    figure; plot(fVec,P1);
    xlabel('Frequency [Hz]');
    ylabel('PSD [units^2/Hz]');
end







end