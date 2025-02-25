cmake_minimum_required(VERSION 3.0)
project(BlobOS VERSION 0.1.2 LANGUAGES C CXX ASM_NASM)

set(CMAKE_C_FLAGS "-O0 -ffreestanding -Wall -Wextra -g")
set(CMAKE_CXX_FLAGS "-O0 -ffreestanding -Wall -Wextra -std=c++17 -mno-sse -g")
# This is so that we don't have the full path on panic messages.
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D__FILENAME__='\"$(subst ${CMAKE_SOURCE_DIR}/,,$(abspath $<))\"'")
set(CMAKE_ASM_NASM_FLAGS "-f elf64")
set(CMAKE_POSITION_INDEPENDENT_CODE FALSE)

# Set linker flags
set(LINKER_SCRIPT "${CMAKE_SOURCE_DIR}/Arch/x86_64/linker.ld")
set(CMAKE_EXE_LINKER_FLAGS "-nostdlib -T ${LINKER_SCRIPT} -no-pie -z noexecstack")

# Add include directories
set(GLOBAL_INC_DIR ".")
include_directories(${GLOBAL_INC_DIR})

file(GLOB_RECURSE ARCH_SOURCES "Arch/x86_64/*.cpp" "Arch/x86_64/*.asm")
file(GLOB_RECURSE KERNEL_SOURCES "Kernel/*.cpp")
file(GLOB_RECURSE LIBK_SOURCES "Kernel/LibK/*.cpp" "Kernel/LibK/*.c")

add_library(LIBK STATIC ${LIBK_SOURCES})

add_executable(BlobOS.bin ${ARCH_SOURCES} ${KERNEL_SOURCES})
set_property(TARGET BlobOS.bin PROPERTY POSITION_INDEPENDENT_CODE FALSE)
target_link_libraries(BlobOS.bin LIBK)

# Ensure that build/iso_root and build/iso_root/boot directories exist
file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/build/iso_root)
file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/build/iso_root/boot)

set(ISO_IMAGE ${PROJECT_NAME}.iso)
add_custom_command(OUTPUT ${ISO_IMAGE} DEPENDS BlobOS.bin
    COMMAND ${CMAKE_COMMAND} -E echo "======== Post Build ========"
    COMMAND cp ${CMAKE_SOURCE_DIR}/build/BlobOS.bin
		${CMAKE_SOURCE_DIR}/Arch/limine.cfg ${CMAKE_SOURCE_DIR}/limine/limine.sys
		${CMAKE_SOURCE_DIR}/build/iso_root/boot/
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/limine/limine-cd.bin
		${CMAKE_SOURCE_DIR}/limine/limine-cd-efi.bin
		${CMAKE_SOURCE_DIR}/build/iso_root/boot/
    # Build BlobOS.iso
    COMMAND xorriso -as mkisofs -b boot/limine-cd.bin -no-emul-boot
		-boot-load-size 4 -boot-info-table --efi-boot boot/limine-cd-efi.bin -efi-boot-part --efi-boot-image --protective-msdos-label -o ${CMAKE_SOURCE_DIR}/build/${ISO_IMAGE} ${CMAKE_SOURCE_DIR}/build/iso_root/

    COMMAND ${CMAKE_SOURCE_DIR}/limine/limine-deploy ${CMAKE_SOURCE_DIR}/build/${ISO_IMAGE}
)

add_custom_target(iso ALL DEPENDS ${ISO_IMAGE})
