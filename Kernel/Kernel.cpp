#include "KLibc/Include/stdio.hpp"
#include <Kernel.hpp>
#include <TextMode.hpp>
#include <multiboot.h>

namespace Kernel {
TextMode::Terminal terminal;
extern "C" void Panic(char *PanicMessage) {
    TextMode::Terminal panicTerminal;

    panicTerminal.SetColor(TextMode::Color::LIGHT_GREY, TextMode::Color::BLUE);
    panicTerminal.Clear();
    panicTerminal.WriteString(
        R"(
         _______
        |.-----.|
        ||x . x||
        ||_.-._||
        `--)-(--`
       __[=== o]___
      |:::::::::::|\
      `-=========-`()
)");
    panicTerminal.WriteString(PanicMessage);

    asm __volatile__("hlt");
}
}; // namespace Kernel

extern "C" void Kmain(multiboot_info_t mb_header) {
    Kernel::terminal.SetColor(TextMode::Color::LIGHT_GREY,
                              TextMode::Color::BLACK);
    Kernel::terminal.Clear();
    k_printf("Welcome to BlobOS!\n");
}
