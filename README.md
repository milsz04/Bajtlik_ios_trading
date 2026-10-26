# Genetic Algorithm for Point Grouping (C++)

A genetic algorithm that splits a set of points in multi-dimensional space into groups so that points in the same group are as close to each other as possible. Written in C++17 with an object-oriented design and no external dependencies.

In a sample run on 10 points in 10 dimensions, the algorithm went from a best random solution with a cost of **319.7** to **5.7** after 1,000 generations.

## The problem

Given **N points** and **K groups**, assign every point to one group. The cost of a solution is the sum of distances between every pair of points that share a group:

```
cost = Σ over groups  Σ over pairs (i, j) in that group  2 · ‖pᵢ − pⱼ‖
```

Lower is better. The search space grows as Kᴺ: the default 10 points and 9 groups already give about 3.5 billion assignments, so brute force quickly becomes impractical.

Test data comes from `CGaussianGroupingEvaluatorFactory`. It samples points from a mixture of multivariate Gaussian distributions, with each dimension's mean and standard deviation drawn from a range you set. A fixed seed makes the dataset reproducible.

## How the algorithm works

```mermaid
flowchart LR
    A[Random population] --> B[Tournament selection]
    B --> C[Single-point crossover]
    C --> D[Per-gene mutation]
    D --> E[Evaluate and track best]
    E -->|next generation| B
```

| Step | Implementation |
|---|---|
| Encoding | A chromosome is a `std::vector<int>` of length N. Gene *i* is the group (1…K) of point *i*. |
| Initialisation | Each gene gets a uniformly random group. |
| Selection | Binary tournament: pick two random individuals and keep the one with lower cost. |
| Crossover | Single-point crossover with probability `pc`. The cut point is random in [1, N−1] and the two parents swap their tails. |
| Mutation | Each gene is reassigned to a random group with probability `pm`. |
| Replacement | Generational: children replace the whole population. The best solution ever seen is stored separately, so it is never lost. |

The repository also includes `COptimizer`, a random-search baseline that samples a new random solution every iteration and keeps the best. It is useful as a point of comparison for the genetic algorithm.

## Build and run

You need a C++17 compiler (GCC 8+, Clang 7+ or MSVC 2019+).

```bash
g++ -std=c++17 -O2 -o ga *.cpp
./ga | tail -n 3
```

The program prints every population at every generation, so piping through `tail` shows just the final result:

```
Best Individual
Genes: 3781526449
Fitness: 5.67415
```

The genes line shows the group of each point in order. Results differ slightly between runs because the algorithm's random engine is seeded from `std::random_device`; the dataset itself is fixed with seed `0`.

## Configuration

All parameters are set in `main.cpp`:

| Parameter | Default | Meaning |
|---|---|---|
| `popSize` | 20 | Individuals per generation |
| `numOfPoints` | 10 | Points to group |
| `numberOfGroups` | 9 | Available groups |
| Gaussian distributions | 4 | Clusters the points are sampled from |
| Dimensions | 10 | Each with mean in [−100, 100] and standard deviation 1 |
| `iterations` | 1000 | Generations to run |
| `crossoverProbability` | 0.6 | Chance that two parents are recombined |
| `mutationProbability` | 0.1 | Chance that each gene is mutated |

## Project structure

| File | Responsibility |
|---|---|
| `main.cpp` | Builds the dataset, configures and runs the algorithm |
| `CGeneticAlgorithm.h/.cpp` | Population, selection, crossover, the generation loop and best-solution tracking |
| `CIndividual.h/.cpp` | One solution: its genes, its cached cost, crossover and mutation operators |
| `GroupingEvaluator.h/.cpp` | Computes the cost of a solution and validates it |
| `GaussianGroupingEvaluatorFactory.h/.cpp` | Generates reproducible test datasets from Gaussian mixtures |
| `Point.h/.cpp` | An N-dimensional point and Euclidean distance |
| `Optimizer.h/.cpp` | Random-search baseline |

## Possible improvements

- Keep the best individuals between generations (elitism) to speed up convergence.
- Accept parameters and a seed from the command line, and add a quiet mode that prints only progress and the final result.
- Add unit tests for crossover, mutation and the evaluator, for example with GoogleTest.
- Add a CMake build and replace the raw `new`/`delete` in the factory with smart pointers.
- Compare against the random-search baseline on larger instances and plot cost per generation.

## Author

Miłosz Szynka · [github.com/milsz04](https://github.com/milsz04)
