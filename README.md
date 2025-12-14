# This is a project 

It generates and reads basic qr's using nasm in 32 bits and a GUI with GTK

There are 40 models in the QR's, for sizes from sizes 21x21 to 177x177
each of these models has 4 levels of correction levels, Low, Medium, Quartile and High

This project uses model 2, level M, to it can only store 26 bytes of data

There are also micro qr's and data modes like kanji, binary, alphabetic, numeric, etc
this is just simple binary

## Installation

This Project is only for linux distros

You need GTK, follow the next install, it may change depending on your packet manager

dnf install gtk4-devel gtk4-devel.i686 libadwaita-devel

dnf install glib2-devel.i686 pango-devel.i686 cairo-devel.i686 gdk-pixbuf2-devel.i686

dnf install libglvnd-gles.i686

## How to run

Just use bash compile.sh, once all the dependencies are installed
remember, is linux only

## The program

The Menu
[menu]

Generating QR's
[generate]

Scanning QR's
[scan]

[menu]: https://github.com/NeithanT/llamen-a-Dios-Qr/menu.png
[generate]: https://github.com/NeithanT/llamen-a-Dios-Qr/generate.png
[scan]: https://github.com/NeithanT/llamen-a-Dios-Qr/scan.png