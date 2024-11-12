% Set subject id
subject_id = 701;

% Load csv with all PRESTUS coordinates
all_simulation_coordinates = readtable('/project/3025011.02/TUS_simulations/planning/planning_coordinate_list.csv');

subject_simulation_coordinates = all_simulation_coordinates(all_simulation_coordinates.subject_id == subject_id, :);

%% Define a function to translate everything to RAS
function subject_RAS_coordinates = translateToRAS(subject_simulation_coordinates, affineMatrix)
    % translateToRAS applies an affine transformation to voxel coordinates in a table.
    %
    % Parameters:
    %   filteredT     - The input table containing voxel coordinates.
    %   affineMatrix  - The 4x4 affine transformation matrix.
    %
    % Returns:
    %   updatedTable  - The table with updated RAS coordinates.

    % Validate affine matrix
    if ~isequal(size(affineMatrix), [4, 4])
        error('Affine matrix must be a 4x4 matrix.');
    end

    % Extract voxel coordinates
    voxel_coords_entry = subject_simulation_coordinates{:, 3:5};  % Columns 3,4,5
    voxel_coords_focus = subject_simulation_coordinates{:, 6:8};  % Columns 6,7,8

    % Number of rows
    numRows = height(subject_simulation_coordinates);

    % Append ones for homogeneous coordinates
    voxel_coords_entry_homog = [voxel_coords_entry, ones(numRows, 1)];
    voxel_coords_focus_homog = [voxel_coords_focus, ones(numRows, 1)];

    % Apply affine transformation
    ras_coords_entry = (affineMatrix * voxel_coords_entry_homog')';
    ras_coords_focus = (affineMatrix * voxel_coords_focus_homog')';

    % Extract RAS coordinates
    ras_coords_entry = ras_coords_entry(:, 1:3);
    ras_coords_focus = ras_coords_focus(:, 1:3);

    % Update the table
    subject_RAS_coordinates = subject_simulation_coordinates;
    subject_RAS_coordinates{:, 3:5} = ras_coords_entry;
    subject_RAS_coordinates{:, 6:8} = ras_coords_focus;

    % Optional: Rename columns
    subject_RAS_coordinates.Properties.VariableNames(3:5) = {'entry_x', 'entry_y', 'entry_z'};
    subject_RAS_coordinates.Properties.VariableNames(6:8) = {'focus_x', 'focus_y', 'focus_z'};
    
    % Round to 3 decimals
    subject_RAS_coordinates{:, 3:8} = round(subject_RAS_coordinates{:, 3:8}, 3);
end

%% Apply function to existing table
% Call the function with your table and affine matrix
subject_RAS_coordinates = translateToRAS(subject_simulation_coordinates, affine);

% Display the updated table
disp('Updated Table with RAS Coordinates:');
disp(subject_RAS_coordinates);

%% Write table to subject folder
writetable(subject_RAS_coordinates,sprintf('/project/3025011.02/raw_data/other/sub-%03d/ses-01/sub-%03d_localite_coordinates.csv', subject_id, subject_id),'Delimiter',';')  