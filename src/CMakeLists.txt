function(set_targ_props)

foreach(t ${ARGV})
  target_include_directories(${t} INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/include)
  set_target_properties(${t} PROPERTIES
    Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)
endforeach()

endfunction(set_targ_props)

# --- vendor libraries
add_subdirectory(vendor/msis00)
add_subdirectory(vendor/lapack95)  # used by PDEparabolic

# --- GEMINI
add_subdirectory(ionization)
add_subdirectory(numerical)
add_subdirectory(mpimod)
add_subdirectory(io)
add_subdirectory(temporal)

add_library(collision OBJECT collisions/collisions.f90)
target_link_libraries(collision PRIVATE const config)

if(NOT MPI_OK)
  set_targ_props(calculus collision config const fang fang_run gbsv logging pathlib reader sanity_check timeutils)
  return()
endif()

# --- other libs
add_subdirectory(unit_tests)
add_subdirectory(neutral)
add_subdirectory(sources)

add_library(multifluid OBJECT multifluid/multifluid.f90)
target_link_libraries(multifluid PRIVATE advec calculus collision const diffusion grid mesh ionization mpimod precipBCs sources timeutils config)

# --- Main GEMINI executable
add_executable(gemini.bin gemini.f90)
set_target_properties(gemini.bin PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
target_link_libraries(gemini.bin PRIVATE advec calculus config const collision diffusion fang grid io interp ionization gbsv mesh mpimod multifluid
  neutral pathlib PDEelliptic PDEparabolic potential precipBCs reader sanity_check sources temporal timeutils)
if(NOT APPLE AND CMAKE_Fortran_COMPILER_ID STREQUAL GNU)
# the gemini.bin linking step can break for "ld" linker due to these getting out of order for gemini.bin
# making them a group seemed to be the fix.
# FIXME: should we instead check if the linker is "ld"?
# We tried every other solution we could think of, and this was the only one that workded.
# even the quotes must be just like below, and don't use imported targets
  message(STATUS " Using link group workaround")
  target_link_libraries(gemini.bin PRIVATE "-Wl,--start-group" ${MUMPS_LIBRARIES} ${SCALAPACK_LIBRARIES} ${LAPACK_LIBRARIES} "-Wl,--end-group")
else()
  target_link_libraries(gemini.bin PRIVATE MUMPS::MUMPS SCALAPACK::SCALAPACK LAPACK::LAPACK)
endif()

add_test(NAME unit:gemini_exe_ok COMMAND $<TARGET_FILE:gemini.bin>)
set_tests_properties(unit:gemini_exe_ok PROPERTIES PASS_REGULAR_EXPRESSION "EOF: Gemini-3D")

#--------magnetic field calculation executable---------------
add_executable(magcalc.bin magcalc.f90)
target_link_libraries(magcalc.bin PRIVATE config const grid io mesh mpimod pathlib reader sanity_check timeutils)
set_target_properties(magcalc.bin PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

add_test(NAME unit:magcalc_exe_ok COMMAND $<TARGET_FILE:magcalc.bin>)
set_tests_properties(unit:magcalc_exe_ok PROPERTIES PASS_REGULAR_EXPRESSION "EOF: MAGCALC")

set_targ_props(calculus collision config const fang fang_run io ionization gbsv logging mpimod multifluid neutral pathlib precipBCs reader sanity_check sources temporal timeutils)
