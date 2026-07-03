%% ===================== LIMPIEZA TOTAL =====================
% Esto es CRÍTICO para resolver el problema de los colores desalineados.
clear all;
close all;
clc;

%% ===================== CONFIGURACIÓN =====================
% Directorio base que contiene las carpetas de energía (ej. '10MeV')
baseDir = 'datos finales'; 
outputCsvName = 'Contribucion_Secundarias_Porcentaje.csv'; % Nombre del archivo de salida

% ======== PALETA (UdeG-friendly) por categoría ========
% (Se define aquí, después del 'clear all')
clear color label; % Limpiamos por si acaso
color.Total   = [0   45 114]/255;   % Azul marino
color.Primary = [200 16  46 ]/255;  % Rojo
color.eminus  = [255 199 44 ]/255;  % Dorado
color.eplus   = [0  122 116]/255;   % Teal
color.gamma   = [0   84 147]/255;   % Azul secundario
color.neutron = [0.83 0.00 0.55];   % Magenta vibrante
color.other   = [232 119 34 ]/255;  % Naranja

label.Total   = 'Dosis Total';
label.Primary = '\gamma Primarios';
label.eminus  = 'e^-';
label.eplus   = 'e^+';
label.gamma   = '\gamma Secundarios';
label.neutron = 'neutrones';
label.other   = 'otras';

% ======== TIPOGRAFÍA para PÓSTER ========
titleFont     = 32;   % título
axisLabelFont = 26;   % etiquetas de ejes
tickFont      = 20;   % números en ejes
legendFont    = 22;   % leyenda
legendTokenSize = [36 20];
legendEdgeColor = [0.85 0.85 0.90];
legendFaceColor = [1 1 1];
legendBox       = 'on';
legendLocation  = 'bestoutside';

% ---- Definición de partículas secundarias a procesar ----
particleMap = containers.Map;
particleMap('eminus')  = 'D_e_minus_Gy';
particleMap('eplus')   = 'D_e_plus_Gy';
particleMap('gamma')   = 'D_gamma_Gy';
particleMap('neutron') = 'D_neutron_Gy';
particleMap('other')   = 'D_other_Gy';

sec_cats = string(keys(particleMap)); 
numParticles = numel(sec_cats);
particleCols = strings(numParticles, 1);
particleLabels = strings(numParticles, 1);
particleColors = zeros(numParticles, 3);

for i = 1:numParticles
    catName = sec_cats(i);                 
    particleCols(i) = particleMap(catName);  
    particleLabels(i) = label.(catName);   
    particleColors(i, :) = color.(catName);
end

%% ===================== PREPARACIÓN =======================
fprintf('Iniciando análisis de contribución de dosis...\n\n');

% 1. Encontrar carpetas de energía
dE = dir(fullfile(baseDir,'*MeV'));
dE = dE([dE.isdir]);
if isempty(dE)
    error('No se encontraron carpetas {E}MeV en %s', baseDir);
end

numEnergies = numel(dE);

% 2. Pre-alocar y extraer nombres Y valores numéricos para ordenar
energyNames = strings(numEnergies, 1);
energyValues = zeros(numEnergies, 1);
all_percentages = zeros(numEnergies, numParticles);
all_rel_errors_prct = zeros(numEnergies, 1); 

fprintf('Carpetas encontradas. Extrayendo valores de energía...\n');
for kE = 1:numEnergies
    energyNames(kE) = dE(kE).name;
    val = sscanf(energyNames(kE), '%fMeV');
    if ~isempty(val)
        energyValues(kE) = val(1);
    else
        warning('No se pudo extraer el valor de energía de: %s', energyNames(kE));
        energyValues(kE) = NaN; 
    end
end

