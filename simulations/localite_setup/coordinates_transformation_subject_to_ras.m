% Set subject id
subject_id = 701;

% Load csv with all PRESTUS coordinates
all_simulation_coordinates = readtable('/project/3025011.02/TUS_simulations/planning/planning_coordinate_list.csv');

subject_simulation_coordinates = all_simulation_coordinates(all_simulation_coordinates.subject_id == subject_id, :);

%% Define a function to translate everything to RAS
function updatedTable = translateToRAS(filteredT, affineMatrix)
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
    voxel_coords1 = filteredT{:, 3:5};  % Columns 3,4,5
    voxel_coords2 = filteredT{:, 6:8};  % Columns 6,7,8

    % Number of rows
    numRows = height(filteredT);

    % Append ones for homogeneous coordinates
    voxel_coords1_homog = [voxel_coords1, ones(numRows, 1)];
    voxel_coords2_homog = [voxel_coords2, ones(numRows, 1)];

    % Apply affine transformation
    ras_coords1 = (affineMatrix * voxel_coords1_homog')';
    ras_coords2 = (affineMatrix * voxel_coords2_homog')';

    % Extract RAS coordinates
    ras_coords1 = ras_coords1(:, 1:3);
    ras_coords2 = ras_coords2(:, 1:3);

    % Update the table
    updatedTable = filteredT;
    updatedTable{:, 3:5} = ras_coords1;
    updatedTable{:, 6:8} = ras_coords2;

    % Optional: Rename columns
    updatedTable.Properties.VariableNames(3:5) = {'entry_x', 'entry_y', 'entry_z'};
    updatedTable.Properties.VariableNames(6:8) = {'focus_x', 'focus_y', 'focus_z'};
end

%% Load the NIfTI image information
info = niftiinfo('/project/3023001.06/Simulations/kenneth_test/original_data/sub-008/sub-008_ses-mri01_acq-t1mpragesagp20p9iso_run-1_T1w.nii.gz');

% Extract the affine transformation matrix
affine = info.Transform.T';

% Your voxel coordinates (replace with your actual coordinates)
i = 10;  % Voxel index along the first dimension
j = 175;  % Voxel index along the second dimension
k = 130;  % Voxel index along the third dimension

% Prepare the voxel coordinates
voxel_coords = [i; j; k; 1];

% Transform to RAS coordinates
ras_coords = affine * voxel_coords;

% Extract RAS coordinates
x = ras_coords(1);
y = ras_coords(2);
z = ras_coords(3);

% Display the results
fprintf('RAS coordinates: x = %f, y = %f, z = %f\n', x, y, z);

%% Apply function to existing table
% Call the function with your table and affine matrix
subject_RAS_coordinates = translateToRAS(subject_simulation_coordinates, affine);

% Display the updated table
disp('Updated Table with RAS Coordinates:');
disp(subject_RAS_coordinates);

%% Write table to subject folder
writetable(subject_RAS_coordinates,sprintf('/project/3025011.02/raw_data/other/sub-%03d/ses-01/sub-%03d_localite_coordinates.csv', subject_id, subject_id),'Delimiter',';')  