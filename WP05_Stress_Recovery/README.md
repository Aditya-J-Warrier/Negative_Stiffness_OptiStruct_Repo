# WP05 — Local Surface-Stress Recovery

## Objective

Investigate whether local surface stresses can be recovered accurately and reliably when shell stiffness contributions are condensed into a superelement and subsequently integrated into an existing solid finite element model.

Evaluate the applicability, accuracy, and numerical influence of using an ultra-thin physical shell as a virtual stress sensor.

## Background

The condensed shell superelement contributes to the global stiffness matrix but does not directly provide local shell stress results.

An ultra-thin physical shell is therefore introduced to obtain local surface-stress information while ideally having a negligible influence on the global structural response.

In the preliminary HiWi investigation, a surface stress of 13.35 MPa was reported for the −10% beam case, compared with an analytical reference value of 12.70 MPa.

This individual result is not sufficient to establish the general reliability of the stress-recovery method.

## Research Questions

- Can ultra-thin physical shells reliably recover local surface stresses?
- Is there a suitable dummy-shell thickness range that allows numerically stable stress recovery while minimally affecting global stiffness?
- How does ZOFFSET influence the calculated surface stresses?
- How sensitive are the recovered stresses to mesh density, element order, and shell orientation?
- Can stress concentrations near local material-subtraction boundaries be reproduced accurately?
- How closely do recovered stresses agree with geometrically modified solid reference models?
- Under which conditions does the stress-recovery approach become unreliable?

## Parameters to Investigate

### Dummy-Shell Properties
- Dummy-shell thickness
- Shell-normal orientation
- Element formulation and order
- Evaluation side of the shell

### Geometric and Numerical Parameters
- ZOFFSET
- Mesh density
- Local versus globally distributed shell regions
- Distance from material-subtraction boundaries
- Positive and negative shell stiffness contributions

## Investigation Procedure

1. Reproduce the existing dummy-shell stress-recovery case from the HiWi research.
2. Compare recovered stresses against analytical and geometrically modified solid reference models.
3. Perform a parameter study using different dummy-shell thicknesses.
4. Investigate the influence of ZOFFSET on stress accuracy.
5. Evaluate mesh sensitivity and the influence of element order.
6. Investigate changes in shell-normal orientation and stress-evaluation side.
7. Extend the investigation to locally confined modification regions.
8. Evaluate stress concentrations near modification boundaries.
9. Determine whether the dummy shell alters the structural response or numerical stability.
10. Derive recommendations for reliable stress recovery.

## Influence on the Global Structural System

The dummy shell must be evaluated not only as a stress-recovery tool but also as an additional structural contribution.

Investigate whether it:

- Changes the global stiffness or displacement response
- Introduces additional small eigenvalues
- Increases the condition number
- Changes local load paths
- Generates artificial stress concentrations

The numerical stability indicators established in WP03 should be used where applicable.

## Reference Models

### Analytical Reference
Use analytical beam-stress calculations where applicable.

### Geometrically Modified Solid Reference
Compare recovered surface stresses with corresponding geometrically modified solid models under consistent loading and boundary conditions.

Use identical or comparable surface discretization where feasible.

## Evaluation Criteria

- Relative surface-stress error
- Maximum-stress error
- Stress-gradient deviation
- Position of stress concentrations
- Change in global displacement response
- Influence on stiffness-matrix conditioning
- Influence on relevant eigenvalues
- Sensitivity to mesh refinement and dummy-shell thickness

Evaluation criteria and preliminary acceptance ranges should be consistent with WP02.

## Expected Deliverables

- Systematic dummy-shell thickness study
- Quantitative evaluation of ZOFFSET influence
- Mesh and element-formulation sensitivity results
- Validation against analytical and geometrically modified solid references
- Assessment of the dummy shell's influence on global structural response
- Recommended dummy-shell thickness and offset ranges
- Documented stress-recovery accuracy and limitations
- Criteria for identifying unreliable stress results

## Status

Not started
