%% demo0122_2 timing benchmark
% Modes:
%   1 = use dwt_max1 during AudioPreprocessing_s; skip filter1010
%   2 = skip dwt_max1; use filter1010 after order conversion
%   3 = skip both dwt_max1 and filter1010
%
% Set mode and numRuns below, then run this script. Source MAT files are read
% but not overwritten. Benchmark images and timing CSV files are written to
% the requested _timing_benchmark folder.

clearvars;
clc;
warning('off','audiowrite:clipInputData');
warning('off','MATLAB:VariableNamingRule');

%% User settings
excelFile = 'E:\data\统计dudu.xlsx';
searchRoot = 'E:\data';
outputDir = 'E:\data\_timing_benchmark';
numRuns = 5;
mode = 3;  % 1: DWT only; 2: filter1010 only; 3: neither

if ~isscalar(mode) || ~ismember(mode,[1 2 3])
    error('mode 必须设为 1、2 或 3。');
end
if ~isscalar(numRuns) || numRuns < 2 || fix(numRuns) ~= numRuns
    error('numRuns 必须是大于或等于 2 的整数。');
end
if ~isfile(excelFile)
    error('找不到 Excel 文件：%s',excelFile);
end
if ~isfolder(searchRoot)
    error('找不到数据目录：%s',searchRoot);
end
if ~isfolder(outputDir)
    mkdir(outputDir);
end

switch mode
    case 1
        modeLabel = 'dwt_only';
        useDwt = true;
        useFilter = false;
    case 2
        modeLabel = 'filter1010_only';
        useDwt = false;
        useFilter = true;
    case 3
        modeLabel = 'no_dwt_no_filter';
        useDwt = false;
        useFilter = false;
end

%% Read and resolve the input list once; list preparation is not timed
nameTable = readtable(excelFile,'Range','A1:A600', ...
    'TreatAsEmpty',{''},'VariableNamingRule','preserve');
rawNames = strip(string(nameTable{:,1}));
validNames = ~ismissing(rawNames) & rawNames ~= "" & rawNames ~= "NaN";
sampleNames = rawNames(validNames);

matPaths = strings(0,1);
keptNames = strings(0,1);
for i = 1:100
    matFileName = [char(sampleNames(i)),'.mat'];
    foundFolder = findFolderPathRecursive(matFileName,searchRoot);
    if isempty(foundFolder)
        fprintf('Excel 列表中的 MAT 文件未找到，跳过：%s\n',matFileName);
        continue;
    end
    matPaths(end+1,1) = string(fullfile(foundFolder,matFileName)); %#ok<SAGROW>
    keptNames(end+1,1) = sampleNames(i); %#ok<SAGROW>
end
if isempty(matPaths)
    error('没有找到可处理的 MAT 文件，请核对 Excel 文件名和数据目录。');
end

fprintf('模式：%d (%s)；找到 %d 个 MAT 文件；每轮处理完整列表，共 %d 轮。\n', ...
    mode,modeLabel,numel(matPaths),numRuns);
fprintf('图像及计时结果目录：%s\n',outputDir);

%% Warm-up one sample; warm-up measurements and files are excluded
warmupDir = tempname(outputDir);
mkdir(warmupDir);
[~,warmOK,warmMessage] = processOneMat( ...
    char(matPaths(1)),warmupDir,'warmup',mode,useDwt,useFilter);
if isfolder(warmupDir)
    rmdir(warmupDir,'s');
end
if ~warmOK
    fprintf('预热样本未成功处理（不计入统计）：%s\n',warmMessage);
end

stageNames = { ...
    'InputLoadAlign_s', ...
    'AudioPreprocessing_s', ...
    'STFT_s', ...
    'OrderConversion_s', ...
    'DirectionalFilter_s', ...
    'NEP_s', ...
    'ImageExport_s', ...
    'SampleTotal_s'};
numStages = numel(stageNames);
runStageTotals = zeros(numRuns,numStages);
runWallClock = zeros(numRuns,1);
runSuccessCount = zeros(numRuns,1);
runFailureCount = zeros(numRuns,1);

