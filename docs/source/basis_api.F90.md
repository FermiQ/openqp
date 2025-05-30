# basis_api.F90

## Overview

The `basis_api` module provides an Application Programming Interface (API) for managing and constructing basis sets, including both electron shells and Effective Core Potentials (ECPs). It defines data structures to represent these components and includes procedures to populate them (often via C interoperability from an external source), map them into the main `basis_set` data structure (from `basis_tools` module), and print basis set information.

## Key Components

### `base_shell` (Abstract Type)
- **Description**: An abstract base type for shell-like structures. It contains common properties like `id`, `element_id`, and pointers for `n_exponents` (number of exponents), `exponents`, and `coefficients`. It defines a deferred procedure `clear`.
- **Fields**:
    - `id` (Integer): Shell identifier.
    - `element_id` (Integer): Identifier of the element this shell belongs to.
    - `n_exponents(:)` (Integer, Pointer): Array storing the number of primitive Gaussians for each contraction.
    - `exponents(:)` (Real, Pointer): Array of exponents for primitive Gaussians.
    - `coefficient(:)` (Real, Pointer): Array of contraction coefficients.
- **Procedures**:
    - `clear` (Deferred): Abstract subroutine to deallocate and reset shell data.

### `electron_shell` (Type, Extends `base_shell`)
- **Description**: Represents an electron shell (e.g., S, P, D functions). It extends `base_shell` and adds `angular_momentum` and a pointer `next` to create a linked list of shells.
- **Fields**:
    - `angular_momentum` (Integer): The angular momentum of the shell (0 for S, 1 for P, etc.).
    - `next` (Type(electron_shell), Pointer): Pointer to the next electron shell in a linked list, allowing for dynamic basis set construction.
- **Procedures**:
    - `clear`: Implements the `base_shell_clear` procedure to deallocate and reset `electron_shell` specific data and recursively clears the next shell in the list.

### `ecpdata` (Type, Extends `base_shell`)
- **Description**: Represents Effective Core Potential data. It extends `base_shell` to store ECP parameters.
- **Fields**:
    - `n_angular_m` (Integer): Number of angular momenta in the ECP.
    - `ecp_zn(:)` (Integer, Pointer): Array of core charges for each atom.
    - `ecp_r_expo(:)` (Integer, Pointer): Array of radial exponents (n in r^n) for ECP terms.
    - `ecp_am(:)` (Integer, Pointer): Array of angular momenta for ECP terms.
    - `ecp_coord(:)` (Real, Pointer): Coordinates associated with ECPs (if applicable, though typically centered on atoms).
- **Procedures**:
    - `clear`: Implements the `base_shell_clear` procedure to deallocate and reset `ecpdata` specific fields.

### `head` (Module Variable)
- **Description**: A pointer of type `electron_shell`. It acts as the head of a linked list of electron shells being constructed. Initialized to `null()`.

### `ecp_head` (Module Variable)
- **Description**: A variable of type `ecpdata`. It stores the ECP data being constructed.

### `append_shell(c_handle)` (Subroutine, C-Bindable)
- **Description**: C-bindable subroutine that calls `oqp_append_shell` to add a new electron shell to the current basis set being constructed. It retrieves necessary information from the `c_handle` (an OQP handle).
- **Arguments**:
    - `c_handle` (Type(oqp_handle_t)): A C handle containing information about the shell to be added.

### `oqp_append_shell(info)` (Subroutine)
- **Description**: Internal subroutine that creates a new `electron_shell` node, populates it with data from the `info` argument (which includes pointers to C arrays for exponents, coefficients, etc.), and appends it to the linked list pointed to by `head`.
- **Arguments**:
    - `info` (Type(information)): A Fortran structure containing detailed shell information.

### `append_ecp(c_handle)` (Subroutine, C-Bindable)
- **Description**: C-bindable subroutine that calls `oqp_append_ecp` to add ECP data.
- **Arguments**:
    - `c_handle` (Type(oqp_handle_t)): A C handle containing ECP information.

### `oqp_append_ecp(info)` (Subroutine)
- **Description**: Internal subroutine that populates the `ecp_head` module variable with ECP data (exponents, coefficients, core charges, etc.) extracted from the `info` argument.
- **Arguments**:
    - `info` (Type(information)): A Fortran structure containing detailed ECP information.

### `print_all_shells()` (Subroutine, C-Bindable)
- **Description**: C-bindable subroutine that iterates through the linked list of electron shells (starting from `head`) and prints their details (ID, element ID, angular momentum, exponents, coefficients).

### `map_shell2basis_set(infos)` (Subroutine)
- **Description**: This is a key subroutine that transforms the collected shell data (from the `head` linked list and `ecp_head`) into the structured `basis_set` type (defined in `basis_tools`). It allocates and populates the arrays within the `basis_set` object (e.g., `ex`, `cc`, `am`, `origin`, ECP parameters). It also calculates properties like the total number of basis functions (`nbf`), shells (`nshell`), primitives (`nprim`), and maximum angular momentum (`mxam`). After mapping, it clears the temporary linked list (`head`) and `ecp_head`.
- **Arguments**:
    - `infos` (Type(information), Target, Intent(inout)): The main information structure which contains the `basis_set` object to be populated.

