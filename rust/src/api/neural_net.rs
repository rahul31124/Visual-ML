use crate::neural_engine::{Layer, MicroNeuralNet};
use rand::distributions::Uniform;
use rand::prelude::*;
use std::f32::consts::PI;
use std::sync::Mutex;

#[derive(Clone, Debug)]
pub struct LayerConfig {
    pub in_features: usize,
    pub out_features: usize,
    pub activation: String,
}

#[derive(Clone, Debug)]
pub struct NetworkConfig {
    pub layers: Vec<LayerConfig>,
    pub learning_rate: f32,
    pub momentum: f32,
    pub regularization: String,
    pub reg_rate: f32,
    pub problem_type: String,
}

#[derive(Clone, Debug)]
pub struct DataPoint {
    pub x: Vec<f32>,
    pub y: Vec<f32>,
}

#[derive(Clone, Debug)]
pub struct LossLandscape3D {
    pub grid_size: usize,
    pub w1_min: f32,
    pub w1_max: f32,
    pub w2_min: f32,
    pub w2_max: f32,
    pub loss_grid: Vec<f32>,
    pub current_w1: f32,
    pub current_w2: f32,
    pub current_loss: f32,
}

#[derive(Clone, Debug)]
pub struct TrainingEpochResult {
    pub epoch: i32,
    pub train_loss: f32,
    pub test_loss: f32,
    pub train_accuracy: f32,
    pub test_accuracy: f32,
    pub weights_summary: Vec<Vec<Vec<f32>>>,
    pub biases_summary: Vec<Vec<f32>>,
    pub decision_boundary: Vec<f32>,
    pub neuron_activations_grid: Vec<Vec<f32>>,
    pub landscape_3d: Option<LossLandscape3D>,
}

static ACTIVE_NET: Mutex<Option<MicroNeuralNet>> = Mutex::new(None);

#[flutter_rust_bridge::frb(sync)]
pub fn init_network(config: NetworkConfig) -> bool {
    let mut specs = Vec::new();
    for l in &config.layers {
        specs.push((l.in_features, l.out_features, l.activation.clone()));
    }

    let net = MicroNeuralNet::new(
        &specs,
        config.learning_rate,
        config.momentum,
        &config.regularization,
        config.reg_rate,
        &config.problem_type,
    );

    let mut lock = ACTIVE_NET.lock().unwrap();
    *lock = Some(net);
    true
}

