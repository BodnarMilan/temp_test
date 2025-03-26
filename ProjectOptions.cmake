include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(moderncpp_cmake_template_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(moderncpp_cmake_template_setup_options)
  option(moderncpp_cmake_template_ENABLE_HARDENING "Enable hardening" ON)
  option(moderncpp_cmake_template_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    moderncpp_cmake_template_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    moderncpp_cmake_template_ENABLE_HARDENING
    OFF)

  moderncpp_cmake_template_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR moderncpp_cmake_template_PACKAGING_MAINTAINER_MODE)
    option(moderncpp_cmake_template_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(moderncpp_cmake_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(moderncpp_cmake_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(moderncpp_cmake_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(moderncpp_cmake_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(moderncpp_cmake_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(moderncpp_cmake_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(moderncpp_cmake_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(moderncpp_cmake_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(moderncpp_cmake_template_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(moderncpp_cmake_template_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(moderncpp_cmake_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(moderncpp_cmake_template_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(moderncpp_cmake_template_ENABLE_IPO "Enable IPO/LTO" ON)
    option(moderncpp_cmake_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(moderncpp_cmake_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(moderncpp_cmake_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(moderncpp_cmake_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(moderncpp_cmake_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(moderncpp_cmake_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(moderncpp_cmake_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(moderncpp_cmake_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(moderncpp_cmake_template_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(moderncpp_cmake_template_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(moderncpp_cmake_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(moderncpp_cmake_template_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      moderncpp_cmake_template_ENABLE_IPO
      moderncpp_cmake_template_WARNINGS_AS_ERRORS
      moderncpp_cmake_template_ENABLE_USER_LINKER
      moderncpp_cmake_template_ENABLE_SANITIZER_ADDRESS
      moderncpp_cmake_template_ENABLE_SANITIZER_LEAK
      moderncpp_cmake_template_ENABLE_SANITIZER_UNDEFINED
      moderncpp_cmake_template_ENABLE_SANITIZER_THREAD
      moderncpp_cmake_template_ENABLE_SANITIZER_MEMORY
      moderncpp_cmake_template_ENABLE_UNITY_BUILD
      moderncpp_cmake_template_ENABLE_CLANG_TIDY
      moderncpp_cmake_template_ENABLE_CPPCHECK
      moderncpp_cmake_template_ENABLE_COVERAGE
      moderncpp_cmake_template_ENABLE_PCH
      moderncpp_cmake_template_ENABLE_CACHE)
  endif()

  moderncpp_cmake_template_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (moderncpp_cmake_template_ENABLE_SANITIZER_ADDRESS OR moderncpp_cmake_template_ENABLE_SANITIZER_THREAD OR moderncpp_cmake_template_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(moderncpp_cmake_template_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(moderncpp_cmake_template_global_options)
  if(moderncpp_cmake_template_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    moderncpp_cmake_template_enable_ipo()
  endif()

  moderncpp_cmake_template_supports_sanitizers()

  if(moderncpp_cmake_template_ENABLE_HARDENING AND moderncpp_cmake_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR moderncpp_cmake_template_ENABLE_SANITIZER_UNDEFINED
       OR moderncpp_cmake_template_ENABLE_SANITIZER_ADDRESS
       OR moderncpp_cmake_template_ENABLE_SANITIZER_THREAD
       OR moderncpp_cmake_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${moderncpp_cmake_template_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${moderncpp_cmake_template_ENABLE_SANITIZER_UNDEFINED}")
    moderncpp_cmake_template_enable_hardening(moderncpp_cmake_template_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(moderncpp_cmake_template_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(moderncpp_cmake_template_warnings INTERFACE)
  add_library(moderncpp_cmake_template_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  moderncpp_cmake_template_set_project_warnings(
    moderncpp_cmake_template_warnings
    ${moderncpp_cmake_template_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(moderncpp_cmake_template_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    moderncpp_cmake_template_configure_linker(moderncpp_cmake_template_options)
  endif()

  include(cmake/Sanitizers.cmake)
  moderncpp_cmake_template_enable_sanitizers(
    moderncpp_cmake_template_options
    ${moderncpp_cmake_template_ENABLE_SANITIZER_ADDRESS}
    ${moderncpp_cmake_template_ENABLE_SANITIZER_LEAK}
    ${moderncpp_cmake_template_ENABLE_SANITIZER_UNDEFINED}
    ${moderncpp_cmake_template_ENABLE_SANITIZER_THREAD}
    ${moderncpp_cmake_template_ENABLE_SANITIZER_MEMORY})

  set_target_properties(moderncpp_cmake_template_options PROPERTIES UNITY_BUILD ${moderncpp_cmake_template_ENABLE_UNITY_BUILD})

  if(moderncpp_cmake_template_ENABLE_PCH)
    target_precompile_headers(
      moderncpp_cmake_template_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(moderncpp_cmake_template_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    moderncpp_cmake_template_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(moderncpp_cmake_template_ENABLE_CLANG_TIDY)
    moderncpp_cmake_template_enable_clang_tidy(moderncpp_cmake_template_options ${moderncpp_cmake_template_WARNINGS_AS_ERRORS})
  endif()

  if(moderncpp_cmake_template_ENABLE_CPPCHECK)
    moderncpp_cmake_template_enable_cppcheck(${moderncpp_cmake_template_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(moderncpp_cmake_template_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    moderncpp_cmake_template_enable_coverage(moderncpp_cmake_template_options)
  endif()

  if(moderncpp_cmake_template_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(moderncpp_cmake_template_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(moderncpp_cmake_template_ENABLE_HARDENING AND NOT moderncpp_cmake_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR moderncpp_cmake_template_ENABLE_SANITIZER_UNDEFINED
       OR moderncpp_cmake_template_ENABLE_SANITIZER_ADDRESS
       OR moderncpp_cmake_template_ENABLE_SANITIZER_THREAD
       OR moderncpp_cmake_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    moderncpp_cmake_template_enable_hardening(moderncpp_cmake_template_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
