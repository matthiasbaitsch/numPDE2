SetFactory("OpenCASCADE");

d1 = 0.115;
d2 = 0.200;
d3 = 0.250;
l0 = 1;

Point(1)  = {           0, 0, 0};
Point(2)  = {          d1, 0, 0};
Point(3)  = {     d1 + d2, 0, 0};
Point(4)  = {d1 + d2 + d3, 0, 0};

Point(5)  = {           0, l0 + d3 + d2 + d1, 0};
Point(6)  = {          d1, l0 + d3 + d2,      0};
Point(7)  = {     d1 + d2, l0 + d3,           0};
Point(8)  = {d1 + d2 + d3, l0,                0};

Point(9)  = {d1 + d2 + d3 + l0, l0 + d3 + d2 + d1, 0};
Point(10) = {d1 + d2 + d3 + l0, l0 + d3 + d2,      0};
Point(11) = {d1 + d2 + d3 + l0, l0 + d3,           0};
Point(12) = {d1 + d2 + d3 + l0, l0,                0};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {1, 5};
Line(5) = {2, 6};
Line(6) = {3, 7};
Line(7) = {4, 8};
Line(11) = {5, 9};
Line(12) = {6, 10};
Line(13) = {7, 11};
Line(14) = {8, 12};
Line(15) = {9, 10};
Line(16) = {10, 11};
Line(17) = {11, 12};

Curve Loop(1) = {1, 5, 12, -15, -11, -4};
Curve Loop(2) = {2, 6, 13, -16, -12, -5};
Curve Loop(3) = {3, 7, 14, -17, -13, -6};

Plane Surface(1) = {1};
Plane Surface(2) = {2};
Plane Surface(3) = {3};

Physical Curve("wi") = {7, 14};
Physical Curve("wa") = {4, 11};
Physical Surface("s1") = {1};
Physical Surface("s2") = {2};
Physical Surface("s3") = {3};


Coherence;

MeshSize{:} = 0.025;

Mesh 2;

Save "corner.msh";





//+
//+
