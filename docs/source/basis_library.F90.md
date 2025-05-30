# basis_library.F90

## Overview

The `basis_library` module is responsible for reading, storing, and managing basis set information from external library files. It defines data structures to hold basis set definitions (shells, exponents, contraction coefficients) for each chemical element and provides procedures to parse standard basis set file formats.

## Key Components

### `atom_basis_t` (Type)
- **Description**: A derived data type that stores the basis set information for a single atom (element).
- **Fields**:
    - `nshells` (Integer): Number of shells for this atom.
    - `nbfs` (Integer): Total number of basis functions for this atom.
    - `nprims` (Integer): Total number of primitive Gaussian functions for this atom.
    - `ang(:)` (Integer, Allocatable): Array storing the angular momentum for each shell (0 for S, 1 for P, etc.).
    - `ncontract(:)` (Integer, Allocatable): Array storing the number of primitive Gaussians in each contracted shell.
    - `ex(:)` (Real(real64), Allocatable): Array storing all exponents of primitive Gaussians.
    - `cc(:)` (Real(real64), Allocatable): Array storing all contraction coefficients.
- **Procedures**:
    - `reserve` (Private): A procedure to dynamically allocate/reallocate memory for the arrays (`ang`, `ncontract`, `ex`, `cc`) as more shells or Gaussians are added.

### `basis_library_t` (Type)
- **Description**: The main derived data type that holds the basis set library. It contains an array of `atom_basis_t` for all possible elements up to `MAX_ELEMENT_Z`.
- **Fields**:
    - `atoms(MAX_ELEMENT_Z)` (Type(atom_basis_t)): An array where each element stores the `atom_basis_t` for a specific chemical element (indexed by atomic number).
- **Procedures**:
    - `from_file(fname)`: Reads basis set data from the specified file name.
    - `calc_req_storage(z, nshell, ngauss, nbasis)`: Calculates the total number of shells, primitive Gaussians, and basis functions for a given set of atomic numbers `z`.
    - `echo()`: Prints the contents of the loaded basis library to standard output.

### `read_basis_library(this, fname)` (Subroutine)
- **Description**: Opens the specified basis library file and calls `read_basis_library_file` to parse its content. Handles file opening errors.
- **Arguments**:
    - `this` (Class(basis_library_t), Target, Intent(inout)): The `basis_library_t` object to populate.
    - `fname` (Character(*), Intent(in)): The name of the basis library file.

### `read_basis_library_file(this, iunit)` (Subroutine)
- **Description**: Reads and parses the basis set data from an already opened file unit. It uses a state machine (`READ_ATOM`, `READ_SHELL`, `READ_GAUSS`) to interpret lines corresponding to atom definitions, shell types, and Gaussian primitive parameters (exponent, coefficient). It populates the `atom_basis_t` structures within the `basis_library_t` object.
- **Arguments**:
    - `this` (Class(basis_library_t), Target, Intent(inout)): The `basis_library_t` object to populate.
    - `iunit` (Integer, Intent(in)): The file unit number of the open basis library file.

### `calc_req_storage(this, z, nshell, ngauss, nbasis)` (Subroutine)
- **Description**: Calculates the aggregated number of shells, primitive Gaussians, and basis functions required for a molecule composed of atoms specified by the array `z` (atomic numbers).
- **Arguments**:
    - `this` (Class(basis_library_t), Target, Intent(in)): The populated `basis_library_t` object.
    - `z(:)` (Integer, Intent(in)): An array of atomic numbers for the atoms in the molecule.
    - `nshell` (Integer, Intent(out)): Total number of shells.
    - `ngauss` (Integer, Intent(out)): Total number of primitive Gaussians.
    - `nbasis` (Integer, Intent(out)): Total number of basis functions.

### `basis_library_echo(this)` (Subroutine)
- **Description**: Prints a summary of the loaded basis library to the standard output. For each element with a defined basis, it lists its name, number of shells, primitives, and basis functions, followed by the details of each shell (angular momentum, number of contractions, and the exponent/coefficient for each primitive).
- **Arguments**:
    - `this` (Class(basis_library_t), Intent(in)): The `basis_library_t` object.

### `atom_basis_reserve(this, nshell, ngauss)` (Subroutine)
- **Description**: A private helper subroutine for `atom_basis_t` to manage dynamic memory allocation for its arrays. If more space is needed than currently allocated, it reallocates the arrays, preserving existing data.
- **Arguments**:
    - `this` (Class(atom_basis_t), Intent(inout)): The `atom_basis_t` object.
    - `nshell` (Optional, Integer, Intent(in)): The required number of shells.
    - `ngauss` (Optional, Integer, Intent(in)): The required number of Gaussian primitives.

