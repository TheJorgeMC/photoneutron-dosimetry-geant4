%% ===============================================================
%  D O S E   M A P S   2 D  &  3 D   (por energía, en mm) — SOLO SVG
%  Origen: "AveragedDose_{E}MeV_AllLayers.csv"
%  - 2D: paneles (Total, Prim, e-, e+, γ, [neutrones si hay], otras)
%  - 3D: Estilo unificado de "vóxeles" (scatter3) para todas las categorías,
%    con un umbral específico para neutrones.
%  Normalización: cada categoría -> su propio máximo (0–1).
%% ===============================================================
%% ===================== CONFIG =====================
baseDir      = 'datos finales';     % carpeta con subcarpetas "{E}MeV"
saveSVG      = false;         % solo SVG
% Tamaño de voxel (mm)
% -------------------------------------------------------------------------
% NOTA / NOTE: el paso REAL de vóxel en X/Y NO es 15 mm.
% La geometria en Geant4 usa fPhantomSize=400 mm y fNVoxX=int(400/15+0.5)=27,
% por lo que el paso real es 400/27 = 14.8148 mm (Z si es exacto: 400/200 = 2 mm).
% Usar 15 mm aqui producia ejes X/Y ~1.2% mas grandes de lo real en los mapas.
% The REAL X/Y voxel pitch is 400/27 mm, not 15 mm (Z is exactly 2 mm).
% -------------------------------------------------------------------------
phantomSize_mm = 400;               % lado del fantoma (mm) / phantom side
NxNom = 27; NyNom = 27; NzNom = 200;% n. de voxeles por eje / voxels per axis
dx_mm = phantomSize_mm / NxNom;     % = 14.8148 mm (paso real / real pitch)
dy_mm = phantomSize_mm / NyNom;     % = 14.8148 mm
dz_mm = phantomSize_mm / NzNom;     % = 2.0 mm

% ======== ESTILOS 3D (APLICADOS A TODAS LAS CATEGORÍAS) =========
voxelThreshold3D = 0.25;        % Umbral para TODAS las categorías EXCEPTO neutrones
markerSize3D     = 25;          % Tamaño del "voxel" en el gráfico scatter3
gamma3D          = 0.8;         % Curva gamma para el colormap 3D (1=lineal, <1 realza altos)
edgeColor3D      = [0.1 0.1 0.1]; % Borde oscuro sutil para cada voxel
edgeAlpha3D      = 0.35;        % Transparencia del borde
downsample3D     = 1;           % 1 = sin downsample; 2 = a la mitad, etc.

% ======== ESTILOS ESPECIALES SOLO PARA NEUTRONES EN 3D =========
neutronVoxelThreshold3D = 0.01; % <-- AÑADIDO: Umbral exclusivo para neutrones

% Apariencia / Tipografías (póster)
titleFont     = 28;
axisLabelFont = 24;
tickFont      = 16;

% ======== PALETA (UdeG-friendly) por categoría ========
clear color;
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
catsBase = ["Total","Primary","eminus","eplus","gamma","neutron","other"];

% Nombres esperados en AllLayers.csv
colNames.Total   = "D_total_Gy";
colNames.Primary = "D_primary_Gy";
colNames.eminus  = "D_e_minus_Gy";
colNames.eplus   = "D_e_plus_Gy";
colNames.gamma   = "D_gamma_Gy";
colNames.neutron = "D_neutron_Gy";
colNames.other   = "D_other_Gy";

% Grilla 2D (ticks en mm)
gridColor     = [0.85 0.85 0.88];
xTickStep_mm  = 80;  
yTickStep_mm  = 80;
neutronGamma2D = 0.8; % Gamma especial para neutrones solo en 2D

%% ===================== PREP =======================
clc; close all;
dE = dir(fullfile(baseDir,'*MeV')); dE = dE([dE.isdir]);
if isempty(dE), error('No se encontraron carpetas {E}MeV en "%s".', baseDir); end
[~,ord] = sort( cellfun(@(s)extractEnergy(s), {dE.name}) );
dE = dE(ord);

