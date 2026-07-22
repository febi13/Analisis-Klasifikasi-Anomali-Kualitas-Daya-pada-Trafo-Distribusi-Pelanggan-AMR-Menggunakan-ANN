% =========================================================================
% SCRIPT: distribusi_kelas_hasil_pelabelan.m
% TUJUAN: Bar chart distribusi 4 kelas hasil pelabelan multi-standar
%         (Normal, Anomali Tegangan, Anomali Ketidakseimbangan Beban,
%          Anomali Faktor Daya)
% MATLAB : R2013b compatible
% INPUT  : dataset_input_ANN_output.xlsx (atau 03_data_with_features_output.xlsx)
% OUTPUT : distribusi_kelas_hasil_pelabelan.png
% =========================================================================
clear; clc; close all;

%% 1. BACA DATA
filename_input = 'dataset_input_ANN_output.xlsx';
[~, ~, raw] = xlsread(filename_input);

header = raw(1, :);
idx_label = find(strcmp(header, 'label_final'));
if isempty(idx_label)
    error('Kolom label_final tidak ditemukan di %s. Cek header file!', filename_input);
end
label_final = raw(2:end, idx_label);

n_total = length(label_final);
fprintf('File dibaca: %s\n', filename_input);
fprintf('Total record: %d\n\n', n_total);

%% 2. HITUNG JUMLAH PER KELAS (urutan sesuai gambar)
kelas_names = {'Normal', 'Anomali Tegangan', ...
               'Anomali Ketidakseimbangan Beban', 'Anomali Faktor Daya'};
jumlah = zeros(1, 4);
for i = 1:4
    jumlah(i) = sum(strcmp(label_final, kelas_names{i}));
end
persen = jumlah / n_total * 100;

fprintf('--- Distribusi Kelas ---\n');
for i = 1:4
    fprintf('%-35s: %4d (%.2f%%)\n', kelas_names{i}, jumlah(i), persen(i));
end
fprintf('%s\n', repmat('-', 1, 50));
fprintf('%-35s: %4d (100.00%%)\n\n', 'Total', n_total);

%% 3. BAR CHART
figure('Position', [100, 100, 720, 450], 'Color', 'white');

warna = [ 31/255, 119/255, 180/255;   % biru  - Normal
         214/255,  39/255,  40/255;   % merah - Anomali Tegangan
         255/255, 165/255,  60/255;   % oranye- Anomali Ketidakseimbangan
         148/255, 103/255, 189/255];  % ungu  - Anomali Faktor Daya

hold on;
for i = 1:4
    bar(i, jumlah(i), 0.6, 'FaceColor', warna(i,:), ...
        'EdgeColor', 'black', 'LineWidth', 1);
end

% Label angka + persentase di atas tiap bar
for i = 1:4
    text(i, jumlah(i) + max(jumlah)*0.03, ...
         sprintf('%d\n(%.2f%%)', jumlah(i), persen(i)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
         'FontSize', 10);
end
hold off;

%% 4. FORMAT
set(gca, 'XTick', 1:4);
set(gca, 'XTickLabel', kelas_names);
set(gca, 'FontSize', 9);
xlabel('Kelas Anomali', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Jumlah Record', 'FontSize', 12, 'FontWeight', 'bold');
title({'Distribusi Kelas Hasil Pelabelan Multi-Standar', ...
       sprintf('(n = %d record)', n_total)}, ...
      'FontSize', 13, 'FontWeight', 'bold');

ylim([0, max(jumlah) * 1.2]);
xlim([0.3, 4.7]);
grid on;
set(gca, 'GridLineStyle', ':');
set(gca, 'Layer', 'top');
box on;

%% 5. SIMPAN
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r150', 'distribusi_kelas_hasil_pelabelan.png');
fprintf('Gambar disimpan: distribusi_kelas_hasil_pelabelan.png\n');
