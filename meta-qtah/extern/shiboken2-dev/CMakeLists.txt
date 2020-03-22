cmake_minimum_required(VERSION 3.1)
cmake_policy(VERSION 3.1)

project(shiboken2)
include(CheckIncludeFileCXX)

#semirandomly cannibalized
find_package(Qt5 5.12 REQUIRED COMPONENTS Core)
find_package(Qt5Xml 5.12)
find_package(Qt5XmlPatterns 5.12)
find_package(LibXml2 2.6.32)
find_package(LibXslt 1.1.19)
find_package(Qt5Test 5.12 REQUIRED)

if(NOT Qt5XmlPatterns_FOUND AND NOT HAS_LIBXSLT)
    set(DISABLE_DOCSTRINGS TRUE)
    message(WARNING
            "Documentation will not be built due to missing dependency (no Qt5XmlPatterns found).")
endif()



set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D QT_NO_CAST_FROM_ASCII -D QT_NO_CAST_TO_ASCII")

set(CLANG_DIR "")  
set(CLANG_DIR_SOURCE "")

set(clang_not_found_message "Unable to detect CLANG location by checking LLVM_INSTALL_DIR, \
                             CLANG_INSTALL_DIR or running llvm-config.")

if (DEFINED ENV{LLVM_INSTALL_DIR})
    set(CLANG_DIR $ENV{LLVM_INSTALL_DIR})
    string(REPLACE "_ARCH_" "${PYTHON_ARCH}" CLANG_DIR "${CLANG_DIR}")
    set(CLANG_DIR_SOURCE "LLVM_INSTALL_DIR")
elseif (DEFINED ENV{CLANG_INSTALL_DIR})
    set(CLANG_DIR $ENV{CLANG_INSTALL_DIR})
    string(REPLACE "_ARCH_" "${PYTHON_ARCH}" CLANG_DIR "${CLANG_DIR}")
    set(CLANG_DIR_SOURCE "CLANG_INSTALL_DIR")  
else ()
    if (NOT LLVM_CONFIG)
        get_llvm_config()
    endif()
    set(CLANG_DIR_SOURCE "${LLVM_CONFIG}")
    if ("${CLANG_DIR_SOURCE}" STREQUAL "")
        message(FATAL_ERROR "${clang_not_found_message}")
    endif()

    EXEC_PROGRAM("${LLVM_CONFIG}" ARGS "--prefix" OUTPUT_VARIABLE CLANG_DIR)
    if (NOT "${CLANG_DIR}" STREQUAL "")
        EXEC_PROGRAM("${LLVM_CONFIG}" ARGS "--version" OUTPUT_VARIABLE CLANG_VERSION)
        if (CLANG_VERSION VERSION_LESS 3.9)
            message(FATAL_ERROR "libclang version 3.9 or higher is required (${LLVM_CONFIG} detected ${CLANG_VERSION} at ${CLANG_DIR}).")
        endif()
    endif()
endif()

if ("${CLANG_DIR}" STREQUAL "")
    message(FATAL_ERROR "${clang_not_found_message}")
elseif (NOT IS_DIRECTORY ${CLANG_DIR})
    message(FATAL_ERROR "${CLANG_DIR} detected by ${CLANG_DIR_SOURCE} does not exist.")
endif()

# The non-development Debian / Ubuntu packages (e.g. libclang1-6.0) do not ship a
# libclang.so symlink, but only libclang-6.0.so.1 and libclang.so.1 (adjusted for version number).
# Thus searching for libclang would not succeed.
# The "libclang.so" symlink is shipped as part of the development package (libclang-6.0-dev) which
# we need anyway because of the headers. Thus we will search for libclang.so.1 also, and complain
# about the headers not being found in a check further down. This is more friendly to the user,
# so they don't scratch their head thinking that they have already installed the necessary package.
set(CLANG_LIB_NAMES clang libclang.so libclang.so.1)
if(MSVC)
    set(CLANG_LIB_NAMES libclang)
endif()

find_library(CLANG_LIBRARY NAMES ${CLANG_LIB_NAMES} HINTS ${CLANG_DIR}/lib)
if (NOT EXISTS ${CLANG_LIBRARY})
    string(REPLACE ";" ", " CLANG_LIB_NAMES_STRING "${CLANG_LIB_NAMES}")
    message(FATAL_ERROR "Unable to find the Clang library in ${CLANG_DIR}.\
        Names tried: ${CLANG_LIB_NAMES_STRING}.")
endif()

message(STATUS "CLANG: ${CLANG_DIR}, ${CLANG_LIBRARY} detected by ${CLANG_DIR_SOURCE}")

set(CLANG_EXTRA_INCLUDES ${CLANG_DIR}/include)
set(CLANG_EXTRA_LIBRARIES ${CLANG_LIBRARY})


# Check if one of the required clang headers is found. Error out early at CMake time instead of
# compile time if not found.
# It can happen that a user uses a distro-provided libclang.so, but no development header package
# was installed (e.g. libclang-6.0-dev on Ubuntu).
set(CMAKE_REQUIRED_INCLUDES ${CLANG_EXTRA_INCLUDES})
set(CLANG_HEADER_FILE_TO_CHECK "clang-c/Index.h")
check_include_file_cxx(${CLANG_HEADER_FILE_TO_CHECK} CLANG_INCLUDE_FOUND)
unset(CMAKE_REQUIRED_INCLUDES)
if (NOT CLANG_INCLUDE_FOUND)
    # Need to unset so that when installing the package, CMake doesn't complain that the header
    # still isn't found.
    unset(CLANG_INCLUDE_FOUND CACHE)
    message(FATAL_ERROR "Unable to find required Clang header file ${CLANG_HEADER_FILE_TO_CHECK} \
        in ${CLANG_DIR}/include. Perhaps you forgot to install the clang development header \
        package? (e.g. libclang-6.0-dev)")
endif()


add_subdirectory(ApiExtractor)
add_subdirectory(dumpcodemodel)

