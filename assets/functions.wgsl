#define_import_path functions

#import types::settings;

const PI: f32 = 3.14159;

fn closest_wrapped_other_position(pos: vec3<f32>, other_pos: vec3<f32>, bounds: vec3<f32>) -> vec3<f32> {
    var other = other_pos;
    var wrapped: vec3<f32>;

    // Wrapping en X
    if (other_pos.x > 0.) {
        wrapped.x = other.x - 2. * bounds.x;
    } else {
        wrapped.x = other.x + 2. * bounds.x;
    }

    // Wrapping en Y
    if (other_pos.y > 0.) {
       wrapped.y = other.y - 2. * bounds.y;
    } else {
       wrapped.y = other.y + 2. * bounds.y;
    }

    // Ajout du wrapping en Z
    if (other_pos.z > 0.) {
       wrapped.z = other.z - 2. * bounds.z;
    } else {
       wrapped.z = other.z + 2. * bounds.z;
    }

    // Choisir la coordonnée la plus proche pour chaque dimension
    if abs(pos.x - wrapped.x) < abs(pos.x - other.x) {
        other.x = wrapped.x;
    }
    if abs(pos.y - wrapped.y) < abs(pos.y - other.y) {
        other.y = wrapped.y;
    }
    if abs(pos.z - wrapped.z) < abs(pos.z - other.z) {
        other.z = wrapped.z;
    }

    return other;
}

fn get_matrix_value(x: u32, y: u32) -> f32 {
    // var s = settings;
    let flat_index = x + y * settings.max_color_count;
    let index = flat_index / 4;
    let offset = flat_index % 4;
    return settings.matrix[index][offset];
}

fn cell_count() -> u32 {
    return settings.cell_count.x * settings.cell_count.y;
}

fn cell_index(position: vec3<f32>) -> u32 {
    let cell_3d = cell_index_3d(position);
    // Index linéaire pour une grille 3D
    let cell_index = cell_3d.x +
                     cell_3d.y * settings.cell_count.x +
                     cell_3d.z * settings.cell_count.x * settings.cell_count.y;
    return cell_index;
}

fn cell_index_3d(position: vec3<f32>) -> vec3<u32> {
    // Déplace la position de [-bounds, bounds] à [0, 2 * bounds]
    let p = settings.bounds + position;
    return vec3<u32>(floor(p / settings.max_distance));
}

fn surrounding_cells(position: vec3<f32>) -> array<u32, 27> {
    let cell = cell_index_3d(position);
    let cells = settings.cell_count;

    var result: array<u32, 27>;
    var index = 0u;

    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            for (var dz = -1; dz <= 1; dz++) {
                // Utilisation de rem_euclid pour gérer correctement les indices négatifs
                let x = rem_euclid(i32(cell.x) + dx, i32(cells.x));
                let y = rem_euclid(i32(cell.y) + dy, i32(cells.y));
                let z = rem_euclid(i32(cell.z) + dz, i32(cells.z));

                // Calcul de l'index 1D à partir des coordonnées 3D
                let cell_idx = x +
                               y * i32(cells.x) +
                               z * i32(cells.x) * i32(cells.y);

                result[index] = u32(cell_idx);
                index++;
            }
        }
    }

    return result;
}

// Fonction rem_euclid améliorée pour WGSL
fn rem_euclid(n: i32, modulo: i32) -> i32 {
    let m = n % modulo;
    return select(m + modulo, m, m >= 0);
}

fn acceleration(rmin: f32, dpos: vec2<f32>, a: f32) -> vec2<f32> {
    switch (settings.acceleration_method) {
        case 0u: { return acceleration1(rmin, dpos, a); }
        case 1u: { return acceleration2(rmin, dpos, a); }
        case 2u: { return acceleration3(rmin, dpos, a); }
        case 3u: { return acceleration90_(rmin, dpos, a); }
        case 4u: { return acceleration_attr(rmin, dpos, a); }
        case 5u: { return planets(rmin, dpos, a); }
        default: { return acceleration1(rmin, dpos, a); }
    }
}

fn acceleration1(rmin: f32, dpos: vec2<f32>, a: f32) -> vec2<f32> {
    let dist = length(dpos);
    var force: f32;
    if (dist < rmin) {
        // always push away. goes from -2 to 0 for dist 0 to rmin
        force = (dist / rmin - 1.);
    } else {
        force = a * (1. - abs(1. + rmin - 2. * dist) / (1. - rmin));
    }
    return dpos * force / dist;
}

// TODO: make these more efficient by not reusing acceleration1
fn acceleration2(rmin: f32, dpos: vec2<f32>, a: f32) -> vec2<f32> {
    let dist = length(dpos);
    return acceleration1(rmin, dpos, a) / dist;
}

fn acceleration3(rmin: f32, dpos: vec2<f32>, a: f32) -> vec2<f32> {
    let dist = length(dpos);
    return acceleration1(rmin, dpos, a) / (dist * dist);
}

fn acceleration90_(rmin: f32, dpos: vec2<f32>, a: f32) -> vec2<f32> {
    let dist = length(dpos);
    var force = a * (1. - dist);
    return vec2<f32>(-dpos.y, dpos.x) * force / dist;
}

fn acceleration_attr(rmin: f32, dpos: vec2<f32>, a: f32) -> vec2<f32> {
   let dist = length(dpos);
   var force = 1. - dist;
   let angle = -a * PI;
   return vec2<f32>(
      cos(angle) * dpos.x + sin(angle) * dpos.y,
       -sin(angle) * dpos.x +cos(angle) * dpos.y,
   ) * force
       / dist;
}

fn planets(rmin: f32, dpos: vec2<f32>, a: f32) -> vec2<f32> {
    let dist = max(0.01, length(dpos));
    return dpos * 0.01 / (dist * dist * dist);
}
