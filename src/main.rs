use bevy::{diagnostic::FrameTimeDiagnosticsPlugin, prelude::*};
use bevy_egui::EguiPlugin;

use camera::{camera_controls, CameraSettings, ParticleCamera};
use compute::ComputePlugin;
use data::SimulationSettings;
use draw::DrawPlugin;
use events::ParticleEvent;

mod camera;
mod compute;
mod data;
mod draw;
mod events;
mod ui;

fn main() {
    App::new()
        .add_event::<ParticleEvent>()
        .add_plugins((
            DefaultPlugins,
            EguiPlugin,
            // Used by ui to display the fps.
            FrameTimeDiagnosticsPlugin::default(),
            ComputePlugin,
            DrawPlugin,
        ))
        .add_systems(Startup, setup)
        .add_systems(Update, (ui::ui, camera_controls).chain())
        .run();
}

fn setup(mut commands: Commands) {
    commands.spawn((
        Camera3dBundle {
            transform: Transform::from_xyz(0.0, 0.0, 30.0)  // Position plus éloignée
                .looking_at(Vec3::ZERO, Vec3::Y),
            ..default()
        },
        CameraSettings::default(),
        ParticleCamera,
    ));

    commands.spawn(DirectionalLightBundle {
        directional_light: DirectionalLight {
            color: Color::WHITE,
            illuminance: 10000.0,
            shadows_enabled: true,
            ..default()
        },
        transform: Transform::from_xyz(4.0, 8.0, 4.0).looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    });

    commands.insert_resource(AmbientLight {
        color: Color::WHITE,
        brightness: 0.3,
    });

    let mut settings = SimulationSettings::default();
    settings.randomize_attractions();
    commands.insert_resource(settings);
}
