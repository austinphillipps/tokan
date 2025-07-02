cmake_minimum_required(VERSION 3.14...3.25)
project(runner LANGUAGES CXX)

# Ensure BINARY_NAME is inherited or defined.
if(NOT DEFINED BINARY_NAME)
    set(BINARY_NAME "tokan" CACHE STRING "Name of the executable")
endif()

# Define the application target. To change its name, modify BINARY_NAME in the
# top-level CMakeLists.txt so `flutter run` continues to work.
add_executable(${BINARY_NAME} WIN32
        "flutter_window.cpp"
        "main.cpp"
        "utils.cpp"
        "win32_window.cpp"
        "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
        "Runner.rc"  # Contains embedded manifest via resource script
)

# Apply standard CMake settings.
apply_standard_settings(${BINARY_NAME})

# Embed Flutter version as preprocessor definitions.
target_compile_definitions(${BINARY_NAME} PRIVATE
        "FLUTTER_VERSION=\"${FLUTTER_VERSION}\""
        "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}"
        "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}"
        "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}"
        "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}"
)

# Disable Windows-specific macros colliding with STL.
target_compile_definitions(${BINARY_NAME} PRIVATE NOMINMAX)

# Link against Flutter and Windows libraries.
target_link_libraries(${BINARY_NAME} PRIVATE
        flutter
        flutter_wrapper_app
        dwmapi.lib
)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Ensure Flutter build steps run before linking.
add_dependencies(${BINARY_NAME} flutter_assemble)
