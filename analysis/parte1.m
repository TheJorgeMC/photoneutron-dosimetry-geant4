%% ===================== CONFIGURACIÓN =====================
% --- Parámetros de entrada y de la simulación ---
baseDir = 'datos finales';             % Carpeta que contiene las subcarpetas de energía (ej. '10MeV', '15MeV')
Nx = 27; Ny = 27; Nz = 200;       % Dimensiones de la malla de vóxeles / grid
% --- Dimensiones físicas del vóxel (para cálculo de profundidad en mm) ---
% NOTA/NOTE: paso REAL de vóxel = fantoma(400 mm)/N. En X/Y = 400/27 = 14.8148 mm,
% en Z = 400/200 = 2 mm (exacto). Aquí solo se usa dz; dx,dy quedan por consistencia.
% REAL voxel pitch = phantom(400 mm)/N; only dz is used below.
mm = 1e-3;
dx = (400/Nx)*mm;                 % 14.8148 mm
dy = (400/Ny)*mm;                 % 14.8148 mm
dz = (400/Nz)*mm;                 % 2.0 mm
% --- Parámetros de procesamiento ---
readSize = 1e6;                    % Número de filas a leer por bloque (ajustar según RAM/SSD)
progressEvery = 10;                % Imprimir progreso cada N bloques
%% ===================== PREPARACIÓN =======================
clc;
dE = dir(fullfile(baseDir,'*MeV'));
dE = dE([dE.isdir]);
if isempty(dE)
    error('No se encontraron carpetas {E}MeV en %s', baseDir);