#[flutter_rust_bridge::frb(sync)]
pub fn step_training(
    train_points: Vec<DataPoint>,
    test_points: Vec<DataPoint>,
    epochs: i32,
    include_landscape: bool,
) -> TrainingEpochResult {
    let mut lock = ACTIVE_NET.lock().unwrap();
    let net = match lock.as_mut() {
        Some(n) => n,
        None => {
            return TrainingEpochResult {
                epoch: 0,
                train_loss: 0.0,
                test_loss: 0.0,
                train_accuracy: 0.0,
                test_accuracy: 0.0,
                weights_summary: Vec::new(),
                biases_summary: Vec::new(),
                decision_boundary: Vec::new(),
                neuron_activations_grid: Vec::new(),
                landscape_3d: None,
            };
        }
    };

    let in_features = if !net.layers.is_empty() {
        net.layers[0].in_features
    } else {
        2
    };

    let train_x: Vec<Vec<f32>> = train_points
        .iter()
        .map(|p| {
            if p.x.len() == in_features {
                p.x.clone()
            } else {
                let x1 = if !p.x.is_empty() { p.x[0] } else { 0.0 };
                let x2 = if p.x.len() > 1 { p.x[1] } else { 0.0 };
                net.expand_features(x1, x2)
            }
        })
        .collect();
    let train_y: Vec<Vec<f32>> = train_points.iter().map(|p| p.y.clone()).collect();

    let test_x: Vec<Vec<f32>> = test_points
        .iter()
        .map(|p| {
            if p.x.len() == in_features {
                p.x.clone()
            } else {
                let x1 = if !p.x.is_empty() { p.x[0] } else { 0.0 };
                let x2 = if p.x.len() > 1 { p.x[1] } else { 0.0 };
                net.expand_features(x1, x2)
            }
        })
        .collect();
    let test_y: Vec<Vec<f32>> = test_points.iter().map(|p| p.y.clone()).collect();

    net.train_batch(&train_x, &train_y, epochs);

    let (train_loss, train_accuracy) = net.compute_metrics(&train_x, &train_y);
    let (test_loss, test_accuracy) = if !test_x.is_empty() {
        net.compute_metrics(&test_x, &test_y)
    } else {
        (train_loss, train_accuracy)
    };

    let num_layers = net.layers.len();

    let mut weights_summary = Vec::with_capacity(num_layers);
    let mut biases_summary = Vec::with_capacity(num_layers);
    for l in &net.layers {
        let mut lw = Vec::with_capacity(l.out_features);
        for i in 0..l.out_features {
            let mut row = Vec::with_capacity(l.in_features);
            for j in 0..l.in_features {
                row.push(l.weights[[i, j]]);
            }
            lw.push(row);
        }
        weights_summary.push(lw);
        biases_summary.push(l.biases.clone());
    }

    let grid_res = 30;
    let mut decision_boundary = Vec::with_capacity(grid_res * grid_res);
    for row in 0..grid_res {
        let y_val = 2.0 - (row as f32 / (grid_res - 1) as f32) * 4.0;
        for col in 0..grid_res {
            let x_val = -2.0 + (col as f32 / (grid_res - 1) as f32) * 4.0;
            let features = net.expand_features(x_val, y_val);
            let pred = net.predict(&features);
            decision_boundary.push(pred[0]);
        }
    }

    let neuron_res = 15;
    let mut hidden_count = 0;
    for l in 0..(num_layers.saturating_sub(1)) {
        hidden_count += net.layers[l].out_features;
    }
    let mut neuron_activations_grid = vec![Vec::with_capacity(neuron_res * neuron_res); hidden_count];

    if hidden_count > 0 {
        for row in 0..neuron_res {
            let y_val = 2.0 - (row as f32 / (neuron_res - 1) as f32) * 4.0;
            for col in 0..neuron_res {
                let x_val = -2.0 + (col as f32 / (neuron_res - 1) as f32) * 4.0;
                let features = net.expand_features(x_val, y_val);
                let (_raw, activated) = net.forward_full(&features);

                let mut n_idx = 0;
                for l in 0..(num_layers.saturating_sub(1)) {
                    for act in &activated[l + 1] {
                        neuron_activations_grid[n_idx].push(*act);
                        n_idx += 1;
                    }
                }
            }
        }
    }

    let landscape_3d = if include_landscape && !net.layers.is_empty() && net.layers[0].in_features >= 2 {
        let current_w1 = net.layers[0].weights[[0, 0]];
        let current_w2 = net.layers[0].weights[[0, 1]];
        let current_loss = train_loss;

        let grid_size = 14;
        let span = 2.2;
        let w1_min = current_w1 - span;
        let w1_max = current_w1 + span;
        let w2_min = current_w2 - span;
        let w2_max = current_w2 + span;

        let mut loss_grid = Vec::with_capacity(grid_size * grid_size);

        for row in 0..grid_size {
            let w2 = w2_min + (row as f32 / (grid_size - 1) as f32) * (w2_max - w2_min);
            for col in 0..grid_size {
                let w1 = w1_min + (col as f32 / (grid_size - 1) as f32) * (w1_max - w1_min);

                net.layers[0].weights[[0, 0]] = w1;
                net.layers[0].weights[[0, 1]] = w2;

                let (sampled_loss, _) = net.compute_metrics(&train_x, &train_y);
                loss_grid.push(sampled_loss.min(8.0));
            }
        }

        net.layers[0].weights[[0, 0]] = current_w1;
        net.layers[0].weights[[0, 1]] = current_w2;

        Some(LossLandscape3D {
            grid_size,
            w1_min,
            w1_max,
            w2_min,
            w2_max,
            loss_grid,
            current_w1,
            current_w2,
            current_loss,
        })
    } else {
        None
    };

    TrainingEpochResult {
        epoch: net.current_epoch,
        train_loss,
        test_loss,
        train_accuracy,
        test_accuracy,
        weights_summary,
        biases_summary,
        decision_boundary,
        neuron_activations_grid,
        landscape_3d,
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_manual_weight(layer_idx: usize, row: usize, col: usize, val: f32) -> bool {
    let mut lock = ACTIVE_NET.lock().unwrap();
    if let Some(net) = lock.as_mut() {
        if layer_idx < net.layers.len() {
            let layer = &mut net.layers[layer_idx];
            if row < layer.out_features && col < layer.in_features {
                layer.weights[[row, col]] = val;
                return true;
            }
        }
    }
    false
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_manual_bias(layer_idx: usize, idx: usize, val: f32) -> bool {
    let mut lock = ACTIVE_NET.lock().unwrap();
    if let Some(net) = lock.as_mut() {
        if layer_idx < net.layers.len() {
            let layer = &mut net.layers[layer_idx];
            if idx < layer.out_features {
                layer.biases[idx] = val;
                return true;
            }
        }
    }
    false
}

#[flutter_rust_bridge::frb(sync)]
pub fn reset_training() -> bool {
    let mut lock = ACTIVE_NET.lock().unwrap();
    if let Some(net) = lock.as_mut() {
        net.current_epoch = 0;
        for layer in &mut net.layers {
            let act = layer.activation.clone();
            *layer = Layer::new(layer.in_features, layer.out_features, act);
        }
    }
    true
}

#[flutter_rust_bridge::frb(sync)]
pub fn generate_dataset(dataset_type: String, count: usize, noise: f32) -> Vec<DataPoint> {
    let mut rng = rand::thread_rng();
    let noise_dist = Uniform::new(-noise, noise);
    let mut points = Vec::with_capacity(count);

    match dataset_type.to_lowercase().as_str() {
        "circle" => {
            let half = count / 2;
            for _ in 0..half {
                let r = rng.gen_range(0.0f32..0.55f32);
                let theta = rng.gen_range(0.0f32..(2.0 * PI));
                let x1 = r * theta.cos() + rng.sample(noise_dist);
                let x2 = r * theta.sin() + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![0.0],
                });
            }
            for _ in half..count {
                let r = rng.gen_range(0.85f32..1.35f32);
                let theta = rng.gen_range(0.0f32..(2.0 * PI));
                let x1 = r * theta.cos() + rng.sample(noise_dist);
                let x2 = r * theta.sin() + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![1.0],
                });
            }
        }
        "xor" => {
            for _ in 0..count {
                let x1 = rng.gen_range(-1.5f32..1.5f32);
                let x2 = rng.gen_range(-1.5f32..1.5f32);
                let label = if (x1 > 0.0 && x2 > 0.0) || (x1 < 0.0 && x2 < 0.0) {
                    1.0
                } else {
                    0.0
                };
                points.push(DataPoint {
                    x: vec![
                        x1 + rng.sample(noise_dist),
                        x2 + rng.sample(noise_dist),
                    ],
                    y: vec![label],
                });
            }
        }
        "spiral" => {
            let half = count / 2;
            for i in 0..half {
                let r = i as f32 / half as f32 * 1.5;
                let t = 1.75 * i as f32 / half as f32 * 2.0 * PI;
                let x1 = r * t.sin() + rng.sample(noise_dist);
                let x2 = r * t.cos() + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![0.0],
                });
            }
            for i in 0..half {
                let r = i as f32 / half as f32 * 1.5;
                let t = 1.75 * i as f32 / half as f32 * 2.0 * PI + PI;
                let x1 = r * t.sin() + rng.sample(noise_dist);
                let x2 = r * t.cos() + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![1.0],
                });
            }
        }
        "sinewave" => {
            for _ in 0..count {
                let x1 = rng.gen_range(-2.0f32..2.0f32);
                let target = (x1 * PI).sin() + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, 0.0],
                    y: vec![target],
                });
            }
        }
        "regression_2d" | "2d_regression" | "keep_training" => {
            for i in 0..count {
                let t = (i as f32 / count as f32) * 2.8 - 1.4;
                let x1 = t + rng.sample(noise_dist) * 0.4;
                let y_val = 0.85 * x1 + rng.sample(noise_dist) * 0.3;
                points.push(DataPoint {
                    x: vec![x1, 0.0],
                    y: vec![y_val],
                });
            }
        }
        "single_step" | "single-step training" => {
            let sample_xs = [-1.1, -0.6, -0.1, 0.5, 1.2];
            for &x1 in &sample_xs {
                points.push(DataPoint {
                    x: vec![x1, 0.0],
                    y: vec![0.8 * x1],
                });
            }
        }
        "broken_line" | "initialization" => {
            for i in 0..count {
                let x1 = (i as f32 / count as f32) * 2.8 - 1.4;
                let y_val = 1.2 * x1.abs() - 0.8 + rng.sample(noise_dist) * 0.3;
                points.push(DataPoint {
                    x: vec![x1, 0.0],
                    y: vec![y_val],
                });
            }
        }
        "w_line" => {
            for i in 0..count {
                let x1 = (i as f32 / count as f32) * 2.8 - 1.4;
                let y_val = 1.8 * (x1.abs() - 0.7).abs() - 0.5 + rng.sample(noise_dist) * 0.3;
                points.push(DataPoint {
                    x: vec![x1, 0.0],
                    y: vec![y_val],
                });
            }
        }
        "classification_2d" | "2d_classification" => {
            let half = count / 2;
            for _ in 0..half {
                let x1 = rng.gen_range(-1.5f32..1.5f32) + rng.sample(noise_dist);
                let x2 = rng.gen_range(-1.2f32..-0.3f32) + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![0.0],
                });
            }
            for _ in half..count {
                let x1 = rng.gen_range(-1.5f32..1.5f32) + rng.sample(noise_dist);
                let x2 = rng.gen_range(0.3f32..1.2f32) + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![1.0],
                });
            }
        }
        "regression_3d" | "3d_regression" => {
            for _ in 0..count {
                let x1 = rng.gen_range(-1.4f32..1.4f32);
                let x2 = rng.gen_range(-1.4f32..1.4f32);
                let y_val = 0.5 * x1 - 0.6 * x2 + rng.sample(noise_dist) * 0.2;
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![y_val],
                });
            }
        }
        "classification_3d" | "3d_classification" => {
            let half = count / 2;
            for _ in 0..half {
                let x1 = rng.gen_range(-1.3f32..-0.3f32) + rng.sample(noise_dist);
                let x2 = rng.gen_range(-1.3f32..-0.3f32) + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![0.0],
                });
            }
            for _ in half..count {
                let x1 = rng.gen_range(0.3f32..1.3f32) + rng.sample(noise_dist);
                let x2 = rng.gen_range(0.3f32..1.3f32) + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![1.0],
                });
            }
        }
        _ => {
            let half = count / 2;
            for _ in 0..half {
                let x1 = rng.gen_range(-1.4f32..-0.2f32) + rng.sample(noise_dist);
                let x2 = rng.gen_range(-1.4f32..-0.2f32) + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![0.0],
                });
            }
            for _ in half..count {
                let x1 = rng.gen_range(0.2f32..1.4f32) + rng.sample(noise_dist);
                let x2 = rng.gen_range(0.2f32..1.4f32) + rng.sample(noise_dist);
                points.push(DataPoint {
                    x: vec![x1, x2],
                    y: vec![1.0],
                });
            }
        }
    }

    points
}
