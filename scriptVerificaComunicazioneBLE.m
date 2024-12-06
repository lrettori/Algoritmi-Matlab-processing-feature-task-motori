%% Script per la verifica dei file txt ottenuti durante le prove di comunicazione tra moduli Bluetooth RIGADO BMD 350


clear all
close all

% Importo il file contenente i dati
[file,path] = uigetfile("*.txt","Seleziona il file dati da testare");
filename = strcat(path,file);
importedData = importdata(filename);

% Divido il file in matrici diverse per ogni sensore, e prelevo il vettore
% colonna counter (prima colonna, è un indice incrementale che identifica i
% pacchetti ricevuti dal BLE module Central)
% counter = importedData(:,1);
% sensor0 = importedData(:,2:7);
% sensor1 = importedData(:,8:13);
% sensor2 = importedData(:,14:19);
% sensor3 = importedData(:,20:25);
% sensor4 = importedData(:,26:31);
% sensor5 = importedData(:,32:37);
% sensor6 = importedData(:,38:43);
% sensor7 = importedData(:,44:49);

% Versione con bytesRead e er
time = importedData.textdata;
importedData = importedData.data;
counter = importedData(:,1);
bytesRead = importedData(:,2);
er = importedData(:,3);
sensor0 = importedData(:,4:9);
sensor1 = importedData(:,10:15);
sensor2 = importedData(:,16:21);
sensor3 = importedData(:,22:27);
sensor4 = importedData(:,28:33);
sensor5 = importedData(:,34:39);
sensor6 = importedData(:,40:45);
sensor7 = importedData(:,46:51);

% figure;subplot(2,1,1);plot(bytesRead); title('bytes in input buffer');
a = cellstr(time);
timeMatrix = zeros(length(time),4);
milliseconds = zeros(length(time),1);

for ii = 1:length(time)
timeMatrix(ii,:) = strsplit(string(a{ii}),":");
milliseconds(ii) = (timeMatrix(ii,1)-timeMatrix(1,1))*3600000+timeMatrix(ii,2)*60000+timeMatrix(ii,3)*1000+timeMatrix(ii,4);
end
milliseconds = milliseconds - milliseconds(1);
diffMs = diff(milliseconds);
subplot(2,1,2);plot(diffMs); title('ms between acquisitions');


% %% Gestione onde quadre tra 4382 e 31043
% firstValues = [sensor0(1,4), sensor1(1,1), sensor1(1,4), sensor2(1,1), sensor2(1,4), sensor3(1,4), sensor4(1,1), sensor4(1,4), sensor5(1,1), sensor5(1,4), sensor6(1,4), sensor7(1,4)];
% squareWaves = [sensor0(:,4), sensor1(:,1), sensor1(:,4), sensor2(:,1), sensor2(:,4), sensor3(:,4), sensor4(:,1), sensor4(:,4), sensor5(:,1), sensor5(:,4), sensor6(:,4), sensor7(:,4)];
% sawtoothWaves = [sensor0(:,2), sensor1(:,2), sensor1(:,5), sensor2(:,2), sensor2(:,5), sensor3(:,2), sensor4(:,2), sensor4(:,5), sensor5(:,2), sensor5(:,5), sensor6(:,2), sensor7(:,2)];
% 
% indOfFirstTransition = zeros(12,1);
% for ii = 1:12
%     if firstValues(ii) == 4382
%         [ind,~] = find(squareWaves(:,ii)== 31043);
%         indOfFirstTransition(ii) = ind(1);
%     else
%         [ind,~] = find(squareWaves(:,ii)== 4382);
%         indOfFirstTransition(ii) = ind(1);
%     end
% end
% 
% % Ricostruisco le onde quadre attese, per verificare che quelle ottenute
% % dai sensori siano coerenti
% signalLength = length(sensor0(:,1));
% expectedSquareWaves = zeros(signalLength,12);
% equality = zeros(12,1);
% 
% for jj = 1:12
%     for ii = 1:signalLength
%         if mod(fix(sawtoothWaves(ii,jj) / 10),2) == 0
%             expectedSquareWaves(ii,jj) = 4382;
%         else
%             expectedSquareWaves(ii,jj) = 31043;
%         end
%     end
%     equality(jj) = isequal(squareWaves(:,jj),expectedSquareWaves(:,jj));
% end



%%
diffCounter = diff(counter);
diffSensor0 = diff(sensor0);
diffSensor1 = diff(sensor1);
diffSensor2 = diff(sensor2);
diffSensor3 = diff(sensor3);
diffSensor4 = diff(sensor4);
diffSensor5 = diff(sensor5);
diffSensor6 = diff(sensor6);
diffSensor7 = diff(sensor7);

diffTotal = diff(importedData(:,2:end));

% Conto i pacchetti persi per ogni asse di ogni sensore
totalNumbOfLostPackets = zeros(48,1);
numbOfSkips = zeros(48,1);
positionOfLostPackets = {};

