SetFactory("OpenCASCADE");

// measurment point
Point(1) = {0.02, 0.005, 0, 1.0};

// rectangle
Rectangle(1) = {0.0, 0, 0, 0.1, 0.01, 0};

// connect point to surface (https://stackoverflow.com/questions/36338025/how-to-ensure-node-points-in-gmsh)
Point{1} In Surface {1};

// physical groups
Physical Point("p") = {1};
Physical Curve("bl") = {4};
Physical Curve("br") = {2};
Physical Surface("s") = {1};

// mesh
MeshSize{:} = 0.002;
Mesh 2;
Save "rod.msh";




