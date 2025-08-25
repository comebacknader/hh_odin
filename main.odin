/*

NOTE: Casey Murator's Handmade Hero educational clone written in Odin by Nader Carun for educational purposes only. 

*/

package main

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"

operation: win.DWORD = win.WHITENESS

main_window_callback :: proc "stdcall" (window: win.HWND, message: win.UINT, w_param: win.WPARAM , l_param: win.LPARAM) -> win.LRESULT {
    result: win.LRESULT
    context = runtime.default_context()
    switch message {
        case win.WM_SIZE:
            fmt.println("WM_SIZE")
            break
        case win.WM_DESTROY:
            fmt.println("WM_DESTROY")
            break
        case win.WM_CLOSE:
            fmt.println("WM_CLOSE")
            break
        case win.WM_ACTIVATEAPP:
            fmt.println("WM_ACTIVATEAPP")
            break
        case win.WM_PAINT:
            fmt.println("WM_PAINT")
            paint: win.PAINTSTRUCT
            device_context: win.HDC = win.BeginPaint(window, &paint)
            x: i32 = paint.rcPaint.left
            y: i32 = paint.rcPaint.top
            height: i32 = paint.rcPaint.bottom - paint.rcPaint.top
            width: i32 = paint.rcPaint.right - paint.rcPaint.left
            win.PatBlt(device_context, x, y, width, height, operation)
            if operation == win.WHITENESS {
                operation = win.BLACKNESS
            } else {
                operation = win.WHITENESS
            }
            win.EndPaint(window, &paint)
            break
        case:
            result = win.DefWindowProcW(window, message, w_param, l_param)
            break
    }
    return result
}

main :: proc() {
    fmt.println("Game starting")
    instance := win.HINSTANCE(win.GetModuleHandleW(nil))

    window_class: win.WNDCLASSW
    
    // TODO: Check if HREDRAW/VREDRAW/OWNDC still matter
    window_class.style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW
    window_class.lpfnWndProc = main_window_callback
    window_class.hInstance = instance 
    window_class.lpszClassName = win.L("HandmadeHeroWindowClass")

    if win.RegisterClassW(&window_class) == 0 {
        fmt.println("Failed to register class")
        return
    }

    window_handle: win.HWND  = win.CreateWindowExW(0,window_class.lpszClassName, win.L("Handmade Hero"), 
        win.WS_OVERLAPPEDWINDOW|win.WS_VISIBLE, 
        win.CW_USEDEFAULT, win.CW_USEDEFAULT, 
        win.CW_USEDEFAULT, win.CW_USEDEFAULT, 
        nil, nil, instance, nil)

    if window_handle == nil {
        fmt.println("Failed to create window")
        return
    }

    message: win.MSG
    for {
        message_result: win.INT32 = win.GetMessageW(&message, nil, 0, 0) 
        if message_result > 0 {
            win.TranslateMessage(&message) 
            win.DispatchMessageW(&message)
        } else {
            break
        }

    }



    fmt.println("Game over")
}

