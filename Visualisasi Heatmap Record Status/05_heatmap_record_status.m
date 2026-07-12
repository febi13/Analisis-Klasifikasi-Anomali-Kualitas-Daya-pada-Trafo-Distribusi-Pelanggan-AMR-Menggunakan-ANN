% =========================================================================
% SCRIPT: heatmap_record_status_v2.m
% TUJUAN: Perbaikan visual heatmap - warna teks adaptif
%         Sel gelap (biru) -> teks putih
%         Sel terang (kuning) -> teks hitam
% VERSI : MATLAB R2013b kompatibel
% =========================================================================

clear; clc; close all;

%% 1. DATA CROSS-TABULATION (dari Tahap 9)
cross_tab = [31, 1265;
             7,  847];

total_grand = sum(cross_tab(:));
agreement_rate = (cross_tab(1,1) + cross_tab(2,2)) / total_grand * 100;

fprintf('Agreement Rate: %.2f%%\n', agreement_rate);
fprintf('Total record: %d\n', total_grand);

%% 2. BUAT HEATMAP DENGAN COLORMAP PARULA (BIRU-KUNING)
figure('Position', [100, 100, 900, 700], 'Color', 'white');

imagesc(cross_tab);
colormap('parula');  % R2013b: parula (biru gelap - kuning terang)
hcb = colorbar;
set(get(hcb, 'Title'), 'String', 'Jumlah Record', ...
    'FontWeight', 'bold', 'FontSize', 11);

%% 3. TAMBAH LABEL ANGKA DENGAN WARNA TEKS ADAPTIF
% Ambang: nilai > 50% dari max cross_tab = sel "terang" (kuning)
max_val = max(cross_tab(:));
ambang_terang = max_val * 0.5;

for i = 1:size(cross_tab, 1)
    for j = 1:size(cross_tab, 2)
        nilai = cross_tab(i, j);
        persen = nilai / total_grand * 100;
        
        % Warna teks adaptif berdasarkan nilai sel
        if nilai > ambang_terang
            % Sel terang (kuning) - teks HITAM
            warna_teks = [0, 0, 0];
            font_weight = 'bold';
        else
            % Sel gelap (biru) - teks PUTIH
            warna_teks = [1, 1, 1];
            font_weight = 'bold';
        end
        
        text(j, i, sprintf('%d\n(%.2f%%)', nilai, persen), ...
             'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', ...
             'FontSize', 16, 'FontWeight', font_weight, ...
             'Color', warna_teks);
    end
end

%% 4. FORMAT AXIS
set(gca, 'XTick', 1:2);
set(gca, 'XTickLabel', {'Meter: Anomali', 'Meter: Normal'});
set(gca, 'YTick', 1:2);
set(gca, 'YTickLabel', {'Pelabelan: Anomali', 'Pelabelan: Normal'});
set(gca, 'FontSize', 12);

xlabel('Record Status Meter EDMI', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Pelabelan Multi-Standar', 'FontSize', 13, 'FontWeight', 'bold');

title({'Cross-Tabulation Pelabelan Multi-Standar vs Record Status', ...
       sprintf('Agreement Rate: %.2f%% | Cohen''s Kappa: 0,0126 (Slight)', ...
       agreement_rate)}, ...
      'FontSize', 13, 'FontWeight', 'bold');

% Garis pemisah sel (tebal)
hold on;
for i = 0.5:1:size(cross_tab,1)+0.5
    plot([0.5, size(cross_tab,2)+0.5], [i, i], 'k-', 'LineWidth', 2);
end
for j = 0.5:1:size(cross_tab,2)+0.5
    plot([j, j], [0.5, size(cross_tab,1)+0.5], 'k-', 'LineWidth', 2);
end
hold off;

axis equal tight;

%% 5. SIMPAN
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r300', 'Gambar_HeatmapRecordStatus_v2.png');
fprintf('\nGambar disimpan: Gambar_HeatmapRecordStatus_v2.png\n');