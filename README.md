# Sand Art Demo

A simple sand physics demo written in Zig using Raylib.

![A demo representation](imgs/demo2.gif)

## Mouse 

Press and hold left mouse button to create sand

## Build Instructions

Zig can call raylib natively, since zig can compile both c
and zig code it can be built using 

`zig build run`

A release build can be created with the following command.

`zig build -Doptimize=ReleaseFast`

