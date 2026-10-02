// ============================================================
// Parametric Corner-Dowel Plate  (original design)
// One flat plate with a closed dowel socket at each of the 4 corners.
// Use one for the bottom and one for the top of a box with open sides
// (print two; the top one just sits upside down).
// Print flat, sockets pointing up, no supports needed.
//
// F6 to render, then File > Export > Export as STL.  Units are mm.
// ============================================================

/* [Plate] */
// Overall plate width (X)
plate_w        = 220;
// Overall plate depth (Y)
plate_d        = 120;
plate_thick    = 5;
// Rounded outer corner radius; 0 = automatic (concentric with each socket)
plate_corner_r = 0;      // 0 = automatic: follows the socket curve

/* [Dowel] */
// Measured outer diameter of your dowel
dowel_d        = 9.525;
// Gap so the dowel slides in (0.2-0.4 typical; test print first)
fit_clearance  = 0.3;
// How deep the dowel sits in the socket
socket_depth   = 25;
wall           = 4;
// Minimum gap between the widest part of the socket (incl. fillet flare)
// and the plate edge. Sockets never extend past the plate edge.
edge_margin    = 2;
// Solid floor under the dowel; 0 = dowel rests on the plate top,
// negative = bore goes through the plate (open hole)
floor_thick    = 0;
// Bore all the way through plate (lets you see/push the dowel out)
through_bore   = false;

/* [Dowel pin hole] */
side_hole      = true;
pin_d          = 3.4;
// Height of the pin hole above the top of the plate
pin_height     = 12;
// Direction of the pin hole: 0 = along X, 90 = along Y
pin_angle      = 0;

/* [Reinforcement] */
// Fillet (cone) where socket meets plate; 0 = none
fillet         = 3;

/* [Centre window (optional lightening / cable pass-through)] */
center_window  = false;
// Solid border left around the window
window_border  = 35;
window_corner_r= 8;

/* [Quality] */
$fn = 96;

// ---------------- derived values ----------------
socket_id = dowel_d + fit_clearance;
socket_od = socket_id + 2 * wall;
socket_r  = socket_od / 2;
base_r    = socket_r + fillet;                // widest radius of a socket (flare)
inset     = base_r + edge_margin;             // socket centre to plate edge
cx        = plate_w / 2 - inset;              // socket centre X
cy        = plate_d / 2 - inset;              // socket centre Y

// outer corner radius: auto = concentric with the socket (equal margin all round)
corner_r  = plate_corner_r > 0 ? plate_corner_r : inset;

assert(plate_w > 2 * inset + 1 && plate_d > 2 * inset + 1,
       "Plate too small for four sockets: increase plate_w / plate_d");
assert(corner_r <= min(plate_w, plate_d) / 2, "corner radius too big");
// a rounded corner must still fully contain the socket's widest circle
assert(corner_r <= inset || (corner_r - inset) * sqrt(2) + base_r <= corner_r,
       "plate_corner_r too large: it would cut into the socket. Lower it or raise edge_margin");
assert(pin_height < socket_depth + max(floor_thick, 0),
       "pin_height is above the top of the socket");
assert(!center_window ||
       (plate_w - 2 * window_border > 2 * window_corner_r &&
        plate_d - 2 * window_border > 2 * window_corner_r),
       "Window border too large for this plate size");

centers = [[ cx,  cy], [-cx,  cy], [ cx, -cy], [-cx, -cy]];

module plate_2d() {
    offset(r = corner_r)
        square([plate_w - 2 * corner_r, plate_d - 2 * corner_r], center = true);
}

module window_2d() {
    ww = plate_w - 2 * window_border;
    wd = plate_d - 2 * window_border;
    offset(r = window_corner_r)
        square([ww - 2 * window_corner_r, wd - 2 * window_corner_r], center = true);
}

module plate_body() {
    linear_extrude(plate_thick)
        difference() {
            plate_2d();
            if (center_window) window_2d();
        }
}

module socket_body() {
    translate([0, 0, plate_thick - 0.01]) {
        cylinder(d = socket_od, h = socket_depth + max(floor_thick, 0) + 0.01);
        if (fillet > 0)
            cylinder(r1 = socket_r + fillet, r2 = socket_r, h = fillet);
    }
}

module dowel_bore() {
    z0 = through_bore ? -1 : plate_thick + max(floor_thick, 0);
    translate([0, 0, z0])
        cylinder(d = socket_id, h = socket_depth + plate_thick + 2);
}

module pin_hole() {
    if (side_hole)
        translate([0, 0, plate_thick + pin_height])
            rotate([0, 0, pin_angle])
                rotate([0, 90, 0])
                    cylinder(d = pin_d, h = socket_od + 2 * fillet + 4, center = true);
}

difference() {
    union() {
        plate_body();
        for (c = centers) translate([c[0], c[1], 0]) socket_body();
    }
    for (c = centers) translate([c[0], c[1], 0]) {
        dowel_bore();
        pin_hole();
    }
}

echo(str("Plate: ", plate_w, " x ", plate_d, " x ", plate_thick, " mm; total height ",
         plate_thick + socket_depth + max(floor_thick, 0), " mm"));
echo(str("Dowel centre spacing: ", 2 * cx, " x ", 2 * cy, " mm (X x Y)"));
echo(str("Dowel length = (open gap between plates) + ", 2 * socket_depth,
         " mm (", socket_depth, " mm inserted at each end)"));
