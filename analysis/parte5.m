%% ===================== CONFIGURACIÓN =====================
baseDir = 'datos finales';      % Carpeta con subcarpetas tipo '*MeV'
Nx = 27; Ny = 27; Nz = 200;     % Dimensiones de la malla de vóxeles / grid

% Paso REAL de vóxel = 400 mm / N (X/Y = 14.8148 mm, Z = 2 mm exacto).
% Aquí solo se usa dz. / Only dz is used here.
mm = 1e-3; dx = (400/Nx)*mm; dy = (400/Ny)*mm; dz = (400/Nz)*mm;
readSize = 1e6;

% ======== TIPOGRAFÍA para PÓSTER ========
titleFont     = 30;   % título
axisLabelFont = 20;   % etiquetas de ejes
tickFont      = 18;   % números en ejes
legendFont    = 18;
legendTokenSize = [36 20];
legendEdgeColor = [0.85 0.85 0.90];
legendFaceColor = [1 1 1];
legendBox       = 'off';
legendLocation  = 'best';

% Interpolación (no aplica aquí; se deja por consistencia)
doInterp      = true; %#ok<NASGU>
interpStep_mm = 1;    %#ok<NASGU>

% ==== Ticks (divisiones GRANDES de malla) ====
xTickStepDepth = 5;   % mm para profundidad (se usa en niceTicksFromEdges)

% Paleta UDG
palette.udg = [
    0   45 114;
    200  16  46;
    255 199  44;
    0  122 116;
    88  89  91;
    0  84 147;
    232 119 34
]/255;

% Bins para histogramas
numBinsDose  = 'auto'; % 'auto' o entero
numBinsDepth = 'auto'; % 'auto' o entero

% Conversión a nGy (si los datos están en Gy)
GY_TO_NGY = 1e9;

% ======== Guardado automático ========
autoSavePNGs   = true;  % guardar automáticamente cada figura
pngDPI         = 300;   % resolución
closeAfterSave = false; % cerrar figura después de guardar

%% ===================== PREPARACIÓN =======================
clc;
dE = dir(fullfile(baseDir,'*MeV'));
dE = dE([dE.isdir]);
if isempty(dE), error('No se encontraron carpetas {E}MeV en %s', baseDir); end

EnergyNames = {};
MapDoseMax  = containers.Map('KeyType','char','ValueType','any'); % Gy
MapDepthMax = containers.Map('KeyType','char','ValueType','any'); % mm
ResumenRows = [];

