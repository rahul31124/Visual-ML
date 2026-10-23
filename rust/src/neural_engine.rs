use ndarray::Array2;
use rand::distributions::Uniform;
use rand::prelude::*;

#[derive(Clone, Debug, PartialEq)]
pub enum ActivationType {
    Relu,
    Tanh,
    Sigmoid,
    Linear,
}

impl ActivationType {
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "relu" => ActivationType::Relu,
            "tanh" => ActivationType::Tanh,
            "sigmoid" => ActivationType::Sigmoid,
            _ => ActivationType::Linear,
        }
    }

    #[inline(always)]
    pub fn activate(&self, x: f32) -> f32 {
        match self {
            ActivationType::Relu => {
                if x > 0.0 {
                    x
                } else {
                    0.0
                }
            }
            ActivationType::Tanh => x.tanh(),
            ActivationType::Sigmoid => 1.0 / (1.0 + (-x).exp()),
            ActivationType::Linear => x,
        }
    }

    #[inline(always)]
    pub fn derivative(&self, activated_val: f32) -> f32 {
        match self {
            ActivationType::Relu => {
                if activated_val > 0.0 {
                    1.0
                } else {
                    0.0
                }
            }
            ActivationType::Tanh => 1.0 - activated_val * activated_val,
            ActivationType::Sigmoid => activated_val * (1.0 - activated_val),
            ActivationType::Linear => 1.0,
        }
    }
}

#[derive(Clone, Debug)]
pub struct Layer {
    pub in_features: usize,
    pub out_features: usize,
    pub weights: Array2<f32>,
    pub biases: Vec<f32>,
    pub weight_momentum: Array2<f32>,
    pub bias_momentum: Vec<f32>,
    pub activation: ActivationType,
}

impl Layer {
    pub fn new(in_features: usize, out_features: usize, activation: ActivationType) -> Self {
        let mut rng = rand::thread_rng();
        let scale = match activation {
            ActivationType::Relu => (2.0 / in_features as f32).sqrt(),
            _ => (1.0 / (in_features + out_features) as f32).sqrt() * 1.5,
        };
        let uniform = Uniform::new(-scale, scale);

        let mut weights_data = Vec::with_capacity(out_features * in_features);
        for _ in 0..(out_features * in_features) {
            weights_data.push(rng.sample(uniform));
        }

        let weights = Array2::from_shape_vec((out_features, in_features), weights_data)
            .unwrap_or_else(|_| Array2::zeros((out_features, in_features)));
        let biases = vec![0.01; out_features];
        let weight_momentum = Array2::zeros((out_features, in_features));
        let bias_momentum = vec![0.0; out_features];

        Self {
            in_features,
            out_features,
            weights,
            biases,
            weight_momentum,
            bias_momentum,
            activation,
        }
    }

    pub fn forward(&self, input: &[f32]) -> (Vec<f32>, Vec<f32>) {
        let mut raw_z = Vec::with_capacity(self.out_features);
        let mut activated = Vec::with_capacity(self.out_features);

        for i in 0..self.out_features {
            let mut sum = self.biases[i];
            for j in 0..self.in_features {
                sum += self.weights[[i, j]] * input[j];
            }
            raw_z.push(sum);
            activated.push(self.activation.activate(sum));
        }
        (raw_z, activated)
    }
}

pub struct MicroNeuralNet {
    pub layers: Vec<Layer>,
    pub learning_rate: f32,
    pub momentum: f32,
    pub regularization: String,
    pub reg_rate: f32,
    pub problem_type: String,
    pub current_epoch: i32,
}

impl MicroNeuralNet {
    pub fn new(
        layer_specs: &[(usize, usize, String)],
        learning_rate: f32,
        momentum: f32,
        regularization: &str,
        reg_rate: f32,
        problem_type: &str,
    ) -> Self {
        let mut layers = Vec::new();
        for (inf, outf, act_str) in layer_specs {
            let act = ActivationType::from_str(act_str);
            layers.push(Layer::new(*inf, *outf, act));
        }

        Self {
            layers,
            learning_rate: learning_rate.max(0.0001),
            momentum: momentum.clamp(0.0, 0.99),
            regularization: regularization.to_lowercase(),
            reg_rate: reg_rate.max(0.0),
            problem_type: problem_type.to_lowercase(),
            current_epoch: 0,
        }
    }

    pub fn forward_full(&self, input: &[f32]) -> (Vec<Vec<f32>>, Vec<Vec<f32>>) {
        let mut all_raw = Vec::with_capacity(self.layers.len());
        let mut all_activated = Vec::with_capacity(self.layers.len() + 1);
        all_activated.push(input.to_vec());

        let mut current_input = input.to_vec();
        for layer in &self.layers {
            let (raw_z, act_a) = layer.forward(&current_input);
            all_raw.push(raw_z);
            current_input = act_a.clone();
            all_activated.push(act_a);
        }

        (all_raw, all_activated)
    }