%% Repeat the complete listed-data pass
for runIndex = 1:numRuns
    fprintf('\n========== %s: Run %d/%d ==========\n',modeLabel,runIndex,numRuns);
    runTimer = tic;
    fileStageTimes = zeros(numel(matPaths),numStages);

    for fileIndex = 1:numel(matPaths)
        safeName = sanitizeFilePart(char(keptNames(fileIndex)));
        imageName = sprintf('%s_sample_%04d_%s',modeLabel,fileIndex,safeName);
        try
            [oneFileTimes,ok,message] = processOneMat( ...
                char(matPaths(fileIndex)),outputDir,imageName,mode,useDwt,useFilter);
            fileStageTimes(fileIndex,:) = structToTimeRow(oneFileTimes,stageNames);
            if ok
                runSuccessCount(runIndex) = runSuccessCount(runIndex)+1;
            else
                runFailureCount(runIndex) = runFailureCount(runIndex)+1;
                if runIndex == 1
                    fprintf('跳过 %s：%s\n',keptNames(fileIndex),message);
                end
            end
        catch ME
            runFailureCount(runIndex) = runFailureCount(runIndex)+1;
            fileStageTimes(fileIndex,:) = NaN;
            if runIndex == 1
                fprintf(2,'处理 %s 时出错：%s\n',keptNames(fileIndex),ME.message);
            end
        end
    end

    runStageTotals(runIndex,:) = sum(fileStageTimes,1,'omitnan');
    runWallClock(runIndex) = toc(runTimer);
    fprintf('本轮成功 %d 个，跳过/失败 %d 个，批次耗时 %.3f s。\n', ...
        runSuccessCount(runIndex),runFailureCount(runIndex),runWallClock(runIndex));
end

%% Save per-run measurements and mean +/- sample standard deviation
runVariableNames = [stageNames,{'DatasetWallClock_s','FilesSucceeded','FilesFailed'}];
runTable = array2table([runStageTotals,runWallClock, ...
    runSuccessCount,runFailureCount],'VariableNames',runVariableNames);
runCsv = fullfile(outputDir,['timing_per_run_',modeLabel,'.csv']);
writetable(runTable,runCsv);

meanBatch = mean(runStageTotals,1)';
stdBatch = std(runStageTotals,0,1)';  % sample standard deviation, N-1
meanPerFile = meanBatch/numel(matPaths);
stdPerFile = stdBatch/numel(matPaths);
meanWall = mean(runWallClock);
stdWall = std(runWallClock,0);

summaryStage = [stageNames,{'DatasetWallClock_s'}]';
summaryTable = table(string(summaryStage),[meanBatch;meanWall], ...
    [stdBatch;stdWall],[meanPerFile;meanWall/numel(matPaths)], ...
    [stdPerFile;stdWall/numel(matPaths)], ...
    'VariableNames',{'Stage','MeanPerDatasetRun_s','StdPerDatasetRun_s', ...
    'MeanPerListedFile_s','StdPerListedFile_s'});
summaryCsv = fullfile(outputDir,['timing_summary_',modeLabel,'.csv']);
writetable(summaryTable,summaryCsv);

fprintf('\n========== %s：%d 轮运行的均值和标准差 ==========\n',modeLabel,numRuns);
disp(summaryTable);
fprintf('逐轮结果：%s\n汇总结果：%s\n',runCsv,summaryCsv);
fprintf(['说明：各阶段累计 Excel 列表中找到的 MAT 文件处理时间；' ...
    'SampleTotal_s 包括读取、信号对齐、音频预处理、STFT、阶次转换、' ...
    '可选滤波/NEP 和图像导出。文件路径搜索和 Excel 读取只执行一次，不计入每轮。\n']);

%% Local functions
function [times,ok,message] = processOneMat(matPath,outputDir,imageName,mode,useDwt,useFilter)
totalTimer = tic;
times = emptyTiming();
ok = false;
message = '';
inputTimer = tic;

