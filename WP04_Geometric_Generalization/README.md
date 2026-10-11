# WP04 — Geometric Generalization

## Objective

Investigate the geometric transferability of the additive and subtractive shell stiffness approach beyond a fully modified prismatic beam.

Determine how local shell regions, geometric transitions, surface curvature, shell orientation, and offset definitions influence the accuracy and reliability of the method.

## Research Questions

- Can the approach reliably represent locally confined material additions and subtractions?
- How do transitions between modified and unmodified regions affect the numerical results?
- How does the length and position of a shell region influence structural response?
- How should shell normals and offsets be defined for non-prismatic or curved geometries?
- How sensitive is the approach to changes in shell orientation and surface curvature?
- Under which geometric conditions is explicit solid remodelling necessary?

## Investigation Levels

### Level 1 — Local Shell Regions on a Straight Beam

Extend the existing prismatic beam model by considering partially modified regions.

Investigate:

- Shell regions covering only part of the beam length
- Different modification lengths
- Different positions along the beam
- Sharp transitions between modified and unmodified regions
- Differences between local and globally distributed shell contributions

Compare the results with corresponding geometrically modified solid reference models.

### Level 2 — Non-Prismatic Demonstrator

Investigate at least one geometrically extended model.

Possible examples:

- Beam with variable height
- Tapered beam
- Stepped beam
- Plate with local thickening or thinning

Evaluate whether the shell contribution approach remains accurate when the underlying geometry is not prismatic.

### Level 3 — Curved or Component-Oriented Demonstrator

Depending on feasibility, extend the investigation to a model with curved surfaces or more complex structural features.

Possible examples:

- Curved plate
- U-profile
- Simplified housing segment
- Abstracted structural component

Investigate how surface curvature, local orientation, and offset definitions affect the representation of material addition and subtraction.

## Parameters to Investigate

### Geometric Parameters
- Length and position of shell modification regions
- Shape and extent of design zones
- Geometric transitions between adjacent regions
- Surface curvature
- Non-prismatic cross-sections

### Modelling Parameters
- Local shell-normal direction
- Shell orientation
- ZOFFSET direction
- Mesh distortion
- Local coupling conditions
- Transitions between adjacent design zones

## Evaluation Methodology

For each selected geometric configuration:

1. Define the baseline solid model.
2. Define the local or extended shell modification region.
3. Generate the corresponding additive or subtractive shell model.
4. Generate a geometrically modified solid reference model.
5. Apply consistent material properties, loads, and boundary conditions.
6. Compare global structural responses.
7. Investigate local deviations near modification boundaries.
8. Evaluate numerical stability using the criteria established in WP03.
9. Document geometric validity limits and modelling restrictions.

The quantitative comparison criteria established in WP02 should be applied consistently.

## Expected Deliverables

- Validated local shell modification cases
- Quantitative comparison with geometrically modified solid reference models
- Investigation of local transition effects
- At least one non-prismatic or curved demonstrator
- Assessment of shell-normal and offset sensitivity
- Documented geometric applicability limits
- Recommendations for extending the method to more complex FE structures

## Scope Limitation

One carefully selected complex demonstrator is sufficient.

The objective is to establish geometric transferability and identify limitations, rather than investigate numerous industrial subassemblies.

## Status

Not started
