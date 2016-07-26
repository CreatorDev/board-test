
# Add executable targets
########################
ADD_EXECUTABLE(test_switch test_switch.c)

configure_file (
"version.in"
"version"
)

# Add install targets
######################
FILE(GLOB SCRIPTS test*.sh)
INSTALL(FILES ${SCRIPTS} DESTINATION /usr/bin/board_test
		PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
					GROUP_EXECUTE GROUP_READ
					WORLD_EXECUTE WORLD_READ)
INSTALL(FILES board_test_common.sh DESTINATION /usr/lib
		PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
					GROUP_EXECUTE GROUP_READ
					WORLD_EXECUTE WORLD_READ)
INSTALL(FILES version DESTINATION /usr/bin/board_test)
INSTALL(TARGETS test_switch RUNTIME DESTINATION /usr/bin/board_test)

# Optional click tests
#OPTION(BUILD_CLICK_TESTS "Build also click tests" OFF)
#IF(BUILD_CLICK_TESTS)
	ADD_SUBDIRECTORY(click)
#ENDIF(BUILD_CLICK_TESTS)
