#include <stdio.h> // Cabecera de la libreria estandar de C para entrada y salida basica
#include <stdlib.h> // Incluye srand
#include <time.h> // Incluye time()
#include <string.h>

#include <allegro5/allegro.h> // Cabecera central de Allegro 5 para iniciar el motor
#include <allegro5/allegro_font.h> // Soporte para fuentes bitmap basicas
#include <allegro5/allegro_ttf.h> // Soporte para fuentes TrueType
#include <allegro5/allegro_native_dialog.h> // Mostrar cuadros de dialogo nativos del sistema
#include <allegro5/allegro_image.h> // Manejo de imagenes en Allegro
#include <allegro5/allegro_primitives.h> // Dibujo de primitivas geometricas
#include <allegro5/allegro_audio.h> // Sistema de audio de Allegro
#include <allegro5/allegro_acodec.h> // Codecs de audio para Allegro

#define MAX_INPUT_LENGTH 256

// ========== ENUMERACIONES ==========

typedef enum {
		MENU_GENERAR = 0, // Entrada de menu que inicia la partida
		MENU_ESCANEAR = 1, // Entrada que muestra la pantalla de high scores
		MENU_SALIR = 2 // Entrada que finaliza la aplicacion
} OpcionMenu;

typedef enum {
		APP_MENU, // La aplicacion esta mostrando el menu principal
		APP_GENERAR, // La aplicacion se encuentra dentro del gameplay
		APP_ESCANEAR // La aplicacion muestra el listado de puntuaciones
} EstadoApp;

// ========== FUNCIONES DE RENDERIZADO ==========

// Dibuja el menu principal con opciones y fondo
void renderizarMenu(int opcion, ALLEGRO_FONT* fuente_grande, ALLEGRO_FONT* fuente_mediana, ALLEGRO_FONT* fuente_pequena, int ancho, int alto, float timer, ALLEGRO_BITMAP* fondo) {
		al_clear_to_color(al_map_rgb(0, 0, 0)); // Limpia la pantalla con un color negro uniforme

		if (fondo) { // Comprueba si se paso un bitmap de fondo valido
				al_draw_scaled_bitmap(fondo, 0, 0, al_get_bitmap_width(fondo), al_get_bitmap_height(fondo), 0, 0, ancho, alto, 0); // Ajusta el fondo a la resolucion actual
		}

		al_draw_text(fuente_grande, al_map_rgb(255, 239, 213), ancho / 2, alto / 2 - 250, ALLEGRO_ALIGN_CENTER, "CODIGOS QR"); // Titulo principal centrado
		al_draw_text(fuente_mediana, al_map_rgb(245, 245, 245), ancho / 2, alto / 2 - 150, ALLEGRO_ALIGN_CENTER, "Generador y Escaneador"); // Subtitulo descriptivo

		const char* texto[3] = { "GENERAR", "ESCANEAR", "SALIR" }; // Lista de opciones del menu
		int y = alto / 2 - 50; // Coordenada vertical base para colocar las opciones

		for (int i = 0; i < 3; i++) { // Recorre cada opcion disponible
				int yPos = y + (i * 60); // Calcula la posicion vertical desplazada segun el indice
				ALLEGRO_COLOR color = (i == opcion) ? al_map_rgb(255, 255, 0) : al_map_rgb(245, 245, 245); // Destaca la opcion activa en amarillo

				al_draw_text(fuente_mediana, color, ancho / 2, yPos, ALLEGRO_ALIGN_CENTER, texto[i]); // Dibuja el texto de la opcion actual

				if (i == opcion) { // Si la opcion esta seleccionada
						al_draw_text(fuente_mediana, color, ancho / 2 - 120, yPos, ALLEGRO_ALIGN_CENTER, ">"); // Dibuja una flecha indicadora
				}
		}

		al_draw_text(fuente_pequena, al_map_rgb(225, 225, 225), ancho / 2, alto - 100, ALLEGRO_ALIGN_CENTER, "Usa W/S o Flechas para navegar"); // Muestra instrucciones de navegacion
		al_draw_text(fuente_pequena, al_map_rgb(225, 225, 225), ancho / 2, alto - 70, ALLEGRO_ALIGN_CENTER, "Presiona ENTER para seleccionar"); // Indica como seleccionar una opcion

		al_flip_display(); // Presenta en pantalla el frame renderizado del menu
}

