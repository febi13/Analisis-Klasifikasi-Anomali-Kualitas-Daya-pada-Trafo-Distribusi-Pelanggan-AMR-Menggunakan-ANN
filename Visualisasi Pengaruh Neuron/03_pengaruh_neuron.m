% =========================================================================
% SCRIPT 3: pengaruh_neuron.m  (FIXED untuk R2013b)
% PERBAIKAN: Hapus 'CapSize'
% =========================================================================

clear; clc; close all;

%% 1. BACA DATA
[~, ~, raw] = xlsread('hasil_36_kombinasi.xlsx');
header = raw(1, :);

idx_neuron  = find(strcmp(header, 'Neuron'));
idx_macroF1 = find(strcmp(header, 'MacroF1'));

neuron = cell2mat(raw(2:end, idx_neuron));
macroF1 = cell2mat(raw(2:end, idx_macroF1)) * 100;

%% 2. STATISTIK
neuron_unique = [16, 32, 64, 128];
mean_f1 = zeros(1, 4);
std_f1 = zeros(1, 4);

fprintf('\nStatistik Macro F1 per Jumlah Neuron:\n');
fprintf('%-10s %-10s %-10s %-10s %-10s\n', 'Neuron', 'Mean', 'Std', 'Min', 'Max');
fprintf('%s\n', repmat('-', 1, 50));
for i = 1:length(neuron_unique)
    data_grp = macroF1(neuron == neuron_unique(i));
    mean_f1(i) = mean(data_grp);
    std_f1(i) = std(data_grp);
    fprintf('%-10d %-10.2f %-10.2f %-10.2f %-10.2f\n', ...
            neuron_unique(i), mean_f1(i), std_f1(i), ...
            min(data_grp), max(data_grp));
end

%% 3. BAR CHART
figure('Position', [100, 100, 900, 600], 'Color', 'white');

warna = [173/255, 216/255, 230/255;
         100/255, 149/255, 237/255;
         46/255,  134/255, 171/255;
         29/255,  53/255,  87/255];

hold on;
for i = 1:length(neuron_unique)
    bar(i, mean_f1(i), 0.6, 'FaceColor', warna(i,:), ...
        'EdgeColor', 'black', 'LineWidth', 1.2);
end

% PERBAIKAN R2013b: Errorbar tanpa CapSize
errorbar(1:length(neuron_unique), mean_f1, std_f1, ...
         'k', 'LineStyle', 'none', 'LineWidth', 1.5);

for i = 1:length(neuron_unique)
    text(i, mean_f1(i) + std_f1(i) + 2, ...
         sprintf('%.2f\n±%.2f', mean_f1(i), std_f1(i)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
         'FontSize', 10);
end
hold off;

%% 4. FORMAT
set(gca, 'XTick', 1:length(neuron_unique));
set(gca, 'XTickLabel', {'16', '32', '64', '128'});
set(gca, 'FontSize', 10);

xlabel('Jumlah Neuron per Hidden Layer', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Rata-rata Macro F1-Score (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Pengaruh Jumlah Neuron terhadap Macro F1-Score', ...
      'FontSize', 13, 'FontWeight', 'bold');

ylim([0, max(mean_f1 + std_f1) * 1.25]);
grid on;
set(gca, 'GridLineStyle', '--');
set(gca, 'Layer', 'top');
box off;

%% 5. SIMPAN
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r150', 'Gambar_4_PengaruhNeuron.png');
fprintf('\nGambar disimpan: Gambar_4_PengaruhNeuron.png\n');
