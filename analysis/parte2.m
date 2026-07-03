%% ===================== CONFIG =====================
baseDir  = 'datos finales';              % Carpeta base con subcarpetas "{E}MeV"
metric   = 'Mean_Dose_Gy';        % Métrica correcta generada por el script parte1.m
dz_mm    = 2;                     % Grosor de voxel en Z (mm) si solo hay Z_index
saveFigPNG = true;                % Guardar PNG
saveFigPDF = false;                % Guardar PDF vectorial (ideal para póster)
exportCSV  = true;                % Exportar PDDs combinadas (long-form)
% ======== PALETA (UdeG-friendly) ========
palette.udg = [
    0   45 114;   % Azul marino
    200  16  46;  % Rojo
    255 199  44;  % Dorado
    0  122 116;   % Teal
    88  89  91;   % Grafito
    0  84 147;    % Azul secundario
    232 119 34    % Naranja
]/255;
% Alternativa daltonismo-friendly (Okabe–Ito):
palette.oi = [
    0.000 0.447 0.741;
    0.850 0.325 0.098;
    0.929 0.694 0.125;
    0.494 0.184 0.556;
    0.466 0.674 0.188;
    0.301 0.745 0.933;
    0.635 0.078 0.184
];
whichPalette = 'udg';             % 'udg' | 'oi'
% Apariencia (líneas / ejes / grilla)
lineWidth     = 2.8;              % grosor de curvas
axesLW        = 1.6;              % grosor de ejes
tickDir       = 'out';
gridColor     = [0.85 0.85 0.88]; % gris claro para grilla
gridAlpha     = 0.60;             % más tenue para que no tape las curvas
% ======== TIPOGRAFÍA para PÓSTER ========
titleFont     = 32;   % título
axisLabelFont = 26;   % etiquetas de ejes
tickFont      = 20;   % números en ejes
legendFont    = 22;   % leyenda
% Leyenda (caja de labels)
legendTokenSize = [36 20];
legendEdgeColor = [0.85 0.85 0.90];
legendFaceColor = [1 1 1];
legendBox       = 'on';
legendLocation  = 'best';
% Interpolación opcional a malla común (sin suavizado)
doInterp      = true;
interpStep_mm = 1;
% ==== Ticks (divisiones GRANDES de malla) ====
xTickStep = 50;    % mm
yTickStep = 20;     % % de PDD
%% ===================== PREP =======================
clc; close all;
dE = dir(fullfile(baseDir,'*MeV')); dE = dE([dE.isdir]);
if isempty(dE), error('No se encontraron carpetas {E}MeV en "%s".', baseDir); end

[~,orderE] = sort( cellfun(@(s)extractEnergy(s), {dE.name}) );
dE = dE(orderE);

C = palette.(whichPalette);
if size(C,1) < numel(dE)
    C = repmat(C, ceil(numel(dE)/size(C,1)), 1);
end

figure('Color','w'); hold on;
allPDD_long = table();
legends = cell(numel(dE),1);
plotData = cell(numel(dE), 1);
allDepths = [];

