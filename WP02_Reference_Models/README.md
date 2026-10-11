# WP02 — Reference Models and Evaluation Criteria

## Objective
Establish reference models and quantitative evaluation criteria to assess the accuracy, numerical stability, and reproducibility of the subtractive shell approach.

## Reference Models

### Reference A — Analytical Solution
For simplified beam configurations:
- Displacement
- Bending stress
- Strain energy
- Natural frequencies (optional)

### Reference B — Geometrically Modified Solid Model
- Generate solid models representing the investigated thickness variations.
- Use these models as numerical references for comparison.

### Reference C — Subtractive Shell Model
- Evaluate the models containing positive or negative shell stiffness contributions.

### Reference D — Optional Alternative Model
- Direct solid-shell composite model
- Finely meshed reference model
- Alternative element order

## Quantitative Evaluation Criteria

### Global Structural Response
- Relative displacement error
- Relative compliance error
- Relative strain-energy error
- Reaction-force error
- Deviation of selected natural frequencies

### Local Structural Response
- Surface-stress error
- Maximum-stress error
- Stress-gradient error
- Location of stress concentrations

### Numerical Stability
- Condition number
- Smallest relevant eigenvalue
- Near-zero and negative eigenvalues
- Matrix residual
- Solver convergence and computational time

### Process Evaluation
- Number of manual interventions
- Failed solver runs
- Model-preparation time
- Reproducibility of identical cases

## Preliminary Acceptance Criteria
The following values are initial targets and must be technically justified:

- Global displacement error below 2%
- Global energy error below 3%
- Local stress error below 5–10%
- No negative physical eigenvalues
- No solver-related termination

## Expected Deliverables
- Defined reference-model hierarchy
- Consistent evaluation metrics
- Documented preliminary acceptance criteria
- Reproducible comparison methodology

## Status
Not started