end
%% ===================== LOOP PRINCIPAL POR ENERGÍA ==============
for kE = 1:numel(dE)
    energyFolder = fullfile(dE(kE).folder, dE(kE).name);
    energyLabel = dE(kE).name;
    fprintf('\n>>======================================================<<\n');
    fprintf('>> Procesando energía: %s\n', energyLabel);
    fprintf('>>======================================================<<\n');
    files = dir(fullfile(energyFolder,'*.csv'));
    if isempty(files)
        warning('No hay archivos CSV en %s. Se omite.', energyFolder);
        continue;
    end
    N_runs = numel(files);
    
    % ---- Leer encabezados del primer archivo para configuración ----
    firstFile = fullfile(files(1).folder, files(1).name);
    ds0 = tabularTextDatastore(firstFile, 'Delimiter', ',', 'ReadVariableNames', true, ...
        'PreserveVariableNames', true, 'TextType','string', 'TreatAsMissing', "", "MissingValue", 0);
    names = string(preview(ds0).Properties.VariableNames);
    col.X = pickName(names, ["X","x","ix","i"]); assert(col.X~="", 'No se encontró la columna X');
    col.Y = pickName(names, ["Y","y","iy","j"]); assert(col.Y~="", 'No se encontró la columna Y');
    col.Z = pickName(names, ["Z","z","iz","k"]); assert(col.Z~="", 'No se encontró la columna Z');
    col.Total = pickName(names, ["DosisTotal","Total","EnergyTotal"]); assert(col.Total~="", 'No se encontró DosisTotal');
    col.Prim = pickName(names, ["DosisPrimaria","Primaria","Primary"]); assert(col.Prim~="", 'No se encontró DosisPrimaria');
    
    % ---- Encontrar el offset (índices mínimos de X,Y,Z) globalmente ----
    reset(ds0);
    ds0.SelectedVariableNames = cellstr([col.X, col.Y, col.Z]);
    ds0.ReadSize = readSize * 5; 
    x_min = inf; y_min = inf; z_min = inf;
    fprintf(' Calculando offset de coordenadas (min X,Y,Z)...\n');
    while hasdata(ds0), Txyz = read(ds0);
        x_min = min(x_min, min(Txyz{:, col.X}));
        y_min = min(y_min, min(Txyz{:, col.Y}));
        z_min = min(z_min, min(Txyz{:, col.Z}));
    end, clear ds0 Txyz;
    
    % =====================================================================
    % INICIO: PASADA 1 - ANÁLISIS POR CORRIDA INDIVIDUAL
    % =====================================================================
    fprintf('\n--- Pasada 1: Analizando cada corrida para estadísticas globales ---\n');
    d_max_values_per_run = zeros(N_runs, 1);
    depth_at_d_max_per_run = zeros(N_runs, 1);
    pdd_sum_per_run = zeros(N_runs, 1);
    depth_mm_axis = (z_min + (0:Nz-1))' * (dz/mm);

    for i = 1:N_runs
        fpath = fullfile(files(i).folder, files(i).name);
        fprintf(' [%d/%d] Analizando: %s\n', i, N_runs, files(i).name);
        % <<< CORRECCIÓN: Añadido 'VariableNamingRule','preserve' para eliminar el warning >>>
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
            if any(slice(:) > 0), pdd_run(z) = mean(slice(slice > 0)); end
        end
        
        [max_dose, idx_max] = max(pdd_run);
        d_max_values_per_run(i) = max_dose;
        depth_at_d_max_per_run(i) = depth_mm_axis(idx_max);
        pdd_sum_per_run(i) = sum(pdd_run, 'omitnan');
    end
    
    % Calcular estadísticas directas a partir de los resultados de cada corrida
    mean_d_max = mean(d_max_values_per_run);
    std_d_max  = std(d_max_values_per_run);
    mean_depth_at_d_max = mean(depth_at_d_max_per_run);
    std_depth_at_d_max  = std(depth_at_d_max_per_run);
    mean_pdd_sum = mean(pdd_sum_per_run);
    std_pdd_sum  = std(pdd_sum_per_run);
    
    fprintf('--- Fin Pasada 1 ---\n');
    % =====================================================================
    % FIN: PASADA 1
    % =====================================================================
    
    % ---- Clasificadores de partículas secundarias ----
    is_e_minus = @(s) ~isempty(regexpi(s, '^Sec[_\s]*e-$'));
    is_e_plus  = @(s) ~isempty(regexpi(s, '^Sec[_\s]*e\+$'));
    is_gamma   = @(s) ~isempty(regexpi(s, '^Sec[_\s]*(gamma|foton|photon)$'));
    is_neutron = @(s) ~isempty(regexpi(s, '^Sec[_\s]*neutron(s)?$'));
    
    % ---- Acumuladores 3D para la pasada de streaming ----
    doseTypes = {'total', 'primary', 'e_minus', 'e_plus', 'gamma', 'neutron', 'other'};
    for i = 1:numel(doseTypes)
        Sum_D.(doseTypes{i}) = zeros(Nx, Ny, Nz, 'single');
        Sum_D2.(doseTypes{i}) = zeros(Nx, Ny, Nz, 'single');
    end
    
    % =====================================================================
    % INICIO: PASADA 2 - PROCESAMIENTO ACUMULADO (STREAMING)
    % =====================================================================
    fprintf('\n--- Pasada 2: Procesando todas las corridas para estadísticas de vóxel ---\n');
    for i = 1:N_runs
        fpath = fullfile(files(i).folder, files(i).name);
        fprintf(' [%d/%d] Acumulando: %s\n', i, N_runs, files(i).name);
        ds = tabularTextDatastore(fpath, 'Delimiter', ',', 'ReadVariableNames', true, ...
            'PreserveVariableNames', true, 'TextType','string', 'TreatAsMissing', "", "MissingValue", 0);
        varsThisFile = string(ds.VariableNames);
        secNames_here = varsThisFile(startsWith(varsThisFile, "Sec_", 'IgnoreCase', true));
        cols_em = secNames_here(arrayfun(@(s) is_e_minus(char(s)), secNames_here));
        cols_ep = secNames_here(arrayfun(@(s) is_e_plus (char(s)), secNames_here));
        cols_g  = secNames_here(arrayfun(@(s) is_gamma (char(s)), secNames_here));
        cols_n  = secNames_here(arrayfun(@(s) is_neutron(char(s)), secNames_here));
        cols_oth = setdiff(secNames_here, [cols_em; cols_ep; cols_g; cols_n]);
        selVars = unique([col.X; col.Y; col.Z; col.Total; col.Prim; ...
            cols_em(:); cols_ep(:); cols_g(:); cols_n(:); cols_oth(:)], 'stable');
        ds.SelectedVariableNames = intersect(selVars, varsThisFile, 'stable');
        ds.ReadSize = readSize;
        blk = 0; tFile = tic;
        while hasdata(ds)
            T = read(ds); if isempty(T), break; end; blk = blk + 1;
            xi = T{:, col.X} - x_min + 1; yi = T{:, col.Y} - y_min + 1; zi = T{:, col.Z} - z_min + 1;
            valid = (xi >= 1 & xi <= Nx) & (yi >= 1 & yi <= Ny) & (zi >= 1 & zi <= Nz);
            if ~any(valid), continue; end
            lin_idx = sub2ind([Nx, Ny, Nz], xi(valid), yi(valid), zi(valid));
            V.total = single(safeCol(T, col.Total, valid)); V.primary = single(safeCol(T, col.Prim, valid));
            V.e_minus = sumColsBlock(T, valid, cols_em); V.e_plus  = sumColsBlock(T, valid, cols_ep);
            V.gamma   = sumColsBlock(T, valid, cols_g); V.neutron = sumColsBlock(T, valid, cols_n);
            V.other   = sumColsBlock(T, valid, cols_oth);
            for j = 1:numel(doseTypes)
                type = doseTypes{j}; dose_values = V.(type);
                Sum_D.(type)(:) = Sum_D.(type)(:) + accumarray(lin_idx, dose_values, [Nx*Ny*Nz, 1]);
                Sum_D2.(type)(:) = Sum_D2.(type)(:) + accumarray(lin_idx, dose_values.^2, [Nx*Ny*Nz, 1]);
            end
            if mod(blk, progressEvery) == 0, fprintf('   bloque %d | t=%.1fs\n', blk, toc(tFile)); end
        end
        fprintf('   finalizado en %.1fs (total bloques=%d)\n', toc(tFile), blk);
    end
    fprintf('--- Fin Pasada 2 ---\n\n');
    % =====================================================================
    % FIN: PASADA 2
    % =====================================================================
    
    % ---- Cálculo de estadísticas finales a partir de datos acumulados ----
    fprintf(' Calculando promedios finales y error estadístico...\n');
    D_mean = struct(); D_std  = struct(); Err_prct = struct();
    for i = 1:numel(doseTypes)
        type = doseTypes{i};
        [D_mean.(type), Err_prct.(type), D_std.(type)] = calculate_statistics(Sum_D.(type), Sum_D2.(type), N_runs);
    end
    
    % ---- PDD a partir de la Dosis Media Acumulada (para exportación) ----
    Mean_D_total_Gy_per_Z = zeros(Nz,1);
    for z = 1:Nz
        slice = D_mean.total(:,:,z);
        if any(slice(:) > 0), Mean_D_total_Gy_per_Z(z) = mean(slice(slice > 0)); end
    end
    DepthDose = table((z_min + (0:Nz-1))', depth_mm_axis, Mean_D_total_Gy_per_Z, ...
        'VariableNames', {'Z_index', 'Depth_mm', 'Mean_Dose_Gy'});
    if max(DepthDose.Mean_Dose_Gy) > 0, DepthDose.PDD_prct = 100 * DepthDose.Mean_Dose_Gy / max(DepthDose.Mean_Dose_Gy);
    else, DepthDose.PDD_prct = zeros(Nz,1); end
    outPDD = fullfile(energyFolder, sprintf('DepthDose_Averaged_%s.csv', energyLabel));
    writetable(DepthDose, outPDD);
    fprintf(' ✓ Curva de Dosis en Profundidad (promediada) guardada en: %s\n', outPDD);
        
    % ---- Resumen final de resultados ----
    mean_err_nz = @(err, d) mean(err(d>0), 'omitnan');
    resumen = table( ...
        ["N_corridas"; "N_voxeles_totales"; ...
         "Dosis_Maxima_Media_Gy"; "Dosis_Maxima_Std_Gy"; ...
         "Profundidad_Dmax_Media_mm"; "Profundidad_Dmax_Std_mm"; ...
         "Dosis_Volumetrica_Total_Mean_Gy"; "Dosis_Volumetrica_Total_Std_Gy"; ...
         "Error_Rel_Medio_en_Voxel_%"], ...
        [N_runs; Nx*Ny*Nz; ...
         mean_d_max; std_d_max; ...
         mean_depth_at_d_max; std_depth_at_d_max; ...
         mean_pdd_sum; std_pdd_sum; ...
         mean_err_nz(Err_prct.total, D_mean.total)], ...
        'VariableNames', {'Metrica','Valor'});
    outCSVsum = fullfile(energyFolder, sprintf('Resumen_%s.csv', energyLabel));
    writetable(resumen, outCSVsum);
    fprintf(' ✓ Resumen guardado en: %s\n', outCSVsum);
    
    % ---- Exportar datos 3D completos a un solo archivo ----
    fprintf(' Exportando matriz de dosis 3D completa...\n');
    [Xi_all, Yi_all, Zi_all] = ndgrid(x_min-1+(1:Nx), y_min-1+(1:Ny), z_min-1+(1:Nz));
    maskAll = D_mean.total > 0;
    Tall = table(Xi_all(maskAll), Yi_all(maskAll), Zi_all(maskAll), ...
        D_mean.total(maskAll), D_std.total(maskAll), Err_prct.total(maskAll), ...
        D_mean.primary(maskAll), D_mean.e_minus(maskAll), D_mean.e_plus(maskAll), ...
        D_mean.gamma(maskAll), D_mean.neutron(maskAll), D_mean.other(maskAll), ...
        'VariableNames', {'X', 'Y', 'Z', ...
        'D_total_Gy', 'D_total_Std_Gy', 'Err_total_prct', ...
        'D_primary_Gy', 'D_e_minus_Gy', 'D_e_plus_Gy', 'D_gamma_Gy', ...
        'D_neutron_Gy', 'D_other_Gy'});
    outAll = fullfile(energyFolder, sprintf('Dosis3D_Averaged_%s.csv', energyLabel));
    writetable(Tall, outAll);
    fprintf(' ✓ Matriz 3D (promediada) guardada en: %s\n', outAll);
    
    % ---- Limpieza de memoria ----
    clear D_mean Err_prct Sum_D Sum_D2 V T Tall DepthDose resumen D_std;
    clear d_max_values_per_run depth_at_d_max_per_run D_run T_run pdd_sum_per_run;
    drawnow;