%% ================== LOOP 1: LEER DATOS =================
for k = 1:numel(dE)
    energyFolder = fullfile(dE(k).folder, dE(k).name);
    energyLabel  = dE(k).name;
    E_MeV = extractEnergy(energyLabel);
    
    depthFiles = dir(fullfile(energyFolder, 'DepthDose_*.csv'));
    if isempty(depthFiles)
        warning('No encontré DepthDose_*.csv en %s. Se omite.', energyFolder);
        continue;
    end
    
    fpath = fullfile(depthFiles(1).folder, depthFiles(1).name);
    T = readtable(fpath, 'VariableNamingRule','preserve');
    names = cleanNames(string(T.Properties.VariableNames));
    T.Properties.VariableNames = names; % Re-asignar nombres limpios
    
    % <<< LÍNEA CORREGIDA PARA ACEPTAR EL TYPO "Deth_mm" >>>
    colDepth = robustFindColumn(names, ["Depth_mm", "Deth_mm", "depth_mm", "Profundidad_mm"]);
    
    if colDepth == ""
        warning('En %s no hay columna de profundidad. Se omite. Encabezados encontrados: %s', fpath, strjoin(names, ', '));
        continue;
    end
    depth_mm = double(T{:, colDepth});
    
    colMetric = robustFindColumn(names, [metric, lower(metric), "MeanDoseGy", "PDD_rct", "PDD_prct"]);
    if colMetric == ""
        warning('En %s no se encontró la métrica "%s". Se omite.', fpath, metric);
        continue;
    end
    dose_val = double(T{:, colMetric});
    
    good = isfinite(depth_mm) & isfinite(dose_val) & dose_val >= 0;
    depth_mm = depth_mm(good); 
    dose_val = dose_val(good);
    [depth_mm, sort_idx] = sort(depth_mm);
    dose_val = dose_val(sort_idx);
    
    if isempty(depth_mm), continue; end
    
    maxVal = max(dose_val);
    if maxVal <= 0, continue; end
    PDD = 100 * (dose_val / maxVal);
    
    plotData{k}.x = depth_mm;
    plotData{k}.y = PDD;
    plotData{k}.color = C(k,:);
    plotData{k}.label = energyLabel;
    plotData{k}.E_MeV = E_MeV;
    
    allDepths = [allDepths; depth_mm(:)]; %#ok<AGROW>
    
    if isnan(E_MeV)
        legends{k} = energyLabel;
    else
        legends{k} = sprintf('%.0f MeV', E_MeV);
    end
end

%% ===================== LOOP 2: PLOTEO Y EXPORTACIÓN =====================
if isempty(allDepths)
    error('No se encontraron datos válidos en ninguna carpeta para graficar.');
end

min_overall_depth = min(allDepths);
max_overall_depth = max(allDepths);

depthCommon = [];
if doInterp && (max_overall_depth > min_overall_depth)
    depthCommon = (ceil(min_overall_depth/interpStep_mm)*interpStep_mm) : interpStep_mm : (floor(max_overall_depth/interpStep_mm)*interpStep_mm);
    if numel(depthCommon) < 2
        warning('Rango de interpolación muy pequeño. Se graficarán los datos originales.');
        doInterp = false;
    end
end

for k = 1:numel(dE)
    if isempty(plotData{k}), continue; end
    
    x_original = plotData{k}.x;
    y_original = plotData{k}.y;
    color = plotData{k}.color;
    
    if doInterp && ~isempty(depthCommon)
        y_interp = interp1(x_original, y_original, depthCommon, 'pchip', 0);
        plot(depthCommon, y_interp, 'LineWidth', lineWidth, 'Color', color);
        
        if exportCSV
            n = numel(depthCommon);
            allPDD_long = [allPDD_long; table( ...
                repmat(string(plotData{k}.label), n, 1), ...
                repmat(plotData{k}.E_MeV, n, 1), ...
                depthCommon(:), y_interp(:), ...
                'VariableNames', {'EnergyLabel','Energy_MeV','Depth_mm','PDD_percent'})];
        end
    else
        plot(x_original, y_original, 'LineWidth', lineWidth, 'Color', color);
        
        if exportCSV
            n = numel(x_original);
            allPDD_long = [allPDD_long; table( ...
                repmat(string(plotData{k}.label), n, 1), ...
                repmat(plotData{k}.E_MeV, n, 1), ...
                x_original(:), y_original(:), ...
                'VariableNames', {'EnergyLabel','Energy_MeV','Depth_mm','PDD_percent'})];
        end
    end
end

%% ===================== ESTILO "PÓSTER / UdeG" ======================
ax = gca;
set(ax, 'FontName','Helvetica', 'FontSize', tickFont, ...
    'LineWidth', axesLW, 'TickDir', 'out', ...
    'XMinorTick','off', 'YMinorTick','off', ...
    'Box','off', 'Layer','bottom');
