set(dir "${CMAKE_CURRENT_SOURCE_DIR}")

set(SOURCES)
file(GLOB SOURCES CONFIGURE_DEPENDS "*.F90" "*.c")

add_subdirectory(io)
add_subdirectory(mathlib)
add_subdirectory(modules)
add_subdirectory(integrals)
add_subdirectory(dftlib)

message(STATUS ${SOURCES})
message(STATUS "CMAKE_INSTALL_LIBDIR = ${CMAKE_INSTALL_LIBDIR}")
add_library(oqp ${SOURCES})
add_dependencies(oqp libxc libtagarray libecpint)
target_link_libraries(oqp xcf03 xc tagarray_f tagarray ecpint Faddeeva)
if("${CMAKE_Fortran_COMPILER_ID}" STREQUAL "GNU")
  target_link_libraries(oqp stdc++)
endif()
target_link_directories(oqp PUBLIC ${CMAKE_BINARY_DIR}/external/libxc/src/libxc-build-${CMAKE_Fortran_COMPILER_ID})
target_include_directories(oqp PUBLIC ${CMAKE_BINARY_DIR}/external/libxc/src/libxc-build-${CMAKE_Fortran_COMPILER_ID})
target_link_directories(oqp PUBLIC ${CMAKE_BINARY_DIR}/external/libtagarray/src/libtagarray-build-${CMAKE_Fortran_COMPILER_ID})
target_include_directories(oqp PUBLIC ${CMAKE_BINARY_DIR}/external/libtagarray/src/libtagarray-build-${CMAKE_Fortran_COMPILER_ID}/include/tagarray
                                      ${CMAKE_BINARY_DIR}/external/libtagarray/src/libtagarray-build-${CMAKE_Fortran_COMPILER_ID}/include/tagarray
                                      ${CMAKE_SOURCE_DIR}/external/libtagarray/src/libtagarray/include)
target_link_directories(oqp PUBLIC    ${CMAKE_BINARY_DIR}/external/libecpint/src/libecpint-build-${CMAKE_Fortran_COMPILER_ID}/src
	                              ${CMAKE_BINARY_DIR}/external/libecpint/src/libecpint-build-${CMAKE_Fortran_COMPILER_ID}/external/Faddeeva)
target_include_directories(oqp PUBLIC ${CMAKE_BINARY_DIR}/external/libecpint/install/include/libecpint
			              ${CMAKE_BINARY_DIR}/external/libecpint/install/include)
set_target_properties(oqp PROPERTIES POSITION_INDEPENDENT_CODE ON)
if(ENABLE_OPENMP)
  target_link_libraries(oqp OpenMP::OpenMP_Fortran OpenMP::OpenMP_C OpenMP::OpenMP_CXX)
endif()
if(ENABLE_MPI)
    target_compile_definitions(oqp PRIVATE ENABLE_MPI)
endif()
target_link_directories(oqp PUBLIC ${CMAKE_BINARY_DIR}/external/libxc/src/libxc-build-${CMAKE_Fortran_COMPILER_ID})
set(WRAPPER_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/wrapper/libecpint_wrapper.cpp)
target_sources(oqp PRIVATE ${WRAPPER_SOURCES})
if(USE_LIBINT)
  target_compile_definitions(oqp PRIVATE OQP_LIBINT_ENABLE)
  add_dependencies(oqp libint2)
  target_include_directories(oqp PUBLIC ${LIBINT2_SOURCE_DIR}/include)
  target_include_directories(oqp PUBLIC ${LIBINT2_PREFIX}/build-${CMAKE_Fortran_COMPILER_ID}/include)
  target_include_directories(oqp PUBLIC ${LIBINT2_PREFIX}/build-${CMAKE_Fortran_COMPILER_ID}/fortran)
  target_link_libraries(oqp ${LIBINT2_PREFIX}/build-${CMAKE_Fortran_COMPILER_ID}/libint2.a)
  if("${CMAKE_Fortran_COMPILER_ID}" STREQUAL "GNU")
    target_link_libraries(oqp stdc++)
  endif()
endif()

# BLAS/LAPACK
cleanBlasVars()
if(NOT ${LINALG_LIB} STREQUAL none)
  findLinearAlgebra()
endif()

if(LINALG_LIB_INT64)
    set_property(SOURCE ${SOURCES_mathlib_ilp64} APPEND PROPERTY COMPILE_DEFINITIONS OQP_BLAS_INT=8)
else()
    set_property(SOURCE ${SOURCES_mathlib_ilp64} APPEND PROPERTY COMPILE_DEFINITIONS OQP_BLAS_INT=4)
endif()

# NLopt include
add_dependencies(oqp nlopt)
target_include_directories(oqp PUBLIC ${NLOPT_PREFIX}/build-${CMAKE_Fortran_COMPILER_ID})
target_link_libraries(oqp ${NLOPT_PREFIX}/build-${CMAKE_Fortran_COMPILER_ID}/libnlopt.a)

install(TARGETS oqp
EXPORT "${PROJECT_NAME}Targets"
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
