add_library(interp OBJECT interpolation.f90 interp2d.f90)
target_link_libraries(interp PRIVATE const)

# --- tests
add_executable(test_interp1 testinterp1.f90)
target_link_libraries(test_interp1 PRIVATE const interp)
add_test(NAME unit:interp1 COMMAND test_interp1 WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
set_tests_properties(unit:interp1 PROPERTIES
  TIMEOUT 10
  FIXTURES_SETUP GemInterp1)

if(NOT hdf5)
  return()
endif()

set(_testfile_interp2in ${CMAKE_CURRENT_BINARY_DIR}/input2d.h5)
set(_testfile_interp2 ${CMAKE_CURRENT_BINARY_DIR}/output2d.h5)
set(_testfile_interp3in ${CMAKE_CURRENT_BINARY_DIR}/input3d.h5)
set(_testfile_interp3 ${CMAKE_CURRENT_BINARY_DIR}/output3d.h5)

add_executable(test_interp2 testinterp2.f90)
target_link_libraries(test_interp2 PRIVATE interp const h5fortran::h5fortran)
add_test(NAME unit:interp2
  COMMAND $<TARGET_FILE:test_interp2> ${_testfile_interp2in} ${_testfile_interp2}
  WORKING_DIRECTORY ${PROJECT_BINARY_DIR})
set_tests_properties(unit:interp2 PROPERTIES
  TIMEOUT 15
  FIXTURES_SETUP GemInterp2)

add_executable(test_interp3 testinterp3.f90)
target_link_libraries(test_interp3 PRIVATE const interp h5fortran::h5fortran)
add_test(NAME unit:interp3
  COMMAND $<TARGET_FILE:test_interp3> ${_testfile_interp3in} ${_testfile_interp3}
  WORKING_DIRECTORY ${PROJECT_BINARY_DIR})
set_tests_properties(unit:interp3 PROPERTIES
  TIMEOUT 30  # need 30 for slow CPU
  FIXTURES_SETUP GemInterp3)


if(python_ok)
  add_test(NAME unit:interp2:python
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/testinterp.py ${_testfile_interp2})
  set_tests_properties(unit:interp2:python PROPERTIES
    REQUIRED_FILES "${_testfile_interp2};${_testfile_interp2in}"
    TIMEOUT 30
    FIXTURES_REQUIRED GemInterp2)

  add_test(NAME unit:interp3:python
    COMMAND ${Python3_EXECUTABLE}  ${CMAKE_CURRENT_SOURCE_DIR}/testinterp3.py ${_testfile_interp3})
  set_tests_properties(unit:interp3:python PROPERTIES
    REQUIRED_FILES "${_testfile_interp3};${_testfile_interp3in}"
    TIMEOUT 30
    RUN_SERIAL true  # due to memory use
    FIXTURES_REQUIRED GemInterp3)
endif(python_ok)