try
    S = load(matPath);
    if ~isfield(S,'Signal_0') || ~isfield(S,'Signal_1')
        message = '缺少 Signal_0 或 Signal_1';
        times.InputLoadAlign_s = toc(inputTimer);
        times.SampleTotal_s = toc(totalTimer);
        return;
    end

    Signal_0 = S.Signal_0;
    Signal_1 = S.Signal_1;
    if startsWithLabel(Signal_1,'r')
        temp = Signal_1;
        Signal_1 = Signal_0;
        Signal_0 = temp;
    end
    if isfield(S,'Signal_2') && startsWithLabel(S.Signal_2,'r')
        temp = S.Signal_2;
        Signal_2 = Signal_0; %#ok<NASGU>
        Signal_0 = temp;
    end

    audio = double(Signal_1.y_values.values(:));
    speed = double(Signal_0.y_values.values(:));
    if isempty(audio) || isempty(speed)
        message = '音频或车速信号为空';
        times.InputLoadAlign_s = toc(inputTimer);
        times.SampleTotal_s = toc(totalTimer);
        return;
    end
    if any(~isfinite(audio)) || any(~isfinite(speed))
        message = '音频或车速信号包含非有限值';
        times.InputLoadAlign_s = toc(inputTimer);
        times.SampleTotal_s = toc(totalTimer);
        return;
    end

    lengthDifference = numel(audio)-numel(speed);
    if any(speed == 0)
        if lengthDifference == 0
            keep = speed ~= 0;
            audio = audio(keep);
            speed = speed(keep);
        else
            message = '存在零车速且音频/车速长度不一致';
            times.InputLoadAlign_s = toc(inputTimer);
            times.SampleTotal_s = toc(totalTimer);
            return;
        end
    end
    if abs(lengthDifference) > 100
        message = sprintf('音频与车速长度差超过 100 个采样点（差值 %d）',lengthDifference);
        times.InputLoadAlign_s = toc(inputTimer);
        times.SampleTotal_s = toc(totalTimer);
        return;
    elseif lengthDifference > 0
        audio = audio(1:end-lengthDifference);
    elseif lengthDifference < 0
        speed = speed(1:end+lengthDifference);
    end
    if isempty(audio) || isempty(speed)
        message = '对齐后的音频或车速信号为空';
        times.InputLoadAlign_s = toc(inputTimer);
        times.SampleTotal_s = toc(totalTimer);
        return;
    end
    times.InputLoadAlign_s = toc(inputTimer);

    [signalTimes,ok,message] = filterAndStftTimed( ...
        outputDir,imageName,Signal_1,audio,speed,mode,useDwt,useFilter);
    times.AudioPreprocessing_s = signalTimes.AudioPreprocessing_s;
    times.STFT_s = signalTimes.STFT_s;
    times.OrderConversion_s = signalTimes.OrderConversion_s;
    times.DirectionalFilter_s = signalTimes.DirectionalFilter_s;
    times.NEP_s = signalTimes.NEP_s;
    times.ImageExport_s = signalTimes.ImageExport_s;
catch ME
    message = ME.message;
    ok = false;
    if times.InputLoadAlign_s == 0
        times.InputLoadAlign_s = toc(inputTimer);
    end
end
times.SampleTotal_s = toc(totalTimer);
end

function [times,ok,message] = filterAndStftTimed( ...
    outputDir,name,Signal_1,audioData,v,mode,useDwt,useFilter)
times = emptyTiming();
ok = false;
message = '';
fs = round(1/Signal_1.x_values.increment);
if ~isfinite(fs) || fs <= 0
    message = '采样率无效';
    return;
end

audioPrepTimer = tic;
audioData = audioData(:);
amplitudeMean = mean(abs(audioData));
if ~isfinite(amplitudeMean) || amplitudeMean == 0
    message = '音频平均绝对幅值为零或非有限值';
    times.AudioPreprocessing_s = toc(audioPrepTimer);
    return;
end
audioData = audioData/amplitudeMean*0.08;
if useDwt
    audioData = dwt_max1(audioData,fs);
    audioData = audioData(:);
end
if numel(v) < numel(audioData)
    message = '车速信号短于音频信号，无法匹配';
    times.AudioPreprocessing_s = toc(audioPrepTimer);
    return;
end
v = v(1:numel(audioData));

if mean(v,2) < 10
    fmin = 200;
    lim = 1200;
elseif mean(v,2) < 20
    fmin = 250;
    lim = 1400;
else
    fmin = 300;
    lim = 1600;
end

% Same A-weighting and windowed high-pass preprocessing as demo0122_2.m
x = audioData(:)';
weightFilt = weightingFilter('A-weighting');
x = weightFilt(x);
highpassEnabled = true;
if highpassEnabled
    winSize = 2*1024;
    hopSize = 0.25;
    winStep = hopSize*winSize;
    if numel(x) < winSize
        message = '信号短于高通滤波所需的 2048 点窗口';
        times.AudioPreprocessing_s = toc(audioPrepTimer);
        return;
    end
    d = designfilt('highpassfir','FilterOrder',250, ...
        'CutoffFrequency',fmin,'SampleRate',fs);
    numWindows = floor((numel(x)-winSize)/winStep)+1;
    xWindows = zeros(numWindows,winSize);
    for i = 1:numWindows
        first = (i-1)*winStep+1;
        xWindows(i,:) = x(first:first+winSize-1);
    end
    filteredWindows = zeros(size(xWindows));
    for i = 1:numWindows
        filteredWindows(i,:) = filtfilt(d,xWindows(i,:));
    end
    xFiltered = zeros(1,numel(x));
    for i = 1:numWindows
        first = (i-1)*winStep+1;
        last = first+winSize-1;
        xFiltered(first:last) = xFiltered(first:last)+filteredWindows(i,:);
    end
    x = xFiltered*(1-hopSize);
