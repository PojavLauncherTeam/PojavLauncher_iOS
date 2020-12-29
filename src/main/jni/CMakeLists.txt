cmake_minimum_required(VERSION 3.6)
project(pojavexec)

# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES egl_bridge.c input_bridge_v3.c jre_launcher.c utils.c)
add_library(pojavexec STATIC ${SOURCE_FILES})
