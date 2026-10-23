import 'dart:convert';
import 'package:flutter/material.dart';

enum LayerBlockType {
  input,
  conv2d,
  maxpool,
  featuresGroup,
  flatten,
  classifierGroup,
  linear,
  relu,
  batchnorm,
  dropout,
  softmax,
  output,
  residualAdd,
}

class NeuralLayerBlock {
  final String id;
  final String name;
  final LayerBlockType type;
  final String tensorShape;
  final Map<String, dynamic> parameters;
  final String description;
  Offset position;

  NeuralLayerBlock({
    required this.id,
    required this.name,
    required this.type,
    required this.tensorShape,
    required this.parameters,
    required this.description,
    this.position = Offset.zero,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'tensorShape': tensorShape,
        'parameters': parameters,
        'description': description,
        'position': {'dx': position.dx, 'dy': position.dy},
      };

  factory NeuralLayerBlock.fromJson(Map<String, dynamic> json) {
    return NeuralLayerBlock(
      id: json['id'] as String,
      name: json['name'] as String,
      type: LayerBlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LayerBlockType.linear,
      ),
      tensorShape: json['tensorShape'] as String? ?? '[N, 10]',
      parameters: Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
      description: json['description'] as String? ?? '',
      position: json['position'] != null
          ? Offset(
              (json['position']['dx'] as num).toDouble(),
              (json['position']['dy'] as num).toDouble(),
            )
          : Offset.zero,
    );
  }

  NeuralLayerBlock copyWith({
    String? name,
    String? tensorShape,
    Map<String, dynamic>? parameters,
    Offset? position,
  }) {
    return NeuralLayerBlock(
      id: id,
      name: name ?? this.name,
      type: type,
      tensorShape: tensorShape ?? this.tensorShape,
      parameters: parameters ?? Map.from(this.parameters),
      description: description,
      position: position ?? this.position,
    );
  }
}

class NeuralModelDefinition {
  final String id;
  final String name;
  final String category;
  final int year;
  final String author;
  final String shortDescription;
  final bool isLocked;
  final int? explicitParamCount;
  final List<NeuralLayerBlock> blocks;
  final List<List<int>> connections;

  NeuralModelDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.year,
    required this.author,
    required this.shortDescription,
    this.isLocked = false,
    this.explicitParamCount,
    required this.blocks,
    required this.connections,
  });

  int get parameterCount {
    if (explicitParamCount != null && explicitParamCount! > 0) {
      return explicitParamCount!;
    }
    int total = 0;
    for (final b in blocks) {
      if (b.type == LayerBlockType.linear) {
        final inDim = b.parameters['in_features'] as int? ?? 120;
        final outDim = b.parameters['out_features'] as int? ?? 10;
        total += inDim * outDim + outDim;
      } else if (b.type == LayerBlockType.conv2d) {
        final inC = b.parameters['in_channels'] as int? ?? 1;
        final outC = b.parameters['out_channels'] as int? ?? 6;
        final k = b.parameters['kernel_size'] as int? ?? 5;
        total += inC * outC * k * k + outC;
      }
    }
    return total > 0 ? total : 61706;
  }

  String toNnFileString() {
    final map = {
      'format': 'visual_neural_network_lab.nn',
      'version': '1.0.0',
      'metadata': {
        'id': id,
        'name': name,
        'category': category,
        'year': year,
        'author': author,
        'description': shortDescription,
        'parameters': parameterCount,
        'explicitParamCount': explicitParamCount,
      },
      'architecture': {
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'connections': connections,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static NeuralModelDefinition fromNnFileString(String content) {
    final map = jsonDecode(content) as Map<String, dynamic>;
    final meta = map['metadata'] as Map<String, dynamic>? ?? {};
    final arch = map['architecture'] as Map<String, dynamic>? ?? {};

    final blocksRaw = arch['blocks'] as List? ?? [];
    final blocks = blocksRaw.map((b) => NeuralLayerBlock.fromJson(b as Map<String, dynamic>)).toList();

    final connRaw = arch['connections'] as List? ?? [];
    final connections = connRaw.map((c) => List<int>.from(c as List)).toList();

    return NeuralModelDefinition(
      id: meta['id'] as String? ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: meta['name'] as String? ?? 'Custom Model',
      category: meta['category'] as String? ?? 'Custom',
      year: meta['year'] as int? ?? DateTime.now().year,
      author: meta['author'] as String? ?? 'You',
      shortDescription: meta['description'] as String? ?? 'User created visual architecture.',
      isLocked: false,
      explicitParamCount: meta['explicitParamCount'] as int?,
      blocks: blocks,
      connections: connections,
    );
  }

  String toPyTorchCode() {
    final buffer = StringBuffer();
    buffer.writeln('import torch');
    buffer.writeln('import torch.nn as nn');
    buffer.writeln('');
    buffer.writeln('class ${name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}(nn.Module):');
    buffer.writeln('    def __init__(self, num_classes=10):');
    buffer.writeln('        super().__init__()');
    buffer.writeln('        self.features = nn.Sequential(');
    for (final b in blocks) {
      if (b.type == LayerBlockType.conv2d) {
        final inC = b.parameters['in_channels'] ?? 1;
        final outC = b.parameters['out_channels'] ?? 6;
        final k = b.parameters['kernel_size'] ?? 5;
        buffer.writeln('            nn.Conv2d($inC, $outC, kernel_size=$k),');
        buffer.writeln('            nn.ReLU(),');
      } else if (b.type == LayerBlockType.maxpool) {
        buffer.writeln('            nn.MaxPool2d(kernel_size=2, stride=2),');
      }
    }
    buffer.writeln('        )');
    buffer.writeln('        self.classifier = nn.Sequential(');
    buffer.writeln('            nn.Flatten(),');
    buffer.writeln('            nn.Linear(120, 84),');
    buffer.writeln('            nn.ReLU(),');
    buffer.writeln('            nn.Linear(84, 10),');
    buffer.writeln('        )');
    buffer.writeln('');
    buffer.writeln('    def forward(self, x):');
    buffer.writeln('        x = self.features(x)');
    buffer.writeln('        x = self.classifier(x)');
    buffer.writeln('        return x');
    return buffer.toString();
  }
}
