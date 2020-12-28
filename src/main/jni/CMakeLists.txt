cmake_minimum_required(VERSION 3.6)
project(pojavexec)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES jre_launcher.c)
add_library(pojavexec STATIC ${SOURCE_FILES})
