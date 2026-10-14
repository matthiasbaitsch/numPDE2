SetFactory("OpenCASCADE");

Rectangle(1) = {0, 0, 0, 1, 1, 0};
Rectangle(2) = {0.3, 0.0, 0, 0.15, 1, 0};
Coherence;

Physical Surface("S1") = {3, 4};
Physical Surface("S2") = {2};
Physical Curve("ΓD") = {2, 4, 6, 8, 9, 10};

MeshSize{:} = 0.025;
Mesh 2;
Save "multi-lambda.msh";

