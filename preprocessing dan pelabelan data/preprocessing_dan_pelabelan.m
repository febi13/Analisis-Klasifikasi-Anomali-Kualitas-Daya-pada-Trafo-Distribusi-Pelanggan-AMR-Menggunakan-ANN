% =========================================================================
% SCRIPT: preprocessing_dan_pelabelan.m (REVISI)
% TUJUAN: Preprocessing data mentah Load Profile AMR dan pelabelan
%         multi-standar untuk klasifikasi anomali kualitas daya
% MATLAB: R2013b compatible
% AUTHOR: Restu Febriani
% =========================================================================
%
% INPUT : LP_PLG_DAYA_197_KVA_MAR-MEI.xlsx (data mentah AMR, 2.160 record)
% OUTPUT: dataset_input_ANN_output.xlsx (data bersih + label, 2.150 record)
%         03_data_with_features_output.xlsx (data lengkap + semua kolom)
%
% STANDAR ACUAN:
%   - SPLN T6.001:2013 / IEC 60038 (Variasi Tegangan, 230 V +5%/-10%)
%   - Dugan et al. (2003) + NEMA MG-1 (Ketidakseimbangan Beban, 5%)
%   - Permen ESDM No. 28/2016 (Faktor Daya >= 0.85)
% =========================================================================

clear; clc; close all;
fprintf('=== PREPROCESSING DAN PELABELAN DATA AMR ===\n');
fprintf('Waktu mulai: %s\n\n', datestr(now));

%% TAHAP 1: BACA DATA MENTAH
fprintf('--- TAHAP 1: Membaca data mentah ---\n');

filename_input = 'LP_PLG_DAYA_197_KVA_MAR-MEI.xlsx';
sheet_name = 'Load_Survey_TRS (2)';

[num_data, txt_data, raw_data] = xlsread(filename_input, sheet_name);

% PENTING: xlsread menyertakan Date/Time sebagai serial number di num_data
% Kolom num_data setelah xlsread:
%   1 = Record No
%   2 = Date/Time (serial number Excel) <-- SKIP, bukan V_R!
%   3 = V_R (Avg Voltage Ph-R)
%   4 = V_S (Avg Voltage Ph-S)
%   5 = V_T (Avg Voltage Ph-T)
%   6 = I_R (Avg Current Ph-R)
%   7 = I_S (Avg Current Ph-S)
%   8 = I_T (Avg Current Ph-T)
%   9 = PF_R (Avg Exp PF Ph-R)
%  10 = PF_S (Avg Exp PF Ph-S)
%  11 = PF_T (Avg Exp PF Ph-T)

record_no = num_data(:, 1);
V_R       = num_data(:, 3);
V_S       = num_data(:, 4);
V_T       = num_data(:, 5);
I_R       = num_data(:, 6);
I_S       = num_data(:, 7);
I_T       = num_data(:, 8);
PF_R      = num_data(:, 9);
PF_S      = num_data(:, 10);
PF_T      = num_data(:, 11);

n_total = length(record_no);

% Ambil Record Status dan Date/Time dari raw_data
record_status = cell(n_total, 1);
datetime_str  = cell(n_total, 1);

for i = 1:n_total
    idx_raw = i + 2;
    
    % Record Status (kolom 12)
    if idx_raw <= size(raw_data, 1) && size(raw_data, 2) >= 12
        rs = raw_data{idx_raw, 12};
        if ischar(rs)
            record_status{i} = rs;
        else
            record_status{i} = '..........';
        end
    else
        record_status{i} = '..........';
    end
    
    % Date/Time (kolom 2)
    if idx_raw <= size(raw_data, 1)
        dt = raw_data{idx_raw, 2};
        if ischar(dt)
            datetime_str{i} = dt;
        elseif isnumeric(dt) && ~isnan(dt)
            try
                datetime_str{i} = datestr(dt + datenum('30-Dec-1899'), 'yyyy-mm-dd HH:MM:SS');
            catch
                datetime_str{i} = num2str(dt);
            end
        else
            datetime_str{i} = '';
        end
    else
        datetime_str{i} = '';
    end
end

fprintf('  File: %s\n', filename_input);
fprintf('  Total record mentah: %d\n', n_total);
fprintf('\n  Verifikasi 3 record pertama:\n');
for i = 1:min(3, n_total)
    fprintf('    Rec %d: V_R=%.2f, I_R=%.2f, PF_R=%.2f, RS=%s\n', ...
        record_no(i), V_R(i), I_R(i), PF_R(i), record_status{i});
end

