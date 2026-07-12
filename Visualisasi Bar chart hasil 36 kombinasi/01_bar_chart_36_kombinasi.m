% =========================================================================
% SCRIPT 1: bar_chart_36_kombinasi.m
% TUJUAN: Bar chart Macro F1-Score untuk 36 kombinasi hyperparameter
%         Dengan highlight M22 sebagai konfigurasi terbaik (warna berbeda)
% INPUT : hasil_36_kombinasi.xlsx
% OUTPUT: Gambar_4_36Kombinasi_BarChart.png
% =========================================================================

clear; clc; close all;

%% 1. BACA DATA HASIL 36 KOMBINASI
[~, ~, raw] = xlsread('hasil_36_kombinasi.xlsx');
header = raw(1, :);

idx_kode    = find(strcmp(header, 'Kode'));
idx_macroF1 = find(strcmp(header, 'MacroF1'));

kode = raw(2:end, idx_kode);
macroF1 = cell2mat(raw(2:end, idx_macroF1)) * 100;

% Urutkan berdasarkan kode M01-M36
[kode_sorted, idx_sort] = sort(kode);
macroF1_sorted = macroF1(idx_sort);

fprintf('Total kombinasi: %d\n', length(kode_sorted));
fprintf('Macro F1 terbaik: %.2f%%\n', max(macroF1_sorted));

%% 2. BUAT BAR CHART
figure('Position', [50, 50, 1400, 500], 'Color', 'white');

warna_default = [70/255, 130/255, 180/255];
warna_terbaik = [230/255, 57/255, 70/255];

hold on;
for i = 1:length(macroF1_sorted)
    if strcmp(kode_sorted{i}, 'M22')
        bar(i, macroF1_sorted(i), 0.7, 'FaceColor', warna_terbaik, ...
            'EdgeColor', 'black', 'LineWidth', 1.2);
    else
        bar(i, macroF1_sorted(i), 0.7, 'FaceColor', warna_default, ...
            'EdgeColor', 'black', 'LineWidth', 0.8);
    end
end

% Anotasi M22
idx_m22 = find(strcmp(kode_sorted, 'M22'));
text(idx_m22, macroF1_sorted(idx_m22) + 3, ...
     sprintf('M22\n(%.2f%%)', macroF1_sorted(idx_m22)), ...
     'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
     'FontSize', 10, 'Color', warna_terbaik);
hold off;

%% 3. FORMAT GRAFIK
% Label X-axis vertikal - manual dengan text() untuk R2013b
set(gca, 'XTick', 1:length(kode_sorted));
set(gca, 'XTickLabel', []);  % hapus default label
set(gca, 'FontSize', 9);

% Buat label rotated manual
for i = 1:length(kode_sorted)
    text(i, -2.5, kode_sorted{i}, ...
         'Rotation', 45, ...
         'HorizontalAlignment', 'right', ...
         'FontSize', 9);
end

xlabel('Kode Model (M01 - M36)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Macro F1-Score (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Perbandingan Macro F1-Score untuk 36 Kombinasi Hyperparameter', ...
      'FontSize', 13, 'FontWeight', 'bold');

ylim([0, 100]);
xlim([0, length(kode_sorted)+1]);
grid on;
set(gca, 'GridLineStyle', '--');
set(gca, 'Layer', 'top');
box off;

%% 4. SIMPAN
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r150', 'Gambar_4_36Kombinasi_BarChart.png');
fprintf('Gambar disimpan: Gambar_4_36Kombinasi_BarChart.png\n');
