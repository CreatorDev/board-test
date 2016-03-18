# Add executable targets
########################
ADD_EXECUTABLE(test_click_read_thermo3 test_click_read_thermo3.c)
ADD_EXECUTABLE(test_click_wait_gpio test_click_wait_gpio.c)
ADD_EXECUTABLE(test_click_access_proximity test_click_access_proximity.c)
ADD_LIBRARY(spi_common OBJECT spi_common.c)
ADD_EXECUTABLE(test_click_read_accel test_click_read_accel.c
                                    $<TARGET_OBJECTS:spi_common>)
ADD_EXECUTABLE(test_click_write_bargraph test_click_write_bargraph.c
                                    $<TARGET_OBJECTS:spi_common>)

# Add install targets
######################
FILE(GLOB SCRIPTS *.sh)
INSTALL(FILES ${SCRIPTS} DESTINATION /usr/bin/board_test
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
        GROUP_EXECUTE GROUP_READ
        WORLD_EXECUTE WORLD_READ)
INSTALL(TARGETS test_click_write_bargraph test_click_read_thermo3
        test_click_wait_gpio test_click_access_proximity test_click_read_accel
        RUNTIME DESTINATION /usr/bin/board_test)