void renderizarPantallaGenerarQR(ALLEGRO_FONT* fuente_grande, ALLEGRO_FONT* fuente_mediana, ALLEGRO_FONT* fuente_pequena, int ancho, int alto, const char *input, int opcion_activa, ALLEGRO_BITMAP *qr_bmp) {

		al_clear_to_color(al_map_rgb(0, 0, 0)); // Limpia la pantalla con un color negro uniforme

		al_draw_text(fuente_grande, al_map_rgb(255, 239, 213), ancho / 2, alto / 3 - 250, ALLEGRO_ALIGN_CENTER, "GENERADOR QR"); // Titulo principal centrado

		ALLEGRO_COLOR color_input = (0 == opcion_activa) ? al_map_rgb(255, 0, 255) : al_map_rgb(245, 245, 245); // Destaca la opcion activa en amarillo

		int x1 = ancho * 0.28515625;
		int x2 = ancho * 0.63671875;
		int y1 = alto * 0.2569444444;
		int y2 = alto * 0.2916666667;
		
		int x_input = ancho * 0.2890625;
		int y_input = alto * 0.26041667;

		al_draw_filled_rectangle(x1, y1, x2, y2, al_map_rgb(255, 255, 255)); // Relleno blanco
		al_draw_rectangle(x1, y1, x2, y2, color_input, 1); // Borde negro
		al_draw_text(fuente_mediana, al_map_rgb(0, 0, 0), x_input, y_input, ALLEGRO_ALIGN_LEFT, input); // Texto negro

		ALLEGRO_COLOR color_boton = (1 == opcion_activa) ? al_map_rgb(255, 0, 255) : al_map_rgb(245, 245, 245); // Destaca la opcion activa en amarillo

		int x1_boton = ancho * 0.640625;
		int x2_boton = ancho * 0.71484375;

		int x_txt = ancho * 0.677734375;
		int y_txt = alto * 0.2625;

		al_draw_rectangle(x1_boton, y1, x2_boton, y2, color_boton, 1);
		al_draw_text(fuente_mediana, color_boton, x_txt, y_txt, ALLEGRO_ALIGN_CENTER, "GENERAR");

		int y1_qr = alto * 0.2986111111;
		int y2_qr = alto * 0.9236111111;

		al_draw_rectangle(x1, y1_qr, x2, y2_qr, al_map_rgb(255, 255, 255), 1);

		al_draw_text(fuente_pequena, al_map_rgb(225, 225, 225), ancho / 2, alto - 70, ALLEGRO_ALIGN_CENTER, "Usa las flechas (der/izq) para navegar"); // Muestra instrucciones de navegacion
		al_draw_text(fuente_pequena, al_map_rgb(225, 225, 225), ancho / 2, alto - 40, ALLEGRO_ALIGN_CENTER, "Presiona ENTER para seleccionar"); // Indica como seleccionar una opcion
		

		al_flip_display(); // Presenta en pantalla el frame renderizado
}

void renderizarPantallaEscaneoQR(ALLEGRO_FONT* fuente_grande, ALLEGRO_FONT* fuente_mediana, ALLEGRO_FONT* fuente_pequena, int ancho, int alto) {

		al_clear_to_color(al_map_rgb(0, 0, 0)); // Limpia la pantalla con un color negro uniforme

		al_draw_text(fuente_grande, al_map_rgb(255, 239, 213), ancho / 2, alto / 3 - 250, ALLEGRO_ALIGN_CENTER, "ESCANEO QR"); // Titulo principal centrado

		al_draw_rectangle(ancho / 2 - 150, alto / 2 - 350, ancho / 2 + 150, alto / 2 - 300, al_map_rgb(255, 255, 255), 1); // Dibuja un rectangulo blanco	
		al_draw_text(fuente_mediana, al_map_rgb(255, 255, 255), ancho / 2, alto / 2 - 345, ALLEGRO_ALIGN_CENTER, "ESCANEAR"); // Texto negro

		al_draw_rectangle(ancho / 2 - 500, alto / 2 - 250, ancho / 2 + 500, alto / 2 - 200, al_map_rgb(255, 255, 255), 1);

		al_draw_text(fuente_pequena, al_map_rgb(225, 225, 225), ancho / 2, alto - 40, ALLEGRO_ALIGN_CENTER, "Presiona ENTER para seleccionar"); // Indica como seleccionar una opcion

		al_flip_display(); // Presenta en pantalla el frame renderizado
}

