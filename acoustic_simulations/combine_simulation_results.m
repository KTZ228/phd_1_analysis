% Remove simnibs from the path to resolve repelem.m conflicts
% SimNIBS ships its own repelem.m that can shadow the built-in and cause bugs.
simnibs_path = '/home/affneu/kenvdzee/.conda/envs/simnibs_env';
matlab_paths = strsplit(path, pathsep);                  % current path as cell array
simnibs_on_path = any(strcmp(matlab_paths, simnibs_path)); % is the root on the path?
if simnibs_on_path
	rmpath(genpath(simnibs_path))   % remove root + all subfolders
end

% ====================== CONFIG ======================
base       = '/project/3025011.02/TUS_simulations';
seg_dir    = fullfile(base, 'segmentation_data');   % m2m_sub-xxx/ live here
conditions = {'planning', 'post-hoc'};              % the two planning regimes
out_csv    = fullfile(base, 'simulation_results.csv');
% ====================================================

rows = {};   % collect results (one struct per subj/cond/target)

% --- Loop over conditions ---
for c = 1:numel(conditions)
    cond     = conditions{c};
    cond_dir = fullfile(base, cond);

    % Find all target_* subfolders, keep only directories
    target_dirs = dir(fullfile(cond_dir, 'target_*'));
    target_dirs = target_dirs([target_dirs.isdir]);

    % --- Loop over targets ---
    for t = 1:numel(target_dirs)
        target   = target_dirs(t).name;             % e.g. 'target_1_1'
        targ_dir = fullfile(cond_dir, target);

        % --- pick the single relevant mask from target indices ---
        idx = sscanf(target, 'target_%d_%d');        % [group; sub]
        grp = idx(1); sub_idx = idx(2);
        % Hemisphere convention: odd sub_idx = left, even = right
        side = 'left'; if mod(sub_idx,2)==0, side = 'right'; end

        % Map target group -> mask filename suffix
        switch grp
            case 1, mask_suffix = sprintf('amygdala_%s', side);
            case 2, mask_suffix = sprintf('payam_dacc_%s_mask', side);
            case 3, continue;                         % target_3_* ignored
            otherwise
                warning('Unrecognized target group: %s', target);
                continue;
        end

        % Find all subject subfolders under this target
        subj_dirs = dir(fullfile(targ_dir, 'sub-*'));
        subj_dirs = subj_dirs([subj_dirs.isdir]);

        % --- Loop over subjects ---
        for s = 1:numel(subj_dirs)
            subj     = subj_dirs(s).name;           % e.g. 'sub-052'
            subj_dir = fullfile(targ_dir, subj);

            % --- locate the single data file ---
            % Pattern allows arbitrary duty-cycle / strength values.
            pat   = sprintf('%s_final_isppa_orig_coord_%s_dc*_strength_*.nii.gz', subj, target);
            hits  = dir(fullfile(subj_dir, pat));
            if isempty(hits)
                warning('No data file: %s / %s / %s', cond, target, subj);
                continue;
            elseif numel(hits) > 1
                warning('Multiple data files (%d), using first: %s / %s / %s', ...
                        numel(hits), cond, target, subj);
            end
            data_file = fullfile(hits(1).folder, hits(1).name);
            img = niftiread(data_file);             % load IPA volume (affine ignored)

            % --- the one relevant mask ---
            m2m_dir = fullfile(seg_dir, ['m2m_' subj]);
            mfile   = fullfile(m2m_dir, sprintf('%s_%s.nii.gz', subj, mask_suffix));
            mask    = niftiread(mfile) > 0;         % binarize

            % img and mask must share the same voxel grid (size check only)
            if ~isequal(size(img), size(mask))
                warning('Size mismatch (%s): %s vs mask %s', subj, target, mask_suffix);
                mval = NaN; maxval = NaN;
            else
                vals   = img(mask);                 % extract in-mask voxel values
                mval   = mean(vals, 'omitnan');     % mean IPA in region
                maxval = max(vals, [], 'omitnan');  % peak ISPPA in region
            end

            % Store one result row
            rows{end+1} = struct( ...                 %#ok<SAGROW>
                'subject',   subj, ...
                'condition', cond, ...
                'target',    target, ...
                'region',    mask_suffix, ...
                'mean_Ipa',  mval, ...
                'Isppa',     maxval);
        end
    end
end

% --- assemble & save ---
T = struct2table([rows{:}]);                          % cell of structs -> table
T = T(:, {'subject','condition','target','region','mean_Ipa','Isppa'});  % column order
writetable(T, out_csv);
fprintf('Saved %d rows to %s\n', height(T), out_csv);