end
times.AudioPreprocessing_s = toc(audioPrepTimer);

[times,ok,message] = stftFixTimed( ...
    outputDir,name,x,fs,lim,v,times,useFilter,mode);
end

function [times,ok,message] = stftFixTimed( ...
    folderPath,name,x,fs,lim,v,times,useFilter,mode)
ok = false;
message = '';
ratio = 66.1/60;
signalDuration = numel(x)/fs;
if signalDuration <= 0 || isempty(v) || max(v) <= 0
    message = '信号时长或车速范围无效';
    return;
end
acc = abs(v(1)-v(end))/signalDuration;

k = 1/1.5;
l = fs*0.1/2/0.1*k;
a = 0.25;
b = 1;
if acc >= 2 && acc < 4
    l = l*0.75;
elseif acc >= 4
    l = l/2;
end
l = round(l);

stftTimer = tic;
[S0,F,T] = stft(x,fs,'Window',hamming(l), ...
    'OverlapLength',round((1-a)*l),'FFTLength',b*l);
k = find(F > 0 & F < lim*2);
F0 = F(k);
S0 = abs(S0(k,:))+eps;
times.STFT_s = toc(stftTimer);
if isempty(F0) || isempty(T)
    message = 'STFT 未产生有效频率或时间点';
    return;
end

orderTimer = tic;
kk = mean(v);
if ~isfinite(kk) || kk <= 0
    message = '阶次转换失败：平均车速必须大于零';
    times.OrderConversion_s = toc(orderTimer);
    return;
end
nMotor = interp1(1/fs:1/fs:signalDuration,v,T)/kk;
nMotor = nMotor(:)';
[Tgrid,Fgrid] = meshgrid(T,F0);
Fscaled = Fgrid.*nMotor;
S = interp2(Tgrid,Fgrid,S0,Tgrid,Fscaled,'linear',0);

F = F0/kk/ratio;
k = find(F < lim/(max(v)*ratio));
F = F(k);
S = abs(S(k,:))+eps;
PdB = 20*log10(S);
Fmax = 50;
k = F < Fmax;
F = F(k);
if isempty(F)
    times.OrderConversion_s = toc(orderTimer);
    message = '阶次范围内没有有效频率点';
    return;
end
PdB = PdB(k,:);
if max(F) < Fmax
    F = [F;max(F)+0.1;Fmax];
    PdB = [PdB;-35*ones(2,numel(T))];
end
F = [0;min(F)-0.1;F];
PdB = [-35*ones(2,numel(T));PdB];
times.OrderConversion_s = toc(orderTimer);

if useFilter
    [PdB,~,filterTimes] = filter1010Timed(PdB,F);
    times.DirectionalFilter_s = filterTimes.DirectionalFilter_s;
    times.NEP_s = filterTimes.NEP_s;
end

