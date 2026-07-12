% =========================================================================
% SCRIPT 4: pengaruh_learning_rate.m  (FIXED untuk R2013b)
% PERBAIKAN: Hapus 'CapSize'
% =========================================================================

clear; clc; close all;

%% 1. BACA DATA
[~, ~, raw] = xlsread('hasil_36_kombinasi.xlsx');
header = raw(1, :);

idx_LR      = find(strcmp(header, 'LR'));
idx_macroF1 = find(strcmp(header, 'MacroF1'));

LR = cell2mat(raw(2:end, idx_LR));
macroF1 = cell2mat(raw(2:end, idx_macroF1)) * 100;

%% 2. STATISTIK
LR_unique = [0.0001, 0.001, 0.01];
mean_f1 = zeros(1, 3);
std_f1 = zeros(1, 3);

fprintf('\nStatistik Macro F1 per Learning Rate:\n');
fprintf('%-10s %-10s %-10s %-10s %-10s\n', 'LR', 'Mean', 'Std', 'Min', 'Max');
fprintf('%s\n', repmat('-', 1, 50));
for i = 1:length(LR_unique)
    data_grp = macroF1(abs(LR - LR_unique(i)) < 1e-6);
    mean_f1(i) = mean(data_grp);
    std_f1(i) = std(data_grp);
    fprintf('%-10.4f %-10.2f %-10.2f %-10.2f %-10.2f\n', ...
            LR_unique(i), mean_f1(i), std_f1(i), ...
            min(data_grp), max(data_grp));
end

%% 3. BAR CHART
figure('Position', [100, 100, 800, 600], 'Color', 'white');

warna = [144/255, 238/255, 144/255;
         60/255,  179/255, 113/255;
         34/255,  139/255, 34/255];

hold on;
for i = 1:length(LR_unique)
    bar(i, mean_f1(i), 0.6, 'FaceColor', warna(i,:), ...
        'EdgeColor', 'black', 'LineWidth', 1.2);
end

% PERBAIKAN R2013b: Errorbar tanpa CapSize
errorbar(1:length(LR_unique), mean_f1, std_f1, ...
         'k', 'LineStyle', 'none', 'LineWidth', 1.5);

for i = 1:length(LR_unique)
    text(i, mean_f1(i) + std_f1(i) + 2, ...
         sprintf('%.2f\n±%.2f', mean_f1(i), std_f1(i)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
         'FontSize', 10);
end
hold off;

%% 4. FORMAT
set(gca, 'XTick', 1:length(LR_unique));
set(gca, 'XTickLabel', {'0,0001', '0,001', '0,01'});
set(gca, 'FontSize', 10);

xlabel('Learning Rate', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Rata-rata Macro F1-Score (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Pengaruh Learning Rate terhadap Macro F1-Score', ...
      'FontSize', 13, 'FontWeight', 'bold');

ylim([0, max(mean_f1 + std_f1) * 1.25]);
grid on;
set(gca, 'GridLineStyle', '--');
set(gca, 'Layer', 'top');
box off;

%% 5. SIMPAN
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r150', 'Gambar_4_PengaruhLR.png');
fprintf('\nGambar disimpan: Gambar_4_PengaruhLR.png\n');
