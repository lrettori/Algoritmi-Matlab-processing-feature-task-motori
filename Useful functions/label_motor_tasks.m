clc;
clear;
close all;

%% ===============================
%  SELEZIONE CARTELLA PRINCIPALE
% ===============================
rootDir = uigetdir("C:\Users\loren\OneDrive - unifi.it\Documents\Unifi\Dati sperimentazioni\0_Olimpia", 'Seleziona la cartella contenente i soggetti');
if rootDir == 0
    error('Nessuna cartella selezionata.');
end

subjectDirs = dir(rootDir);
subjectDirs = subjectDirs([subjectDirs.isdir]);
subjectDirs = subjectDirs(~ismember({subjectDirs.name},{'.','..'}));
nSubjects = numel(subjectDirs);


generateReportNow = false;
stopAnalysis = false;

labelMap = containers.Map( ...
    {'1','2','3','4','5'}, ...
    {'corretto','tagliare_inizio','tagliare_fine','corrotto','unknown'});



%% ===============================
%  SELEZIONE TASK (GUI)
% ===============================
taskList = {'THFv','THFa','FTAP','OPCv','OPCa','PSUP','HRST','POST',...
            'KINT','FRST','TTHP','HTTP','HETO','HEHE','GTAS','STUP','ROTA'};

[selectedTask, cancelled] = selectTaskGUI(taskList);
if cancelled
    error('Selezione task annullata.');
end

%% ===============================
%  FINESTRA DI LABELING (UNA SOLA)
% ===============================
[labelFig, labelHandles] = createLabelGUI();

%% ===============================
%  STRUTTURA PER REPORT
% ===============================
reportHeader = {};
reportData   = {};

rowCounter = 1;

%% ===============================
%  LOOP SOGGETTI
% ===============================
for s = 1:nSubjects

    if stopAnalysis
        break;
    end

    subjName = subjectDirs(s).name;
    subjPath = fullfile(rootDir, subjName);

    labelHandles.counter.String = sprintf('%d / %d', s, nSubjects);

    innerDirs = dir(subjPath);
    innerDirs = innerDirs([innerDirs.isdir]);
    innerDirs = innerDirs(~ismember({innerDirs.name},{'.','..'}));

    %% LOOP CARTELLE INTERNE (1-T0_0 ecc)
    for d = 1:numel(innerDirs)

        if stopAnalysis
            break
        end

        innerName = innerDirs(d).name;
        innerPath = fullfile(subjPath, innerName);

        files = dir(fullfile(innerPath,'*.txt'));
        taskFiles = files(startsWith({files.name}, selectedTask));

        if isempty(taskFiles)
            continue
        end


        %% prepara header CSV (una volta sola)
        if isempty(reportHeader)
            reportHeader = [{'NomeSoggetto','NomeCartella'}, erase({taskFiles.name},'.txt')];
        end

        rowLabels = cell(1, numel(taskFiles));

        for f = 1:numel(taskFiles)

            if stopAnalysis
                break
            end

            filename = taskFiles(f).name;
            filepath = fullfile(innerPath, filename);
            [fileBaseName,~,~] = fileparts(filename);

            dataStruct = extractSignals(filepath);

            figure(2); clf;

            if strcmp(selectedTask,'GTAS')
                % GTAS NON ANALIZZATO
                continue
            end

            if isfield(dataStruct,'ax_Dx')
                plot12Signals(dataStruct, subjName, fileBaseName);
            else
                plot6Signals(dataStruct, subjName);
            end


            % =============================
            % LABELING
            % =============================
            stopNow = waitForLabel(labelFig);

            if stopNow
                stopAnalysis = true;
                continue
            end

            if ~stopAnalysis
                labels = {};
                if labelHandles.cb_correct.Value,   labels{end+1} = 'corretto'; end
                if labelHandles.cb_cut_start.Value, labels{end+1} = 'tagliare_inizio'; end
                if labelHandles.cb_cut_end.Value,   labels{end+1} = 'tagliare_fine'; end
                if labelHandles.cb_corrupt.Value,   labels{end+1} = 'corrotto'; end
                if labelHandles.cb_unknown.Value,   labels{end+1} = 'unknown'; end

                rowLabels{f} = strjoin(labels,';');
                resetCheckboxes(labelHandles);
            end % loop file

            % [stopNow, labelNum] = waitForLabel(labelFig);
            % 
            % if stopNow
            %     stopAnalysis = true;
            %     continue
            % end
            % 
            % if ~isempty(labelNum)
            %     rowLabels{f} = labelMap(labelNum);
            % end


        end




        if ~stopAnalysis
            reportData(rowCounter,:) = [{subjName, innerName}, rowLabels];
            rowCounter = rowCounter + 1;
        end

    end % loop cartelle
