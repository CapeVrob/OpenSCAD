// ============================================================
// Parametric Corner-Dowel Plate  (original design)
// One flat plate with a closed dowel socket at each of the 4 corners.
// Use one for the bottom and one for the top of a box with open sides
// (print two; the top one just sits upside down).
// Print flat, sockets pointing up, no supports needed.
//
// F6 to render, then File > Export > Export as STL.  Units are mm.
// ============================================================

/* [Output - choose what to export] */
// plate = the plate (print 2: bottom, and the top one flipped over in the box)
// panel_x = front/back panel (print 2) | panel_y = left/right panel (print 2)
// panels_layout = all enabled panels on one bed | preview = whole box, view only
part = "preview"; // [plate, panel_x, panel_y, panels_layout, preview]

/* [Plate] */
// Overall plate width (X)
plate_w        = 200;
// Overall plate depth (Y)
plate_d        = 150;
plate_thick    = 5;
// Rounded outer corner radius; 0 = automatic (concentric with each socket)
plate_corner_r = 0;      // 0 = automatic: follows the socket curve

/* [Dowel] */
// Measured outer diameter of your dowel
dowel_d        = 30;
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

/* [Panel slots (grooves between the dowel mounts)] */
// Thickness of the vertical panel that slides into the slot
panel_thick    = 3;
// Extra width so the panel slides in (0.2-0.4 typical)
slot_clearance = 0.3;
// How far the slot sinks into the plate (must be less than plate_thick)
slot_depth     = 3;
// Slot on each side (front = -Y edge, back = +Y edge, left = -X, right = +X)
slot_front     = true;
slot_back      = true;
slot_left      = true;
slot_right     = true;
// Shift slots sideways from the dowel centre line (+ = towards plate centre,
// - = towards outer edge). 0 = slot centred on the dowel centres.
slot_offset    = 0;

/* [Box & panels] */
// Distance between the INNER faces of the two plates. The dowel length is
// this (minus a little play) because the dowels run socket floor to socket floor.
box_gap        = 100;
// Panel THICKNESS is always panel_thick (set in the slots group above), so the
// panel and its slot stay linked: slot width = panel thickness + slot_clearance.
// Total play taken off the panel length and height so it slides in easily
panel_fit      = 0.4;
// Rounded corner radius of the panel outline
panel_corner_r = 3;
// solid | window (one big opening) | vents (horizontal slots) | holes (round hole grid)
panel_style    = "solid"; // [solid, window, vents, holes]
// Solid frame left around any window / vents / holes
panel_border   = 15;
// Corner radius of the window opening
panel_cut_r    = 4;
// Vents: number of slots and the height of each
vent_count     = 4;
vent_w         = 5;
// Holes: diameter and centre-to-centre spacing
hole_d         = 8;
hole_pitch     = 14;

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

slot_w = panel_thick + slot_clearance;

assert(slot_depth > 0 && slot_depth <= plate_thick - 1,
       "slot_depth must leave at least 1 mm of plate underneath: raise plate_thick or lower slot_depth");
assert(slot_w / 2 + abs(slot_offset) <= socket_r - 1,
       "Slot is too wide / too far off-centre to end cleanly on the sockets: reduce panel_thick or slot_offset");
// slots must not run into the optional centre window
assert(!center_window ||
       ((!(slot_front || slot_back) ||
         cy - slot_offset - slot_w / 2 > plate_d / 2 - window_border + 1) &&
        (!(slot_left || slot_right) ||
         cx - slot_offset - slot_w / 2 > plate_w / 2 - window_border + 1)),
       "A slot would run into the centre window: raise window_border or move the slot");

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

// One slot between two sockets: a strip along the dowel centre line, with the
// socket circles removed so the slot ends hug the socket walls.
// (dir = "x" runs along X at y = yc, dir = "y" runs along Y at x = xc)
module slot_strip(dir, pos) {
    z0 = plate_thick - slot_depth;
    translate([0, 0, z0])
        linear_extrude(slot_depth + fillet + 1)
            difference() {
                if (dir == "x")
                    translate([0, pos]) square([2 * cx, slot_w], center = true);
                else
                    translate([pos, 0]) square([slot_w, 2 * cy], center = true);
                for (c = centers) translate(c) circle(r = socket_r - 0.005);
            }
}

module slots() {
    if (slot_front) slot_strip("x", -cy + slot_offset);
    if (slot_back)  slot_strip("x",  cy - slot_offset);
    if (slot_left)  slot_strip("y", -cx + slot_offset);
    if (slot_right) slot_strip("y",  cx - slot_offset);
}

module plate() {
difference() {
    union() {
        plate_body();
        for (c = centers) translate([c[0], c[1], 0]) socket_body();
    }
    for (c = centers) translate([c[0], c[1], 0]) {
        dowel_bore();
        pin_hole();
    }
    slots();
}
}


// =================== panels ===================
// Largest flat panel length that fits between two sockets (slot end to slot end)
d_edge    = slot_w / 2 + abs(slot_offset);
max_len_x = 2 * (cx - sqrt(socket_r * socket_r - d_edge * d_edge));
max_len_y = 2 * (cy - sqrt(socket_r * socket_r - d_edge * d_edge));
panel_len_x = max_len_x - panel_fit;     // front / back panels
panel_len_y = max_len_y - panel_fit;     // left / right panels
panel_h     = box_gap + 2 * slot_depth - panel_fit;   // sinks into both plates
dowel_len   = box_gap - 2 * max(floor_thick, 0) - 0.5;

