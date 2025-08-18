/*

NOTE: Casey Murator's Handmade Hero educational clone written in Odin by Nader Carun for educational purposes only. 

*/

package main

import "core:fmt"
import win "core:sys/windows"

main_window_callback :: proc "stdcall" (window: win.HWND, message: win.UINT, wParam: win.WPARAM , lParam: win.LPARAM) -> win.LRESULT {
    result: win.LRESULT
    switch message {
        case win.WM_SIZE:
            break
        case win.WM_DESTROY:
            break
        case win.WM_CLOSE:
            break
        case win.WM_ACTIVATEAPP:
            break
        case:
            break
    }
    return result
}

main :: proc() {
    fmt.println("beginning of handmade hero in odin")
    instance := win.HINSTANCE(win.GetModuleHandleW(nil))

    window_class: win.WNDCLASSW
    
    // TODO: Check if HREDRAW/VREDRAW/OWNDC still matter
    window_class.style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW
    window_class.lpfnWndProc = main_window_callback
    window_class.hInstance = instance 
    window_class.lpszClassName = win.L("HandmadeHeroWindowClass")

    fmt.println("end of game")
}

