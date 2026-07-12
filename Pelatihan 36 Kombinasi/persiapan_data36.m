% ============================================================
% LOOP 36 KOMBINASI HYPERPARAMETER (KOMPATIBEL MATLAB R2013b)
% ============================================================
clear; clc; close all;

% Load + normalisasi data
data = readtable('dataset.xlsx');
X = table2array(data(:, 1:9))';
[X_norm, ~] = mapminmax(X, 0, 1);
labels = data.label_numerik;
Y = full(ind2vec(labels' + 1));

% Matriks eksperimen
hidden_layers  = [1, 2, 3];
neurons        = [16, 32, 64, 128];
learning_rates = [0.0001, 0.001, 0.01];

% Pre-allocate array (cara R2013b - tidak pakai table('Size',...))
n_total = length(hidden_layers) * length(neurons) * length(learning_rates);
kode_arr      = cell(n_total, 1);
hl_arr        = zeros(n_total, 1);
neuron_arr    = zeros(n_total, 1);
lr_arr        = zeros(n_total, 1);
acc_arr       = zeros(n_total, 1);
macroF1_arr   = zeros(n_total, 1);
f1_normal_arr = zeros(n_total, 1);
f1_tegangan_arr = zeros(n_total, 1);
f1_unbalance_arr = zeros(n_total, 1);
f1_pf_arr     = zeros(n_total, 1);
waktu_arr     = zeros(n_total, 1);

kombinasi = 0;
for hl = hidden_layers
    for n = neurons
        for lr = learning_rates
            kombinasi = kombinasi + 1;
            kode = sprintf('M%02d', kombinasi);
            
            % Bangun arsitektur sesuai hl
            if hl == 1
                arch = n;
            elseif hl == 2
                arch = [n n];
            else
                arch = [n n n];
            end
            
            % Setup network
            rng(42);
            net = patternnet(arch);
            net.trainFcn = 'traingdx';
            net.trainParam.lr = lr;
            net.trainParam.epochs = 1000;
            net.trainParam.showWindow = false;
            net.divideParam.trainRatio = 0.70;
            net.divideParam.valRatio   = 0.15;
            net.divideParam.testRatio  = 0.15;
            net = init(net);
            
            % Train
            fprintf('[%2d/36] %s: HL=%d, Neuron=%d, LR=%.4f ... ', ...
                kombinasi, kode, hl, n, lr);
            tic;
            [net, tr] = train(net, X_norm, Y);
            t = toc;
            
            % Evaluasi
            X_test = X_norm(:, tr.testInd);
            Y_test = Y(:, tr.testInd);
            outputs_test = net(X_test);
            
            [~, y_true] = max(Y_test);
            [~, y_pred] = max(outputs_test);
            
            cm = zeros(4, 4);
            for i = 1:length(y_true)
                cm(y_pred(i), y_true(i)) = cm(y_pred(i), y_true(i)) + 1;
            end
            
            acc = sum(diag(cm)) / sum(cm(:));
            f1_per_class = zeros(1, 4);
            for c = 1:4
                TP = cm(c, c);
                FP = sum(cm(c, :)) - TP;
                FN = sum(cm(:, c)) - TP;
                if (TP+FP) == 0 || (TP+FN) == 0
                    f1_per_class(c) = 0;
                else
                    prec = TP/(TP+FP);
                    rec  = TP/(TP+FN);
                    if (prec+rec) == 0
                        f1_per_class(c) = 0;
                    else
                        f1_per_class(c) = 2*prec*rec/(prec+rec);
                    end
                end
            end
            macro_f1 = mean(f1_per_class);
            
            % Simpan ke array
            kode_arr{kombinasi}        = kode;
            hl_arr(kombinasi)          = hl;
            neuron_arr(kombinasi)      = n;
            lr_arr(kombinasi)          = lr;
            acc_arr(kombinasi)         = acc;
            macroF1_arr(kombinasi)     = macro_f1;
            f1_normal_arr(kombinasi)   = f1_per_class(1);
            f1_tegangan_arr(kombinasi) = f1_per_class(2);
            f1_unbalance_arr(kombinasi)= f1_per_class(3);
            f1_pf_arr(kombinasi)       = f1_per_class(4);
            waktu_arr(kombinasi)       = t;
            
            fprintf('Acc=%.3f, MacroF1=%.3f, Time=%.1fs\n', acc, macro_f1, t);
        end
    end
end

% Konversi array ke table (cara R2013b - pakai konstruktor langsung)
hasil = table(kode_arr, hl_arr, neuron_arr, lr_arr, ...
              acc_arr, macroF1_arr, ...
              f1_normal_arr, f1_tegangan_arr, f1_unbalance_arr, f1_pf_arr, ...
              waktu_arr, ...
    'VariableNames', {'Kode','HL','Neuron','LR','Akurasi','MacroF1', ...
                      'F1_Normal','F1_Tegangan','F1_Unbalance','F1_PF','Waktu_dtk'});

% Simpan ke Excel
writetable(hasil, 'hasil_36_kombinasi.xlsx');

% Urut dari terbaik
hasil_sorted = sortrows(hasil, 'MacroF1', 'descend');
fprintf('\n=== TOP 5 MODEL ===\n');
disp(hasil_sorted(1:5, :));
writetable(hasil_sorted, 'hasil_36_kombinasi_sorted.xlsx');

fprintf('\nSelesai. Hasil tersimpan:\n');
fprintf('  - hasil_36_kombinasi.xlsx (urut kombinasi)\n');
fprintf('  - hasil_36_kombinasi_sorted.xlsx (urut Macro F1 terbaik)\n');