% ============================================================
%  MODEL FINAL M22 - SINGLE TRAINING + SEMUA PLOT UNTUK BAB IV
%  Arsitektur: HL=2, Neuron=128, LR=0.0001
% ============================================================
clear; clc; close all;

%% LANGKAH 1: Persiapan Data (identik dengan script 36 kombinasi)
data = readtable('dataset.xlsx');
X = table2array(data(:, 1:9))';     % [9 fitur × 2150 sampel]
[X_norm, settings_X] = mapminmax(X, 0, 1);
labels = data.label_numerik;
Y = full(ind2vec(labels' + 1));

fprintf('Data siap: %d sampel, %d fitur, %d kelas\n', size(X_norm,2), size(X_norm,1), size(Y,1));

%% LANGKAH 2: Setup Model M22 (parameter PERSIS sesuai pemenang tuning)
rng(42);                            % WAJIB: seed sama dengan saat tuning
net = patternnet([128 128]);        % HL=2, Neuron=128 per layer
net.trainFcn = 'traingdx';
net.trainParam.lr = 0.0001;         % LR=0.0001
net.trainParam.mc = 0.9;
net.trainParam.epochs = 1000;
net.trainParam.showWindow = true;   % WAJIB: tampilkan window training agar bisa save plot

net.divideFcn = 'dividerand';
net.divideParam.trainRatio = 0.70;
net.divideParam.valRatio   = 0.15;
net.divideParam.testRatio  = 0.15;

net = init(net);

%% LANGKAH 3: Training
fprintf('\nMulai training M22 (HL=2, Neuron=128, LR=0.0001)...\n');
tic;
[net, tr] = train(net, X_norm, Y);
waktu_training = toc;
fprintf('Selesai dalam %.2f detik\n\n', waktu_training);

%% LANGKAH 4: Prediksi untuk setiap subset
outputs_all   = net(X_norm);
outputs_train = net(X_norm(:, tr.trainInd));
outputs_val   = net(X_norm(:, tr.valInd));
outputs_test  = net(X_norm(:, tr.testInd));

Y_train = Y(:, tr.trainInd);
Y_val   = Y(:, tr.valInd);
Y_test  = Y(:, tr.testInd);

%% LANGKAH 5: PLOT 1 - Confusion Matrix Test (PALING PENTING)
figure('Position', [100 100 600 500]);
plotconfusion(Y_test, outputs_test);
title('Confusion Matrix - Test Set (M22)');
saveas(gcf, 'confusion_test.png');
fprintf('Plot disimpan: confusion_test.png\n');

%% LANGKAH 6: PLOT 2 - Confusion Matrix Semua (Train+Val+Test+All)
figure('Position', [100 100 1000 800]);
plotconfusion(Y_train, outputs_train, 'Training', ...
              Y_val,   outputs_val,   'Validation', ...
              Y_test,  outputs_test,  'Test', ...
              Y,       outputs_all,   'All');
saveas(gcf, 'confusion_all.png');
fprintf('Plot disimpan: confusion_all.png\n');

%% LANGKAH 7: PLOT 3 - Training Performance (Error vs Epoch)
figure('Position', [100 100 700 500]);
plotperform(tr);
saveas(gcf, 'training_performance.png');
fprintf('Plot disimpan: training_performance.png\n');

%% LANGKAH 8: PLOT 4 - Training State (Learning Rate Adaptasi)
figure('Position', [100 100 700 600]);
plottrainstate(tr);
saveas(gcf, 'training_state.png');
fprintf('Plot disimpan: training_state.png\n');

%% LANGKAH 9: Hitung Metrik Detail per Kelas
[~, y_true_idx] = max(Y_test);
[~, y_pred_idx] = max(outputs_test);

cm = zeros(4, 4);
for i = 1:length(y_true_idx)
    cm(y_pred_idx(i), y_true_idx(i)) = cm(y_pred_idx(i), y_true_idx(i)) + 1;
end

kelas_names = {'Normal','Anomali Tegangan','Anomali Ketidakseimbangan','Anomali Faktor Daya'};
prec_all = zeros(4, 1);
rec_all  = zeros(4, 1);
f1_all   = zeros(4, 1);
support  = zeros(4, 1);

fprintf('\n=== METRIK PER KELAS (Test Set) ===\n');
fprintf('%-28s %10s %10s %10s %10s\n', 'Kelas', 'Precision', 'Recall', 'F1-Score', 'Support');
fprintf('%s\n', repmat('-', 1, 72));

for c = 1:4
    TP = cm(c, c);
    FP = sum(cm(c, :)) - TP;
    FN = sum(cm(:, c)) - TP;
    support(c) = sum(cm(:, c));
    
    if (TP+FP) == 0
        prec_all(c) = 0;
    else
        prec_all(c) = TP / (TP+FP);
    end
    
    if (TP+FN) == 0
        rec_all(c) = 0;
    else
        rec_all(c) = TP / (TP+FN);
    end
    
    if (prec_all(c)+rec_all(c)) == 0
        f1_all(c) = 0;
    else
        f1_all(c) = 2 * prec_all(c) * rec_all(c) / (prec_all(c)+rec_all(c));
    end
    
    fprintf('%-28s %9.2f%% %9.2f%% %9.2f%% %10d\n', ...
        kelas_names{c}, prec_all(c)*100, rec_all(c)*100, f1_all(c)*100, support(c));
end

akurasi = sum(diag(cm)) / sum(cm(:));
macro_f1 = mean(f1_all);
weighted_f1 = sum(f1_all .* support) / sum(support);

fprintf('%s\n', repmat('-', 1, 72));
fprintf('%-28s %32s %9.2f%%\n', 'Macro F1-Score', '', macro_f1*100);
fprintf('%-28s %32s %9.2f%%\n', 'Weighted F1-Score', '', weighted_f1*100);
fprintf('%-28s %32s %9.2f%%\n', 'Akurasi Test', '', akurasi*100);
fprintf('%-28s %32s %9d\n', 'Total Sampel Test', '', sum(support));

%% LANGKAH 10: Simpan tabel metrik ke Excel
metrik = table(kelas_names', prec_all*100, rec_all*100, f1_all*100, support, ...
    'VariableNames', {'Kelas','Precision_pct','Recall_pct','F1_Score_pct','Support'});
writetable(metrik, 'metrics_summary.xlsx');
fprintf('\nTabel metrik disimpan: metrics_summary.xlsx\n');

%% LANGKAH 11: Simpan model terlatih untuk reproducibility
save('model_M22_final.mat', 'net', 'tr', 'settings_X', 'cm', 'metrik', ...
     'akurasi', 'macro_f1', 'weighted_f1', 'waktu_training');
fprintf('Model disimpan: model_M22_final.mat\n');

fprintf('\n=== SELESAI ===\n');
fprintf('5 file output siap dipakai di skripsi.\n');
