%% Script per la conversione dei file dati vecchio formato in quello nuovo (da Olimpia in poi)
% Aggiunge l'header e raccoglie i dati secondo la struttura definita
% (eliminando i campi relativi al magnetometro)

clear
close all


flagSubSampling = true;
% -----------------------------------------------------
% % Soluzione in cui seleziono un file txt alla volta
% [filenameIn, pathIn] = uigetfile('D:\Ricerca UNIFI\Olimpia\Dati esempio vecchi (pre-Olimpia)\Esercizi di prova\*.txt');
% -----------------------------------------------------

% -----------------------------------------------------
% Soluzione in cui seleziono una cartella e faccio la conversione di tutti
% i file txt al suo interno (da selezionare la cartella SENSOR_DATA)
pathIn = uigetdir('C:\Users\loren\OneDrive - unifi.it\Documents\Unifi\Olimpia\Dati\Dati pre-Olimpia', "Seleziona la cartella");
FolderInfo = dir(strcat(pathIn,'\*.txt'));
len = 3; % metto len = 3 così entrerò nel ciclo for una sola volta
singleFolder = true;
% -----------------------------------------------------

% -----------------------------------------------------
% % Soluzione in cui seleziono una cartella contenente le cartelle di più
% % soggetti, e le converte una alla volta
% pathIn2 = uigetdir('C:\Users\loren\OneDrive - unifi.it\Documents\Unifi\Olimpia\Dati\Dati pre-Olimpia', "Seleziona la cartella contenente le cartelle dei soggetti");
% BigFolderInfo = dir(pathIn2);
% len = length(BigFolderInfo);
% singleFolder = false;
% -----------------------------------------------------