### `print_basis(infos)` (Subroutine)
- **Description**: Prints detailed information about the constructed basis set (and ECPs if present) to the log file specified in `infos%log_filename`. It iterates through shells and ECPs, printing exponents, coefficients, and other relevant data.
- **Arguments**:
    - `infos` (Type(information), Target, Intent(inout)): The main information structure.

### `ecp_printing(basis, iw, j)` (Subroutine)
- **Description**: A helper subroutine called by `print_basis` to print the details of ECP parameters for a specific atom `j`.
- **Arguments**:
    - `basis` (Class(basis_set), Intent(in)): The basis set object containing ECP data.
    - `iw` (Integer, Intent(in)): The file unit number for writing.
    - `j` (Integer, Intent(in)): The atom index for which to print ECP data.

### `electron_shell_clear(this)` (Subroutine)
- **Description**: Specific implementation of the deferred `clear` procedure for `electron_shell`. Deallocates its pointer arrays and recursively calls `clear` on the `next` shell.
- **Arguments**:
    - `this` (Class(electron_shell), Intent(inout)): The electron shell to clear.

### `ecpdata_clear(this)` (Subroutine)
- **Description**: Specific implementation of the deferred `clear` procedure for `ecpdata`. Deallocates its pointer arrays.
- **Arguments**:
    - `this` (Class(ecpdata), Intent(inout)): The ECP data structure to clear.

## Important Variables/Constants

- The module primarily uses derived types and pointers to manage basis set data dynamically. The key "variables" are the module-level pointers `head` (for electron shells) and the module-level variable `ecp_head` (for ECP data), which temporarily store basis set information before it's mapped to the `basis_set` type.

## Usage Examples

*This module is primarily used internally by the system when reading basis set data from an external source (likely via C API calls). Direct usage by an end-user in an input file is not typical. The typical workflow involves:*
1. External calls to `append_shell` and `append_ecp` (or their C counterparts) to populate the linked list and `ecp_head`.
2. A call to `map_shell2basis_set` to process this raw data into the structured `infos%basis` object.
3. Optionally, a call to `print_basis` to write basis set details to the log.

```fortran
! Conceptual Fortran usage (actual population would likely come from C)
module main_example
  use basis_api
  use types, only: information, initialize_information_type, elshell_data_type
  use basis_tools, only: basis_set
  use iso_c_binding, only: c_double, c_int, c_ptr, c_loc

  implicit none
  type(information) :: infos
  type(electron_shell), pointer :: current_shell
  real(c_double), target :: some_exponents(2), some_coeffs(2)
  integer(c_int) :: num_exp(1)

  ! Initialize infos structure (simplified)
  call initialize_information_type(infos)
  infos%log_filename = 'basis_example.log'
  allocate(infos%basis)
  allocate(infos%atoms)
  infos%atoms%zn = [1.0_c_double] ! Example for one Hydrogen
  infos%mol_prop%natom = 1

  ! --- Manually simulate appending a shell (in reality, this comes from C via append_shell) ---
  ! Create a dummy shell info to pass to oqp_append_shell
  infos%elshell%id = 1
  infos%elshell%element_id = 1 ! For the first atom
  infos%elshell%ang_mom = 0    ! S-shell
  num_exp(1) = 2
  some_exponents = [0.5_c_double, 0.1_c_double]
  some_coeffs    = [0.8_c_double, 0.2_c_double]
  infos%elshell%num_expo = c_loc(num_exp)
  infos%elshell%expo = c_loc(some_exponents)
  infos%elshell%coef = c_loc(some_coeffs)
  call oqp_append_shell(infos) ! Appends to the 'head' list

  ! --- Manually simulate appending ECP data (if any) ---
  ! infos%elshell%ecp_zn = ... (and other ecp fields)
  ! call oqp_append_ecp(infos) ! Populates 'ecp_head'

  ! Map the collected shells and ECPs to the basis_set object
  call map_shell2basis_set(infos)

  ! Print the basis set
  call print_basis(infos)

  ! Clean up (basis_set has its own destroy method, head and ecp_head are cleared in map_shell2basis_set)
  if (allocated(infos%basis%ex)) call infos%basis%destroy()
  deallocate(infos%basis, infos%atoms)

end module main_example
```

## Dependencies and Interactions

- **Internal Dependencies**:
    - `c_interop`: For `oqp_handle_t` and `oqp_handle_get_info` to interface with C.
    - `types`: Uses the `information` derived type extensively to pass data between procedures and to hold basis set construction details (`elshell_data_type` within `information`).
    - `basis_tools`: The `map_shell2basis_set` procedure populates a `basis_set` object, which is defined in this module.
    - `elements`: Used by `print_basis` to get short names for elements.
    - `physical_constants`: Uses `UNITS_ANGSTROM`.
    - `libecpint_wrapper`: Though not directly used in many functions shown, its `use` statement suggests potential interaction or that some types/interfaces might originate here for ECP handling.
- **External Libraries**:
    - `iso_c_binding`: Essential for C interoperability (pointers, types).
    - `iso_fortran_env`: For `real64` kind parameter.
- **Interactions**:
    - This module acts as a bridge between external (likely C-based) basis set input routines and the internal Fortran representation (`basis_set` type).
    - It is a foundational module for any calculation that requires basis sets, as it prepares the primary `basis_set` data structure used by other parts of the quantum chemistry program.
```
