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

Win32_Offscreen_Buffer:: struct {
    info: win.BITMAPINFO,
    memory: rawptr,
    width, height: i32,
    pitch: i32,
    bytes_per_pixel: i32
}

global_back_buffer: Win32_Offscreen_Buffer

render_weird_gradient :: proc(buffer: Win32_Offscreen_Buffer, blue_offset, green_offset: i32) {
    // TODO(Nader): Let's see what the optimizer does
    width, height: i32 = buffer.width, buffer.height 
    pitch: int = int(width*buffer.bytes_per_pixel)
    row: [^]u8 = cast([^]u8)buffer.memory
    for y: i32 = 0; y < buffer.height; y += 1 
    {
        pixel := (^u32)(row)
        for x: i32 = 0; x < buffer.width; x += 1 
        {
            blue := u8(x + blue_offset)
            green := u8(y + green_offset)

            pixel^ = (u32(green) << 8) | u32(blue)

            pixel = mem.ptr_offset(pixel, 1)
        }

        row = mem.ptr_offset(row, buffer.pitch)
    }
}

/* 
    [Definition] DIB: Device Independent Bitmap --> the name that Window uses to talk about things
    that you can write into that you can then display using GDI (Graphics Device Interface)
*/
win32_resize_dib_section :: proc(buffer: ^Win32_Offscreen_Buffer, width, height: i32) {
    // TODO: Bulletproof this
    // Maybe don't free first, free after, then free first if that fails. 

    if buffer.memory != nil 
    {
        win.VirtualFree(buffer.memory, 0, win.MEM_RELEASE)
    }

    buffer.width = width
    buffer.height = height 
    buffer.bytes_per_pixel = 4

    buffer.info.bmiHeader.biSize = size_of(buffer.info.bmiHeader)
    buffer.info.bmiHeader.biWidth = buffer.width
    buffer.info.bmiHeader.biHeight = -buffer.height // "-" value means from top to bottom
    buffer.info.bmiHeader.biPlanes = 1
    buffer.info.bmiHeader.biBitCount = 32 // getting 32 because of DWORD alignment instead of 24 (8 bits for Red, 8 bits for Green, 8 bits for Blue)
    buffer.info.bmiHeader.biCompression = win.BI_RGB

    bitmap_memory_size: uint = uint((buffer.width*buffer.height)*buffer.bytes_per_pixel)
    buffer.memory = win.VirtualAlloc(nil, uint(bitmap_memory_size), win.MEM_COMMIT, win.PAGE_READWRITE)

    buffer.pitch = width*buffer.bytes_per_pixel
     
    // TODO(Nader): Probably want to clear this to black
}

win32_display_buffer_in_window :: proc(
    device_context: win.HDC, client_rect: win.RECT, 
    buffer: ^Win32_Offscreen_Buffer,
    x, y, width, height: i32
) {
    window_width: i32 = client_rect.right - client_rect.left
    window_height: i32 = client_rect.bottom - client_rect.top

    // StretchDIBits: Takes our DIB section and it "blits" it, and allows us to scale it to the size of the window
    // [Definition] BLIT (aka BitBLT) --> bit-block transfer, copying a rectangular block of pixel data from one part
    // of memory to another.
    win.StretchDIBits(device_context, 
        0, 0, buffer.width, buffer.height,
        0, 0, window_width, window_height,
        buffer.memory, &buffer.info, 
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
            win32_resize_dib_section(&global_back_buffer, width, height)
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

            win32_display_buffer_in_window(device_context, client_rect, &global_back_buffer, 
                x, y, width, height)
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
    
    window_class.style = win.CS_HREDRAW|win.CS_VREDRAW
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

    x_offset: i32 = 0
    y_offset: i32 = 0

    running = true
    for running {
        message: win.MSG
        for win.PeekMessageW(&message, nil, 0, 0, win.PM_REMOVE) {
            if message.message == win.WM_QUIT {
                running = false
            }
            win.TranslateMessage(&message)
            win.DispatchMessageW(&message)
        }
        render_weird_gradient(global_back_buffer, x_offset, y_offset)
        device_context: win.HDC = win.GetDC(window)
        client_rect: win.RECT

        win.GetClientRect(window,  &client_rect)
        window_width: i32 = client_rect.right - client_rect.left
        window_height: i32 = client_rect.right - client_rect.left
        win32_display_buffer_in_window(device_context, client_rect, 
            &global_back_buffer, 0, 0, window_width, window_height)
        win.ReleaseDC(window, device_context)

        x_offset = x_offset + 1
        y_offset += 1
    }

    fmt.println("Game Exiting")
}

