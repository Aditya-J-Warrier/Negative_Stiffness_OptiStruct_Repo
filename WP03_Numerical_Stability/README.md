# WP03 — Numerical Stability and Validity Limits

## Objective

Determine the parameter ranges within which positive and negative shell stiffness contributions can be applied reliably to existing finite element models.

Investigate numerical instability, critical eigenmodes, and the influence of modelling parameters on the global stiffness matrix.

## Research Questions

- How do positive and negative shell contributions affect the eigenvalue spectrum of the global stiffness matrix?
- Which eigenvalues correspond to physical structural modes, and which arise from additional interface or rotational degrees of freedom?
- At what degree of subtraction does the stiffness matrix become singular, indefinite, or numerically unreliable?
- How do boundary conditions and ASET/SPC partitioning influence numerical stability?
- Which numerical stability indicators are suitable for automatic validation?
- Can numerically inadmissible states be avoided through physically justified parameter limits?

## Parameters to Investigate

- Positive and negative shell stiffness contributions
- Ratio of shell contribution to initial thickness
- Very small shell contributions near zero
- Mesh density
- Linear and quadratic finite elements
- Shell-region length and width
- Shell offset (ZOFFSET)
- Boundary conditions
- Dummy-shell activation and deactivation

## Investigation Procedure

1. Perform a coarse parameter sweep over positive and negative thickness modifications.
2. Identify numerically critical parameter regions.
3. Refine the parameter increments around critical regions, particularly near zero shell contribution.
4. Evaluate the eigenvalue spectra of the global stiffness matrices.
5. Distinguish physical structural modes from interface-related and rotational modes.
6. Compare solver behaviour and structural responses against reference models.
7. Derive numerical and physical validity limits.

## Numerical Stability Evaluation

### Matrix Conditioning
- Calculate condition numbers.
- Investigate changes in conditioning near zero shell contribution.
- Assess whether conventional condition numbers are suitable stability indicators.

### Eigenvalue Analysis
- Determine positive, negative, and near-zero eigenvalues.
- Examine eigenvectors associated with the smallest eigenvalues.
- Distinguish physical modes from additional interface or rotational modes.
- Investigate the influence of boundary conditions and ASET/SPC definitions.

### Additional Stability Checks
- Evaluate translational and rotational degrees-of-freedom contributions.
- Investigate modal energy contributions.
- Assess sensitivity to small matrix perturbations.
- Monitor changes in physically relevant modes.
- Compare numerical stability indicators against solver convergence and structural response.

## Important Considerations

The condition number alone must not be treated as a sufficient indicator of numerical instability.

Additional rotational degrees of freedom may produce very small eigenvalues without necessarily making the global displacement solution unusable.

Consequently, numerical stability should be evaluated using multiple indicators and their physical interpretation.

## Expected Deliverables

- Numerical stability maps for the investigated parameter ranges
- Eigenvalue and condition-number evaluations
- Identification of critical numerical transition regions
- Classification of physical and interface-related eigenmodes
- Admissible shell-thickness or stiffness-ratio intervals
- Recommended criteria for numerical validity checks
- Rules for handling shell contributions close to zero

## Status

Not started
