# Project Properties
####################
CMAKE_MINIMUM_REQUIRED (VERSION 2.6.2)

PROJECT(board_test)
# This will be extended to take the version from SCM
# Version config can be simplified from 3.0+
SET(board_test_VERSION_MAJOR 0)
SET(board_test_VERSION_MINOR 1)
SET(board_test_VERSION_PATCH 0)
SET(board_test_VERSION
    ${board_test_VERSION_MAJOR}.${board_test_VERSION_MINOR}.${board_test_VERSION_PATCH})

ADD_SUBDIRECTORY(src)