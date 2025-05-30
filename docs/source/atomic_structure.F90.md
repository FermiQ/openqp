# atomic_structure.F90

## Overview

This file defines the `atomic_structure_m` module, which encapsulates the data and procedures related to the atomic structure of a molecule. It provides a structured way to store and manage atomic information like nuclear charge, mass, coordinates, and gradients.

## Key Components

### `atomic_structure` (Type)
- A derived data type that holds information about the atomic structure. It contains allocatable arrays for nuclear charge (`zn`), mass (`mass`), gradient (`grad`), and atomic coordinates (`xyz`). It also defines procedures for initialization, cleaning, and centering the atomic structure.

### `atomic_structure_init(self, natoms)` (Function)
- **Description**: Initializes the `atomic_structure` object. It deallocates any existing arrays and then allocates them to the specified number of atoms (`natoms`).
- **Arguments**:
    - `self`: An instance of the `atomic_structure` type.
    - `natoms`: An integer representing the number of atoms.
- **Returns**: `ok` (integer status code, 0 for success).

### `atomic_structure_clean(self)` (Function)
- **Description**: Deallocates all allocatable arrays within the `atomic_structure` object (`zn`, `mass`, `grad`, `xyz`).
- **Arguments**:
    - `self`: An instance of the `atomic_structure` type.
- **Returns**: `ok` (integer status code, 0 for success).

### `atomic_structure_center(self, weight)` (Function)
- **Description**: Calculates the center of the atomic structure. It can compute either the geometric center (unweighted) or the center of mass.
- **Arguments**:
    - `self`: An instance of the `atomic_structure` type.
    - `weight` (Optional, Character): Specifies the weighting scheme. Can be 'NONE' (default) for geometric center or 'MASS' for center of mass.
- **Returns**: `r` (real array of size 3) representing the coordinates of the center.

## Important Variables/Constants

- **`zn(:)`**: (Real, Allocatable Array) Stores the atomic number or nuclear charge for each atom.
- **`mass(:)`**: (Real, Allocatable Array) Stores the atomic mass for each atom.
- **`grad(:,:)`**: (Real, Allocatable Array) Stores the gradient (e.g., forces) for each atom in three dimensions.
- **`xyz(:,:)`**: (Real, Allocatable Array) Stores the Cartesian coordinates (x, y, z) for each atom.
- **`WTYPE_NONE`**: (Character Parameter) Constant for specifying no weighting in `atomic_structure_center`.
- **`WTYPE_MASS`**: (Character Parameter) Constant for specifying mass weighting in `atomic_structure_center`.

## Usage Examples

```fortran
! Example of using atomic_structure_m module
module main_program
  use atomic_structure_m
  use iso_c_binding, only: c_double
  implicit none

  type(atomic_structure) :: molecule
  integer :: num_atoms
  integer :: status
  real(c_double) :: center_coords(3)

  num_atoms = 3
  ! Initialize the molecule
  status = molecule%init(num_atoms)
  if (status /= 0) then
    print *, "Error initializing molecule"
    stop
  end if

  ! Populate atomic data (example for H2O)
  molecule%zn = [8.0_c_double, 1.0_c_double, 1.0_c_double]
  molecule%mass = [15.999_c_double, 1.008_c_double, 1.008_c_double]
  molecule%xyz(1,:) = [0.0_c_double, 0.0_c_double, 0.0_c_double]       ! Oxygen
  molecule%xyz(2,:) = [0.757_c_double, 0.586_c_double, 0.0_c_double]    ! Hydrogen 1
  molecule%xyz(3,:) = [-0.757_c_double, 0.586_c_double, 0.0_c_double]   ! Hydrogen 2

  ! Calculate center of mass
  center_coords = molecule%center(weight='MASS')
  print *, "Center of mass:", center_coords

  ! Clean up
  status = molecule%clean()
  if (status /= 0) then
    print *, "Error cleaning molecule"
    stop
  end if

end module main_program
```

## Dependencies and Interactions

- **Internal Dependencies**:
    - `strings` module (specifically `to_upper` function used in `atomic_structure_center`).
- **External Libraries**:
    - `iso_c_binding`: Used for defining types compatible with C (`c_double`, `c_int`).
- **Interactions**:
    - This module is fundamental for representing molecular geometry and is likely used by many other modules in the project that perform calculations or manipulations based on atomic coordinates, masses, etc.
```
