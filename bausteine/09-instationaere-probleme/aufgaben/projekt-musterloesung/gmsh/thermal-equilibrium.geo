
SetFactory("OpenCASCADE");

Rectangle(1) = {0.0, 0, 0, 0.1, 0.1, 0};
Rectangle(2) = {0.1, 0, 0, 0.1, 0.1, 0};

Coherence;

Physical Curve("c1") = {2};
Physical Surface("s1") = {1};
Physical Surface("s2") = {2};

MeshSize{:} = 0.005;

Mesh 2;

Save "thermal-equilibrium.msh";