end
fprintf('\nProceso completado.\n');
%% ===================== FUNCIONES AUXILIARES =====================
function [D_mean, Err_prct, D_std] = calculate_statistics(Sum_D, Sum_D2, N)
    Sum_D = double(Sum_D); Sum_D2 = double(Sum_D2);
    D_mean = Sum_D / N;
    D_std = zeros(size(D_mean)); Err_prct = zeros(size(D_mean));
    if N > 1
        Var = (Sum_D2 - (Sum_D.^2 / N)) / (N - 1); Var(Var < 0) = 0;
        D_std = sqrt(Var);
        SEM = D_std / sqrt(N);
        Err_prct = (SEM ./ D_mean) * 100; Err_prct(~isfinite(Err_prct)) = 0;
    end
end
function name = pickName(names, candidates)
    name = "";
    for c = candidates(:).', m = find(strcmpi(names, c), 1, 'first');
        if ~isempty(m), name = names(m); return; end
    end
end
function s = sumColsBlock(T, validMask, cols)
    if isempty(cols), s = zeros(nnz(validMask), 1, 'single'); return; end
    present_cols = intersect(cellstr(cols(:)), T.Properties.VariableNames, 'stable');
    if isempty(present_cols), s = zeros(nnz(validMask), 1, 'single'); return; end
    s = sum(single(T{validMask, present_cols}), 2);
end
function v = safeCol(T, name, validMask)
    if ismember(char(name), T.Properties.VariableNames), v = T{validMask, name};
    else, v = zeros(nnz(validMask), 1); end
end