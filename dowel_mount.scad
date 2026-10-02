// ============================================================
// Parametric Dowel Mount  (original design)
// Flat base plate with 4 countersunk screw holes + closed socket
// for a round dowel, with an optional cross hole to pin the dowel.
// Print with the flat base on the bed, socket pointing up.
// No supports needed.
//
// To use: change values below, press F6 (render), then
// File > Export > Export as STL.  Units are mm.
// ============================================================

/* [Dowel] */
// Measured outer diameter of your dowel
dowel_d        = 9.525;
// Extra gap so the dowel slides in (0.2-0.4 typical; test print first)
fit_clearance  = 0.3;
// How deep the dowel sits in the socket
socket_depth   = 25;
// Socket wall thickness
wall           = 4;
// Solid floor under the dowel (inside the socket)
floor_thick    = 0;      // 0 = dowel rests on the base plate itself

/* [Base plate] */
base_thickness = 3;
// Rounded corner radius of plate
plate_corner_r = 4;
// Distance from screw head edge to plate edge
edge_margin    = 3;

/* [Screws] */
// Screw shank diameter (clearance hole). M4 -> ~4.4
screw_d        = 4.4;
// Screw head diameter (for countersink and spacing)
screw_head_d   = 8.5;
// Countersink on (true) or plain through-hole (false)
countersink    = true;

/* [Dowel pin hole] */
side_hole      = true;
// Diameter of the pin/screw that locks the dowel
pin_d          = 3.4;
// Height of the pin hole above the top of the base plate
pin_height     = 12;

/* [Reinforcement] */
// Fillet (cone) where socket meets plate; 0 = none
fillet         = 3;

/* [Quality] */
$fn = 96;

// ---------------- derived values ----------------
socket_id   = dowel_d + fit_clearance;
socket_od   = socket_id + 2 * wall;
socket_r    = socket_od / 2;
head_r      = screw_head_d / 2;

// screws sit on the diagonals, clear of the socket
hole_off    = (socket_r + fillet + head_r + 1) / sqrt(2);
plate_side  = 2 * (hole_off + head_r + edge_margin);

// 90 degree countersink depth
csk_depth   = (screw_head_d - screw_d) / 2;

assert(!countersink || csk_depth < base_thickness,
       "Base too thin for this countersink: raise base_thickness or lower screw_head_d");
assert(pin_height < socket_depth + floor_thick + base_thickness,
       "pin_height is above the top of the socket");

module rounded_square(side, r) {
    offset(r = r) square(side - 2 * r, center = true);
}

module base_plate() {
    linear_extrude(base_thickness)
        rounded_square(plate_side, plate_corner_r);
}

module socket_body() {
    translate([0, 0, base_thickness - 0.01]) {
        cylinder(d = socket_od, h = socket_depth + floor_thick + 0.01);
        if (fillet > 0)
            cylinder(r1 = socket_r + fillet, r2 = socket_r, h = fillet);
    }
}

module screw_holes() {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * hole_off, sy * hole_off, 0]) {
            translate([0, 0, -1])
                cylinder(d = screw_d, h = base_thickness + 2);
            if (countersink)
                translate([0, 0, base_thickness - csk_depth])
                    cylinder(d1 = screw_d, d2 = screw_head_d + 0.01,
                             h = csk_depth + 0.01);
            else
                translate([0, 0, base_thickness - 0.01])
                    cylinder(d = screw_head_d, h = 1);
        }
}

module dowel_bore() {
    translate([0, 0, base_thickness + floor_thick])
        cylinder(d = socket_id, h = socket_depth + 1);
}

module pin_hole() {
    if (side_hole)
        translate([0, 0, base_thickness + pin_height])
            rotate([0, 90, 0])
                cylinder(d = pin_d, h = socket_od + 2 * fillet + 4, center = true);
}

difference() {
    union() {
        base_plate();
        socket_body();
    }
    dowel_bore();
    screw_holes();
    pin_hole();
}

echo(str("Plate: ", plate_side, " x ", plate_side, " mm; socket OD: ", socket_od,
         " mm; total height: ", base_thickness + socket_depth + floor_thick, " mm"));
echo(str("Screw spacing: ", 2 * hole_off, " mm square"));