%% ===================== LOOP PRINCIPAL POR ENERGÍA =====================
for kE = 1:numel(dE)
    energyFolder = fullfile(dE(kE).folder, dE(kE).name);
    energyLabel  = dE(kE).name;
    fprintf('\n>>======================================================<<\n');
    fprintf('>> Procesando energía: %s\n', energyLabel);
    fprintf('>>======================================================<<\n');

    outDetalle = fullfile(energyFolder, sprintf('PerRun_Dmax_y_DepthDmax_%s.csv', energyLabel));

    % ====== usar CSV existente si ya está ======
    if exist(outDetalle,'file')
        fprintf(' ✓ CSV existente detectado. Usando %s\n', outDetalle);
        Detalle = readtable(outDetalle);
        assert(all(ismember({'Dmax','Profundidad_Dmax_mm'}, Detalle.Properties.VariableNames)), ...
               'El CSV existente no tiene las columnas esperadas.');
        dmax_vals_gy  = Detalle.Dmax(:);
        depth_vals_mm = Detalle.Profundidad_Dmax_mm(:);

        EnergyNames{end+1}           = energyLabel; %#ok<SAGROW>
        MapDoseMax(energyLabel)      = dmax_vals_gy;
        MapDepthMax(energyLabel)     = depth_vals_mm;

        muD = mean(dmax_vals_gy, 'omitnan');  sdD = std(dmax_vals_gy, 'omitnan');  erD = 100*sdD/max(muD,eps);
        muZ = mean(depth_vals_mm,'omitnan');  sdZ = std(depth_vals_mm,'omitnan');  erZ = 100*sdZ/max(muZ,eps);

        ResumenRows = [ResumenRows; struct( ...
            'Energia',              string(energyLabel), ...
            'N_corridas',           numel(dmax_vals_gy), ...
            'DoseMax_media',        muD, ...
            'DoseMax_sigma',        sdD, ...
            'DoseMax_errorRel_pct', erD, ...
            'DepthMax_media_mm',    muZ, ...
            'DepthMax_sigma_mm',    sdZ, ...
            'DepthMax_errorRel_pct',erZ )]; %#ok<AGROW>
        continue;
    end

    % ====== calcular si no existe ======
    files = dir(fullfile(energyFolder,'*.csv'));
    if isempty(files)
        warning('No hay archivos CSV en %s. Se omite.', energyFolder);
        continue;
    end
    N_runs = numel(files);

    firstFile = fullfile(files(1).folder, files(1).name);
    ds0 = tabularTextDatastore(firstFile, 'Delimiter', ',', 'ReadVariableNames', true, ...
        'PreserveVariableNames', true, 'TextType','string', 'TreatAsMissing', "", "MissingValue", 0);
    names = string(preview(ds0).Properties.VariableNames);
    col.X    = pickName(names, ["X","x","ix","i"]);         assert(col.X~="",    'No se encontró la columna X');
    col.Y    = pickName(names, ["Y","y","iy","j"]);         assert(col.Y~="",    'No se encontró la columna Y');
    col.Z    = pickName(names, ["Z","z","iz","k"]);         assert(col.Z~="",    'No se encontró la columna Z');
    col.Total= pickName(names, ["DosisTotal","Total","EnergyTotal"]);
    assert(col.Total~="", 'No se encontró DosisTotal/Total/EnergyTotal');

    % Offset de coordenadas desde el primer archivo
    reset(ds0);
    ds0.SelectedVariableNames = cellstr([col.X, col.Y, col.Z]);
    ds0.ReadSize = readSize * 5;
    x_min = inf; y_min = inf; z_min = inf;
    fprintf(' Calculando offset de coordenadas (min X,Y,Z) en %s ...\n', files(1).name);
    while hasdata(ds0)
        Txyz = read(ds0);
        x_min = min(x_min, min(Txyz{:, col.X}));
        y_min = min(y_min, min(Txyz{:, col.Y}));
        z_min = min(z_min, min(Txyz{:, col.Z}));
    end
    clear ds0 Txyz;

    depth_mm_axis = (z_min + (0:Nz-1))' * (dz/mm);

    dmax_vals_gy  = zeros(N_runs,1); % Gy
    depth_vals_mm = zeros(N_runs,1);

    Detalle = table('Size',[N_runs 3], ...
        'VariableTypes', {'string','double','double'}, ...
        'VariableNames', {'Archivo','Dmax','Profundidad_Dmax_mm'});

    for i = 1:N_runs
        fpath = fullfile(files(i).folder, files(i).name);
        fprintf(' [%d/%d] Analizando: %s\n', i, N_runs, files(i).name);

        T_run = readtable(fpath, 'VariableNamingRule','preserve');

        D_run = zeros(Nx, Ny, Nz, 'single');
        xi = T_run{:, col.X} - x_min + 1;
        yi = T_run{:, col.Y} - y_min + 1;
        zi = T_run{:, col.Z} - z_min + 1;

        valid = (xi >= 1 & xi <= Nx) & (yi >= 1 & yi <= Ny) & (zi >= 1 & zi <= Nz);
        lin_idx = sub2ind([Nx, Ny, Nz], xi(valid), yi(valid), zi(valid));
        D_run(:) = accumarray(lin_idx, T_run{valid, col.Total}, [Nx*Ny*Nz, 1]);

        pdd_run = zeros(Nz, 1);
        for z = 1:Nz
            slice = D_run(:,:,z);
            if any(slice(:) > 0)
                pdd_run(z) = mean(slice(slice > 0));
            end
        end

        [max_dose, idx_max] = max(pdd_run);
        dmax_vals_gy(i)  = max_dose;               % Gy
        depth_vals_mm(i) = depth_mm_axis(idx_max); % mm

        Detalle.Archivo(i)             = string(files(i).name);
        Detalle.Dmax(i)                = dmax_vals_gy(i);
        Detalle.Profundidad_Dmax_mm(i) = depth_vals_mm(i);
    end

    writetable(Detalle, outDetalle);
    fprintf(' ✓ Resultados por corrida guardados en: %s\n', outDetalle);

    EnergyNames{end+1}           = energyLabel; %#ok<SAGROW>
    MapDoseMax(energyLabel)      = dmax_vals_gy;
    MapDepthMax(energyLabel)     = depth_vals_mm;

    muD = mean(dmax_vals_gy, 'omitnan');  sdD = std(dmax_vals_gy, 'omitnan');  erD = 100*sdD/max(muD,eps);
    muZ = mean(depth_vals_mm,'omitnan');  sdZ = std(depth_vals_mm,'omitnan');  erZ = 100*sdZ/max(muZ,eps);

    ResumenRows = [ResumenRows; struct( ...
        'Energia',              string(energyLabel), ...
        'N_corridas',           N_runs, ...
        'DoseMax_media',        muD, ...
        'DoseMax_sigma',        sdD, ...
        'DoseMax_errorRel_pct', erD, ...
        'DepthMax_media_mm',    muZ, ...
        'DepthMax_sigma_mm',    sdZ, ...
        'DepthMax_errorRel_pct',erZ )]; %#ok<AGROW>

    clear T_run D_run Detalle pdd_run xi yi zi lin_idx valid;
