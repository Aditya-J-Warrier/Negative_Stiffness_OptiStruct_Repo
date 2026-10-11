# WP06 — Automated Simulation and Evaluation Workflow

## Objective

Transform the existing manual and partly scripted MATLAB/OptiStruct implementation into a robust, modular, and reproducible simulation and evaluation workflow.

The automated process should support repeated investigations of positive and negative shell stiffness contributions with minimal manual intervention.

## Research Questions

- Which steps of the existing implementation can be fully automated?
- How can node identity, matrix dimensions, and model consistency be checked automatically?
- How can invalid ASET/SPC assignments be detected and prevented?
- How can shell regions, offsets, and stiffness contribution signs be generated consistently?
- How can matrix export, transformation, and reintegration be performed robustly?
- Which solver errors must be detected, logged, and handled automatically?
- How can simulation results and numerical stability indicators be extracted automatically?
- How can the complete workflow be made reproducible and suitable for repeated execution?

## Proposed Automation Modules

### Module 1 — Input Validation

Validate the model before initiating solver execution.

Tasks:
- Check unit consistency
- Validate element types
- Verify node IDs
- Check shell orientation
- Validate surface-normal directions
- Read and verify boundary conditions

### Module 2 — Design-Zone Generation

Generate and configure the regions in which positive or negative shell stiffness contributions are applied.

Tasks:
- Select shell modification regions
- Assign shell-thickness parameters
- Calculate shell offsets
- Identify positive and negative stiffness contributions
- Generate consistent design-zone definitions

### Module 3 — ASET Generation

Automatically generate valid interface degree-of-freedom definitions.

Tasks:
- Identify relevant interface nodes
- Exclude nodes constrained by SPC definitions
- Assign the appropriate degrees of freedom
- Generate ASET1 cards
- Detect and prevent conflicting ASET/SPC definitions

A known issue from the preliminary research is OptiStruct Error 833, which occurred because of conflicting SPC and ASET assignments.

The automated process must prevent this conflict before solver execution.

### Module 4 — Matrix Export

Automate the export of the condensed shell stiffness matrix.

Tasks:
- Generate the matrix-export solver deck
- Execute OptiStruct
- Verify successful solver execution
- Validate the generated PCH/DMIG file
- Check matrix dimensions
- Check matrix symmetry

### Module 5 — Matrix Transformation

Apply the transformations required to represent additive or subtractive shell stiffness contributions.

Tasks:
- Apply the required positive or negative sign
- Perform appropriate matrix scaling
- Store transformation metadata
- Perform plausibility checks on the transformed matrix

### Module 6 — System Integration

Automatically integrate the transformed stiffness matrix into the existing finite element model.

Tasks:
- Generate INCLUDE entries
- Define the K2GG assignment
- Verify consistency of boundary conditions
- Generate the final solver deck

### Module 7 — Solver Control

Automate solver execution and monitor simulation status.

Tasks:
- Start the OptiStruct solver
- Detect and evaluate solver error codes
- Record execution time
- Store solver logs
- Identify unsuccessful or incomplete simulations

### Module 8 — Result Extraction

Automatically retrieve relevant numerical and structural quantities after each simulation.

Structural results:
- Displacements
- Reaction forces
- Surface stresses
- Compliance
- Strain energy

Numerical indicators:
- Eigenvalues
- Matrix conditioning indicators
- Solver status

The extracted results should support the quantitative evaluation criteria defined in WP02 and the numerical investigations performed in WP03–WP05.

### Module 9 — Documentation and Traceability

Automatically document each simulation case.

Record:
- Input parameters
- Model version
- Script version
- Matrix file
- Solver file
- Result file
- Error indicators
- Timestamp

Each simulation should be traceable to its corresponding configuration, model, and software version.

## Software Requirements

The automation workflow should satisfy the following requirements:

- Modular software architecture
- Clear configuration files
- No hard-coded node IDs
- Transparent error messages
- Reproducible execution
- Version control using Git
- Automated testing of central functions

## Proposed Workflow

1. Validate input model and configuration.
2. Generate design zones and shell parameters.
3. Generate and validate ASET definitions.
4. Export condensed shell stiffness matrices.
5. Transform the matrices for additive or subtractive contributions.
6. Integrate transformed matrices into the solid model.
7. Execute the final solver analysis.
8. Extract structural results and numerical stability indicators.
9. Store simulation metadata and evaluation results.

## Integration With Other Work Packages

### WP01 — Baseline Verification
Use verified preliminary models to test the automation workflow.

### WP02 — Reference Models
Automate comparisons with analytical and geometrically modified solid reference models.

### WP03 — Numerical Stability
Support automated parameter sweeps, eigenvalue analyses, and conditioning evaluations.

### WP04 — Geometric Generalization
Support varying shell regions, geometric configurations, and offset definitions.

### WP05 — Stress Recovery
Automate dummy-shell parameter studies and the extraction of local surface stresses.

### WP07 — Optimization
Provide the reproducible simulation and evaluation process required for repeated optimization iterations.

## Expected Deliverables

- Modular automated MATLAB/Python–OptiStruct workflow
- Automatic input and consistency validation
- Automated ASET generation and conflict detection
- Automated matrix export, transformation, and integration
- Automated solver execution and error handling
- Automatic result and numerical-indicator extraction
- Reproducible simulation-case documentation
- Automated tests for essential software functions
- Documented workflow limitations

## Status

Not started