imageTimer = tic;
widthCm = 7.8;
heightCm = 3.6;
wpsDpi = 96;
pxPerCm = wpsDpi/2.54;
widthPx = round(widthCm*pxPerCm);
heightPx = round(heightCm*pxPerCm);
fig = figure('Visible','off','Units','pixels','Position',[0 0 widthPx heightPx]);
cleanupFigure = onCleanup(@() closeIfOpen(fig)); %#ok<NASGU>
surf(F,T,PdB','EdgeColor','none');
axis tight;
view(0,90);
clim([0 35]);
colormap jet;
shading interp;
set(gca,'FontName','Times New Roman','FontSize',7);
xlabel('Orders','FontName','Times New Roman','FontSize',7);
ylabel('Time/s','FontName','Times New Roman','FontSize',7);
set(gca,'XTickLabelRotation',0);
xticks(linspace(0,Fmax,Fmax/5+1));
savePath = fullfile(folderPath,[name,'.jpg']);
exportgraphics(fig,savePath,'Resolution',600);
savefig(fig,fullfile(folderPath,[name,'.fig']),'compact');
closeIfOpen(fig);
times.ImageExport_s = toc(imageTimer);
ok = true;
if mode == 1
    message = 'DWT בלבד';
elseif mode == 2
    message = 'filter1010 בלבד';
else
    message = '未使用 DWT 和 filter1010';
end
end

function [P,Fk,times] = filter1010Timed(P,F)
times = struct('DirectionalFilter_s',0,'NEP_s',0);
filterTimer = tic;
P(P < 0) = 0;
P = imgaussfilt(P,1.5);
P0 = P;
sobelY = [-1 -2 -1;0 0 0;1 2 1];
P = imfilter(P,sobelY,'replicate');
P(P < 0.6*max(P,[],1)) = 0;
k = P ~= 0;
P(k) = P0(k);
P = [zeros(1,size(P,2));P(1:end-1,:)];
colMin = min(P,[],1);
colMax = max(P,[],1);
colRange = colMax-colMin;
colRange(colRange == 0) = 1;
P = ((P-colMin)./colRange).^(1/2)*40;
P(P < 0.6*max(P,[],1)) = 0;
times.DirectionalFilter_s = toc(filterTimer);

nepTimer = tic;
a = sum(P ~= 0,2);
lim = 0.18;
k = a >= lim*size(P,2);
[~,idy] = sort(a,'descend');
a(idy(20:end)) = 0;
k(idy(15:end)) = 0;
a = a(:);
z = [0;find(a == 0);numel(a)+1];
s = z(1:end-1)+1;
e = z(2:end)-1;
len = e-s+1;
valid = len > 0;
s = s(valid);
e = e(valid);
a0 = zeros(size(a));
for j = 1:numel(s)
    ss = s(j);
    ee = e(j);
    [~,idx] = max(a(ss:ee));
    a0(ss+idx-1) = a(ss+idx-1);
end
[~,idy] = sort(a0,'descend');
k1 = zeros(size(k));
k1(idy(1:min(10,numel(idy)))) = 1;
k(idy(1:min(5,numel(idy)))) = 1;
k2 = k & k1;

minValues = min(P.*(P ~= 0)+100*(P == 0),[],2);
rowMeansMatrix = repmat(minValues,1,size(P,2));
elementsLessThanMean = P < rowMeansMatrix;
replaceMask = bsxfun(@and,elementsLessThanMean,k);
P(replaceMask) = rowMeansMatrix(replaceMask);
P(~k,:) = 0;
Fk = F(k2)';
times.NEP_s = toc(nepTimer);
end

function audioData = dwt_max1(x,fs) %#ok<INUSD>
% SWT segmented thresholding from demo0122_2.m
waveName = 'sym7';
Lswt = 7;
factor = 2^Lswt;
x = x(:)';
Nfit = factor*floor(numel(x)/factor);
if Nfit < factor
    error('信号长度不足以进行 dwt_max1（至少需要 %d 个采样点）。',factor);
end
x = x(1:Nfit);
swc = swt(x,Lswt,waveName);
for lev = [5 6 7]
    cd = swc(lev,:);
    sigma = median(abs(cd))/0.6745;
    E = abs(cd).^2;
    Emean = mean(E);
    mask = E > 4*Emean;
    thr = 2*sigma;
    if any(mask)
        thr = thr*0.5;
    end
    swc(lev,:) = wthresh(cd,'h',thr);
end
audioData = iswt(swc,waveName);
end

function times = emptyTiming()
times = struct( ...
    'InputLoadAlign_s',0, ...
    'AudioPreprocessing_s',0, ...
    'STFT_s',0, ...
    'OrderConversion_s',0, ...
    'DirectionalFilter_s',0, ...
    'NEP_s',0, ...
    'ImageExport_s',0, ...
    'SampleTotal_s',0);
end

function row = structToTimeRow(times,stageNames)
row = zeros(1,numel(stageNames));
for i = 1:numel(stageNames)
    if isfield(times,stageNames{i})
        row(i) = times.(stageNames{i});
    end
end
end

function tf = startsWithLabel(S,expectedChar)
tf = false;
try
    label = char(S.y_values.quantity.label);
    tf = ~isempty(label) && label(1) == expectedChar;
catch
end
end

function safeName = sanitizeFilePart(name)
safeName = regexprep(name,'[<>:"/\\|?*]','_');
safeName = strtrim(safeName);
if isempty(safeName)
    safeName = 'sample';
end
end

function closeIfOpen(fig)
if isgraphics(fig)
    close(fig);
end
end

function folderPath = findFolderPathRecursive(fileName,searchPath)
folderPath = '';
items = dir(searchPath);
for i = 1:numel(items)
    if strcmp(items(i).name,'.') || strcmp(items(i).name,'..')
        continue;
    end
    itemPath = fullfile(searchPath,items(i).name);
    if items(i).isdir
        folderPath = findFolderPathRecursive(fileName,itemPath);
        if ~isempty(folderPath)
            return;
        end
    elseif strcmp(items(i).name,fileName)
        folderPath = searchPath;
        return;
    end
end
end