end

%% ===================== CSV RESUMEN GLOBAL =====================
if ~isempty(ResumenRows)
    Tsum = struct2table(ResumenRows);
    outResumen = fullfile(baseDir, 'Resumen_global_por_energia_PerRun.csv');
    if exist(outResumen,'file')
        fprintf(' ⚠️ Ya existía %s. No se sobrescribe.\n', outResumen);
    else
        writetable(Tsum, outResumen);
        fprintf('\n✓ Resumen global guardado en: %s\n', outResumen);
    end
else
    warning('No se generó resumen global (¿sin energías válidas?).');
end

%% ===================== FIGURAS: UN HISTOGRAMA POR ENERGÍA =====================
% Si los mapas están vacíos porque sólo había CSVs, recárgalos:
if isempty(EnergyNames)
    dE = dir(fullfile(baseDir,'*MeV')); dE = dE([dE.isdir]);
    for kE = 1:numel(dE)
        energyFolder = fullfile(dE(kE).folder, dE(kE).name);
        energyLabel  = dE(kE).name;
        outDetalle = fullfile(energyFolder, sprintf('PerRun_Dmax_y_DepthDmax_%s.csv', energyLabel));
        if exist(outDetalle,'file')
            Detalle = readtable(outDetalle);
            EnergyNames{end+1} = energyLabel; %#ok<SAGROW>
            MapDoseMax(energyLabel)  = Detalle.Dmax(:);
            MapDepthMax(energyLabel) = Detalle.Profundidad_Dmax_mm(:);
        end
    end
end

