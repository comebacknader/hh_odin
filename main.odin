/*

NOTE: Casey Murator's Handmade Hero educational clone written in Odin by Nader Carun for educational purposes only. 

*/

package main

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"

// TODO: This is a global for now.
running: bool
operation: win.DWORD = win.WHITENESS
bitmap_info: win.BITMAPINFO
bitmap_memory: rawptr 
bitmap_handle: win.HBITMAP

win32_resize_dib_section :: proc(width, height: i32) {

    // TODO: Bulletproof this
    // Maybe don't free first, free after, then free first if that fails. 

    if bitmap_memory != nil {
        win.VirtualFree(bitmap_memory, 0, win.MEM_RELEASE)
    }

    bitmap_info.bmiHeader.biSize = size_of(bitmap_info.bmiHeader)
    bitmap_info.bmiHeader.biWidth = width
    bitmap_info.bmiHeader.biHeight = height
    bitmap_info.bmiHeader.biPlanes = 1
    bitmap_info.bmiHeader.biBitCount = 32
    bitmap_info.bmiHeader.biCompression = win.BI_RGB

    bytes_per_pixel: uint = 4
    bitmap_memory_size: uint = uint(width*height)*bytes_per_pixel
    bitmap_memory = win.VirtualAlloc(nil, bitmap_memory_size, win.MEM_COMMIT, win.PAGE_READWRITE)
    
}

win32_update_window :: proc(device_context: win.HDC, x, y, width, height: i32) {
    win.StretchDIBits(device_context, 
        x, y, width, height, 
        x, y, width, height, 
        bitmap_memory, &bitmap_info, 
        win.DIB_RGB_COLORS, win.SRCCOPY)
}

main_window_callback :: proc "stdcall" (window: win.HWND, message: win.UINT, w_param: win.WPARAM , l_param: win.LPARAM) -> win.LRESULT {
    result: win.LRESULT
    context = runtime.default_context()
    switch message {
        case win.WM_SIZE:
            client_rect: win.RECT
            win.GetClientRect(window, &client_rect)
            width: i32 = client_rect.right - client_rect.left
            height: i32 = client_rect.bottom - client_rect.top
            win32_resize_dib_section(width, height)
            break
        case win.WM_DESTROY:
            // TODO: Handle this as an error - recreate window?
            running = false
            break
        case win.WM_CLOSE:
            // TODO: Handle this with a message to the user?
            running = false
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
            win32_update_window(device_context, x, y, width, height)
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

    running = true

    for running {
        message: win.MSG
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

