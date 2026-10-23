# Visual ML

Visual ML is an interactive deep learning laboratory and neural network simulator built with Flutter and Rust.

This project is built for understanding how machine learning mathematics, optimization algorithms, and computer vision architectures operate under the hood in real time, while making deep learning accessible and visual.
<p align="center">
  <img src="images/preview_image.png" width="220">
</p>

## Features
- **Interactive Neural Network Lab**  
  Construct multi-layer perceptrons by adding or removing hidden layers and adjusting neuron counts. Watch decision boundary contours evolve in real time as weights adapt during training.

- **Synthetic Datasets and Feature Engineering**  
  Experiment on five distinct classification datasets: Linear, Circle, XOR, Sinewave, and Spiral. Toggle raw coordinates, polynomial features, and trigonometric transforms to understand non-linear boundary separation.

- **3D Loss Surface and Optimization Tracking**  
  Switch to an interactive 3D loss landscape to observe gradient descent trajectories rolling down optimization basins toward minimum loss.

- **Model Studio and Landmark Vision Architectures**  
  Explore visual pipelines of benchmark convolutional neural network architectures including LeNet-5, AlexNet, VGG-16, GoogLeNet, and ResNet-50. Inspect tensor dimensions at each layer and simulate vision training on digit classification benchmarks.

- **High-Performance Native Rust Core**  
  All matrix algebra, forward propagation, loss calculations, and analytical backpropagation derivatives execute natively in compiled Rust via Foreign Function Interface (FFI) for sub-millisecond execution on mobile CPUs.

- **Context-Aware Gemini AI Tutor**  
  An integrated educational mentor that inspects active screen hyperparameters, dataset configurations, and loss convergence curves to explain the mathematics and diagnose training behavior.

## Tech Used
- Flutter
- Dart
- Rust 
- Provider (State Management)
- Google Fonts
- Gemini API


## Screenshots

| Splash | Playground | Model Studio |
|:---:|:---:|:---:|
| <img src="images/splash_s.jpg" width="240"> | <img src="images/playground.jpg" width="240"> | <img src="images/model_s.jpg" width="240"> |

| Lab | Visual Model |
|:---:|:---:|
| <img src="images/lab_s.jpg" width="380"> | <img src="images/visual_m.jpg" width="380"> |

| Output | Loss Landscape |
|:---:|:---:|
| <img src="images/output_.jpg" width="380"> | <img src="images/loss_.jpg" width="380"> |


## Architecture

```mermaid
graph TD
    subgraph UI ["Presentation Layer (Flutter)"]
        Screens["Screens and Controls<br/>LabScreen, ModelStudio, Missions, Knowledge"]
        Painters["Real-Time Renderers<br/>DecisionBoundary, NetworkCanvas, LossLandscape3D, LossChart"]
    end

    subgraph State ["State Management (Provider)"]
        Providers["Providers<br/>LabProvider, ModelProvider, MissionsProvider"]
        NetState["Domain State<br/>Immutable NetworkState Entity"]
        AIProv["AI Telemetry<br/>GeminiProvider"]
    end

    subgraph Bridge ["FFI Communication Bridge"]
        FRB["flutter_rust_bridge<br/>Dart FFI Bindings"]
        CABI["C-ABI Memory Boundary<br/>Zero-Copy Float32List Buffers"]
    end

    subgraph RustCore ["Native Engine "]
        Engine["MicroNeuralNet and Layers<br/>Weights Matrix, Biases, Momentum"]
        Forward["Forward Pass and Activations<br/>Inlined ReLU, Tanh, Sigmoid, Linear"]
        Backward["Backpropagation and Optimizers<br/>Analytical Gradients, Momentum, L1/L2 Regularization"]
        Generators["Generators and Samplers<br/>Circle, Spiral, XOR, 50x50 Mesh, 3D Loss Grid"]
    end

    subgraph AI ["AI Explanation Layer"]
        GeminiClient["GeminiService<br/>REST Client"]
        GeminiAPI["Google Gemini 3.5 Flash API<br/>Real-Time Explanations and Diagnostics"]
    end

    Screens -->|User Input and Actions| Providers
    Providers -->|Notify State| NetState
    NetState -->|Render Data| Painters
    Painters -->|Visual Canvas| Screens

    Providers -->|Dispatch Training Step| FRB
    FRB -->|Native C Call| CABI
    CABI -->|Execute Batch| Engine
    Engine --> Forward
    Forward --> Backward
    Engine --> Generators
    Generators -->|Boundary and Loss Surface Data| CABI
    CABI -->|Epoch Result Float32List| FRB
    FRB -->|Update Epoch Metrics| Providers

    Providers -->|Loss and Model Telemetry| AIProv
    AIProv -->|Contextual Prompt| GeminiClient
    GeminiClient -->|HTTPS Query| GeminiAPI
    GeminiAPI -->|Educational Guidance| GeminiClient
    GeminiClient -->|Display Insights| Screens
```

### System Architecture Breakdown

- **Presentation Layer (Flutter)**: Handles UI interactions, hyperparameter selection, dataset generation triggers, and real-time canvas rendering for decision boundary contour heatmaps, synaptic network graphs with animated Bezier curves, and 3D loss surface topography.
- **State Management (Provider)**: Coordinates application state through immutable `NetworkState` entities, runs the asynchronous training loop timer, batches data updates, and routes telemetry to the UI and AI services.
- **FFI Communication Bridge (flutter_rust_bridge)**: Facilitates low-latency cross-language communication between Dart and compiled Rust over C-ABI boundaries, passing numeric arrays (`Float32List`) without JSON serialization overhead.
- **Native Computational Engine (Rust)**: Executes all CPU-intensive mathematical operations natively. Utilizes `ndarray` for matrix algebra, evaluates forward inference, performs analytical backpropagation with momentum and regularization, and samples both the 50x50 decision space and 3D loss landscapes.
- **AI Explanation Layer**: Integrates Google Gemini 3.5 Flash to inspect live screen context, hyperparameters, and loss metrics, generating real-time explanations and training diagnostics.


## Privacy
This app does not collect or share any personal data.  
All neural network training computations are executed locally on the device.

