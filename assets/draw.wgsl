#import types::{settings, particles, view, counter};
#import functions::{surrounding_cells, cell_index};

struct VertexInput {
    @builtin(vertex_index) index: u32,
    @builtin(instance_index) instance: u32,
}

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec4<f32>,
    @location(1) world_position: vec3<f32>,
    @location(2) world_normal: vec3<f32>,
}

const PI: f32 = 3.14159265359;

@vertex
fn vertex(input: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    var local_position: vec3<f32>;
    var normal: vec3<f32>;

    // Générer une sphère directement (ignorer settings.shape)
    // Génération procédurale d'une UV-sphère
    let vertex_count = settings.sphere_resolution * settings.sphere_resolution * 6u;
    let longitude_segments = settings.sphere_resolution;
    let latitude_segments = settings.sphere_resolution / 2u;

    // Convertir l'indice en position sur la grille longitude/latitude
    let longitude_index = (input.index % longitude_segments);
    let latitude_index = ((input.index / longitude_segments) % latitude_segments);

    // Convertir en angles
    let phi = 2.0 * PI * (f32(longitude_index) / f32(longitude_segments));
    let theta = PI * (f32(latitude_index) / f32(latitude_segments));

    // Convertir en coordonnées cartésiennes (x, y, z)
    let x = sin(theta) * cos(phi);
    let y = cos(theta);
    let z = sin(theta) * sin(phi);

    local_position = settings.particle_size * vec3<f32>(x, y, z);
    // Pour une sphère, la normale est la direction du centre vers le point
    normal = normalize(local_position);

    let particle = particles.particles[input.instance];
    let center = particle.position;

    // Position dans l'espace du monde
    let world_position = local_position + center;
    let view_position = vec4<f32>(world_position, 1.0);

    // Transformation en position d'écran
    out.position = view.clip_from_world * view_position;

    // Stockage de la position et normale dans l'espace du monde pour l'éclairage
    out.world_position = world_position;
    out.world_normal = normal;

    // Assignation de la couleur
    if (settings.rgb == 1u) {
        let color_f32 = (f32(particle.color) + settings.time * settings.rgb_speed) % f32(settings.max_color_count);
        let color_1 = settings.colors[u32(floor(color_f32))];
        let color_2 = settings.colors[u32(ceil(color_f32)) % settings.max_color_count];
        let t = fract(color_f32);

        out.color = mix(color_1, color_2, t);
    } else {
        out.color = settings.colors[particle.color];
    }

    return out;
}

// Définition des sommets d'un cube - 8 sommets
var<private> cube_vertices: array<vec3<f32>, 8> = array<vec3<f32>, 8>(
    vec3<f32>(-1.0, -1.0, -1.0),  // 0: coin arrière-bas-gauche
    vec3<f32>( 1.0, -1.0, -1.0),  // 1: coin arrière-bas-droite
    vec3<f32>(-1.0,  1.0, -1.0),  // 2: coin arrière-haut-gauche
    vec3<f32>( 1.0,  1.0, -1.0),  // 3: coin arrière-haut-droite
    vec3<f32>(-1.0, -1.0,  1.0),  // 4: coin avant-bas-gauche
    vec3<f32>( 1.0, -1.0,  1.0),  // 5: coin avant-bas-droite
    vec3<f32>(-1.0,  1.0,  1.0),  // 6: coin avant-haut-gauche
    vec3<f32>( 1.0,  1.0,  1.0)   // 7: coin avant-haut-droite
);

// Indices pour les 12 triangles (6 faces) du cube
var<private> cube_indices: array<u32, 36> = array<u32, 36>(
    // Face arrière (Z négatif)
    0, 1, 2,  1, 3, 2,
    // Face avant (Z positif)
    4, 6, 5,  5, 6, 7,
    // Face gauche (X négatif)
    0, 2, 4,  2, 6, 4,
    // Face droite (X positif)
    1, 5, 3,  3, 5, 7,
    // Face bas (Y négatif)
    0, 4, 1,  1, 4, 5,
    // Face haut (Y positif)
    2, 3, 6,  3, 7, 6
);

// Normales pour chaque face (utilisées pour l'éclairage)
var<private> cube_normals: array<vec3<f32>, 6> = array<vec3<f32>, 6>(
    vec3<f32>(0.0, 0.0, -1.0),  // Face arrière
    vec3<f32>(0.0, 0.0, 1.0),   // Face avant
    vec3<f32>(-1.0, 0.0, 0.0),  // Face gauche
    vec3<f32>(1.0, 0.0, 0.0),   // Face droite
    vec3<f32>(0.0, -1.0, 0.0),  // Face bas
    vec3<f32>(0.0, 1.0, 0.0)    // Face haut
);

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    var final_color = in.color;

    // Éclairage simple, uniquement si activé
    if (settings.use_lighting == 1u) {
        // Direction de lumière fixe (venant d'en haut à droite)
        let light_dir = normalize(vec3<f32>(0.2, 1.0, 0.1));

        // Calcul simple de l'éclairage diffus
        let diff = max(dot(in.world_normal, light_dir), 0.0);

        // Lumière ambiante fixe à 30%
        let ambient = 0.3;

        // La couleur finale est un mélange de la couleur ambiante et diffuse
        final_color = vec4<f32>(
            final_color.rgb * (ambient + diff * 0.7),
            final_color.a
        );
    }

    return final_color;
}