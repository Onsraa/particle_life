use std::f32::consts::PI;
use bevy::{
    input::mouse::{MouseMotion, MouseWheel},
    prelude::*,
    render::extract_component::ExtractComponent,
};
use bevy_egui::EguiContexts;

#[derive(Component, ExtractComponent, Debug, Clone, Copy, Default)]
pub struct ParticleCamera;

#[derive(Component, Debug, Clone, Copy)]
pub struct CameraSettings {
    pub pan_speed: f32,
    pub scroll_speed: f32,
    pub rotation_speed: f32,
    pub sensitivity: f32,
}

impl Default for CameraSettings {
    fn default() -> Self {
        Self {
            pan_speed: 1.0,
            scroll_speed: 1.0,
            rotation_speed: 0.005,
            sensitivity: 0.3,
        }
    }
}

pub fn camera_controls(
    mut camera: Query<(&mut Transform, &CameraSettings), With<ParticleCamera>>,
    keyboard: Res<ButtonInput<KeyCode>>,
    mouse: Res<ButtonInput<MouseButton>>,
    mut mouse_motion: EventReader<MouseMotion>,
    mut mouse_wheel: EventReader<MouseWheel>,
    mut egui_contexts: EguiContexts,
    time: Res<Time>,
) {
    let egui_context = egui_contexts.ctx_mut();
    let block_mouse = egui_context.is_pointer_over_area() || egui_context.is_using_pointer();

    let (mut transform, settings) = camera.single_mut();
    let dt = time.delta_seconds();

    // Rotation de caméra avec le bouton droit de la souris
    if mouse.pressed(MouseButton::Right) && !block_mouse {
        for event in mouse_motion.read() {
            // Extraction des angles d'Euler actuels
            let (mut yaw, mut pitch, _) = transform.rotation.to_euler(EulerRot::YXZ);

            // Mise à jour des angles
            yaw -= event.delta.x * settings.rotation_speed * settings.sensitivity;
            pitch = (pitch + event.delta.y * settings.rotation_speed * settings.sensitivity)
                .clamp(-PI/2.0 + 0.01, PI/2.0 - 0.01); // Évite le gimbal lock

            // Application de la nouvelle rotation
            transform.rotation = Quat::from_euler(EulerRot::YXZ, yaw, pitch, 0.0);
        }
    } else {
        // Consommer les événements même si on ne les utilise pas
        mouse_motion.read().for_each(|_| {});
    }

    // Calcul des vecteurs de direction (avant, droite, haut)
    let forward = transform.forward();
    let right = transform.right();
    let up = Vec3::Y; // Utilisation du vecteur Y global pour simplifier le déplacement vertical

    // Déplacement de la caméra avec WASD + QE
    // Déplacement de la caméra avec WASD + QE
    let mut movement = Vec3::ZERO;

    // Déplacement avant/arrière
    if keyboard.pressed(KeyCode::KeyW) {
        movement = Vec3::new(
            movement.x + forward.x,
            movement.y + forward.y,
            movement.z + forward.z
        );
    }
    if keyboard.pressed(KeyCode::KeyS) {
        movement = Vec3::new(
            movement.x - forward.x,
            movement.y - forward.y,
            movement.z - forward.z
        );
    }

    // Déplacement gauche/droite
    if keyboard.pressed(KeyCode::KeyA) {
        movement = Vec3::new(
            movement.x - right.x,
            movement.y - right.y,
            movement.z - right.z
        );
    }
    if keyboard.pressed(KeyCode::KeyD) {
        movement = Vec3::new(
            movement.x + right.x,
            movement.y + right.y,
            movement.z + right.z
        );
    }

    // Déplacement haut/bas
    if keyboard.pressed(KeyCode::KeyQ) {
        movement = Vec3::new(
            movement.x + up.x,
            movement.y + up.y,
            movement.z + up.z
        );
    }
    if keyboard.pressed(KeyCode::KeyE) {
        movement = Vec3::new(
            movement.x - up.x,
            movement.y - up.y,
            movement.z - up.z
        );
    }

    // Normaliser le mouvement pour éviter la vitesse diagonale plus rapide
    if movement != Vec3::ZERO {
        movement = movement.normalize() * settings.pan_speed * dt * 100.0;
    }

    // Application du mouvement
    transform.translation = transform.translation + movement;

    // Zoom avec la molette de la souris
    if !block_mouse {
        for event in mouse_wheel.read() {
            let zoom_direction = Vec3::new(0.0, 0.0, -event.y * settings.scroll_speed);
            transform.translation = transform.translation + transform.rotation * zoom_direction;
        }
    }

    // Ajustement de la vitesse de panoramique avec shift
    if keyboard.pressed(KeyCode::ShiftLeft) || keyboard.pressed(KeyCode::ShiftRight) {
        movement = movement * 2.0;
    }

    // Reset de la caméra avec touche R
    if keyboard.just_pressed(KeyCode::KeyR) {
        transform.translation = Vec3::new(0.0, 0.0, 10.0);
        transform.rotation = Quat::from_euler(EulerRot::YXZ, 0.0, 0.0, 0.0);
    }
}
