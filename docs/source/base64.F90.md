# base64.F90

## Overview

This file defines the `base64` module, which provides procedures for Base64 encoding and decoding. It supports encoding and decoding of Fortran arrays of `integer(int32)`, `integer(int64)`, `real(real32)`, `real(real64)`, and `character` types. The core encoding/decoding logic is implemented in C and accessed via ISO C Binding.

## Key Components

### `b64_encode` (Generic Interface)
- **Description**: A generic interface for Base64 encoding functions. It resolves to specific procedures based on the input data type.
- **Specific Procedures**:
    - `b64_encode_int32(src)`: Encodes an array of `integer(int32)`.
    - `b64_encode_int64(src)`: Encodes an array of `integer(int64)`.
    - `b64_encode_real32(src)`: Encodes an array of `real(real32)`.
    - `b64_encode_real64(src)`: Encodes an array of `real(real64)`.
    - `b64_encode_char(src)`: Encodes a character string.
- **Arguments**:
    - `src`: A Fortran array or character string of a supported type.
- **Returns**: A character string (`character(:), allocatable`) containing the Base64 encoded data.

### `b64_decode` (Generic Interface)
- **Description**: A generic interface for Base64 decoding functions. It resolves to specific procedures based on the output data type.
- **Specific Procedures**:
    - `b64_decode_int32(src, res)`: Decodes a Base64 string into an array of `integer(int32)`.
    - `b64_decode_int64(src, res)`: Decodes a Base64 string into an array of `integer(int64)`.
    - `b64_decode_real32(src, res)`: Decodes a Base64 string into an array of `real(real32)`.
    - `b64_decode_real64(src, res)`: Decodes a Base64 string into an array of `real(real64)`.
    - `b64_decode_char(src, res)`: Decodes a Base64 string into a character string.
- **Arguments**:
    - `src`: A character string containing the Base64 encoded data.
    - `res`: An allocatable Fortran array or character string of the corresponding type to store the decoded data (intent `inout`).

### `base64_encode` (C Function Interface)
- **Description**: Interface to the external C function that performs Base64 encoding.
- **Arguments**:
    - `src` (`c_ptr`, value): Pointer to the source data.
    - `dst` (`c_ptr`, value): Pointer to the destination buffer for encoded data.
    - `nbytes` (`c_long_long`, value): Number of bytes in the source data.
- **Returns**: (`c_long_long`) The length of the encoded string.

### `base64_decode` (C Function Interface)
- **Description**: Interface to the external C function that performs Base64 decoding.
- **Arguments**:
    - `src` (`c_ptr`, value): Pointer to the Base64 encoded string.
    - `dst` (`c_ptr`, value): Pointer to the destination buffer for decoded data.
- **Returns**: (`c_long_long`) The number of bytes in the decoded data.

### `strlen` (C Function Interface)
- **Description**: Interface to the C `strlen` function to determine the length of a C string.
- **Arguments**:
    - `str` (`c_ptr`, value): Pointer to the C string.
- **Returns**: (`c_size_t`) The length of the string.

### Helper Functions
- `c_to_f_string(str)`: Converts a C character array (null-terminated) to a Fortran allocatable character string.
- `f_to_c_string(str)`: Converts a Fortran character string to a C allocatable character array (null-terminated).
- `string_fix_c_length(string)`: Potentially adds a null terminator for gfortran if the string length determined by `len()` is less than `strlen()`. (Conditional compilation via `#ifdef __GFORTRAN__`)

## Important Variables/Constants

- **`BASE64_TABLE`**: (Character Parameter) A constant string containing the 64 characters used in the Base64 encoding scheme ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/").

## Usage Examples

```fortran
! Example of using the base64 module for encoding and decoding
module test_base64_module
  use base64
  use iso_fortran_env, only: int32, real64
  implicit none

  character(:), allocatable :: encoded_str, decoded_char_str
  integer(int32), allocatable :: original_int_array(:), decoded_int_array(:)
  real(real64), allocatable :: original_real_array(:), decoded_real_array(:)
  character(len=20) :: original_char_str

  ! --- Integer array example ---
  original_int_array = [1, 2, 3, 4, 5]
  encoded_str = b64_encode(original_int_array)
  print *, "Original Integers: ", original_int_array
  print *, "Encoded String:    '", encoded_str, "'"
  call b64_decode(encoded_str, decoded_int_array)
  print *, "Decoded Integers:  ", decoded_int_array
  deallocate(encoded_str, decoded_int_array)
  print *,""

  ! --- Real array example ---
  original_real_array = [1.1_real64, 2.2_real64, 3.3_real64]
  encoded_str = b64_encode(original_real_array)
  print *, "Original Reals: ", original_real_array
  print *, "Encoded String: '", encoded_str, "'"
  call b64_decode(encoded_str, decoded_real_array)
  print *, "Decoded Reals:  ", decoded_real_array
  deallocate(encoded_str, decoded_real_array)
  print *,""

  ! --- Character string example ---
  original_char_str = "Hello Base64 World!"
  encoded_str = b64_encode(original_char_str)
  print *, "Original String: '", original_char_str, "'"
  print *, "Encoded String:  '", encoded_str, "'"
  call b64_decode(encoded_str, decoded_char_str)
  print *, "Decoded String:  '", decoded_char_str, "'"
  deallocate(encoded_str, decoded_char_str)

end module test_base64_module
```

## Dependencies and Interactions

- **Internal Dependencies**:
    - None explicitly within other Fortran modules of this project, but it relies on C functions.
- **External Libraries**:
    - `iso_c_binding`: Heavily used for defining interfaces to C functions and for C-compatible data types.
    - `iso_fortran_env`: Used for portable kind parameters for integer and real types (`int32`, `int64`, `real32`, `real64`).
- **Interactions**:
    - This module interacts with C code (presumably in `cbase64.c` or a linked library) that implements the `base64_encode`, `base64_decode`, and `strlen` functions.
    - It is likely used by other parts of the project that require data to be encoded or decoded in Base64 format, for example, for saving binary data in text-based formats (like JSON or XML) or for data transmission.
```