%% =========== LOOP DE EXTRACCIÓN DE DATOS POR ENERGÍA ===========
for kE = 1:numEnergies
    energyLabel = energyNames(kE);
    energyFolder = fullfile(dE(kE).folder, energyLabel);
    
    fprintf('>> Procesando Energía: %s (Valor: %.1f)\n', energyLabel, energyValues(kE));
    
    resumenFile = fullfile(energyFolder, sprintf('Resumen_%s.csv', energyLabel));
    dosisFile = fullfile(energyFolder, sprintf('Dosis3D_Averaged_%s.csv', energyLabel));
    
    if ~exist(resumenFile, 'file') || ~exist(dosisFile, 'file')
        warning('Faltan archivos Resumen o Dosis3D para %s. Omitiendo.', energyLabel);
        all_percentages(kE, :) = NaN; 
        all_rel_errors_prct(kE) = NaN;
        continue;
    end
    
    T_resumen = readtable(resumenFile);
    relErrorPercent = getValueFromResumen(T_resumen, 'Error_Rel_Medio_en_Voxel_%');
    all_rel_errors_prct(kE) = relErrorPercent;

    T_dosis = readtable(dosisFile);
    
    totalDose_VolumetricSum = 0;
    if ismember('D_total_Gy', T_dosis.Properties.VariableNames)
        totalDose_VolumetricSum = sum(T_dosis.D_total_Gy, 'omitnan');
    else
        warning('Columna D_total_Gy no encontrada en %s. Omitiendo.', dosisFile);
        all_percentages(kE, :) = NaN; 
        all_rel_errors_prct(kE) = NaN;
        continue;
    end
    
    fprintf('   Dosis Volumétrica Total (Suma de Vóxeles): %.4e Gy\n', totalDose_VolumetricSum);
    fprintf('   Error Rel. Medio en Vóxel (para barras de error): %.3f %%\n', relErrorPercent);
    fprintf('   Contribución de secundarias:\n');
    
    for j = 1:numParticles
        colName = particleCols(j);
        label_j = particleLabels(j);
        particleDoseSum = 0;
        
        if ismember(colName, T_dosis.Properties.VariableNames)
            particleDoseSum = sum(T_dosis.(colName), 'omitnan');
        end
        
        percentage = 0;
        if totalDose_VolumetricSum > 0
            percentage = (particleDoseSum / totalDose_VolumetricSum) * 100;
        end
        
        all_percentages(kE, j) = percentage;
        fprintf('     - %-18s: %9.5f %%\n', label_j, percentage);
    end
    fprintf('\n');
end

%% ===================== ORDENAR DATOS POR ENERGÍA =====================
fprintf('Datos extraídos. Ordenando por energía...\n');

[~, sortIdx] = sort(energyValues);

energyNames = energyNames(sortIdx);
all_percentages = all_percentages(sortIdx, :);
all_rel_errors_prct = all_rel_errors_prct(sortIdx);

fprintf('Orden final: %s\n\n', strjoin(energyNames, ', '));

%% ===================== EXPORTAR RESULTADOS A CSV =====================
fprintf('Exportando porcentajes a CSV...\n');

colNames = sec_cats; 
T_export = array2table(all_percentages, ...
    'VariableNames', colNames, ...
    'RowNames', energyNames); 
T_export.Error_Rel_Medio_Voxel_prct = all_rel_errors_prct;
outputCsvFile = fullfile(baseDir, outputCsvName);

try
    writetable(T_export, outputCsvFile, 'WriteRowNames', true);
    fprintf(' ✓ Resultados (desagregados) guardados en: %s\n\n', outputCsvFile);
catch ME
    fprintf(' X ERROR al guardar el CSV: %s\n', ME.message);
    warning('No se pudo guardar el archivo CSV. Verifique los permisos.');
end


%% ===================== FILTRADO Y PREPARACIÓN DE GRÁFICA =====================
fprintf('Agrupando e^-, e^+ y gamma para la gráfica...\n');

% 1. Omitir energías que fallaron (marcadas como NaN)
validEnergiesMask = ~isnan(all_rel_errors_prct);
if ~any(validEnergiesMask)
    error('No se pudieron procesar datos válidos de ninguna energía.');
end
Y_data_all = all_percentages(validEnergiesMask, :);
E_rel_all = all_rel_errors_prct(validEnergiesMask) / 100; 
plot_energyNames = energyNames(validEnergiesMask);
numValidEnergies = numel(plot_energyNames);

% 2. Encontrar los índices de las columnas originales
idx_em = find(sec_cats == "eminus");
idx_ep = find(sec_cats == "eplus");
idx_g  = find(sec_cats == "gamma");
idx_n  = find(sec_cats == "neutron");
idx_o  = find(sec_cats == "other");

% 3. Crear la NUEVA matriz de datos (Y_data) agrupando las columnas
Y_data_grouped = zeros(numValidEnergies, 3);
Y_data_grouped(:, 1) = Y_data_all(:, idx_em) + Y_data_all(:, idx_ep) + Y_data_all(:, idx_g);
Y_data_grouped(:, 2) = Y_data_all(:, idx_n);
Y_data_grouped(:, 3) = Y_data_all(:, idx_o);

