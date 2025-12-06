# Interfaz con Allegro
Para compilar con GCC, se necesitaran de las librerias, en linux:
apt install build-essentials liballegro5-dev
dnf yum, etc igualmente, con el paquete que se utilice

y para compilar con gcc, esperar que pkg carree

verificar addons: 

pkg-config --libs --cflags allegro-5 allegro_font-5 allegro_ttf-5 allegro_dialog-5 allegro_image-5 allegro_primitives-5 allegro_audio-5 allegro_acodec-5 

gcc main.c -o qr $(pkg-config allegro-5 allegro_font-5 allegro_ttf-5 allegro_dialog-5 allegro_image-5 allegro_primitives-5 allegro_audio-5 allegro_acodec-5 --libs --cflags)

https://github.com/liballeg/allegro_wiki/wiki/Quickstart