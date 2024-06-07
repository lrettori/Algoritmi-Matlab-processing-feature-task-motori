%% Script per la conversione del formato features classico (funzioni Matlab di Erika) all'ordine dettato dal protocollo Olimpia

% Vettore di input, copiato e incollato a mano dal file excel sorgente
input = [...
    0.002213297	0.002956228	0.003135078	2.05078125	1.66015625	2.24609375	38.82875356	41.63872266	39.03166746	8.971056162	7.113716602	7.948873129	95.70457085	95.70677771	95.7203707	0.238897411	0.272562254	0.188333602	0.9765625	1.171875	2.24609375	43.60190394	28.63338292	18.86041265	13.8201953	11.88883466	10.60502149	0.004299274	0.00392916	0.003706775	1.953125	1.66015625	2.1484375	34.79768074	45.82929666	38.45432555	12.49922462	8.879988135	16.7415554	97.49103607	97.64345336	97.51904525	0.230303334	0.425220954	0.474759968	2.44140625	1.66015625	2.1484375	31.87802695	41.34845658	31.60067603	17.787284	12.57936918	24.48744863
    ];

% Label del task, da modificare a mano
% task = "THFF";
% task = "FTAP";
% task = "OPCL";
% task = "PSUP";
task = "POST";
% task = "HRST";
% task = "KINT";
% task = "TTHP";
% task = "HEHE";
% task = "HTTP";
% task = "HETO";
% task = "FRST";
% task = "ROTA";
% task = "GTAS";
% task = "STUP";

switch task
    case {"THFF", "FTAP", "OPCL", "PSUP", "TTHP", "HTTP"}
        % Stesso ordine, al massimo possono mancare alcune feature nel file
        % sorgente (int e int10 ad esempio)
        output = zeros(18,6);
        output(:,1) = input(1:3:54);
        output(:,2) = input(2:3:54);
        output(:,3) = input(3:3:54);
        output(:,4) = input(55:3:end);
        output(:,5) = input(56:3:end);
        output(:,6) = input(57:3:end);

    case "HETO"
        % Stesso ordine
        output = zeros(13,6);
        output(:,1) = input(1:3:39);
        output(:,2) = input(2:3:39);
        output(:,3) = input(3:3:39);
        output(:,4) = input(40:3:end);
        output(:,5) = input(41:3:end);
        output(:,6) = input(42:3:end);

    case {"HEHE", "ROTA"}
        output = zeros(5,6);
        output(:,1) = input(1:3:15);
        output(:,2) = input(2:3:15);
        output(:,3) = input(3:3:15);
        output(:,4) = input(16:3:end);
        output(:,5) = input(16:3:end);
        output(:,6) = input(16:3:end);

    case "POST"
        % Modificare l'ordine dopo aver estratto i dati dalla tabella,
        % secondo un certo schema
        outputTemp = zeros(9,6);
        outputTemp(:,1) = input(1:3:27);
        outputTemp(:,2) = input(2:3:27);
        outputTemp(:,3) = input(3:3:27);
        outputTemp(:,4) = input(28:3:end);
        outputTemp(:,5) = input(29:3:end);
        outputTemp(:,6) = input(30:3:end);

        % Riorganizzo i dati, in  base all'ordine del protocollo Olimpia
        output = zeros(9,6);
        output(1,:) = outputTemp(3,:);
        output(2,:) = outputTemp(8,:);
        output(3,:) = outputTemp(4,:);
        output(4,:) = outputTemp(9,:);
        output(5,:) = outputTemp(1,:);
        output(6,:) = outputTemp(6,:);
        output(7,:) = outputTemp(2,:);
        output(8,:) = outputTemp(7,:);
        output(9,:) = outputTemp(5,:);

    case {"HRST", "FRST"}
        % Modificare l'ordine dopo aver estratto i dati dalla tabella,
        % secondo un certo schema
        outputTemp = zeros(45,6);
        outputTemp(:,1) = input(1:3:135);
        outputTemp(:,2) = input(2:3:135);
        outputTemp(:,3) = input(3:3:135);
        outputTemp(:,4) = input(136:3:end);
        outputTemp(:,5) = input(137:3:end);
        outputTemp(:,6) = input(138:3:end);

        % Divido i dati in 5 sottogruppi, uno per ogni intervallo temporale
        % considerato dal protocollo Olimpia. Questo perché ogni 9 feature
        % lo schema di riordinamento si ripete, e così lo gestisco più
        % facilmente
        outputTempSubIntervals(:,:,1) = outputTemp(1:9,:);
        outputTempSubIntervals(:,:,2) = outputTemp(10:18,:);
        outputTempSubIntervals(:,:,3) = outputTemp(19:27,:);
        outputTempSubIntervals(:,:,4) = outputTemp(28:36,:);
        outputTempSubIntervals(:,:,5) = outputTemp(37:45,:);

        % Infine riorganizzo i dati
        output = zeros(45,6);
        for ii = 1:5
            output((ii-1)*9 + 1,:) = outputTempSubIntervals(3,:,ii);
            output((ii-1)*9 + 2,:) = outputTempSubIntervals(8,:,ii);
            output((ii-1)*9 + 3,:) = outputTempSubIntervals(4,:,ii);
            output((ii-1)*9 + 4,:) = outputTempSubIntervals(9,:,ii);
            output((ii-1)*9 + 5,:) = outputTempSubIntervals(1,:,ii);
            output((ii-1)*9 + 6,:) = outputTempSubIntervals(6,:,ii);
            output((ii-1)*9 + 7,:) = outputTempSubIntervals(2,:,ii);
            output((ii-1)*9 + 8,:) = outputTempSubIntervals(7,:,ii);
            output((ii-1)*9 + 9,:) = outputTempSubIntervals(5,:,ii);
        end
end









