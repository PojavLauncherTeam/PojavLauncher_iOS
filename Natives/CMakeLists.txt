cmake_minimum_required(VERSION 3.6)
project(PojavLauncher)

# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

add_executable(PojavLauncher main.m AppDelegate.m JavaLauncher.c)
add_library(pojavexec STATIC egl_bridge.c input_bridge_v3.c utils.c)