end % loop soggetti




%% ===============================
%  SCRITTURA CSV
% ===============================
if ~isempty(reportData)
    reportCell = [reportHeader; reportData];
    outFile = fullfile(rootDir, ['Report_' selectedTask '.csv']);
    writecell(reportCell, outFile);
    disp(['Report generato: ' outFile]);
else
    warning('Nessun dato etichettato. Report non generato.');
end


%%

function [task, cancelled] = selectTaskGUI(taskList)

cancelled = false;
task = '';

f = figure('Position',[500 250 320 520], ...
           'MenuBar','none', ...
           'Name','Seleziona Task', ...
           'NumberTitle','off', ...
           'Resize','off');

bg = uibuttongroup(f,'Position',[0.1 0.25 0.8 0.7]);

rb = gobjects(numel(taskList)+1,1);

for i = 1:numel(taskList)
    rb(i) = uicontrol(bg,'Style','radiobutton', ...
        'String',taskList{i}, ...
        'Units','normalized', ...
        'Position',[0.1 1-i*0.045 0.8 0.045]);
end

% Radiobutton custom
rb(end) = uicontrol(bg,'Style','radiobutton', ...
    'String','Altro (custom)', ...
    'Units','normalized', ...
    'Position',[0.1 1-(numel(taskList)+1)*0.045 0.8 0.045]);

% Textbox custom (disabilitata di default)
uicontrol(f,'Style','text','String','Nome task:', ...
          'Position',[30 80 80 20]);

customEdit = uicontrol(f,'Style','edit', ...
                       'Position',[120 80 150 25], ...
                       'Enable','off');

% abilita/disabilita textbox
bg.SelectionChangedFcn = @(~,event) ...
    set(customEdit,'Enable', ...
        ternary(strcmp(event.NewValue.String,'Altro (custom)'), ...
                'on','off'));

uicontrol(f,'Style','pushbutton','String','OK', ...
    'Position',[60 30 80 35], ...
    'Callback',@okCallback);

uicontrol(f,'Style','pushbutton','String','Annulla', ...
    'Position',[170 30 80 35], ...
    'Callback',@cancelCallback);

uiwait(f);

    function okCallback(~,~)
        sel = bg.SelectedObject.String;
        if strcmp(sel,'Altro (custom)')
            if isempty(customEdit.String)
                errordlg('Inserire il nome del task custom','Errore');
                return;
            end
            task = customEdit.String;
        else
            task = sel;
        end
        uiresume(f);
        close(f);
    end

    function cancelCallback(~,~)
        cancelled = true;
        uiresume(f);
        close(f);
    end
end


%%
function [f, h] = createLabelGUI()

f = figure('Position',[50 250 260 360], ...
           'MenuBar','none', ...
           'Name','Labeling', ...
           'NumberTitle','off', ...
           'Resize','off', ...
           'CloseRequestFcn',@onClose);

% checkbox
h.cb_correct   = uicontrol(f,'Style','checkbox','String','Corretto','Position',[20 290 200 20]);
h.cb_cut_start = uicontrol(f,'Style','checkbox','String','Tagliare inizio','Position',[20 260 200 20]);
h.cb_cut_end   = uicontrol(f,'Style','checkbox','String','Tagliare fine','Position',[20 230 200 20]);
h.cb_corrupt   = uicontrol(f,'Style','checkbox','String','Corrotto','Position',[20 200 200 20]);
h.cb_unknown   = uicontrol(f,'Style','checkbox','String','Unknown','Position',[20 170 200 20]);

% contatore soggetti
h.counter = uicontrol(f,'Style','text','String','0/0','Position',[20 135 200 20]);

% avanti
h.next = uicontrol(f,'Style','pushbutton', ...
                   'String','AVANTI (Invio)', ...
                   'Position',[40 80 180 35], ...
                   'Callback',@onNext);

% genera report
h.report = uicontrol(f,'Style','pushbutton', ...
                     'String','Genera report', ...
                     'Position',[40 30 180 35], ...
                     'Callback',@onGenerateReport);

% gestione invio
set(f,'KeyPressFcn',@(src,event) ...
    strcmp(event.Key,'return') && onNext());

% flag condivisa
setappdata(f,'generateReportNow',false);

    function onNext(~,~)
        uiresume(f);
    end

    function onGenerateReport(~,~)
        choice = questdlg('Sei sicuro di voler generare il report adesso?', ...
                          'Conferma', ...
                          'Sì','No','No');
        if strcmp(choice,'Sì')
            setappdata(f,'generateReportNow',true);
            uiresume(f);
        end
    end

    function onClose(~,~)
        % impedisce chiusura accidentale
        delete(f);
    end
