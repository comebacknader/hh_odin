/*

NOTE: Casey Murator's Handmade Hero educational clone written in Odin by Nader Carun for educational purposes only. 

*/

package main

import "core:fmt"
import win "core:sys/windows"



main :: proc() {
    fmt.println("beginning of handmade hero in odin")
    instance := win.HINSTANCE(win.GetModuleHandleW(nil))
    
    fmt.println("end of game")
}