% ===== Figuras individuales: Dosis Máxima (nGy) =====
for k = 1:numel(EnergyNames)
    eName = EnergyNames{k};
    valsGy   = MapDoseMax(eName);
    valsnGy  = valsGy * GY_TO_NGY;
    c        = paletteColor(palette.udg, k);

    f = figure('Name',['Dosis Máxima - ' eName],'Color','w');
    ax = axes(f); hold(ax,'on');
    h = plot_hist(valsnGy, numBinsDose, 'FaceColor', c, 'EdgeColor', 'none');
    yMax = max(h.Values(:));
    grid on; box on; ax.FontSize = tickFont;
    title(['Dosis Máxima — ' eName],'FontSize',titleFont,'FontWeight','bold');
    xlabel('Dosis máxima (nGy)','FontSize',axisLabelFont);
    ylabel('Frecuencia','FontSize',axisLabelFont);

    % Media, sigma y epsilon
    mu  = mean(valsnGy,'omitnan');
    sd  = std (valsnGy,'omitnan');
    epsRel = 100*sd/max(mu,eps);

    % Media (línea + símbolo)
    hMean = xline(mu, '-', 'Color', c, 'LineWidth', 2);
    plot(ax, mu, 0.96*yMax, 'o', 'MarkerSize', 8, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k');

    % Barra horizontal ±σ + símbolo
    [hErrSeg, ~] = drawHErrorbar(ax, mu, sd, yMax, c);
    plot(ax, mu+sd, 0.88*yMax, 's', 'MarkerSize', 7, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k');

    lg = legend([h, hMean, hErrSeg], {'Histograma','Media (\mu)','\pm\sigma'}, ...
        'Location', legendLocation, 'Box', legendBox);
    lg.FontSize = legendFont; lg.EdgeColor = legendEdgeColor; lg.Color = legendFaceColor;

    % Subtítulo con μ, σ y ε
    subtitle(sprintf('\\mu=%.4g nGy, \\sigma=%.4g nGy, \\epsilon=%.2f%%', mu, sd, epsRel), 'Interpreter','tex', 'FontSize', 14);

    % ===== Guardado automático =====
    if autoSavePNGs
        outDir = fullfile(baseDir, eName); if ~exist(outDir,'dir'), mkdir(outDir); end
        outPng = fullfile(outDir, sprintf('Hist_DosisMax_%s.png', eName));
        saveAsPNG(f, outPng, pngDPI);
        if closeAfterSave, close(f); end
    end
end

% ===== Figuras individuales: Profundidad de Dosis Máxima (mm) =====
for k = 1:numel(EnergyNames)
    eName = EnergyNames{k};
    vals  = MapDepthMax(eName);
    c     = paletteColor(palette.udg, k);

    f = figure('Name',['Profundidad Dmax - ' eName],'Color','w');
    ax = axes(f); hold(ax,'on');
    h = plot_hist(vals, numBinsDepth, 'FaceColor', c, 'EdgeColor', 'none');
    yMax = max(h.Values(:));
    grid on; box on; ax.FontSize = tickFont;
    title(['Profundidad de Dosis Máxima — ' eName],'FontSize',titleFont,'FontWeight','bold');
    xlabel('Profundidad de Dosis Máxima (mm)','FontSize',axisLabelFont);
    ylabel('Frecuencia','FontSize',axisLabelFont);

    % ---- Ticks y límites "bonitos" usando bordes reales del histograma ----
    edges = h.BinEdges;               % bordes usados por histogram
    xlim([edges(1) edges(end)]);      % asegura que entren todos los bins
    ticks = niceTicksFromEdges(edges, 6, xTickStepDepth); % ~6 divisiones grandes
    xticks(ticks);

    % Métricas
    mu  = mean(vals,'omitnan');
    sd  = std (vals,'omitnan');
    epsRel = 100*sd/max(mu,eps);

    % Media + símbolo
    hMean = xline(mu, '-', 'Color', c, 'LineWidth', 2);
    plot(ax, mu, 0.96*yMax, 'o', 'MarkerSize', 8, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k');

    % Barra horizontal ±σ + símbolo
    [hErrSeg, ~] = drawHErrorbar(ax, mu, sd, yMax, c);
    plot(ax, mu+sd, 0.88*yMax, 's', 'MarkerSize', 7, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k');

    lg = legend([h, hMean, hErrSeg], {'Histograma','Media (\mu)','\pm\sigma'}, ...
        'Location', legendLocation, 'Box', legendBox);
    lg.FontSize = legendFont; lg.EdgeColor = legendEdgeColor; lg.Color = legendFaceColor;

    subtitle(sprintf('\\mu=%.4g mm, \\sigma=%.4g mm, \\epsilon=%.2f%%', mu, sd, epsRel), 'Interpreter','tex', 'FontSize', 14);

    % ===== Guardado automático =====
    if autoSavePNGs
        outDir = fullfile(baseDir, eName); if ~exist(outDir,'dir'), mkdir(outDir); end
        outPng = fullfile(outDir, sprintf('Hist_ProfundidadDmax_%s.png', eName));
        saveAsPNG(f, outPng, pngDPI);
        if closeAfterSave, close(f); end
    end
end

fprintf('\nFiguras listas: un histograma por energía (dosis y profundidad) con \\epsilon, ticks ajustados y PNGs guardados.\n');

%% ===================== FUNCIONES AUXILIARES =====================
function name = pickName(names, candidates)
    name = "";
    for c = candidates(:).'
        m = find(strcmpi(names, c), 1, 'first');
        if ~isempty(m), name = names(m); return; end
    end
end

function c = paletteColor(pal, idx)
    n = size(pal,1);
    c = pal( mod(idx-1, n) + 1, : );
end

function h = plot_hist(vals, binsSpec, varargin)
% Envoltorio robusto para histogram:
% - Acepta 'auto' como BinMethod
% - Devuelve handle
    if isempty(vals) || all(~isfinite(vals)), vals = 0; end
    if (ischar(binsSpec) || (isstring(binsSpec) && isscalar(binsSpec))) && strcmpi(string(binsSpec),'auto')
        h = histogram(vals, 'BinMethod', 'auto', varargin{:});
    elseif isnumeric(binsSpec) && isscalar(binsSpec) && isfinite(binsSpec) && binsSpec>0
        h = histogram(vals, binsSpec, varargin{:});
    else
        h = histogram(vals, 'BinMethod', 'auto', varargin{:});
    end
end

function [hSeg, hCaps] = drawHErrorbar(ax, mu, sigma, yMax, color)
% Dibuja barra horizontal ±σ con caps
    hSeg = gobjects(1); hCaps = gobjects(2);
    if ~isfinite(mu) || ~isfinite(sigma) || sigma<=0 || ~isfinite(yMax) || yMax<=0
        return;
    end
    yPos = 0.88 * yMax;
    capFrac = 0.04;
    capH = capFrac * yMax;
    lw = 2;
    hold(ax, 'on');
    hSeg = plot(ax, [mu - sigma, mu + sigma], [yPos, yPos], ':', 'Color', color, 'LineWidth', lw, 'HandleVisibility','off');
    hCaps(1) = plot(ax, [mu - sigma, mu - sigma], [yPos - capH, yPos + capH], '-', 'Color', color, 'LineWidth', lw, 'HandleVisibility','off');
    hCaps(2) = plot(ax, [mu + sigma, mu + sigma], [yPos - capH, yPos + capH], '-', 'Color', color, 'LineWidth', lw, 'HandleVisibility','off');
end

function ticks = niceTicksFromEdges(edges, targetN, preferredStep)
% Genera ticks "bonitos" a partir de los bordes del histograma.
% targetN: número deseado de divisiones grandes (~5-7 típico).
% preferredStep (opcional): si se da, intenta usarlo (p. ej. 5 mm).
    if nargin < 2 || isempty(targetN),     targetN = 6; end
    if nargin < 3,                         preferredStep = []; end
    xmin = edges(1); xmax = edges(end);
    rng  = max(xmax - xmin, eps);

    if ~isempty(preferredStep) && preferredStep > 0
        step = preferredStep;
    else
        % candidatos de paso "bonito"
        steps = [0.5 1 2 5 10 20 25 50 100];
        step  = steps(find(rng./steps <= targetN, 1, 'first'));
        if isempty(step), step = max(1, round(rng/targetN)); end
    end

    start = ceil(xmin/step)*step; 
    stop  = floor(xmax/step)*step;
    if start >= stop
        ticks = linspace(xmin, xmax, min(targetN,5));
    else
        ticks = start:step:stop;
    end
end

function saveAsPNG(figHandle, outFile, dpi)
% Guarda una figura a PNG con la mejor API disponible
    try
        exportgraphics(figHandle, outFile, 'Resolution', dpi);
    catch
        % fallback para versiones viejas de MATLAB
        print(figHandle, outFile, '-dpng', sprintf('-r%d', dpi));
    end
    fprintf('   → PNG guardado: %s\n', outFile);
end