### `reserve_array_int(a, n)` / `reserve_array_real(a, n)` (Subroutines)
- **Description**: Private helper subroutines for dynamically resizing allocatable integer and real arrays, respectively. They increase array size by a fixed increment (16) if `n` exceeds current bounds.
- **Arguments**:
    - `a(:)` (Allocatable, Intent(inout)): The array to be resized.
    - `n` (Integer, Intent(in)): The required minimum size.

### `skip_string(str)` (Logical Function)
- **Description**: Checks if a given string should be skipped during file parsing. A string is skipped if it's empty after removing leading spaces or if its first non-space character is one of `!#&$/'`.
- **Arguments**:
    - `str` (Character(*)): The input string.
- **Returns**: `.true.` if the string should be skipped, `.false.` otherwise.

## Important Variables/Constants

- **`READ_ATOM`, `READ_SHELL`, `READ_GAUSS`**: Integer parameters defining states for the parser in `read_basis_library_file`.
- **`ANGULAR_LABEL`**: (From `constants` module) Character array mapping angular momentum integers to labels (e.g., 'S', 'P', 'D').
- **`NUM_CART_BF`**: (From `constants` module) Integer array giving the number of Cartesian basis functions for each angular momentum.
- **`MAX_ELEMENT_Z`**: (From `elements` module) Maximum atomic number supported.

## Usage Examples

```fortran
! Example of using the basis_library module
module test_basis_lib
  use basis_library
  use elements, only: get_element_id
  implicit none

  type(basis_library_t) :: my_basis_library
  integer :: nshell_total, ngauss_total, nbasis_total
  integer :: atomic_numbers(2)

  ! Create a dummy basis file for testing: "dummy_basis.lib"
  ! H
  ! S 1
  ! 1 0.3425250 1.0000000
  ! P 1
  ! 1 0.1425250 1.0000000
  !
  ! HE
  ! S 1
  ! 1 0.8000000 1.0000000

  ! It's better to create this file externally or use a real basis file.
  ! For this example, assume "dummy_basis.lib" exists with the content above.
  ! open(unit=10, file="dummy_basis.lib", status="new", action="write")
  ! write(10,*) "H"
  ! write(10,*) "S 1"
  ! write(10,*) "1 0.3425250 1.0000000"
  ! write(10,*) "P 1"
  ! write(10,*) "1 0.1425250 1.0000000"
  ! write(10,*) ""  ! Blank line
  ! write(10,*) "HE"
  ! write(10,*) "S 1"
  ! write(10,*) "1 0.8000000 1.0000000"
  ! close(10)

  ! Load the basis library from the file
  call my_basis_library%from_file("dummy_basis.lib")

  ! Echo the loaded library to standard output
  call my_basis_library%echo()

  ! Calculate storage for a water molecule (H, H, O - assuming O is not in dummy_basis.lib)
  ! For this example, let's use H and He from the dummy file.
  atomic_numbers(1) = get_element_id("H")
  atomic_numbers(2) = get_element_id("HE")

  call my_basis_library%calc_req_storage(atomic_numbers, &
                                        nshell_total, ngauss_total, nbasis_total)

  print *, "For atoms H, HE:"
  print *, "Total shells:      ", nshell_total  ! Expected: (2 for H) + (1 for He) = 3
  print *, "Total Gaussians:   ", ngauss_total  ! Expected: (1+1 for H) + (1 for He) = 3
  print *, "Total basis funcs: ", nbasis_total  ! Expected: (1 S + 3 P for H) + (1 S for He) = 1+3+1 = 5

end module test_basis_lib
```

## Dependencies and Interactions

- **Internal Dependencies**:
    - `elements`: Uses `MAX_ELEMENT_Z`, `get_element_id`, `ELEMENTS_LONG_NAME`.
    - `strings`: Uses `to_upper` (though not explicitly visible in the provided snippet, common in such parsers).
    - `constants`: Uses `ANGULAR_LABEL`, `NUM_CART_BF`.
    - `io_constants`: Uses `IW` for output unit.
- **External Libraries**:
    - `iso_fortran_env`: For `real64`.
- **Interactions**:
    - This module provides the fundamental `basis_library_t` type which is then likely used by other modules (e.g., `basis_tools` or a molecule setup module) to extract the specific `atom_basis_t` for each atom in a molecular system and construct the actual `basis_set` object used in calculations.
    - It interacts with the file system to read basis set files.
```
