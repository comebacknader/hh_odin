/*

NOTE: Casey Murator's Handmade Hero educational clone written in Odin by Nader Carun for educational purposes only. 

Current Lesson: Day 004

*/

package main

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"
import "core:mem"

// TODO: This is a global for now.
running: bool

operation: win.DWORD = win.WHITENESS
bitmap_info: win.BITMAPINFO
bitmap_memory: rawptr 
bitmap_width, bitmap_height: i32 
bytes_per_pixel: i32 = 4

render_weird_gradient :: proc(x_offset, y_offset: i32) {
    width, height: i32 = bitmap_width, bitmap_height
    pitch: int = int(width*bytes_per_pixel)
    row: [^]u8 = cast([^]u8)bitmap_memory
    for y: i32 = 0; y < bitmap_height; y += 1 
    {
        pixel := (^u32)(row)
        for x: i32 = 0; x < bitmap_width; x += 1 
        {
            blue := u8(x + x_offset)
            green := u8(y + y_offset)

            pixel^ = (u32(green) << 8) | u32(blue)

            pixel = mem.ptr_offset(pixel, 1)
        }

        row = mem.ptr_offset(row, pitch)
    }
}

/* 
    [Definition] DIB: Device Independent Bitmap --> the name that Window uses to talk about things
    that you can write into that you can then display using GDI (Graphics Device Interface)
*/
win32_resize_dib_section :: proc(width, height: i32) {
    // TODO: Bulletproof this
    // Maybe don't free first, free after, then free first if that fails. 

    if bitmap_memory != nil 
    {
        win.VirtualFree(bitmap_memory, 0, win.MEM_RELEASE)
    }

    bitmap_width = width
    bitmap_height = height 

    bitmap_info.bmiHeader.biSize = size_of(bitmap_info.bmiHeader)
    bitmap_info.bmiHeader.biWidth = bitmap_width
    bitmap_info.bmiHeader.biHeight = -bitmap_height
    bitmap_info.bmiHeader.biPlanes = 1
    bitmap_info.bmiHeader.biBitCount = 32 // getting 32 because of DWORD alignment instead of 24 (8 bits for Red, 8 bits for Green, 8 bits for Blue)
    bitmap_info.bmiHeader.biCompression = win.BI_RGB

    bitmap_memory_size: uint = uint((bitmap_width*bitmap_height)*bytes_per_pixel)
    bitmap_memory = win.VirtualAlloc(nil, uint(bitmap_memory_size), win.MEM_COMMIT, win.PAGE_READWRITE)
     
    // TODO(Nader): Probably want to clear this to black
}

win32_update_window :: proc(
    device_context: win.HDC, client_rect: ^win.RECT, 
    x, y, width, height: i32
) {
    window_width: i32 = client_rect.right - client_rect.left
    window_height: i32 = client_rect.bottom - client_rect.top

    // StretchDIBits: Takes our DIB section and it "blits" it, and allows us to scale it to the size of the window
    // [Definition] BLIT (aka BitBLT) --> bit-block transfer, copying a rectangular block of pixel data from one part
    // of memory to another.
    win.StretchDIBits(device_context, 
        0, 0, bitmap_width, bitmap_height,
        0, 0, window_width, window_height,
        bitmap_memory, &bitmap_info, 
        win.DIB_RGB_COLORS, win.SRCCOPY)
}

main_window_callback :: proc "stdcall" (
    window: win.HWND, message: win.UINT, 
    w_param: win.WPARAM , l_param: win.LPARAM
) -> win.LRESULT {
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
            
            client_rect: win.RECT
            win.GetClientRect(window, &client_rect)

            win32_update_window(device_context, &client_rect, x, y, width, height)
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

    window: win.HWND = win.CreateWindowExW(0, window_class.lpszClassName, win.L("Handmade Hero"), 
        win.WS_OVERLAPPEDWINDOW|win.WS_VISIBLE, 
        win.CW_USEDEFAULT, win.CW_USEDEFAULT, 
        win.CW_USEDEFAULT, win.CW_USEDEFAULT, 
        nil, nil, instance, nil)

    if window == nil {
        fmt.println("Failed to create window")
        return
    }

    running = true

    x_offset: i32 = 0
    y_offset: i32 = 0
    for running {
        message: win.MSG
        for win.PeekMessageW(&message, nil, 0, 0, win.PM_REMOVE) {
            if message.message == win.WM_QUIT {
                running = false
            }
            win.TranslateMessage(&message)
            win.DispatchMessageW(&message)
        }
        render_weird_gradient(x_offset, y_offset)
        device_context: win.HDC = win.GetDC(window)
        client_rect: win.RECT

        win.GetClientRect(window,  &client_rect)
        window_width: i32 = client_rect.right - client_rect.left
        window_height: i32 = client_rect.right - client_rect.left
        win32_update_window(device_context, &client_rect, 0, 0, window_width, window_height)
        win.ReleaseDC(window, device_context)

        x_offset = x_offset + 1;
    }



    fmt.println("Game Exiting")
}