    pub fn predict(&self, input: &[f32]) -> Vec<f32> {
        let mut current = input.to_vec();
        for layer in &self.layers {
            let (_, act) = layer.forward(&current);
            current = act;
        }
        current
    }

    pub fn train_batch(
        &mut self,
        train_x: &[Vec<f32>],
        train_y: &[Vec<f32>],
        epochs: i32,
    ) {
        let num_layers = self.layers.len();
        if num_layers == 0 || train_x.is_empty() {
            return;
        }

        let batch_size = train_x.len() as f32;

        for _ in 0..epochs {
            self.current_epoch += 1;

            let mut weight_grads: Vec<Array2<f32>> = self
                .layers
                .iter()
                .map(|l| Array2::zeros((l.out_features, l.in_features)))
                .collect();
            let mut bias_grads: Vec<Vec<f32>> = self
                .layers
                .iter()
                .map(|l| vec![0.0; l.out_features])
                .collect();

            for s in 0..train_x.len() {
                let x = &train_x[s];
                let y = &train_y[s];
                let (_raws, activated) = self.forward_full(x);
                let output = activated.last().unwrap();

                let mut delta = Vec::with_capacity(output.len());
                let output_layer = &self.layers[num_layers - 1];

                for i in 0..output.len() {
                    let err = output[i] - y[i];
                    let deriv = output_layer.activation.derivative(output[i]);
                    delta.push(err * deriv);
                }

                for l in (0..num_layers).rev() {
                    let prev_act = &activated[l];
                    let layer = &self.layers[l];

                    for i in 0..layer.out_features {
                        bias_grads[l][i] += delta[i];
                        for j in 0..layer.in_features {
                            weight_grads[l][[i, j]] += delta[i] * prev_act[j];
                        }
                    }

                    if l > 0 {
                        let prev_layer = &self.layers[l - 1];
                        let mut next_delta = Vec::with_capacity(layer.in_features);
                        for j in 0..layer.in_features {
                            let mut sum = 0.0;
                            for i in 0..layer.out_features {
                                sum += delta[i] * layer.weights[[i, j]];
                            }
                            let deriv = prev_layer.activation.derivative(prev_act[j]);
                            next_delta.push(sum * deriv);
                        }
                        delta = next_delta;
                    }
                }
            }

            for l in 0..num_layers {
                let layer = &mut self.layers[l];
                for i in 0..layer.out_features {
                    let bg = bias_grads[l][i] / batch_size;
                    let vb = self.momentum * layer.bias_momentum[i] + self.learning_rate * bg;
                    layer.bias_momentum[i] = vb;
                    layer.biases[i] -= vb;

                    for j in 0..layer.in_features {
                        let mut wg = weight_grads[l][[i, j]] / batch_size;
                        if self.regularization == "l2" {
                            wg += self.reg_rate * layer.weights[[i, j]];
                        } else if self.regularization == "l1" {
                            wg += self.reg_rate * layer.weights[[i, j]].signum();
                        }

                        let vw = self.momentum * layer.weight_momentum[[i, j]]
                            + self.learning_rate * wg;
                        layer.weight_momentum[[i, j]] = vw;
                        layer.weights[[i, j]] -= vw;
                    }
                }
            }
        }
    }

    pub fn compute_metrics(&self, xs: &[Vec<f32>], ys: &[Vec<f32>]) -> (f32, f32) {
        if xs.is_empty() {
            return (0.0, 0.0);
        }

        let mut total_loss = 0.0;
        let mut correct = 0;

        for i in 0..xs.len() {
            let pred = self.predict(&xs[i]);
            let target = &ys[i];

            if self.problem_type == "classification" {
                let p = pred[0].clamp(1e-7, 1.0 - 1e-7);
                let t = target[0];
                total_loss += -(t * p.ln() + (1.0 - t) * (1.0 - p).ln());
                let pred_class = if p >= 0.5 { 1.0 } else { 0.0 };
                if (pred_class - t).abs() < 0.1 {
                    correct += 1;
                }
            } else {
                let diff = pred[0] - target[0];
                total_loss += diff * diff;
                if diff.abs() < 0.25 {
                    correct += 1;
                }
            }
        }

        (total_loss / xs.len() as f32, correct as f32 / xs.len() as f32)
    }

    pub fn expand_features(&self, x1: f32, x2: f32) -> Vec<f32> {
        let in_features = if !self.layers.is_empty() {
            self.layers[0].in_features
        } else {
            2
        };

        match in_features {
            2 => vec![x1, x2],
            3 => vec![x1, x2, x1 * x1],
            4 => vec![x1, x2, x1 * x1, x2 * x2],
            5 => vec![x1, x2, x1 * x1, x2 * x2, x1 * x2],
            6 => vec![x1, x2, x1 * x1, x2 * x2, x1 * x2, x1.sin()],
            7 => vec![x1, x2, x1 * x1, x2 * x2, x1 * x2, x1.sin(), x2.sin()],
            _ => {
                let mut v = vec![x1, x2];
                while v.len() < in_features {
                    v.push(0.0);
                }
                v
            }
        }
    }
}