grid(ax,'on'); ax.GridColor = gridColor; ax.GridAlpha = gridAlpha;

xlabel('Profundidad [mm]','FontWeight','bold','FontSize',axisLabelFont);
ylabel('PDD (Dosis Media) [%]','FontWeight','bold','FontSize',axisLabelFont);
title('Comparación de PDD por energía','FontWeight','bold','FontSize',titleFont);

final_xmin = min_overall_depth;
final_xmax = max_overall_depth;

if final_xmin >= final_xmax
    warning('Todos los datos están en la misma profundidad. Se creará un rango de visualización artificial.');
    final_xmin = final_xmin - 5;
    final_xmax = final_xmax + 5;
end

xlim([final_xmin final_xmax]); 
ylim([0 105]);

xticks_start = ceil(final_xmin / xTickStep) * xTickStep;
xticks_end = floor(final_xmax / xTickStep) * xTickStep;
if xticks_start > xticks_end
    xticks(round(mean([final_xmin, final_xmax])));
else
    xticks(xticks_start : xTickStep : xticks_end);
end
yticks(0:yTickStep:100);

lg = legend(legends(~cellfun(@isempty,legends)), 'Location', legendLocation);
set(lg, 'Interpreter','none', 'FontSize', legendFont, ...
    'Box', legendBox, 'Color', legendFaceColor, 'EdgeColor', legendEdgeColor, ...
    'ItemTokenSize', legendTokenSize);
    
outBaseName = sprintf('PDD_comparacion_%s', metric);
if saveFigPNG
    exportgraphics(gcf, fullfile(baseDir, [outBaseName '.png']), 'Resolution', 300);
    fprintf('✓ PNG guardado: %s\n', [outBaseName '.png']);
end
if saveFigPDF
    exportgraphics(gcf, fullfile(baseDir, [outBaseName '.pdf']), 'ContentType','vector');
    fprintf('✓ PDF (vectorial) guardado: %s\n', [outBaseName '.pdf']);
end
if exportCSV && ~isempty(allPDD_long)
    outCSV = fullfile(baseDir, sprintf('PDD_all_energies_%s.csv', metric));
    writetable(allPDD_long, outCSV);
    fprintf('✓ CSV combinado guardado en: %s\n', outCSV);
end

fprintf('\nListo.\n');
%% ===================== HELPERS =====================
function E = extractEnergy(label)
    m = regexp(label, '([\d\.]+)\s*MeV', 'tokens','once','ignorecase');
    if isempty(m), E = NaN; else, E = str2double(m{1}); end
end

function namesOut = cleanNames(namesIn)
    % Elimina caracteres de control y el BOM (Byte Order Mark) de UTF-8
    namesOut = regexprep(namesIn, '[\p{C}]', ''); 
    % Reemplaza espacios 'no-breaking' por espacios normales
    namesOut = replace(namesOut, char(160), ' ');
    % Elimina espacios al inicio y al final
    namesOut = strtrim(namesOut);
end

function name = robustFindColumn(names, candidates)
    % Itera a través de una lista de nombres de columna candidatos
    for c = candidates(:).'
        % 1. Búsqueda exacta (case-sensitive)
        if ismember(c, names)
            name = c; 
            return; 
        end
        % 2. Búsqueda sin importar mayúsculas/minúsculas
        idx = find(strcmpi(names, c), 1, 'first');
        if ~isempty(idx)
            name = names(idx); 
            return; 
        end
    end
    
    % 3. Si falla, intenta una búsqueda normalizada (quita espacios, guiones, etc.)
    norm = @(s) regexprep(lower(s), '[^a-z0-9]', '');
    namesN = arrayfun(norm, names);
    for c = candidates(:).'
        cN = norm(c); 
        idx = find(strcmp(namesN, cN), 1, 'first');
        if ~isempty(idx)
            name = names(idx); 
            return; 
        end
    end

    name = ""; % Si no se encuentra nada, retorna vacío
end