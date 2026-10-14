SetFactory("OpenCASCADE");

// Point and circular domain
Point(1) = {0, 0, 0};
Disk(1) = {0, 0, 0, 2.2, 2.2};
Point{1} In Surface{1};

// Mesh size
MeshSize{:} = 0.2;

// Create and save mesh 
Mesh 2;
Save "heat-plate.msh";