%% ===================== LOOP ENERGÍAS ==============
for kE = 1:numel(dE)
    energyFolder = fullfile(dE(kE).folder, dE(kE).name);
    energyLabel  = dE(kE).name;
    E_MeV        = extractEnergy(energyLabel);
    allFiles = dir(fullfile(energyFolder, 'Dosis3D_*.csv'));
    if isempty(allFiles)
        warning('No encontré "Dosis3D_*.csv" en %s. Omito.', energyFolder);
        continue;
    end
    fpath = fullfile(allFiles(1).folder, allFiles(1).name);
    
    T = readtable(fpath, 'Delimiter', ',', 'TextType','string', 'VariableNamingRule','preserve');
    rawNames = string(T.Properties.VariableNames);
    names = cleanNames(rawNames);
    
    colX = robustFindColumn(names, ["X","x"], 1);
    colY = robustFindColumn(names, ["Y","y"], 1);
    colZ = robustFindColumn(names, ["Z","z","Z_index","z_index"], 1);
    assert(colX~="" && colY~="" && colZ~="", 'No encontré X/Y/Z en %s', fpath);
    ixX = find(names == colX, 1, 'first');
    ixY = find(names == colY, 1, 'first');
    ixZ = find(names == colZ, 1, 'first');
    X = double(T{:, ixX}); Y = double(T{:, ixY}); Z = double(T{:, ixZ});
    
    xVals = unique(X); yVals = unique(Y); zVals = unique(Z);
    Nx = numel(xVals); Ny = numel(yVals); Nz = numel(zVals);
    x_min = min(xVals); y_min = min(yVals); z_min = min(zVals);
    xi = round(X - x_min + 1);
    yi = round(Y - y_min + 1);
    zi = round(Z - z_min + 1);
    lin = sub2ind([Nx,Ny,Nz], xi, yi, zi);
    x_mm = (x_min + (0:Nx-1)) * dx_mm;
    y_mm = (y_min + (0:Ny-1)) * dy_mm;
    z_mm = (z_min + (0:Nz-1)) * dz_mm;
    
    V = struct(); hasData = struct();
    for ii = 1:numel(catsBase)
        cname = char(catsBase(ii));
        V.(cname) = zeros(Nx,Ny,Nz,'double');
        hasData.(cname) = false;
    end
    
    for ii = 1:numel(catsBase)
        cname  = char(catsBase(ii));
        wanted = colNames.(cname);
        colFound = robustFindColumn(names, [string(wanted), lower(wanted), erase(wanted,"_")], 2);
        if colFound == ""
            hasData.(cname) = false;
            fprintf('   [%s] Falta columna: %s (busqué "%s").\n', energyLabel, cname, wanted);
            continue;
        end
        idxCol = find(names == colFound, 1, 'first');
        vals = double(T{:, idxCol});
        V.(cname)(:) = V.(cname)(:) + accumarray(lin, vals, [Nx*Ny*Nz,1], @sum, 0);
        hasData.(cname) = any(V.(cname)(:) > 0);
    end
    
    catsPlot = strings(0,1);
    for ii = 1:numel(catsBase)
        cname = char(catsBase(ii));
        m = max(V.(cname)(:));
        if m > 0 && hasData.(cname)
            V.(cname) = V.(cname) ./ m;
            catsPlot(end+1,1) = string(cname); %#ok<AGROW>
        else
            if strcmp(cname,'neutron')
                fprintf('   [%s] Neutrones sin datos. Se omite.\n', energyLabel);
            end
        end
    end
    if isempty(catsPlot)
        warning('   [%s] Ninguna categoría con datos para graficar.', energyLabel);
        continue;
    end

    %% ===================== 2D (MIP XY) =====================
    M = struct();
    for ip = 1:numel(catsPlot)
        cname = char(catsPlot(ip));
        M.(cname) = squeeze(max(V.(cname),[],3));
    end
    nP = numel(catsPlot);
    nCols = min(4, max(3, nP));
    nRows = ceil(nP / nCols);
    fig2D = figure('Color','w','Name',sprintf('Maps2D %s', energyLabel),'Position',[100 100 150*nCols*3 150*nRows*3]);
    t = tiledlayout(nRows, nCols, 'TileSpacing','compact','Padding','compact');
    for ip = 1:nP
        cname = char(catsPlot(ip));
        nexttile;
        imagesc([x_mm(1) x_mm(end)], [y_mm(1) y_mm(end)], M.(cname)'); 
        axis image; set(gca,'YDir','normal');
        if strcmp(cname,'neutron')
            colormap(gca, makeCmapGamma(color.(cname), neutronGamma2D));
        else
            colormap(gca, makeCmap(color.(cname)));
        end
        c = colorbar; c.Label.String = 'Norm.';
        title(label.(cname),'FontWeight','bold','FontSize',axisLabelFont);
        ax = gca;
        set(ax,'FontSize',tickFont,'LineWidth',1.2,'TickDir','out','Box','off','Layer','bottom');
        grid(ax,'on'); ax.GridColor = gridColor; ax.GridAlpha = 0.85;
        xticks( ceil(x_mm(1)/xTickStep_mm)*xTickStep_mm : xTickStep_mm : floor(x_mm(end)/xTickStep_mm)*xTickStep_mm );
        yticks( ceil(y_mm(1)/yTickStep_mm)*yTickStep_mm : yTickStep_mm : floor(y_mm(end)/yTickStep_mm)*yTickStep_mm );
        xlabel('X (mm)','FontSize',axisLabelFont);
        ylabel('Y (mm)','FontSize',axisLabelFont);
        caxis([0 1]);
    end
    if isnan(E_MeV)
        title(t, sprintf('Mapas de distribución de dósis — %s', energyLabel), 'FontSize', titleFont, 'FontWeight','bold');
    else
        title(t, sprintf('Mapas de distribución de dósis — %.0f MeV', E_MeV), 'FontSize', titleFont, 'FontWeight','bold');
    end
    if saveSVG          
        outSVG2D = fullfile(energyFolder, sprintf('Maps2D_%s.svg', energyLabel));
        try
            print(fig2D, outSVG2D, '-dsvg', '-r300');
            fprintf('✓ SVG 2D guardado: %s\n', outSVG2D);
        catch ME
            warning('No pude guardar SVG 2D: %s', ME.message);
        end
    else
        % GUARDAR EN PNG
        outPNG2D = fullfile(energyFolder, sprintf('Maps2D_%s.png', energyLabel));
        try
            print(fig2D, outPNG2D, '-dpng', '-r300');
            fprintf('✓ PNG 2D guardado: %s\n', outPNG2D);
        catch ME
            warning('No pude guardar PNG 2D: %s', ME.message);
        end
    end

    
    %% ===================== 3D (UNA POR CATEGORÍA, ESTILO UNIFICADO) =====================
    for ip = 1:numel(catsPlot)
        cname = char(catsPlot(ip));
        Vc = V.(cname);
        
        if downsample3D > 1
            try
                Vc = imresize3(Vc, 1/downsample3D, 'Method','box'); %#ok<IMRESIZE>
                xq = linspace(x_mm(1), x_mm(end), size(Vc,1));
                yq = linspace(y_mm(1), y_mm(end), size(Vc,2));
                zq = linspace(z_mm(1), z_mm(end), size(Vc,3));
            catch
                Vc = Vc(1:downsample3D:end, 1:downsample3D:end, 1:downsample3D:end);
                xq = x_mm(1:downsample3D:end);
                yq = y_mm(1:downsample3D:end);
                zq = z_mm(1:downsample3D:end);
            end
        else
            xq = x_mm; yq = y_mm; zq = z_mm;
        end
        
        fig3D = figure('Color','w','Name',sprintf('Map3D %s - %s', energyLabel, cname), 'Position',[100 100 900 800]);
        ax3 = axes('Parent',fig3D); hold(ax3,'on');
        
        % ====== MÉTODO SCATTER3 PARA TODAS LAS CATEGORÍAS ======
        % MODIFICADO: Seleccionar el umbral según la categoría
        if strcmp(cname, 'neutron')
            currentThreshold = neutronVoxelThreshold3D;
        else
            currentThreshold = voxelThreshold3D;
        end
        
        [I,J,K] = ind2sub(size(Vc), find(Vc >= currentThreshold));
        xv = xq(I); yv = yq(J); zv = zq(K);
        cv = Vc(Vc >= currentThreshold);
        
        if isempty(cv)
            [cv_sorted, idx_sorted] = sort(Vc(:), 'descend');
            N = min(5000, numel(cv_sorted));
            sel = idx_sorted(1:N);
            [I,J,K] = ind2sub(size(Vc), sel);
            xv = xq(I); yv = yq(J); zv = zq(K);
            cv = Vc(sel);
        end
        
        sc = scatter3(ax3, xv, yv, zv, markerSize3D, cv, 's', 'filled');
        colormap(ax3, makeCmapGamma(color.(cname), gamma3D));
        cb = colorbar(ax3); cb.Label.String = 'Norm.';
        sc.MarkerEdgeColor = edgeColor3D;
        try, sc.MarkerEdgeAlpha = edgeAlpha3D; end %#ok<TRYNC>
        
        daspect(ax3, [1 1 1]); view(ax3, 3); camlight(ax3, 'headlight'); lighting(ax3, 'gouraud');
        grid(ax3,'on'); ax3.GridColor = gridColor; ax3.GridAlpha = 0.6;
        set(ax3,'FontSize',tickFont,'LineWidth',1.2,'TickDir','out','Box','on');
        xlabel(ax3,'X (mm)','FontSize',axisLabelFont);
        ylabel(ax3,'Y (mm)','FontSize',axisLabelFont);
        zlabel(ax3,'Z (mm)','FontSize',axisLabelFont);
        xlim(ax3, [xq(1) xq(end)]); ylim(ax3, [yq(1) yq(end)]); zlim(ax3, [zq(1) zq(end)]);
        
        if isnan(E_MeV), ttlE = energyLabel; else, ttlE = sprintf('%.0f MeV', E_MeV); end
        % MODIFICADO: Mostrar el umbral correcto en el título
        title(ax3, sprintf('%s — %s (umbral=%.2f%%)', ttlE, label.(cname), currentThreshold * 100), ...
              'FontWeight','bold','FontSize',titleFont);
        
        if saveSVG
            outSVG3D = fullfile(energyFolder, sprintf('Map3D_%s_%s.svg', energyLabel, cname));
            try
                print(fig3D, outSVG3D, '-dsvg', '-r300');
                fprintf('✓ SVG 3D guardado: %s\n', outSVG3D);
            catch ME
                warning('No pude guardar SVG 3D (%s): %s', cname, ME.message);
            end
        else
            outPNG3D = fullfile(energyFolder, sprintf('Map3D_%s_%s.png', energyLabel, cname));
            try
                print(fig3D, outPNG3D, '-dpng', '-r300');
                fprintf('✓ PNG 3D guardado: %s\n', outPNG3D);
            catch ME
                warning('No pude guardar PNG 3D (%s): %s', cname, ME.message);
            end
        end
    end
    close all force;
end
fprintf('\nTodo listo.\n');
%% ===================== HELPERS =====================
function E = extractEnergy(label)
    m = regexp(label, '([\d\.]+)\s*MeV', 'tokens','once','ignorecase');
    if isempty(m), E = NaN; else, E = str2double(m{1}); end
end
function namesOut = cleanNames(namesIn)
    namesOut = namesIn;
    namesOut = regexprep(namesOut, '[\p{C}]', '');
    namesOut = replace(namesOut, char(160), ' ');
    namesOut = strtrim(namesOut);
    namesOut = regexprep(namesOut, '\s+', ' ');
end
function name = robustFindColumn(names, candidates, maxDist)
    if nargin<3, maxDist = 2; end
    for c = candidates(:).', idx = find(names == c, 1, 'first'); if ~isempty(idx), name = names(idx); return; end, end
    for c = candidates(:).', idx = find(strcmpi(names, c), 1, 'first'); if ~isempty(idx), name = names(idx); return; end, end
    norm = @(s) regexprep(lower(strtrim(s)), '[^a-z0-9]', '');
    namesN = arrayfun(norm, names);
    for c = candidates(:).', cN = norm(c); idx = find(namesN == cN, 1, 'first'); if ~isempty(idx), name = names(idx); return; end, end
    for c = candidates(:).', pat = lower(regexprep(char(c), '_', ' ')); idx = find(contains(lower(names), pat), 1, 'first'); if ~isempty(idx), name = names(idx); return; end, end
    bestIdx = []; bestD = inf; bestName = "";
    for i = 1:numel(names)
        ni = namesN(i);
        for c = candidates(:).', d = editDistance(ni, norm(c)); if d < bestD, bestD = d; bestIdx = i; bestName = names(i); end, end
    end
    if ~isempty(bestIdx) && bestD <= maxDist, name = bestName; else, name = ""; end
end
function d = editDistance(a,b)
    a = char(a); b = char(b); la = length(a); lb = length(b); D = zeros(la+1, lb+1);
    D(:,1) = 0:la; D(1,:) = 0:lb;
    for i = 2:la+1, for j = 2:lb+1, cost = ~(a(i-1) == b(j-1)); D(i,j) = min([ D(i-1,j)+1, D(i,j-1)+1, D(i-1,j-1)+cost ]); end, end
    d = D(end,end);
end
function cmap = makeCmap(baseColor)
    n = 256; r = linspace(1, baseColor(1), n)'; g = linspace(1, baseColor(2), n)'; b = linspace(1, baseColor(3), n)'; 
    cmap = [r g b];
end
function cmap = makeCmapGamma(baseColor, gammaVal)
    if nargin<2, gammaVal = 1; end; n = 256; t = linspace(0,1,n)'.^gammaVal;
    r = 1 + (baseColor(1)-1).*t; g = 1 + (baseColor(2)-1).*t; b = 1 + (baseColor(3)-1).*t;
    cmap = [r g b];
end