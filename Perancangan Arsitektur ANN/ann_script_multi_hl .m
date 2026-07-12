% ============================================================
%  PROGRAM ANN UNTUK MATLAB R2013b (VERSI DIPERBAIKI + MULTI HIDDEN LAYER)
% ============================================================
clear; clc; close all;

% 1. Membaca Data
data = readtable('dataset.xlsx');

% 2. Mempersiapkan Input (X)
X = table2array(data(:, 1:9))';     % [9 fitur × 2150 sampel]

% 3. NORMALISASI MIN-MAX (KRITIS! sebelumnya tidak ada)
[X_norm, settings_X] = mapminmax(X, 0, 1);

% 4. Mempersiapkan Target (Y)
labels = data.label_numerik;
Y = full(ind2vec(labels' + 1)); 

% 5. Membuat Arsitektur ANN
% ============================================================
% UBAH 2 PARAMETER INI UNTUK SETIAP PERCOBAAN:
% ------------------------------------------------------------
jumlahHiddenLayer = 1;         % <--- UBAH (1, 2, atau 3)
neuronPerLayer    = 16;        % <--- UBAH (16, 32, 64, atau 128)
% ------------------------------------------------------------
% Bangun vektor arsitektur otomatis:
%   jumlahHiddenLayer=1, neuronPerLayer=16 -> [16]
%   jumlahHiddenLayer=2, neuronPerLayer=16 -> [16 16]
%   jumlahHiddenLayer=3, neuronPerLayer=16 -> [16 16 16]
hiddenLayerSize = repmat(neuronPerLayer, 1, jumlahHiddenLayer);

net = patternnet(hiddenLayerSize);

% 6. Setting algoritma training
net.trainFcn = 'traingdx';     
net.trainParam.lr = 0.001;     % <--- UBAH (0.0001, 0.001, 0.01)
net.trainParam.mc = 0.9;       % Momentum (default)
net.trainParam.epochs = 1000;

% 7. Pembagian Data Stratified
net.divideFcn = 'dividerand';  
net.divideParam.trainRatio = 0.70;
net.divideParam.valRatio   = 0.15;
net.divideParam.testRatio  = 0.15;

% 8. Random seed SEBELUM init bobot
rng(42);
net = init(net);

% 9. Memulai Training
fprintf('Training: HL=%d, Neuron/Layer=%d, Arsitektur=[%s], LR=%.4f, Algo=%s\n', ...
    jumlahHiddenLayer, neuronPerLayer, num2str(hiddenLayerSize), ...
    net.trainParam.lr, net.trainFcn);
[net, tr] = train(net, X_norm, Y);

% 10. Evaluasi pada test set
X_test = X_norm(:, tr.testInd);
Y_test = Y(:, tr.testInd);
outputs_test = net(X_test);

% Plot confusion matrix
figure;
plotconfusion(Y_test, outputs_test);
title(sprintf('Test - HL:%d, Neuron:%d, LR:%.4f', ...
    jumlahHiddenLayer, neuronPerLayer, net.trainParam.lr));

% 11. Hitung F1-Score per kelas
[~, y_true_idx] = max(Y_test);
[~, y_pred_idx] = max(outputs_test);
cm = zeros(4, 4);
for i = 1:length(y_true_idx)
    cm(y_pred_idx(i), y_true_idx(i)) = cm(y_pred_idx(i), y_true_idx(i)) + 1;
end

fprintf('\nF1-Score per kelas:\n');
kelas_names = {'Normal','Anomali Tegangan','Anomali Ketidakseimbangan','Anomali Faktor Daya'};
f1_all = zeros(1, 4);
for c = 1:4
    TP = cm(c, c);
    FP = sum(cm(c, :)) - TP;
    FN = sum(cm(:, c)) - TP;
    if (TP + FP) == 0 || (TP + FN) == 0
        f1 = 0;
    else
        prec = TP / (TP + FP);
        rec  = TP / (TP + FN);
        if (prec + rec) == 0
            f1 = 0;
        else
            f1 = 2 * prec * rec / (prec + rec);
        end
    end
    f1_all(c) = f1;
    fprintf('  %s: F1=%.4f (support=%d)\n', kelas_names{c}, f1, sum(cm(:, c)));
end
fprintf('Macro F1-Score: %.4f\n', mean(f1_all));
fprintf('Akurasi Test  : %.4f\n', sum(diag(cm))/sum(cm(:)));