// ========== FUNCION PRINCIPAL ==========

int main() {
		srand((unsigned int)time(NULL)); // Inicializa el generador de numeros aleatorios con la hora actual

		if (!al_init()) { // Comprueba si Allegro se inicializa correctamente
				al_show_native_message_box(NULL, "Error", "Error", "No se pudo iniciar Allegro", NULL, 0); // Muestra un dialogo de error
				return -1; // Finaliza la aplicacion con codigo de error
		}

		al_init_font_addon(); // Activa el addon de fuentes de Allegro
		al_init_ttf_addon(); // Activa el addon para fuentes TrueType
		al_init_image_addon(); // Activa el addon de imagenes
		al_init_primitives_addon(); // Activa el addon de primitivas graficas
		al_install_keyboard(); // Habilita la lectura del teclado
		al_uninstall_mouse(); // Desactiva el raton porque no se utiliza
		al_install_audio(); // Inicializa el subsistema de audio
		al_init_acodec_addon(); // Habilita los codecs necesarios para reproducir sonido
		al_reserve_samples(16); // Reserva 16 canales de audio simultaneos para musica y efectos

		ALLEGRO_MONITOR_INFO info; // Estructura para almacenar informacion del monitor principal
		al_get_monitor_info(0, &info); // Obtiene las dimensiones del monitor 0
		int ancho = info.x2 - info.x1; // Calcula el ancho total de la pantalla
		int alto = info.y2 - info.y1; // Calcula el alto total de la pantalla

		ALLEGRO_DISPLAY* pantalla = al_create_display(ancho, alto); // Crea una ventana o pantalla a resolucion completa
		if (!pantalla) { // Verifica que la pantalla se haya creado correctamente
				al_show_native_message_box(NULL, "Error", "Error", "No se pudo crear la pantalla", NULL, 0); // Informa si hubo un error creando la ventana
				return -1; // Termina la ejecucion porque no se puede continuar sin pantalla
		}

		ALLEGRO_FONT* font_grande = al_load_ttf_font("titulo.ttf", 72, 0); // Carga la fuente grande usada en el titulo
		if (!font_grande) { // Comprueba que la fuente se haya cargado
				al_show_native_message_box(pantalla, "Error", "Error", "No se pudo cargar la fuente grande", NULL, 0); // Muestra mensaje si falla
				return -1; // Cancela la aplicacion para evitar fallos posteriores
		}

		ALLEGRO_FONT* font_mediana = al_load_ttf_font("cuerpo.ttf", 24, 0); // Carga la fuente mediana para textos generales
		if (!font_mediana) { // Valida la carga de la fuente mediana
				al_show_native_message_box(pantalla, "Error", "Error", "No se pudo cargar la fuente mediana", NULL, 0); // Muestra aviso de error
				return -1; // Interrumpe la ejecucion si no se puede dibujar texto
		}

		ALLEGRO_FONT* font_pequena = al_load_ttf_font("cuerpo.ttf", 16, 0); // Carga la fuente pequena para instrucciones
		if (!font_pequena) { // Comprueba que se cargo la fuente pequena
				al_show_native_message_box(pantalla, "Error", "Error", "No se pudo cargar la fuente pequena", NULL, 0); // Muestra mensaje de error
				return -1; // Finaliza porque el menu necesita esta fuente
		}

		ALLEGRO_BITMAP* fondo_menu = al_load_bitmap("Imagenes/menu.png"); // Intenta cargar la imagen del menu principal
		if (!fondo_menu) { // Si la imagen no esta disponible
				al_show_native_message_box(pantalla, "Advertencia", "Aviso", "No se pudo cargar la imagen de fondo del menu", NULL, ALLEGRO_MESSAGEBOX_WARN); // Advierte al usuario pero no detiene el programa
		}

		ALLEGRO_TIMER* timer = al_create_timer(1.0 / 60.0); // Crea un temporizador para generar eventos a 60 FPS
		ALLEGRO_EVENT_QUEUE* queue = al_create_event_queue(); // Crea la cola donde se almacenaran eventos del sistema

		al_register_event_source(queue, al_get_keyboard_event_source()); // Registra el teclado como fuente de eventos
		al_register_event_source(queue, al_get_display_event_source(pantalla)); // Registra la ventana de la pantalla como fuente de eventos
		al_register_event_source(queue, al_get_timer_event_source(timer)); // Registra el temporizador para recibir ticks de actualizacion

		EstadoApp app = APP_MENU; // Variable que guarda el estado actual de la aplicacion, inicia en el menu
		int opcion = 0; // Indica cual opcion del menu esta seleccionada al inicio
		float timer_anim = 1.0f; // Acumula tiempo para potenciales animaciones de interfaz
		char input[MAX_INPUT_LENGTH] = {0}; // Buffer para almacenar el texto de entrada 
		int ignorar_proximo_evento = 0; // Bandera para ignorar el primer evento despu�s de cambiar de estado

		al_start_timer(timer); // Inicia el temporizador para que comience a generar eventos de reloj
		int running = 1; // Bandera que indica si el bucle principal debe seguir ejecutandose

		while (running) { // Bucle principal que se ejecuta hasta que el usuario sale
				ALLEGRO_EVENT ev; // Estructura para recibir eventos
				al_wait_for_event(queue, &ev); // Espera bloqueante hasta recibir un evento disponible

				// ===== MEN� PRINCIPAL =====
				if (app == APP_MENU && ev.type == ALLEGRO_EVENT_KEY_DOWN) {
						if (ev.keyboard.keycode == ALLEGRO_KEY_ESCAPE) { // Si se presiona Escape en el menu
								running = 0; // Se sale por completo de la aplicacion
						}

						if (ev.keyboard.keycode == ALLEGRO_KEY_W || ev.keyboard.keycode == ALLEGRO_KEY_UP) { // Movimiento hacia arriba en el menu
								opcion--; // Decrementa la opcion seleccionada
								if (opcion < 0) opcion = 2; // Hace wrap-around para volver a la ultima opcion
						}

						if (ev.keyboard.keycode == ALLEGRO_KEY_S || ev.keyboard.keycode == ALLEGRO_KEY_DOWN) { // Movimiento hacia abajo en el menu
								opcion++; // Incrementa la opcion activa
								if (opcion >= 3) opcion = 0; // Reinicia al inicio cuando pasa del ultimo elemento
						}

						if (ev.keyboard.keycode == ALLEGRO_KEY_ENTER) { // Confirmacion de la opcion actual
								if (opcion == 0) { // Si el usuario eligio generar
										app = APP_GENERAR; // Cambia al estado de pantalla de generaci�n
										input[0] = '\0'; // Resetea el buffer de entrada de texto
										opcion = 0; // Resetea opci�n a 0 (input)
										ignorar_proximo_evento = 1; // Ignora el siguiente evento para evitar conflictos
								}
								else if (opcion == 1) { // Si el usuario quiere escanear
										app = APP_ESCANEAR; // Cambia al estado de pantalla de escaneo
										ignorar_proximo_evento = 1; // Ignora el siguiente evento para evitar conflictos
								}
								else if (opcion == 2) { // Si el usuario decide salir
										running = 0; // Termina el bucle principal para cerrar la aplicacion
								}
						}
				}

				// ===== PANTALLA GENERAR QR =====
				if (app == APP_GENERAR && ev.type == ALLEGRO_EVENT_KEY_DOWN) {
						if (ev.keyboard.keycode == ALLEGRO_KEY_ESCAPE) { // Gestiona la salida de la pantalla de generaci�n
								app = APP_MENU; // Regresa al estado de menu cuando se presiona Escape
								opcion = 0; // Resetea opci�n al volver al men�
						}

						else if (ev.keyboard.keycode == ALLEGRO_KEY_BACKSPACE) { // Maneja la tecla de retroceso para borrar caracteres
								if (opcion == 0) { // Solo si el input esta activo
										int len = strlen(input); // Obtiene la longitud actual del texto
										if (len > 0) { // Si hay caracteres para borrar
												input[len - 1] = '\0'; // Elimina el ultimo caracter
										}
								}
						}

						else if (ev.keyboard.keycode == ALLEGRO_KEY_RIGHT) { // Movimiento hacia la derecha (entre opciones)
								opcion++;
								if (opcion >= 2) opcion = 0;
						}

						else if (ev.keyboard.keycode == ALLEGRO_KEY_LEFT) { // Movimiento hacia la izquierda (entre opciones)
								opcion--;
								if (opcion < 0) opcion = 1;
						}

						else if (ev.keyboard.keycode == ALLEGRO_KEY_ENTER) { // Confirmar entrada
								if (opcion == 1) {
									// TODO AQUI VA LA LOGICA DE GENERACION DE CODIGO QR
								}
						}		
				}
				// Agregar caracteres normales (letras, n�meros, s�mbolos)
				if (app == APP_GENERAR && ev.type == ALLEGRO_EVENT_KEY_CHAR && opcion == 0) {
						if (ev.keyboard.unichar >= 32 && ev.keyboard.unichar <= 126) {
								int len = strlen(input);
								if (len < MAX_INPUT_LENGTH - 1) {
										input[len] = (char)ev.keyboard.unichar; // Agrega el car�cter
										input[len + 1] = '\0'; // Asegura null-termination
								}
						}
				}

				// ===== PANTALLA ESCANEAR QR =====
				if (app == APP_ESCANEAR && ev.type == ALLEGRO_EVENT_KEY_DOWN) {
						if (ignorar_proximo_evento) {
								ignorar_proximo_evento = 0; // Consume el evento de transici�n
						}
						else if (ev.keyboard.keycode == ALLEGRO_KEY_ESCAPE) { // Gestiona la salida de la pantalla de escaneo
								app = APP_MENU; // Regresa al estado de menu cuando se presiona Escape
						}
						else if (ev.keyboard.keycode == ALLEGRO_KEY_ENTER) { // Abre el di�logo solo cuando presionas ENTER
								ALLEGRO_FILECHOOSER* imagen = al_create_native_file_dialog(NULL, "Selecciona una imagen de codigo QR", "*.png;*.jpg;*.bmp", ALLEGRO_FILECHOOSER_FILE_MUST_EXIST);
								if (imagen) {
										if (al_show_native_file_dialog(pantalla, imagen)) {
												if (al_get_native_file_dialog_count(imagen) > 0) {
														const char* ruta = al_get_native_file_dialog_path(imagen, 0);
														ALLEGRO_BITMAP* bmp = al_load_bitmap(ruta);
														if (bmp) {
																//TODO DE AQUI VA LA LOGICA DE ESCANEO DE CODIGO QR
																al_destroy_bitmap(bmp); // Destruye el bitmap despues de usarlo
														}
														else {
																al_show_native_message_box(pantalla, "Error", "Error", "No se pudo cargar la imagen seleccionada", NULL, 0);
														}
												}
										}
										al_destroy_native_file_dialog(imagen); // Destruye el dialogo despues de usarlo
								}
						}
				}	

				// ===== RENDERIZADO =====
				if (ev.type == ALLEGRO_EVENT_TIMER && ev.timer.source == timer) { // Se ejecuta cada tick del temporizador
						timer_anim += 1.0f / 60.0f; // Incrementa el acumulador temporal a razon de un frame

						if (app == APP_MENU) { // Si se esta en el menu
								renderizarMenu(opcion, font_grande, font_mediana, font_pequena, ancho, alto, timer_anim, fondo_menu); // Redibuja el menu con la opcion actual
						}
						else if (app == APP_GENERAR) { // Si se esta en la pantalla de generacion
								renderizarPantallaGenerarQR(font_grande, font_mediana, font_pequena, ancho, alto, input, opcion, NULL); // Redibuja la pantalla de generacion con el input actual y opcion seleccionada
						}
						else if (app == APP_ESCANEAR) { // Si se esta en la pantalla de escaneo
								renderizarPantallaEscaneoQR(font_grande, font_mediana, font_pequena, ancho, alto); // Redibuja la pantalla de escaneo
						}
				}

				// ===== CIERRE DE VENTANA =====
				if (ev.type == ALLEGRO_EVENT_DISPLAY_CLOSE) { // Maneja el evento de cierre de la ventana
						running = 0; // Termina el bucle principal para salir correctamente
				}
		}

		// ===== LIBERAR RECURSOS =====
		if (fondo_menu) al_destroy_bitmap(fondo_menu); // Destruye el bitmap del menu si fue cargado
		al_destroy_font(font_grande); // Libera la fuente grande
		al_destroy_font(font_mediana); // Libera la fuente mediana
		al_destroy_font(font_pequena); // Libera la fuente pequena
		al_destroy_event_queue(queue); // Destruye la cola de eventos
		al_destroy_timer(timer); // Destruye el temporizador
		al_destroy_display(pantalla); // Cierra y libera la pantalla principal

		return 0; // Finaliza la aplicacion indicando exito
}