% Sanity check
if mean(V_R) > 200 && mean(V_R) < 260
    fprintf('  [OK] V_R rata-rata %.1f V (masuk akal)\n', mean(V_R));
else
    fprintf('  [WARNING] V_R rata-rata %.1f (TIDAK masuk akal, cek kolom!)\n', mean(V_R));
end
if mean(I_R) < 10
    fprintf('  [OK] I_R rata-rata %.4f A (masuk akal)\n', mean(I_R));
else
    fprintf('  [WARNING] I_R rata-rata %.1f (TIDAK masuk akal, cek kolom!)\n', mean(I_R));
end

%% TAHAP 2: PREPROCESSING
fprintf('\n--- TAHAP 2: Preprocessing (hapus record tidak valid) ---\n');

idx_V_zero = (V_R == 0) | (V_S == 0) | (V_T == 0);
n_V_zero = sum(idx_V_zero);
fprintf('  Record dengan V = 0 V : %d\n', n_V_zero);

idx_PF_invalid = (abs(PF_R) > 1) | (abs(PF_S) > 1) | (abs(PF_T) > 1);
n_PF_invalid = sum(idx_PF_invalid);
fprintf('  Record dengan |PF| > 1: %d\n', n_PF_invalid);

idx_valid = ~idx_V_zero & ~idx_PF_invalid;
n_removed = sum(~idx_valid);
n_clean = sum(idx_valid);
fprintf('  Total record dihapus  : %d\n', n_removed);
fprintf('  Total record bersih   : %d\n', n_clean);

record_no = record_no(idx_valid);
datetime_str = datetime_str(idx_valid);
V_R = V_R(idx_valid); V_S = V_S(idx_valid); V_T = V_T(idx_valid);
I_R = I_R(idx_valid); I_S = I_S(idx_valid); I_T = I_T(idx_valid);
PF_R = PF_R(idx_valid); PF_S = PF_S(idx_valid); PF_T = PF_T(idx_valid);
record_status = record_status(idx_valid);

%% TAHAP 3: HITUNG FITUR TAMBAHAN
fprintf('\n--- TAHAP 3: Hitung fitur tambahan ---\n');

I_avg = (I_R + I_S + I_T) / 3;

unbalance_pct_raw = zeros(n_clean, 1);
for i = 1:n_clean
    if I_avg(i) > 0
        devs = [abs(I_R(i)-I_avg(i)), abs(I_S(i)-I_avg(i)), abs(I_T(i)-I_avg(i))];
        unbalance_pct_raw(i) = (max(devs) / I_avg(i)) * 100;
    end
end
fprintf('  I_avg range: %.4f - %.4f A\n', min(I_avg), max(I_avg));

%% TAHAP 4: NO-LOAD GATING
fprintf('\n--- TAHAP 4: No-Load Gating ---\n');

I_rated_CT = 4.74;
I_threshold = 0.05 * I_rated_CT;  % 0.237 A
fprintf('  Threshold: 5%% x %.2f = %.3f A\n', I_rated_CT, I_threshold);

idx_noload = I_avg < I_threshold;
unbalance_pct = unbalance_pct_raw;
unbalance_pct(idx_noload) = 0;

n_noload = sum(idx_noload);
fprintf('  No-load : %d (%.1f%%)\n', n_noload, n_noload/n_clean*100);
fprintf('  Loaded  : %d (%.1f%%)\n', n_clean-n_noload, (n_clean-n_noload)/n_clean*100);

%% TAHAP 5: PELABELAN MULTI-STANDAR
fprintf('\n--- TAHAP 5: Pelabelan Multi-Standar ---\n');

V_upper = 230 * 1.05;  % 241.5 V
V_lower = 230 * 0.90;  % 207.0 V
unb_thr = 5;
pf_thr  = 0.85;

fprintf('  Tegangan: %.1f - %.1f V\n', V_lower, V_upper);
fprintf('  Unbalance: %d%%\n', unb_thr);
fprintf('  PF: %.2f\n', pf_thr);

label_V         = cell(n_clean, 1);
label_unbalance = cell(n_clean, 1);
label_PF        = cell(n_clean, 1);
label_final     = cell(n_clean, 1);
label_numerik   = zeros(n_clean, 1);

