# WP01 — Baseline Verification and Reproduction

## Objective

Establish a reliable, reproducible, and well-documented starting point for the master's thesis by reviewing and verifying the preliminary research conducted during the HiWi project.

The purpose of this work package is not to develop the subtractive shell approach from scratch, but to consolidate the existing implementation, reproduce selected results, and identify the assumptions and limitations relevant to subsequent investigations.

## 1. Preliminary Work — HiWi Research

The following activities were undertaken during the preliminary research:

- Development of a simplified cantilever beam model using solid CHEXA elements.
- Implementation of surface-coincident shell elements with shared interface nodes.
- Application of shell thickness and ZOFFSET definitions.
- Static condensation of shell stiffness contributions using ASET1 definitions.
- Export and integration of condensed stiffness matrices using DMIG.
- Implementation of positive and negative shell stiffness contributions.
- Comparison of global displacements against analytical solutions and geometrically modified solid reference models.
- Initial surface-stress recovery using ultra-thin dummy shells.
- Preliminary numerical stability investigations involving eigenvalues and condition numbers.
- Development of partially automated MATLAB/OptiStruct workflows.

These preliminary results provide the starting point for the master's thesis. Their reproducibility and applicability must be verified where necessary.

## 2. Existing Preliminary Results

### Global Displacement Validation

Positive and negative shell stiffness contributions were investigated for thickness modifications between −20% and +20%.

The reported displacement formulation errors relative to the geometrically modified solid models remained below 1% for the investigated cases.

### Local Surface-Stress Recovery

An initial dummy-shell approach was investigated to recover local surface stresses.

For the −10% beam case:
- Recovered stress: 13.35 MPa
- Analytical reference: 12.70 MPa

This represents an initial proof of concept rather than a systematic validation.

### Numerical Stability

Preliminary investigations included:
- Extraction and analysis of global stiffness matrices.
- Eigenvalue spectrum evaluation.
- Investigation of matrix conditioning.
- Identification of additional interface and rotational degrees of freedom.
- Investigation of numerical behaviour near zero shell contribution.

The physical interpretation of the eigenvalue spectra and the identification of suitable stability indicators remain subjects of further investigation in WP03.

## 3. Master's Thesis Tasks

- Review the existing HiWi models and implementation.
- Verify the completeness of the existing files and scripts.
- Reproduce selected baseline, positive, and negative shell contribution cases.
- Compare reproduced results against the original HiWi results.
- Document modelling assumptions, units, boundary conditions, loads, and element formulations.
- Identify discrepancies, limitations, and requirements for further development.
- Establish a verified starting point for the remaining work packages.

## 4. Documentation — Chapter 3

**Planned period: 16–31 October 2026**

Chapter 3, "Existing Preliminary Work," will document:

- Analytical foundation
- Multi-model FE approach
- Superelement condensation and matrix export
- Positive and negative stiffness contributions
- Benchmark results and validation
- Existing implementation and automation workflow
- Limitations and unresolved questions

Chapter 3 documents the preliminary work. The additional verification and reproduction tasks within WP01 will be completed as required during the thesis.

## 5. Existing Data and Scripts

The original HiWi research files are retained in the repository's `main` branch.

The thesis branch was created from this existing research repository.

Existing models and scripts will be reviewed before deciding whether they can be reused directly, require modifications, or should be reproduced in a revised implementation.

Original research data should remain traceable to the preliminary work.

## 6. Expected Deliverables

- Documented preliminary implementation
- Inventory of existing models and scripts
- Reproducible baseline and selected positive/negative cases
- Comparison with previous analytical and numerical results
- Documented assumptions and limitations
- Verified foundation for subsequent thesis investigations

## 7. Current Status

**Status: Preliminary HiWi work available; thesis documentation and verification pending.**

October 2026:
- Chapter 2 — State of Research: deadline 15 October
- Chapter 3 — Existing Preliminary Work: planned for the remainder of October
- WP01 reproduction and verification: to be scheduled as needed

## References

- HiWi Progress Report — September 2026
- Working Guideline for the Master's Thesis
- Original research files in the `main` branch