end

% function [f, h] = createLabelGUI()
% 
% f = figure('Position',[50 250 320 360], ...
%            'MenuBar','none', ...
%            'Name','Labeling', ...
%            'NumberTitle','off', ...
%            'Resize','off', ...
%            'CloseRequestFcn',@onClose);
% 
% %% LEGENDA
% legendText = {
%     'Legenda:'
%     '1 = corretto'
%     '2 = tagliare inizio'
%     '3 = tagliare fine'
%     '4 = corrotto'
%     '5 = unknown'
%     };
% 
% uicontrol(f,'Style','text', ...
%              'String',legendText, ...
%              'HorizontalAlignment','left', ...
%              'Position',[20 210 280 120]);
% 
% %% TEXTBOX INPUT
% uicontrol(f,'Style','text', ...
%              'String','Inserisci label (1–5):', ...
%              'Position',[20 170 200 20], ...
%              'HorizontalAlignment','left');
% 
% h.editLabel = uicontrol(f,'Style','edit', ...
%                         'Position',[220 170 50 30], ...
%                         'FontSize',14, ...
%                         'HorizontalAlignment','center', ...
%                         'Callback',@onEdit); %#ok<NASGU>
% 
% %% CONTATORE
% h.counter = uicontrol(f,'Style','text', ...
%                       'String','0 / 0', ...
%                       'Position',[20 130 200 20], ...
%                       'HorizontalAlignment','left');
% 
% %% AVANTI (default)
% h.next = uicontrol(f,'Style','pushbutton', ...
%                    'String','AVANTI', ...
%                    'Position',[40 70 240 35], ...
%                    'Callback',@onNext);
% 
% %% GENERA REPORT
% h.report = uicontrol(f,'Style','pushbutton', ...
%                      'String','Genera report', ...
%                      'Position',[40 25 240 35], ...
%                      'Callback',@onGenerateReport);
% 
% %% focus di default sul pulsante AVANTI
% uicontrol(h.next);
% 
% %% flag condivisa
% setappdata(f,'generateReportNow',false);
% setappdata(f,'currentLabel','');
% 
% %% gestione tastiera
% set(f,'KeyPressFcn',@onKeyPress);
% 
%     function onKeyPress(~,event)
%         if ismember(event.Key,{'1','2','3','4','5'})
%             h.editLabel.String = event.Key;
%         elseif strcmp(event.Key,'return')
%             onNext();
%         end
%     end
% 
%     function onEdit(src,~)
%         val = src.String;
%         if numel(val) > 1 || ~ismember(val,{'1','2','3','4','5'})
%             src.String = '';
%         end
%     end
% 
%     function onNext(~,~)
%         val = h.editLabel.String;
%         if isempty(val)
%             return
%         end
%         setappdata(f,'currentLabel',val);
%         h.editLabel.String = '';
%         uiresume(f);
%     end
% 
%     function onGenerateReport(~,~)
%         choice = questdlg('Sei sicuro di voler generare il report adesso?', ...
%                           'Conferma', ...
%                           'Sì','No','No');
%         if strcmp(choice,'Sì')
%             setappdata(f,'generateReportNow',true);
%             uiresume(f);
%         end
%     end
% 
%     function onClose(~,~)
%         delete(f);
%     end
% end




%%
% function stopNow = waitForLabel(labelFig)
%     uiwait(labelFig);
%     stopNow = getappdata(labelFig,'generateReportNow');
% end

% versione tastiera
function [stopNow, labelNum] = waitForLabel(labelFig)
    uiwait(labelFig);
    stopNow  = getappdata(labelFig,'generateReportNow');
    labelNum = getappdata(labelFig,'currentLabel');
end



function resetCheckboxes(h)
    fields = fieldnames(h);
    for i = 1:numel(fields)
        if contains(fields{i},'cb_')
            h.(fields{i}).Value = 0;
        end
    end
end

%%
function plot6Signals(d, subj)
signals = {d.ax,d.ay,d.az,d.wx,d.wy,d.wz};
names   = {'ax','ay','az','wx','wy','wz'};
for i=1:6
    subplot(3,2,i);
    plot(signals{i});
    title(names{i});
end
sgtitle(subj, 'Interpreter','none');
end

function plot12Signals(d, subj)
signals = {d.ax_Sx,d.ay_Sx,d.az_Sx,d.wx_Sx,d.wy_Sx,d.wz_Sx,...
           d.ax_Dx,d.ay_Dx,d.az_Dx,d.wx_Dx,d.wy_Dx,d.wz_Dx};