assert(box_gap >= 2 * (socket_depth + max(floor_thick, 0)) + 1,
       "box_gap too small: the sockets of the top and bottom plates would collide. Raise box_gap or lower socket_depth");
assert(panel_corner_r * 2 < min(panel_len_y, panel_h), "panel_corner_r too large");

module panel_outline(len, h) {
    offset(r = panel_corner_r) square([len - 2 * panel_corner_r, h - 2 * panel_corner_r], center = true);
}

module panel_cuts(len, h) {
    iw = len - 2 * panel_border;     // usable width inside the frame
    ih = h   - 2 * panel_border;     // usable height inside the frame
    if (panel_style == "window") {
        assert(iw > 2 * panel_cut_r && ih > 2 * panel_cut_r, "panel_border too big for a window");
        offset(r = panel_cut_r) square([iw - 2 * panel_cut_r, ih - 2 * panel_cut_r], center = true);
    } else if (panel_style == "vents") {
        pitch = ih / vent_count;
        assert(ih > 0 && vent_w <= pitch - 1.5, "vents too tall / too many for this panel: lower vent_count or vent_w, or panel_border");
        for (i = [0 : vent_count - 1])
            translate([0, -ih / 2 + pitch * (i + 0.5)])
                offset(r = vent_w / 2) square([iw - vent_w, 0.01], center = true);
    } else if (panel_style == "holes") {
        assert(hole_pitch > hole_d + 1, "hole_pitch must be larger than hole_d");
        nx = floor((iw - hole_d) / hole_pitch) + 1;
        ny = floor((ih - hole_d) / hole_pitch) + 1;
        assert(nx >= 1 && ny >= 1, "panel_border too big / holes too big for this panel");
        for (i = [0 : nx - 1], j = [0 : ny - 1])
            translate([(i - (nx - 1) / 2) * hole_pitch, (j - (ny - 1) / 2) * hole_pitch])
                circle(d = hole_d);
    }
}

// Panel lying flat (print orientation): length along X, height along Y, thickness along Z
module panel_flat(len, h) {
    linear_extrude(panel_thick)
        difference() {
            panel_outline(len, h);
            panel_cuts(len, h);
        }
}

// Panel standing in the box (for the preview)
module panel_standing(len, h) {
    translate([0, panel_thick / 2, 0]) rotate([90, 0, 0]) panel_flat(len, h);
}

module panels_layout() {
    items = concat(
        (slot_front ? [[panel_len_x]] : []), (slot_back ? [[panel_len_x]] : []),
        (slot_left  ? [[panel_len_y]] : []), (slot_right ? [[panel_len_y]] : []));
    for (i = [0 : len(items) - 1])
        translate([0, i * (panel_h + 8), 0]) panel_flat(items[i][0], panel_h);
}

module preview_box() {
    pt = plate_thick;
    color("burlywood") plate();
    color("burlywood") translate([0, 0, 2 * pt + box_gap]) mirror([0, 0, 1]) plate();
    color("sienna")
        for (c = centers) translate([c[0], c[1], pt + max(floor_thick, 0)])
            cylinder(d = dowel_d, h = dowel_len);
    zc = pt - slot_depth + panel_fit / 2 + panel_h / 2;
    color("lightsteelblue") {
        if (slot_front) translate([0, -cy + slot_offset, zc]) panel_standing(panel_len_x, panel_h);
        if (slot_back)  translate([0,  cy - slot_offset, zc]) panel_standing(panel_len_x, panel_h);
        if (slot_left)  translate([-cx + slot_offset, 0, zc]) rotate([0, 0, 90]) panel_standing(panel_len_y, panel_h);
        if (slot_right) translate([ cx - slot_offset, 0, zc]) rotate([0, 0, 90]) panel_standing(panel_len_y, panel_h);
    }
}

// ---------------- what gets rendered ----------------
if (part == "plate")              plate();
else if (part == "panel_x")       panel_flat(panel_len_x, panel_h);
else if (part == "panel_y")       panel_flat(panel_len_y, panel_h);
else if (part == "panels_layout") panels_layout();
else if (part == "preview")       preview_box();

echo(str("Plate: ", plate_w, " x ", plate_d, " x ", plate_thick, " mm; socket height ",
         socket_depth + max(floor_thick, 0), " mm"));
echo(str("Dowel centre spacing: ", 2 * cx, " x ", 2 * cy, " mm (X x Y)"));
echo(str("DOWEL LENGTH: ", dowel_len, " mm  (box_gap ", box_gap, " mm between plate inner faces)"));
echo(str("Slot width ", slot_w, " mm, sunk ", slot_depth, " mm (", plate_thick - slot_depth,
         " mm of plate left under it); panel thickness ", panel_thick, " mm"));
echo(str("PANEL front/back (panel_x): ", panel_len_x, " x ", panel_h, " x ", panel_thick, " mm"));
echo(str("PANEL left/right (panel_y): ", panel_len_y, " x ", panel_h, " x ", panel_thick, " mm"));