for i = 1:n_clean
    % Tegangan
    if (V_R(i)>V_upper)||(V_S(i)>V_upper)||(V_T(i)>V_upper)
        label_V{i} = 'Overvoltage';
    elseif (V_R(i)<V_lower)||(V_S(i)<V_lower)||(V_T(i)<V_lower)
        label_V{i} = 'Undervoltage';
    else
        label_V{i} = 'Normal';
    end
    
    % Unbalance & PF
    if idx_noload(i)
        label_unbalance{i} = 'Normal';
        label_PF{i} = 'Normal';
    else
        if unbalance_pct(i) > unb_thr
            label_unbalance{i} = 'Tidak Seimbang';
        else
            label_unbalance{i} = 'Normal';
        end
        
        if (abs(PF_R(i))<pf_thr)||(abs(PF_S(i))<pf_thr)||(abs(PF_T(i))<pf_thr)
            label_PF{i} = 'Rendah';
        else
            label_PF{i} = 'Normal';
        end
    end
    
    % Hierarki: PF > Tegangan > Unbalance
    if strcmp(label_PF{i}, 'Rendah')
        label_final{i} = 'Anomali Faktor Daya';
        label_numerik(i) = 3;
    elseif ~strcmp(label_V{i}, 'Normal')
        label_final{i} = 'Anomali Tegangan';
        label_numerik(i) = 1;
    elseif strcmp(label_unbalance{i}, 'Tidak Seimbang')
        label_final{i} = 'Anomali Ketidakseimbangan Beban';
        label_numerik(i) = 2;
    else
        label_final{i} = 'Normal';
        label_numerik(i) = 0;
    end
end

%% TAHAP 6: REKAP
fprintf('\n--- TAHAP 6: Rekap Distribusi Kelas ---\n');

n_normal    = sum(label_numerik == 0);
n_tegangan  = sum(label_numerik == 1);
n_unbalance = sum(label_numerik == 2);
n_pf        = sum(label_numerik == 3);

fprintf('  Normal                          : %4d (%5.2f%%)\n', n_normal, n_normal/n_clean*100);
fprintf('  Anomali Tegangan                : %4d (%5.2f%%)\n', n_tegangan, n_tegangan/n_clean*100);
fprintf('  Anomali Ketidakseimbangan Beban : %4d (%5.2f%%)\n', n_unbalance, n_unbalance/n_clean*100);
fprintf('  Anomali Faktor Daya             : %4d (%5.2f%%)\n', n_pf, n_pf/n_clean*100);
fprintf('  -----------------------------------------\n');
fprintf('  Total                           : %4d (100.00%%)\n', n_clean);

%% TAHAP 7: SIMPAN
fprintf('\n--- TAHAP 7: Simpan hasil ---\n');

fn1 = 'dataset_input_ANN_output.xlsx';
h1 = {'V_R','V_S','V_T','I_R','I_S','I_T','PF_R','PF_S','PF_T','label_final','label_numerik'};
d1 = [num2cell([V_R,V_S,V_T,I_R,I_S,I_T,PF_R,PF_S,PF_T]), label_final, num2cell(label_numerik)];
xlswrite(fn1, h1, 1, 'A1');
xlswrite(fn1, d1, 1, 'A2');
fprintf('  Tersimpan: %s\n', fn1);

fn2 = '03_data_with_features_output.xlsx';
h2 = {'record_no','datetime','V_R','V_S','V_T','I_R','I_S','I_T','PF_R','PF_S','PF_T',...
      'I_avg','unbalance_pct','unbalance_pct_raw','record_status','label_V','label_unbalance','label_PF','label_final'};
d2 = [num2cell(record_no), datetime_str, ...
      num2cell([V_R,V_S,V_T,I_R,I_S,I_T,PF_R,PF_S,PF_T,I_avg,unbalance_pct,unbalance_pct_raw]), ...
      record_status, label_V, label_unbalance, label_PF, label_final];
xlswrite(fn2, h2, 1, 'A1');
xlswrite(fn2, d2, 1, 'A2');
fprintf('  Tersimpan: %s\n', fn2);

%% TAHAP 8: VERIFIKASI
fprintf('\n--- TAHAP 8: Verifikasi ---\n');
fprintf('  Record mentah  : %d\n', n_total);
fprintf('  Record dihapus : %d\n', n_removed);
fprintf('  Record bersih  : %d\n', n_clean);
fprintf('\n  Cek 3 record pertama:\n');
for i = 1:min(3, n_clean)
    fprintf('    Rec %d: V_R=%.2f I_R=%.3f PF_R=%.2f -> %s\n', ...
        record_no(i), V_R(i), I_R(i), PF_R(i), label_final{i});
end

fprintf('\n=== PREPROCESSING SELESAI ===\n');
fprintf('Waktu selesai: %s\n', datestr(now));
fprintf('\nHASIL YANG DIHARAPKAN:\n');
fprintf('  Normal: 854, A.Tegangan: 1054, A.Unbalance: 140, A.PF: 102\n');