names = {'ax Sx','ay Sx','az Sx','wx Sx','wy Sx','wz Sx',...
         'ax Dx','ay Dx','az Dx','wx Dx','wy Dx','wz Dx'};
for i=1:12
    subplot(4,3,i);
    plot(signals{i});
    title(names{i});
end
sgtitle(subj, 'Interpreter','none');
end


%%
function dataStruct = extractSignals(filenameData)
% EXTRACTSIGNALS
% Legge un file txt di acquisizione motoria ed estrae i segnali di interesse
% in base al task e al lato, secondo la logica originale fornita.
%
% OUTPUT:
% dataStruct contiene i segnali estratti, con campi:
%   - task con 6 segnali: ax, ay, az, wx, wy, wz
%   - task con 12 segnali: ax_Sx, ay_Sx, az_Sx, wx_Sx, wy_Sx, wz_Sx,
%                          ax_Dx, ay_Dx, az_Dx, wx_Dx, wy_Dx, wz_Dx
%   - samples

%% ===============================
%  LETTURA FILE
% ===============================
firstImportRawData = importdata(filenameData, '\t', 9);

[~, filename, ~] = fileparts(filenameData);
filename = convertCharsToStrings(filename);

nameSplit = strsplit(filename, '_');
exercise  = nameSplit(1);

dataStruct = struct();
dataStruct.exercise = exercise;

%% ===============================
%  SELEZIONE COLONNE (IDENTICA)
% ===============================
switch exercise
    case {'FTAP', 'THFv', 'THFa', 'OPCv', 'OPCa', 'KINT'}
        side = nameSplit(2);
        if strcmp(side,'DX')
            dataColumns = 31:36; % RIND
        else
            dataColumns = 13:18; % LIND
        end

    case 'PSUP'
        side = nameSplit(2);
        if strcmp(side,'DX')
            dataColumns = 19:24; % RWRS
        else
            dataColumns = 1:6;   % LWRS
        end

    case {'POST', 'HRST'}
        dataColumnsSx = 13:18; % LIND
        dataColumnsDx = 31:36; % RIND

    case {'TTHP', 'HTTP', 'HEHE', 'HETO', 'ROTA'}
        side = nameSplit(2);
        if strcmp(side,'DX')
            dataColumns = 43:48; % RFTT
        else
            dataColumns = 37:42; % LFTT
        end

    case 'FRST'
        dataColumnsSx = 37:42; % LFTT
        dataColumnsDx = 43:48; % RFTT

    case 'STUP'
        dataColumns = 43:48; % RFTT

    case 'GTAS'
        % Al momento GTAS non viene analizzato
        dataStruct.GTAS_not_analyzed = true;
        return
end

%% ===============================
%  ESTRAZIONE SEGNALI
% ===============================
switch exercise
    case {'POST', 'HRST', 'FRST'}

        % SX
        dataStruct.ax_Sx = firstImportRawData.data(:,dataColumnsSx(1));
        dataStruct.ay_Sx = firstImportRawData.data(:,dataColumnsSx(2));
        dataStruct.az_Sx = firstImportRawData.data(:,dataColumnsSx(3));
        dataStruct.wx_Sx = firstImportRawData.data(:,dataColumnsSx(4));
        dataStruct.wy_Sx = firstImportRawData.data(:,dataColumnsSx(5));
        dataStruct.wz_Sx = firstImportRawData.data(:,dataColumnsSx(6));

        % DX
        dataStruct.ax_Dx = firstImportRawData.data(:,dataColumnsDx(1));
        dataStruct.ay_Dx = firstImportRawData.data(:,dataColumnsDx(2));
        dataStruct.az_Dx = firstImportRawData.data(:,dataColumnsDx(3));
        dataStruct.wx_Dx = firstImportRawData.data(:,dataColumnsDx(4));
        dataStruct.wy_Dx = firstImportRawData.data(:,dataColumnsDx(5));
        dataStruct.wz_Dx = firstImportRawData.data(:,dataColumnsDx(6));

        dataStruct.samples = length(dataStruct.ax_Dx);

    case 'GTAS'
        % non gestito
        dataStruct.GTAS_not_analyzed = true;

    otherwise
        dataStruct.ax = firstImportRawData.data(:,dataColumns(1));
        dataStruct.ay = firstImportRawData.data(:,dataColumns(2));
        dataStruct.az = firstImportRawData.data(:,dataColumns(3));
        dataStruct.wx = firstImportRawData.data(:,dataColumns(4));
        dataStruct.wy = firstImportRawData.data(:,dataColumns(5));
        dataStruct.wz = firstImportRawData.data(:,dataColumns(6));

        dataStruct.samples = length(dataStruct.ax);
end

end


%%
function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end


