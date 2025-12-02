![Octoliner CMake](logo.svg)


# Octoliner CMake

A small collection of reusable CMake helper functions and utilities used across Octoliner projects. The goal is to keep common patterns simple and consistent (fetching deps, adding tests/libraries, documentation, and common compiler settings).

---

## Highlights

### Functions (quick list)

* `Add_Simple_Googletest_Target(TARGET_NAME [libs...])`
* `Simple_Fetch_Repository(NAME REPO GIT_TAG [DISABLE_OPTIONS opt1;opt2;...])`
* `Add_Simple_Library(TARGET_NAME [TYPE])`
* `Add_Project_Documentation(DOC_DIR_SRC)`

### Utilities

* `compiler_warning.cmake` — common compiler flags / warnings-as-errors behavior
* `generate_locals.cmake` — generate `include/locals.h` (embeds git commit)

---

## How to add this to your project

Place the `.cmake` files inside a `cmake/` folder in the project root. In your top-level `CMakeLists.txt` either add the folder to `CMAKE_MODULE_PATH` or directly include the helper files:

```cmake
# either add module path once:
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
# then you can include helpers by name (if they are modules) or full path:
include(${CMAKE_SOURCE_DIR}/cmake/add_simple_library.cmake)

# or directly include the directory's cmake files:
include(${CMAKE_SOURCE_DIR}/cmake/compiler_warning.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/generate_locals.cmake)
```

Adjust to your project layout; these helpers expect `PROJECT_NAME` and `PROJECT_SOURCE_DIR` to be set by the calling project.

---

# Functions (concise reference)

### `Add_Simple_Googletest_Target(TARGET_NAME [libs...])`

**Purpose:** Create a test executable from `*.cpp` inside the calling directory and wire GoogleTest (auto-fetch if not available).

**Behavior / Notes:**

* Tries `find_package(GoogleTest QUIET)` and uses `FetchContent` to download googletest (v1.17.0) if not found.
* Collects `*.cpp` files in the current source directory and `add_executable(${TARGET_NAME} ...)`.
* Adds include directories (`${PROJECT_SOURCE_DIR}`) and links `GTest::gtest_main` + any libs passed as extra args.
* Registers tests with `gtest_discover_tests(${TARGET_NAME})`.

**Example:**

```cmake
# inside tests/unit/
Add_Simple_Googletest_Target(configuration_test MyProj::configuration RapidJSON::rapidjson)
```

---

### `Simple_Fetch_Repository(NAME REPO GIT_TAG [DISABLE_OPTIONS opt1;opt2;...])`

**Purpose:** Lightweight wrapper around `FetchContent` to fetch a third-party repo with common option handling.

**Signature:** `Simple_Fetch_Repository(NAME REPO GIT_TAG)`

**Behavior / Notes:**

* Attempts `find_package(NAME QUIET)` first; if the package/target exists, it returns early.
* Accepts `REPO` as either a full URL (`https://...`) or short `owner/repo` (converted to `https://github.com/owner/repo.git`).
* Temporarily forces common build options off (default `BUILD_TESTS;BUILD_DOC`) to avoid building extras in fetched projects; accepts a `DISABLE_OPTIONS` list via extra ARGN to customize.
* Uses `FetchContent_Declare` and `FetchContent_MakeAvailable` to populate the dependency.
* Restores any previously defined option variables after the fetch.

**Example:**

```cmake
# short form repo + tag
Simple_Fetch_Repository(OConfigurator leocity207/OConfigurator V0.0.3)

# full URL and disable custom options
Simple_Fetch_Repository(MyLib https://github.com/org/MyLib.git v1.2.3 DISABLE_OPTIONS BUILD_TESTS;BUILD_DOC;SOME_FLAG)
```

---

### `Add_Simple_Library(TARGET_NAME [TYPE])`

**Purpose:** Create a simple library target from `*.cpp` files in the current directory, with standard include paths and an alias in the form `${PROJECT_NAME}::${TARGET_NAME}`.

**Behavior / Notes:**

* `TYPE` defaults to `STATIC` if omitted (accepted values: `STATIC|SHARED|MODULE|OBJECT|INTERFACE`).
* Gathers sources with `file(GLOB TEST_SRC CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp")`. If no sources found, the function emits a fatal error.
* `add_library(${TARGET_NAME} ${TYPE} ${TEST_SRC})` then sets include directories:

  * PUBLIC: `$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>` and `$<INSTALL_INTERFACE:include>`
  * PRIVATE: `${PROJECT_SOURCE_DIR}`
* If additional libraries are passed as trailing arguments they are linked PUBLIC to the target.
* Creates an alias target named `${PROJECT_NAME}::${TARGET_NAME}`.

**Example:**

```cmake
# create a static library from ./src/*.cpp and link to project::io
Add_Simple_Library(dcel STATIC ${PROJECT_NAME}::io)
```

---

### `Add_Project_Documentation(DOC_DIR_SRC)`

**Purpose:** Small helper that fetches `cmake-sphinx`, configures Doxygen (XML) + Sphinx (breathe) and creates an HTML documentation target.

**Behavior / Notes:**

* Uses `FetchContent` to get `cmake-sphinx` and appends its `cmake/Modules` to `CMAKE_MODULE_PATH` if present.
* Requires `Doxygen` and `Sphinx` to be available (`find_package`), otherwise warns that docs cannot be built.
* Configures Doxygen to generate XML (`DOXYGEN_GENERATE_XML YES`) and calls `doxygen_add_docs(...)` on `${PROJECT_SOURCE_DIR}/include`.
* Calls `sphinx_add_docs` with `BREATHE_PROJECTS doxygen` and builder `html` using the provided `DOC_DIR_SRC` for both source and config.
* Result: A target named `${PROJECT_NAME}_Documentation` is created (when requirements are met).

**Example:**

```cmake
# docs/ contains Sphinx conf.py and sources
Add_Project_Documentation(documentation/src)
```

---

## Small utilities / other scripts

### `compiler_warning.cmake`

* Detects MSVC and sets `/W4 /utf-8` plus some suppression defines, otherwise sets `-Wall -Wextra -pedantic -Og`.
* Intended to be included early in your project to standardize warning levels.

### `generate_locals.cmake`

* Runs `git rev-parse HEAD` and stores result in `GIT_COMMIT_HASH`.
* Calls `configure_file(${PROJECT_SOURCE_DIR}/include/locals.h.in ${PROJECT_SOURCE_DIR}/include/locals.h)` to embed local configuration (version/commit) into the project includes.

---

## Quick checklist before using helpers

* Ensure `PROJECT_NAME` and `PROJECT_SOURCE_DIR` are defined in the calling `CMakeLists.txt`.
* If you intend to build docs, install Doxygen and Sphinx + breathe extension.
* These helpers use `FetchContent` — CMake >= 3.14 recommended.

---

## Contributing & Style

* Keep helpers small and single-responsibility.
* Prefer `FetchContent_MakeAvailable` over custom git clones.
* Document new helpers with a short example and behavior notes (like above).

---