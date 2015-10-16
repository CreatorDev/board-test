
# Add executable targets
########################
ADD_EXECUTABLE(test_switch test_switch.c)
ADD_EXECUTABLE(test_serial_loopback test_serial_loopback.c)


configure_file (
"version.in"
"version"
)

# Add install targets
######################
FILE(GLOB SCRIPTS *.sh)
INSTALL(FILES ${SCRIPTS} DESTINATION /usr/bin/board_test
	PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
		    GROUP_EXECUTE GROUP_READ
		    WORLD_EXECUTE WORLD_READ)
INSTALL(FILES version DESTINATION /usr/bin/board_test)
INSTALL(TARGETS test_switch test_serial_loopback RUNTIME DESTINATION /usr/bin/board_test)