for ii = 1:48
    [a,b] = find(diffTotal(:,ii)>1);
    totalNumbOfLostPackets(ii) = sum((diffTotal(a,ii) - 1));  % QUI VA MODIFICATO, CONTO SOLO I DIFF>1 MA DEVO CONTARE ANCHE LE VOLTE IN CUI RICEVO VALORI CHE TORNANO INDIETRO (magari classificandoli in altro modo, non come lost)
    positionOfLostPackets{ii} = a;
    numbOfSkips(ii) = length(a);
end

timeVector = 0:0.01:0.01*(length(diffSensor0) - 1);


% figure;plot(timeVector,diffCounter); title("diffCounter"); xlabel("time (sec)")

% Filtro i salti dovuti al raggiungimento del massimo valore del vettore
diffSensor0ForPlot = diffSensor0; diffSensor0ForPlot(diffSensor0ForPlot == -65279 | diffSensor0ForPlot == -65535) = 1;
diffSensor1ForPlot = diffSensor1; diffSensor1ForPlot(diffSensor1ForPlot == -65279 | diffSensor1ForPlot == -65535) = 1;
diffSensor2ForPlot = diffSensor2; diffSensor2ForPlot(diffSensor2ForPlot == -65279 | diffSensor2ForPlot == -65535) = 1;
diffSensor3ForPlot = diffSensor3; diffSensor3ForPlot(diffSensor3ForPlot == -65279 | diffSensor3ForPlot == -65535) = 1;
diffSensor4ForPlot = diffSensor4; diffSensor4ForPlot(diffSensor4ForPlot == -65279 | diffSensor4ForPlot == -65535) = 1;
diffSensor5ForPlot = diffSensor5; diffSensor5ForPlot(diffSensor5ForPlot == -65279 | diffSensor5ForPlot == -65535) = 1;
diffSensor6ForPlot = diffSensor6; diffSensor6ForPlot(diffSensor6ForPlot == -65279 | diffSensor6ForPlot == -65535) = 1;
diffSensor7ForPlot = diffSensor7; diffSensor7ForPlot(diffSensor7ForPlot == -65279 | diffSensor7ForPlot == -65535) = 1;

labels = ["accX", "accY", "accZ", "gyrX", "gyrY", "gyrZ"];

figure;
subplot(2,3,1); hold on; title("diffSensor0"); xlabel("time (sec)")
for ii = 1 : 6
    plot(timeVector,diffSensor0ForPlot(:,ii),'DisplayName',labels(ii));
end
legend

subplot(2,3,2); hold on; title("diffSensor1"); xlabel("time (sec)")
for ii = 1 : 6
    plot(timeVector,diffSensor1ForPlot(:,ii),'DisplayName',labels(ii));
end
legend

subplot(2,3,3); hold on; title("diffSensor2"); xlabel("time (sec)")
for ii = 1 : 6
    plot(timeVector,diffSensor2ForPlot(:,ii),'DisplayName',labels(ii));
end
legend

subplot(2,3,4); hold on; title("diffSensor3"); xlabel("time (sec)")
for ii = 1 : 6
    plot(timeVector,diffSensor3ForPlot(:,ii),'DisplayName',labels(ii));
end
legend

subplot(2,3,5); hold on; title("diffSensor4"); xlabel("time (sec)")
for ii = 1 : 6
    plot(timeVector,diffSensor4ForPlot(:,ii),'DisplayName',labels(ii));
end
legend

subplot(2,3,6); hold on; title("diffSensor5"); xlabel("time (sec)")
for ii = 1 : 6
    plot(timeVector,diffSensor5ForPlot(:,ii),'DisplayName',labels(ii));
end
legend

figure;
subplot(1,2,1);hold on; title("diffSensor6"); xlabel("time (sec)")
for ii = 1 : 6
    plot(timeVector,diffSensor6ForPlot(:,ii),'DisplayName',labels(ii));
end
legend

subplot(1,2,2);hold on; title("diffSensor7"); xlabel("time (sec)")
for ii = 1 : 6
    plot(timeVector,diffSensor7ForPlot(:,ii),'DisplayName',labels(ii));
end
legend


%% Parte per il controllo di packetsSent e packetsReceived



packetsReceived = importedData(:,52:55);
packetsSent = importedData(:,56:59);


packetsReceived2 = zeros(size(packetsReceived));
counters = zeros(1,4);
for i =1:length(packetsReceived(:,1))-1
    for j = 1:4
        packetsReceived2(i,j) = packetsReceived(i,j) + counters(j)*256;
        if packetsReceived(i,j) - packetsReceived(i+1,j) > 240
            counters(j) = counters(j) + 1;
        end
    end
end


counters = zeros(1,4);
packetsSent2 = zeros(size(packetsSent));
for i =1:length(packetsSent(:,1))-1
    for j = 1:4
        packetsSent2(i,j) = packetsSent(i,j) + counters(j)*256;
        if packetsSent(i,j) - packetsSent(i+1,j) > 240
            counters(j) = counters(j) + 1;
        end
    end
end
figure;plot(packetsReceived2-packetsSent2)


