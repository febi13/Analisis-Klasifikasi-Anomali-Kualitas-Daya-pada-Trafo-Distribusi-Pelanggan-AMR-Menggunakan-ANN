% =========================================================================
% SCRIPT: bar_chart_distribusi.m  (VERSI PERBAIKAN UNTUK R2013b)
% TUJUAN: Membuat bar chart vertikal distribusi 4 kelas anomali
% PERBAIKAN:
%   - Hapus property 'GridAlpha' (tidak ada di R2013b)
%   - Label X-axis pakai spasi normal (lebih reliable di R2013b)
% =========================================================================

clear; clc; close all;

%% 1. BACA DATASET
[~, ~, raw] = xlsread('dataset_input_ANN.xlsx');
header = raw(1, :);
idx_label = find(strcmp(header, 'label_final'));
labels = raw(2:end, idx_label);
labels = cellfun(@char, labels, 'UniformOutput', false);

fprintf('Total record: %d\n', length(labels));

%% 2. HITUNG DISTRIBUSI KELAS
kelas_order = {'Normal', ...
               'Anomali Tegangan', ...
               'Anomali Ketidakseimbangan Beban', ...
               'Anomali Faktor Daya'};

total = length(labels);
counts = zeros(1, 4);
for i = 1:length(kelas_order)
    counts(i) = sum(strcmp(labels, kelas_order{i}));
end
persentase = (counts / total) * 100;

fprintf('\n%-35s %-10s %-10s\n', 'Kelas', 'Jumlah', 'Persen');
fprintf('%s\n', repmat('-', 1, 55));
for i = 1:length(kelas_order)
    fprintf('%-35s %-10d %.2f%%\n', kelas_order{i}, counts(i), persentase(i));
end
fprintf('%s\n', repmat('-', 1, 55));
fprintf('%-35s %-10d %.2f%%\n', 'TOTAL', total, 100);

%% 3. BUAT BAR CHART
figure('Position', [100, 100, 1000, 600], 'Color', 'white');

% Warna RGB 0-1
warna = [46/255,  134/255, 171/255;   % biru   - Normal
         230/255, 57/255,  70/255;    % merah  - Anomali Tegangan
         244/255, 162/255, 97/255;    % oranye - Anomali Ketidakseimbangan
         157/255, 78/255,  221/255];  % ungu   - Anomali Faktor Daya

hold on;
for i = 1:length(counts)
    bar(i, counts(i), 0.6, 'FaceColor', warna(i,:), ...
        'EdgeColor', 'black', 'LineWidth', 1.2);
end
hold off;

%% 4. LABEL DI ATAS BAR
y_offset = max(counts) * 0.02;
for i = 1:length(counts)
    label_text = sprintf('%d\n(%.2f%%)', counts(i), persentase(i));
    text(i, counts(i) + y_offset, label_text, ...
         'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'bottom', ...
         'FontSize', 11, 'FontWeight', 'bold');
end

%% 5. FORMAT GRAFIK
% Label X-axis dengan spasi normal (label panjang dimuat di gambar lebar)
set(gca, 'XTick', 1:length(counts));
set(gca, 'XTickLabel', {'Normal', ...
                        'Anomali Tegangan', ...
                        'Anomali Ketidakseimbangan', ...
                        'Anomali Faktor Daya'});
set(gca, 'FontSize', 10);

xlabel('Kelas Anomali', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Jumlah Record', 'FontSize', 12, 'FontWeight', 'bold');
title({'Distribusi Kelas Hasil Pelabelan Multi-Standar'; ...
       sprintf('(n = %d record)', total)}, ...
      'FontSize', 13, 'FontWeight', 'bold');

ylim([0, max(counts) * 1.18]);

% Grid TANPA GridAlpha (compat R2013b)
grid on;
set(gca, 'GridLineStyle', '--');
set(gca, 'Layer', 'top');

box off;

%% 6. SIMPAN GAMBAR
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r150', 'Gambar_4_Distribusi_Kelas.png');

fprintf('\nGambar berhasil disimpan: Gambar_4_Distribusi_Kelas.png\n');
fprintf('Resolusi: 150 DPI | Format: PNG\n');