for ll = 3 : len
    if ~(singleFolder)
        pathIn = strcat(pathIn2,'\',BigFolderInfo(ll).name,'\SENSOR_DATA');
        FolderInfo = dir(strcat(BigFolderInfo(ll).folder,'\',BigFolderInfo(ll).name,'\SENSOR_DATA\*.txt'));
    end


    idcs   = strfind(pathIn,'\');
    pathOut = strcat(pathIn(1:idcs(end)-1),'\NewFormatData\');
    mkdir(pathOut);

    ColumnNames = {'Timestamps' 'Acc_x_0' 'Acc_y_0'	'Acc_z_0'	'Gyr_x_0'	'Gyr_y_0'	'Gyr_z_0'...
        'Acc_x_1'	'Acc_y_1'	'Acc_z_1'	'Gyr_x_1'	'Gyr_y_1'	'Gyr_z_1'...
        'Acc_x_2'	'Acc_y_2'	'Acc_z_2'	'Gyr_x_2'	'Gyr_y_2'	'Gyr_z_2'...
        'Acc_x_3'	'Acc_y_3'	'Acc_z_3'	'Gyr_x_3'	'Gyr_y_3'	'Gyr_z_3'...
        'Acc_x_4'	'Acc_y_4'	'Acc_z_4'	'Gyr_x_4'	'Gyr_y_4'	'Gyr_z_4'...
        'Acc_x_5'	'Acc_y_5'	'Acc_z_5'	'Gyr_x_5'	'Gyr_y_5'	'Gyr_z_5'...
        'Acc_x_6'	'Acc_y_6'	'Acc_z_6'	'Gyr_x_6'	'Gyr_y_6'	'Gyr_z_6'...
        'Acc_x_7'	'Acc_y_7'	'Acc_z_7'	'Gyr_x_7'	'Gyr_y_7'	'Gyr_z_7'};

    counter = 0;
    f = waitbar(counter/length(FolderInfo),'Please wait...');
    f.Children.Title.Interpreter = 'none';
    for kk = 1:length(FolderInfo)
        flagSaveFile = 0;
        flagDuplicateVelAmpFile = 0;

        waitBarText = 'Processing file n.' + string(kk) + ' of ' + string(length(FolderInfo)) + ' : ' + FolderInfo(kk).name;
        waitbar(counter/length(FolderInfo),f,waitBarText);

        nameSplitted = split(convertCharsToStrings(FolderInfo(kk).name),'_');
        taskSelected = nameSplitted(1);
        side = nameSplitted(2);
        rep = split(nameSplitted(end),'.');
        rep = str2num(rep(1));

        %     folderNameSplitted = split(FolderInfo(kk).folder,'\');
        %     patientCode = split(folderNameSplitted(end),'S');
        %     patientCode = str2num(patientCode{end});
        pathNameSplitted = strsplit(pathIn,'\');
        patientCode = pathNameSplitted(end-1);
        patientCode = patientCode{1};
        %     patientCode = 0;
        vers = "1.0";
        exerCode = nameSplitted(1);
        if strcmp(exerCode, "THFF")
            flagDuplicateVelAmpFile = 1;
            exerCode = "THFv";
            exerCode2 = "THFa";
        elseif strcmp (exerCode, "OPCL")
            flagDuplicateVelAmpFile = 1;
            exerCode = "OPCv";
            exerCode2 = "OPCa";
        end

        if (strcmp(exerCode,"THFFv") || strcmp(exerCode,"THFv"))
            exerCode = "THFv";
        elseif (strcmp(exerCode,"THFFa") || strcmp(exerCode,"THFa"))
            exerCode = "THFa";
        elseif (strcmp(exerCode,"OPCLv") || strcmp(exerCode,"OPCv"))
            exerCode = "OPCv";
        elseif (strcmp(exerCode,"OPCLa") || strcmp(exerCode,"OPCa"))
            exerCode = "OPCa";
        end

        switch taskSelected
            case {"FTAP","THFF","OPCL","PSUP","KINT","THFFv","STUP","THFFa", "OPCLv", "OPCLa", "THFv", "THFa", "OPCv", "OPCa"}
                limbs = "one arm";

            case {"POST","HRST"}
                limbs = "two arms";

            case {"TTHP","HEHE","HTTP","HETO","ROTA", "TUGT"}
                limbs = "one leg";

            case "FRST"
                limbs = "two legs";

            case {"GTAH","GTAF"}
                limbs = "all";
        end

        %% Extraction of data
        if strcmp(limbs,"one arm") || strcmp(limbs,"one leg")

            flagSaveFile = 1;
            dataIn = importdata(strcat(FolderInfo(kk).folder, '\', FolderInfo(kk).name));
            samples = length(dataIn.data(:,1));
            dataOutTemp = zeros(samples,48);
            
            % If subsampling is requested (from 100 Hz to 50 Hz)
            if flagSubSampling
                samples = ceil(samples/2);
            end

            % STUP can be acquiered via one foot or one hand device. In both cases,
            % I need to put the data in the right foot place (since the feature
            % processing is expecting that)
            if strcmp(taskSelected,"STUP") &&  length(dataIn.data(1,:)) < 15
                limbs = "STUP acquired via foot sensor";
            elseif strcmp(taskSelected,"STUP") &&  length(dataIn.data(1,:)) >= 15
                limbs = "STUP acquired via hand sensor";
            end

            % Offset che serve se per caso i dati sono stati salvati con un
            % ulteriore tab prima della prima colonna di dati utili (serve ad
            % ignorare la colonna di NaN che si ha nei dati importati)
            if isnan(dataIn.data(1,2))
                columnOffset = 1;
            else
                columnOffset = 0;
            end

            if strcmp(limbs,"one arm")
                if strcmp(side, 'Lx')
                    dataOutTemp(:,1:6) = dataIn.data(:,columnOffset + 2 : columnOffset + 7);
                    dataOutTemp(:,7:12) = dataIn.data(:,columnOffset + 11 : columnOffset + 16);
                    dataOutTemp(:,13:18) = dataIn.data(:,columnOffset + 20 : columnOffset + 25);
                    latoForFileName = "SX";
                    latoForHeader = "Sx";

                elseif strcmp(side,'Rx')
                    dataOutTemp(:,19:24) = dataIn.data(:,columnOffset + 2 : columnOffset + 7);
                    dataOutTemp(:,25:30) = dataIn.data(:,columnOffset + 11 : columnOffset + 16);
                    dataOutTemp(:,31:36) = dataIn.data(:,columnOffset + 20 : columnOffset + 25);
                    latoForFileName = "DX";
                    latoForHeader = "Dx";
                end

            elseif strcmp(limbs,"one leg")
                if strcmp(side, 'Lx')
                    dataOutTemp(:,37:42) = dataIn.data(:,columnOffset + 2 : columnOffset + 7);
                    latoForFileName = "SX";
                    latoForHeader = "Sx";

                elseif strcmp(side,'Rx')
                    dataOutTemp(:,43:48) = dataIn.data(:,columnOffset + 2 : columnOffset + 7);
                    latoForFileName = "DX";
                    latoForHeader = "Dx";
                end
            end

        elseif (strcmp(limbs,"two arms") || strcmp(limbs,"two legs")) && strcmp(side,'Lx')

            flagSaveFile = 1;
            dataInLeft = importdata(strcat(FolderInfo(kk).folder, '\', FolderInfo(kk).name));
            dataInRight = importdata(strcat(FolderInfo(kk).folder, '\', strcat(taskSelected,'_Rx_0',string(rep),'.txt')));

            % Offset che serve se per caso i dati sono stati salvati con un
            % ulteriore tab prima della prima colonna di dati utili (serve ad
            % ignorare la colonna di NaN che si ha nei dati importati)
            if isnan(dataInLeft.data(1,2))
                columnOffsetLeft = 1;
            else
                columnOffsetLeft = 0;
            end
            if isnan(dataInRight.data(1,2))
                columnOffsetRight = 1;
            else
                columnOffsetRight = 0;
            end

            samplesLeft = length(dataInLeft.data(:,1));
            samplesRight = length(dataInRight.data(:,1));
            samples = max(samplesLeft,samplesRight);

            % If subsampling is requested (from 100 Hz to 50 Hz)
            if flagSubSampling
                samples = ceil(samples/2);
            end

            dataOutTemp = zeros(samples,48);

            switch limbs
                case "two arms"
                    dataOutTemp(1:samplesLeft,1:6) = dataInLeft.data(:,columnOffsetLeft + 2 : columnOffsetLeft + 7);
                    dataOutTemp(1:samplesLeft,7:12) = dataInLeft.data(:,columnOffsetLeft + 11 : columnOffsetLeft + 16);
                    dataOutTemp(1:samplesLeft,13:18) = dataInLeft.data(:,columnOffsetLeft + 20 : columnOffsetLeft + 25);
                    dataOutTemp(1:samplesRight,19:24) = dataInRight.data(:,columnOffsetRight + 2 : columnOffsetRight + 7);
                    dataOutTemp(1:samplesRight,25:30) = dataInRight.data(:,columnOffsetRight + 11 : columnOffsetRight + 16);
                    dataOutTemp(1:samplesRight,31:36) = dataInRight.data(:,columnOffsetRight + 20 : columnOffsetRight + 25);
                case "two legs"
                    dataOutTemp(1:samplesLeft,37:42) = dataInLeft.data(:,columnOffsetLeft + 2 : columnOffsetLeft + 7);
                    dataOutTemp(1:samplesRight,43:48) = dataInRight.data(:,columnOffsetRight + 2 : columnOffsetRight + 7);
            end

            latoForFileName = "";
            latoForHeader = "N/A";

        elseif strcmp(exerCode,"GTAH") && strcmp(side,"Lx")
            flagSaveFile = 1;
            % Gait
            dataInLeftHand = importdata(strcat(FolderInfo(kk).folder, '\', FolderInfo(kk).name));
            dataInRightHand = importdata(strcat(FolderInfo(kk).folder, '\', strcat(taskSelected,'_Rx_0',string(rep),'.txt')));
            dataInLeftFoot = importdata(strcat(FolderInfo(kk).folder, '\', strcat("GTAF",'_Lx_0',string(rep),'.txt')));
            dataInRightFoot = importdata(strcat(FolderInfo(kk).folder, '\', strcat("GTAF",'_Rx_0',string(rep),'.txt')));

            % Offset che serve se per caso i dati sono stati salvati con un
            % ulteriore tab prima della prima colonna di dati utili (serve ad
            % ignorare la colonna di NaN che si ha nei dati importati)
            if isnan(dataInLeftHand.data(1,2))
                columnOffsetLeftHand = 1;
            else
                columnOffsetLeftHand = 0;
            end
            if isnan(dataInLeftFoot.data(1,2))
                columnOffsetLeftFoot = 1;
            else
                columnOffsetLeftFoot = 0;
            end
            if isnan(dataInRightHand.data(1,2))
                columnOffsetRightHand = 1;
            else
                columnOffsetRightHand = 0;
            end
            if isnan(dataInRightFoot.data(1,2))
                columnOffsetRightFoot = 1;
            else
                columnOffsetRightFoot = 0;
            end

            samplesLeftHand = length(dataInLeftHand.data(:,1));
            samplesRightHand = length(dataInRightHand.data(:,1));
            samplesLeftFoot = length(dataInLeftFoot.data(:,1));
            samplesRightFoot = length(dataInRightFoot.data(:,1));
            samples = max([samplesLeftHand,samplesRightHand,samplesLeftFoot,samplesRightFoot]);

            % If subsampling is requested (from 100 Hz to 50 Hz)
            if flagSubSampling
                samples = ceil(samples/2);
            end

            dataOutTemp = zeros(samples,48);

            dataOutTemp(1:samplesLeftHand,1:6) = dataInLeftHand.data(:,columnOffsetLeftHand + 2 : columnOffsetLeftHand + 7);
            dataOutTemp(1:samplesLeftHand,7:12) = dataInLeftHand.data(:,columnOffsetLeftHand + 11 : columnOffsetLeftHand + 16);
            dataOutTemp(1:samplesLeftHand,13:18) = dataInLeftHand.data(:,columnOffsetLeftHand + 20 : columnOffsetLeftHand + 25);
            dataOutTemp(1:samplesRightHand,19:24) = dataInRightHand.data(:,columnOffsetRightHand + 2 : columnOffsetRightHand + 7);
            dataOutTemp(1:samplesRightHand,25:30) = dataInRightHand.data(:,columnOffsetRightHand + 11 : columnOffsetRightHand + 16);
            dataOutTemp(1:samplesRightHand,31:36) = dataInRightHand.data(:,columnOffsetRightHand + 20 : columnOffsetRightHand + 25);
            dataOutTemp(1:samplesLeftFoot,37:42) = dataInLeftFoot.data(:,columnOffsetLeftFoot + 2 : columnOffsetLeftFoot + 7);
            dataOutTemp(1:samplesRightFoot,43:48) = dataInRightFoot.data(:,columnOffsetRightFoot + 2 : columnOffsetRightFoot + 7);

            latoForFileName = "";
            latoForHeader = "N/A";
            exerCode = "GTAS";
        end

        % Manage the STUP cases separately
        if strcmp (limbs,"STUP acquired via hand sensor")
            flagSaveFile = 1;
            dataOutTemp(:,43:48) = dataIn.data(:,columnOffset + 2 : columnOffset + 7);

            latoForFileName = "";
            latoForHeader = "N/A";

        elseif strcmp (limbs,"STUP acquired via foot sensor")
            flagSaveFile = 1;
            dataOutTemp(:,43:48) = dataIn.data(:,columnOffset + 2 : columnOffset + 7);

            latoForFileName = "";
            latoForHeader = "N/A";

        end


        if flagSaveFile
            %% Creation of time vector

            % Creo il vettore dei tempi
            start = datetime('9:00 AM', 'InputFormat','h:mm a');
            
            % If subsampling is requested (from 100 Hz to 50 Hz)
            if flagSubSampling
                interval = milliseconds(20);
            else
                interval = milliseconds(10);
            end

            finish = start + (samples - 1) * interval;
            timeVector = (start : interval : finish).';
            timeVector.Format = 'hh:mm:ss:SSS';
            timeVectorString = datestr(timeVector,'HH:MM:SS:FFF');

            %% Stampo su txt

            if strcmp(latoForFileName,"")
                title = strcat(pathOut,exerCode,"_Ex",string(rep),".txt");
            else
                title = strcat(pathOut,exerCode,"_",latoForFileName,"_Ex",string(rep),".txt");
            end

            dataOut = zeros(samples,48);
            if flagSubSampling
                dataOut = dataOutTemp(1:2:end,:);
            else
                dataOut = dataOutTemp;
            end

            fid = fopen(title,'wt');
            fprintf(fid,'Date\t23/10/2024\r');
            fprintf(fid,'Time\t11:40:00\r');
            fprintf(fid,'Codice Paziente\t%s\r',patientCode);
            fprintf(fid,'Codice esercizio\t%s\r', exerCode);
            fprintf(fid,'Lato\t%s\r', latoForHeader);
            fprintf(fid,'Ripetizione\t%s\r', string(rep));
            fprintf(fid,'N. Samples\t%d\r', samples);
            fprintf(fid,'Versione\t1.0\r');

            fprintf(fid, '%s\t\t', ColumnNames{1});
            for ii = 2:49
                fprintf(fid, '%s\t', ColumnNames{ii});
            end

            for ii = 1:samples
                fprintf(fid, '\n%s',string(timeVectorString(ii,:)));
                for jj = 1:48
                    % fprintf(fid,'\t%s',string(dataOut(ii,jj)));
                    fprintf(fid,'\t%.2f',dataOut(ii,jj));
                end
            end

            fclose(fid);

            % Casi THFF e OPCL, creo un altro file per la relativa prova amplitude
            % (copiando il file velocity)
            % if (strcmp(exerCode,"THFv") || strcmp(exerCode,"OPCv")) && flagDuplicateVelAmpFile
            %     title2 = strcat(pathOut,exerCode2,"_",latoForFileName,"_Ex",string(rep),".txt");
            %     cellDataOutput2 = cellDataOutput;
            %     cellDataOutput2{4,2} = exerCode2;
            %     writecell(cellDataOutput2,title2,'delimiter','\t');
            % end



            if strcmp(exerCode,"THFv") && flagDuplicateVelAmpFile
                title2 = strcat(pathOut,exerCode2,"_",latoForFileName,"_Ex",string(rep),".txt");
                fid = fopen(title2,'wt');
                fprintf(fid,'Date\t23/10/2023\r');
                fprintf(fid,'Time\t11:40:00\r');
                fprintf(fid,'Codice Paziente\t%s\r',patientCode);
                fprintf(fid,'Codice esercizio\t%s\r', exerCode2);
                fprintf(fid,'Lato\t%s\r', latoForHeader);
                fprintf(fid,'Ripetizione\t%s\r', string(rep));
                fprintf(fid,'N. Samples\t%d\r', samples);
                fprintf(fid,'Versione\t1.0\r');

                fprintf(fid, '%s\t\t', ColumnNames{1});
                for ii = 2:49
                    fprintf(fid, '%s\t', ColumnNames{ii});
                end

                for ii = 1:samples
                    fprintf(fid, '\n%s',string(timeVectorString(ii,:)));
                    for jj = 1:48
                        % fprintf(fid,'\t%s',string(dataOut(ii,jj)));
                        fprintf(fid,'\t%.2f',dataOut(ii,jj));
                    end
                end

                fclose(fid);

            elseif strcmp(exerCode,"OPCv") && flagDuplicateVelAmpFile
                title2 = strcat(pathOut,exerCode2,"_",latoForFileName,"_Ex",string(rep),".txt");
                fid = fopen(title2,'wt');
                fprintf(fid,'Date\t23/10/2023\r');
                fprintf(fid,'Time\t11:40:00\r');
                fprintf(fid,'Codice Paziente\t%s\r',patientCode);
                fprintf(fid,'Codice esercizio\t%s\r', exerCode2);
                fprintf(fid,'Lato\t%s\r', latoForHeader);
                fprintf(fid,'Ripetizione\t%s\r', string(rep));
                fprintf(fid,'N. Samples\t%d\r', samples);
                fprintf(fid,'Versione\t1.0\r');

                fprintf(fid, '%s\t\t', ColumnNames{1});
                for ii = 2:49
                    fprintf(fid, '%s\t', ColumnNames{ii});
                end

                for ii = 1:samples
                    fprintf(fid, '\n%s',string(timeVectorString(ii,:)));
                    for jj = 1:48
                        % fprintf(fid,'\t%s',string(dataOut(ii,jj)));
                        fprintf(fid,'\t%.2f',dataOut(ii,jj));
                    end
                end

                fclose(fid);
            end

        end
        counter = counter + 1;
    end
    close(f)





end








