function offset = offsetCalculation(gyrDataVector,timeVector,timeStart,timeStop)

% Calcolo dell'offset di un segnale proveniente dal giroscopio, come la
% media dei valori compresi tra i due istanti indicati dagli input
% timeStart e timeStop. Filtro i valori del segnale che possono essere
% riconducibili a spike indesiderati o false partenze.
% Il filtraggio è ottenuto non considerando quei valori che si discostano
% troppo dal picco della distribuzione del segnale all'interno
% dell'intervallo di riferimento.
[~,indexTimeStart] = min(abs(timeVector-timeStart));
[~,indexTimeStop] = min(abs(timeVector-timeStop));

% Filtro eventuali false partenze o spike nei segnali
gyrDataVectorIntervalExtraction = gyrDataVector(indexTimeStart:indexTimeStop);

% [histCountW,histValW] = hist(gyrDataVectorIntervalExtraction,1000);
[histCountW,histValW] = hist(gyrDataVectorIntervalExtraction,length(gyrDataVectorIntervalExtraction));

% Calcolo il picco dell'istogramma per le tre misure, e ricavo l'offset
% come la media dei valori che ricadono in un intervallo pari a +-4 intorno
% a quel valore (false partenze e spike raggiungono valori molto più
% elevati, e quindi vengono filtrati via)
[~,maxPosW] = max(histCountW);
peakHistW = histValW(maxPosW);

offset = mean(gyrDataVectorIntervalExtraction(gyrDataVectorIntervalExtraction > peakHistW - 4 & gyrDataVectorIntervalExtraction < peakHistW + 4));













 end