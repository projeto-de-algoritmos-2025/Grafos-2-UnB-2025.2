#include <stdio.h>
#include <stdlib.h>

int absDiff(int a, int b) { return a > b ? a - b : b - a; }

int minCostConnectPoints(int** points, int pointsSize, int* pointsColSize) {
    int n = pointsSize;
    int *inMST = calloc(n, sizeof(int)); 
    int *minDist = malloc(n * sizeof(int));
    
    for (int i = 0; i < n; i++) minDist[i] = 1e9; // Inicialmente infinito
    minDist[0] = 0; // Começa do ponto 0
    
    int result = 0;
    
    for (int i = 0; i < n; i++) {
        int u = -1;
        // Escolher o ponto fora da MST com menor distância
        for (int j = 0; j < n; j++) {
            if (!inMST[j] && (u == -1 || minDist[j] < minDist[u])) u = j;
        }
        
        inMST[u] = 1;       
        result += minDist[u];
        
        // Atualiza as distâncias dos vizinhos
        for (int v = 0; v < n; v++) {
            if (!inMST[v]) {
                int cost = absDiff(points[u][0], points[v][0]) + absDiff(points[u][1], points[v][1]);
                if (cost < minDist[v]) minDist[v] = cost;
            }
        }
    }
    
    free(inMST);
    free(minDist);
    return result;
}
