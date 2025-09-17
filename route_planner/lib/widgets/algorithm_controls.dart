import 'package:flutter/material.dart';
import '../algorithms/dijkstra_algorithm.dart';

class AlgorithmControls extends StatelessWidget {
  final DijkstraAlgorithm dijkstraAlgorithm;
  final VoidCallback onFindRoute;
  final VoidCallback onReset;
  final bool canFindRoute;

  const AlgorithmControls({
    super.key,
    required this.dijkstraAlgorithm,
    required this.onFindRoute,
    required this.onReset,
    required this.canFindRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Criteria: ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: DropdownButton<String>(
                  value: dijkstraAlgorithm.weightCriteria,
                  isExpanded: true,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'distance',
                      child: Text('Distance', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'time',
                      child: Text('Time', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'highway_priority',
                      child: Text('Highway', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  onChanged: dijkstraAlgorithm.isRunning
                      ? null
                      : (value) {
                          if (value != null) {
                            dijkstraAlgorithm.setWeightCriteria(value);
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: canFindRoute && !dijkstraAlgorithm.isRunning
                    ? onFindRoute
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(80, 32),
                ),
                child: const Text('Find Route', style: TextStyle(fontSize: 12)),
              ),
              if (dijkstraAlgorithm.isRunning) ...[
                ElevatedButton(
                  onPressed: dijkstraAlgorithm.isPaused
                      ? dijkstraAlgorithm.resume
                      : dijkstraAlgorithm.pause,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(60, 32),
                  ),
                  child: Text(
                    dijkstraAlgorithm.isPaused ? 'Resume' : 'Pause',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: dijkstraAlgorithm.stop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text('Stop', style: TextStyle(fontSize: 12)),
                ),
              ],
              ElevatedButton(
                onPressed: onReset,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(60, 32),
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (dijkstraAlgorithm.isRunning) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                dijkstraAlgorithm.isPaused ? Colors.orange : Colors.blue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}