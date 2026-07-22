% =========================================================================
% SCRIPT 6: statistik_deskriptif.m
% TUJUAN: Menghitung statistik deskriptif (Mean, Median, Std, Min, Max)
%         untuk 9 parameter input ANN (V_R, V_S, V_T, I_R, I_S, I_T,
%         PF_R, PF_S, PF_T) dari dataset bersih (n = 2.150 record)
% INPUT : dataset_input_ANN.xlsx
% OUTPUT: Tabel_7_Statistik_Deskriptif.xlsx (siap copy-paste ke Word)
% =========================================================================

clear; clc; close all;

%% 1. BACA DATASET
[~, ~, raw] = xlsread('dataset_input_ANN_output.xlsx');
header = raw(1, :);

% Cari kolom 9 parameter input
fitur = {'V_R', 'V_S', 'V_T', 'I_R', 'I_S', 'I_T', 'PF_R', 'PF_S', 'PF_T'};
data = zeros(size(raw,1)-1, length(fitur));

for i = 1:length(fitur)
    idx_col = find(strcmp(header, fitur{i}));
    data(:, i) = cell2mat(raw(2:end, idx_col));
end

n = size(data, 1);
fprintf('Total record: %d\n', n);
fprintf('Jumlah fitur: %d\n\n', length(fitur));

%% 2. HITUNG 5 STATISTIK PER FITUR
mean_val = mean(data, 1);
median_val = median(data, 1);
std_val = std(data, 0, 1);  % 0 = pakai (n-1) untuk sample std
min_val = min(data, [], 1);
max_val = max(data, [], 1);

%% 3. TAMPILKAN KE COMMAND WINDOW (FORMAT TABEL)
fprintf('%-8s %-10s %-10s %-10s %-10s %-10s\n', ...
        'Param', 'Mean', 'Median', 'Std', 'Min', 'Max');
fprintf('%s\n', repmat('-', 1, 60));

for i = 1:length(fitur)
    fprintf('%-8s %-10.3f %-10.3f %-10.3f %-10.3f %-10.3f\n', ...
            fitur{i}, mean_val(i), median_val(i), std_val(i), ...
            min_val(i), max_val(i));
end

%% 4. SIMPAN KE EXCEL (siap copy-paste ke Word)
% Buat cell array untuk output
output = cell(length(fitur)+1, 6);
output{1,1} = 'Parameter';
output{1,2} = 'Mean';
output{1,3} = 'Median';
output{1,4} = 'Std';
output{1,5} = 'Min';
output{1,6} = 'Max';

for i = 1:length(fitur)
    output{i+1, 1} = fitur{i};
    output{i+1, 2} = round(mean_val(i)*1000)/1000;     % 3 desimal
    output{i+1, 3} = round(median_val(i)*1000)/1000;
    output{i+1, 4} = round(std_val(i)*1000)/1000;
    output{i+1, 5} = round(min_val(i)*1000)/1000;
    output{i+1, 6} = round(max_val(i)*1000)/1000;
end

% Simpan ke Excel
xlswrite('Tabel_7_Statistik_Deskriptif.xlsx', output);
fprintf('\nTabel disimpan: Tabel_7_Statistik_Deskriptif.xlsx\n');

%% 5. CETAK INSIGHT PENTING
fprintf('\n=== INSIGHT KUNCI ===\n');
fprintf('Tegangan rata-rata mendekati batas atas SPLN 241,5 V:\n');
fprintf('  V_R mean = %.3f V (selisih %.2f V dari batas)\n', ...
        mean_val(1), 241.5 - mean_val(1));
fprintf('  V_S mean = %.3f V (selisih %.2f V dari batas)\n', ...
        mean_val(2), 241.5 - mean_val(2));
fprintf('  V_T mean = %.3f V (selisih %.2f V dari batas)\n', ...
        mean_val(3), 241.5 - mean_val(3));

fprintf('\nArus rata-rata sangat rendah (dari rated 4,74 A):\n');
fprintf('  I_R mean = %.3f A (%.2f%% dari rated)\n', ...
        mean_val(4), mean_val(4)/4.74*100);
fprintf('  I_S mean = %.3f A (%.2f%% dari rated)\n', ...
        mean_val(5), mean_val(5)/4.74*100);
fprintf('  I_T mean = %.3f A (%.2f%% dari rated)\n', ...
        mean_val(6), mean_val(6)/4.74*100);

fprintf('\nFaktor Daya rata-rata negatif (mengindikasikan reverse power flow):\n');
fprintf('  PF_R mean = %.3f\n', mean_val(7));
fprintf('  PF_S mean = %.3f\n', mean_val(8));
fprintf('  PF_T mean = %.3f\n', mean_val(9));