% 4. Definir las NUEVAS etiquetas y colores (ASEGURANDO LA ALINEACIÓN)
plot_labels_grouped = [ ...
    "e^-, e^+, \gamma Sec.", ...  % Etiqueta para Col 1
    label.neutron, ...         % Etiqueta para Col 2 ("neutrones")
    label.other ];             % Etiqueta para Col 3 ("otras")
    
plot_colors_grouped = [ ...
    color.Total; ...           % Color para Col 1 (Azul marino)
    color.neutron; ...         % Color para Col 2 (Magenta vibrante)
    color.other ];             % Color para Col 3 (Naranja)

% 5. Omitir partículas (columnas agrupadas) que no figuran en NINGÚN caso
sumPerParticle = sum(Y_data_grouped, 1, 'omitnan');
validParticlesMask = (sumPerParticle > 0);

if ~any(validParticlesMask)
    error('No se encontraron datos de dosis de partículas secundarias en ningún archivo.');
end

% 6. Filtrar los datos finales para la gráfica
Y_data = Y_data_grouped(:, validParticlesMask);
plot_labels = plot_labels_grouped(validParticlesMask);
plot_colors = plot_colors_grouped(validParticlesMask, :); 

% 7. Calcular los valores de error absoluto para las barras
E_data_abs = Y_data .* E_rel_all; 

%% ===================== GENERACIÓN DE GRÁFICA (Estilo Póster) =====================
%
%  --- SECCIÓN MODIFICADA (MÉTODO DE FUERZA BRUTA) ---
%
fprintf('Generando gráfica...\n');

figure('Name', 'Contribución de Dosis de Secundarias (Agrupada)', 'Color', 'w', 'Position', [100 100 1200 800]);
ax = gca;

% NO establecemos ColorOrder. Simplemente dibujamos la gráfica.
b = bar(Y_data, 'grouped');
set(ax, 'YScale', 'log');
set(ax, 'XTickLabel', plot_energyNames);

% --- Aplicar Tipografía de Póster ---
xlabel('Energía de Haz Incidente', 'FontSize', axisLabelFont);
ylabel('Contribución a Dosis Total (%)', 'FontSize', axisLabelFont);
title('Contribución de Partículas Secundarias a la Dosis Total', ...
    'FontSize', titleFont, 'FontWeight', 'bold');
grid on;
box on;
set(ax, 'FontSize', tickFont); 

% --- ASIGNACIÓN MANUAL DE COLOR Y LEYENDA (LA SOLUCIÓN) ---
% Iteramos sobre cada serie de barras (b(1), b(2), etc.)
% numel(b) será 3 (o menos, si se filtró algo)
for i = 1:numel(b)
    % Asignar el color correcto de nuestra paleta FILTRADA
    b(i).FaceColor = plot_colors(i, :);
    
    % Asignar la etiqueta correcta de nuestra lista FILTRADA
    b(i).DisplayName = plot_labels(i);
end

% --- Aplicar Estilo de Leyenda de Póster ---
% Ahora llamamos a 'legend' SIN argumentos. Leerá los 'DisplayName'
% que acabamos de asignar manualmente.
lgd = legend('Location', legendLocation, ...
    'FontSize', legendFont, ...
    'Box', legendBox, ...
    'EdgeColor', legendEdgeColor, ...
    'Color', legendFaceColor);
lgd.ItemTokenSize(1) = legendTokenSize(1); 

hold(ax, 'on');

numValidParticles = numel(plot_labels);
xCoords = zeros(numValidEnergies, numValidParticles);
for i = 1:numValidParticles
    xCoords(:, i) = b(i).XEndPoints;
end

errorbar(xCoords, Y_data, E_data_abs, ...
    'k', 'LineStyle', 'none', 'CapSize', 3, 'HandleVisibility', 'off');
hold(ax, 'off');

minVal = min(Y_data(Y_data > 0));
maxVal = max(max(Y_data + E_data_abs, [], 'all'));
if ~isempty(minVal) && minVal > 0
    ylim(ax, [minVal*0.5, maxVal*1.5]); 
else
    ylim(ax, [0.01, maxVal*1.5]); 
end

fprintf('Proceso completado.\n');

%% ===================== FUNCIÓN AUXILIAR =====================

function val = getValueFromResumen(T_resumen, metricName)
    idx = strcmpi(T_resumen.Metrica, metricName);
    if any(idx)
        val = T_resumen.Valor(idx);
    else
        warning('Métrica "%s" no encontrada. Se asume 0.', metricName);
        val = 0;
    end
end