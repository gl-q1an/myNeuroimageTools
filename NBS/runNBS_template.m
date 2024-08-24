% runNBS_command
% matlab run_NBS_template
% It can output the nodes and edges in the results.

maxNumCompThreads(${RUN_CPUS});

disp('===== RUN NBS IN COMMAND =====')
disp(['It begins at ', char(datetime)])

% Set the parameters
% ----- Part 1 Statistical Model -----
UI.design.ui="${DESIGN_MATRIX}";
UI.contrast.ui="${CONTRAST}"; 

UI.test.ui="t-test";
UI.thresh.ui="3.1";
% ----- Part 2 Data ----
UI.matrices.ui="${NETWORK_FILE}";
UI.node_coor.ui="${NODE_COOR}";                         
UI.node_label.ui="${NODE_LABEL}";
% ----- Part 3 Advanced Setting ----
UI.exchange.ui=""; 
UI.perms.ui="${PREMS}";
UI.alpha.ui="${P_ALPHA}";
UI.method.ui="Run NBS"; 
UI.size.ui="Extent";
% ------------------------------------

% ------ Add -----
tmp.matrix = load(UI.design.ui);
[tmp.rows, tmp.cols] = size(tmp.matrix);
tmp.df = tmp.rows - 2;
tmp.p1_thresh = 0.001;
tmp.t_value = tinv(1 - tmp.p1_thresh, tmp.df);
UI.thresh.ui=num2str(tmp.t_value);
% --------------

NBSrun(UI,[])

if exist('nbs', 'var')
    save('nbs.mat', 'nbs');
    disp('The significant result is saved in the nbs.mat');

    [row, col, ~] = find(nbs.NBS.con_mat{1,1});
    numROIs = numel(nbs.NBS.node_label);
    roiCounts = zeros(numROIs, 1);

    for i = 1:numel(row)
        roiCounts(row(i)) = roiCounts(row(i)) + 1;
        roiCounts(col(i)) = roiCounts(col(i)) + 1;
    end

    roiNames = nbs.NBS.node_label;
    T = table(roiNames, roiCounts, 'VariableNames', {'ROI', 'Count'});
    T = sortrows(T, 'Count', 'descend');
    writetable(T, 'roi_counts.csv');

    fileID = fopen('edge_count.txt', 'w');

    for i = 1:length(row)
        fprintf(fileID, '%d-%d\n', row(i), col(i));
    end

    fclose(fileID);

    disp('The significant nodes and edges are saved in the roi_counts.csv');

else
    disp('There is no result.');
end

disp(['It ends at ', char(datetime)])
disp('===== END =====')