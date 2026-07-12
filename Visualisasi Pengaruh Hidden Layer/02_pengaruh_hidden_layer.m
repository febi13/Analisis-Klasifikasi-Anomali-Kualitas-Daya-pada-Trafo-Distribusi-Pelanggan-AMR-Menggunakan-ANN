% =========================================================================
% SCRIPT 2: pengaruh_hidden_layer.m  (FIXED untuk R2013b)
% PERBAIKAN: Hapus 'CapSize' (tidak ada di R2013b)
% =========================================================================

clear; clc; close all;

%% 1. BACA DATA
[~, ~, raw] = xlsread('hasil_36_kombinasi.xlsx');
header = raw(1, :);

idx_HL      = find(strcmp(header, 'HL'));
idx_macroF1 = find(strcmp(header, 'MacroF1'));

HL = cell2mat(raw(2:end, idx_HL));
macroF1 = cell2mat(raw(2:end, idx_macroF1)) * 100;

%% 2. STATISTIK PER GROUP HL
HL_unique = [1, 2, 3];
mean_f1 = zeros(1, 3);
std_f1 = zeros(1, 3);

fprintf('\nStatistik Macro F1 per Hidden Layer:\n');
fprintf('%-5s %-10s %-10s %-10s %-10s\n', 'HL', 'Mean', 'Std', 'Min', 'Max');
fprintf('%s\n', repmat('-', 1, 45));
for i = 1:length(HL_unique)
    data_grp = macroF1(HL == HL_unique(i));
    mean_f1(i) = mean(data_grp);
    std_f1(i) = std(data_grp);
    fprintf('%-5d %-10.2f %-10.2f %-10.2f %-10.2f\n', ...
            HL_unique(i), mean_f1(i), std_f1(i), ...
            min(data_grp), max(data_grp));
end

%% 3. BAR CHART
figure('Position', [100, 100, 800, 600], 'Color', 'white');

warna = [70/255, 130/255, 180/255;
         46/255, 134/255, 171/255;
         29/255, 53/255,  87/255];

hold on;
for i = 1:length(HL_unique)
    bar(i, mean_f1(i), 0.6, 'FaceColor', warna(i,:), ...
        'EdgeColor', 'black', 'LineWidth', 1.2);
end

% PERBAIKAN R2013b: Errorbar tanpa CapSize
errorbar(1:length(HL_unique), mean_f1, std_f1, ...
         'k', 'LineStyle', 'none', 'LineWidth', 1.5);

for i = 1:length(HL_unique)
    text(i, mean_f1(i) + std_f1(i) + 2, ...
         sprintf('%.2f\n±%.2f', mean_f1(i), std_f1(i)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
         'FontSize', 10);
end
hold off;

%% 4. FORMAT
set(gca, 'XTick', 1:length(HL_unique));
set(gca, 'XTickLabel', {'HL = 1', 'HL = 2', 'HL = 3'});
set(gca, 'FontSize', 10);

xlabel('Jumlah Hidden Layer', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Rata-rata Macro F1-Score (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Pengaruh Jumlah Hidden Layer terhadap Macro F1-Score', ...
      'FontSize', 13, 'FontWeight', 'bold');

ylim([0, max(mean_f1 + std_f1) * 1.25]);
grid on;
set(gca, 'GridLineStyle', '--');
set(gca, 'Layer', 'top');
box off;

%% 5. SIMPAN
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r150', 'Gambar_4_PengaruhHL.png');
fprintf('\nGambar disimpan: Gambar_4_PengaruhHL.png\n');
