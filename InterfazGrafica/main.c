#include <gtk/gtk.h> // Include GTK header for GUI
#include <gdk-pixbuf/gdk-pixbuf.h> // Include GDK Pixbuf for image handling
#include <string.h> // Include string manipulation functions

#define MAX_INPUT_LENGTH 256 // Define maximum input length for text, even thugh the max is 26 in reality

// External assembly functions
extern void generate_qr_asm(char* input);
extern void read_qr_asm(char* filename, char* buffer);

// Application states
typedef enum { // application states
    APP_MENU, // Menu state
    APP_GENERAR, // Generate QR state
    APP_ESCANEAR // Scan QR state
} EstadoApp;

// Application structure to hold all state
typedef struct { // Define structure to hold application data
    GtkWidget *window; // Main application window
    GtkWidget *stack; // Stack container for page switching
    
    // Menu widgets
    GtkWidget *menu_page;
    
    // Generator widgets
    GtkWidget *gen_page; // Generator page widget
    GtkWidget *gen_entry; // Text entry for generator
    GtkWidget *gen_image; // Image widget for QR display
    GtkWidget *gen_button; // Generate button
    
    // Scanner widgets
    GtkWidget *scan_page; // Scanner page widget
    GtkWidget *scan_button; // Scan button
    
    EstadoApp estado; // Current application state
    GdkPixbuf *qr_pixbuf; // Pixbuf for QR image
} AppData; // Application data structure

// Function definitions, too boring to make a .h
static void activate(GtkApplication *app, gpointer user_data);
static GtkWidget* create_menu_page(AppData *data);
static GtkWidget* create_generator_page(AppData *data);
static GtkWidget* create_scanner_page(AppData *data);
static void on_menu_generar_clicked(GtkButton *button, gpointer user_data);
static void on_menu_escanear_clicked(GtkButton *button, gpointer user_data);
static void on_menu_salir_clicked(GtkButton *button, gpointer user_data);
static void on_gen_generar_clicked(GtkButton *button, gpointer user_data);
static void on_gen_volver_clicked(GtkButton *button, gpointer user_data);
static void on_scan_escanear_clicked(GtkButton *button, gpointer user_data);
static void on_scan_volver_clicked(GtkButton *button, gpointer user_data);
static void on_file_dialog_open_callback(GObject *source, GAsyncResult *result, gpointer user_data);

// Main function
int main(int argc, char **argv) {
    GtkApplication *app;
    int status;
    
    app = gtk_application_new("org.explodingmittens.qrcode", G_APPLICATION_DEFAULT_FLAGS); // Create new GUI
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL); // Connect activate, the function that starts it
    status = g_application_run(G_APPLICATION(app), argc, argv); // Run the application
    g_object_unref(app); // Unreference the application
    
    return status; // Return the status
}

// On opening the app
static void activate(GtkApplication *app, gpointer user_data) { // Called when application is activated
    AppData *data = g_new0(AppData, 1); // Allocate and initialize AppData structure
    data->estado = APP_MENU; // Set initial state to menu
    data->qr_pixbuf = NULL; // Initialize QR pixbuf to NULL
    
    // Create main window
    data->window = gtk_application_window_new(app); // initialize the window
    gtk_window_set_title(GTK_WINDOW(data->window), "Códigos QR - Proyecto02"); // set name of the window
    gtk_window_set_default_size(GTK_WINDOW(data->window), 1000, 800); // set the dimensions
    
    // Set up CSS for background
    GtkCssProvider *provider = gtk_css_provider_new(); // css to adjust the image
    gtk_css_provider_load_from_path(provider, "InterfazGrafica/styles.css"); // load the css file
    gtk_style_context_add_provider_for_display(gdk_display_get_default(), GTK_STYLE_PROVIDER(provider),
                                               GTK_STYLE_PROVIDER_PRIORITY_APPLICATION); // default css config
    g_object_unref(provider); // no need for the css provider, as it is already loaded in memory
    
    // Create stack for page switching
    data->stack = gtk_stack_new(); // the stack
    gtk_stack_set_transition_type(GTK_STACK(data->stack), GTK_STACK_TRANSITION_TYPE_SLIDE_LEFT_RIGHT); // left animation, cool
    
    // Create pages
    data->menu_page = create_menu_page(data); // the page for menu, calls that function
    data->gen_page = create_generator_page(data); // the page for generating qr
    data->scan_page = create_scanner_page(data); // the page for scanning qr
    
    // Add pages to stack
    gtk_stack_add_named(GTK_STACK(data->stack), data->menu_page, "menu"); // identify menu page
    gtk_stack_add_named(GTK_STACK(data->stack), data->gen_page, "generar"); // identify generate page
    gtk_stack_add_named(GTK_STACK(data->stack), data->scan_page, "escanear"); // identify scan page
    
    // Set initial page
    gtk_stack_set_visible_child_name(GTK_STACK(data->stack), "menu"); // show the menu as main
    
    gtk_window_set_child(GTK_WINDOW(data->window), data->stack); // show the window
    
    // Store AppData in window data
    g_object_set_data_full(G_OBJECT(data->window), "app-data", data, g_free);
    
    gtk_window_present(GTK_WINDOW(data->window));
}

// Create menu page
static GtkWidget* create_menu_page(AppData *data) {

    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 20); // a vertical box with 20 elements, could be like 5 but oh well
    gtk_widget_set_halign(box, GTK_ALIGN_FILL); // to fill in horizontal
    gtk_widget_set_valign(box, GTK_ALIGN_FILL); //, fill in vertical
    gtk_widget_set_hexpand(box, TRUE); // can be expanded when increasing window size
    gtk_widget_set_vexpand(box, TRUE); // same for vertical
    
    gtk_widget_add_css_class(box, "menu-background"); // adds the css from before
    // in this case, loads the image
    
    // Top space, so things are not at the top
    GtkWidget *top_spacer = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_set_vexpand(top_spacer, TRUE);
    gtk_box_append(GTK_BOX(box), top_spacer);
    
    // Title
    GtkWidget *title = gtk_label_new(NULL);
    gtk_label_set_text(GTK_LABEL(title), "CODIGOS QR"); //"CODIGOS QR" text
    gtk_widget_add_css_class(title, "title-label"); // the name of the class in the css
    gtk_box_append(GTK_BOX(box), title); // append the element in the box
    
    // Subtitle
    GtkWidget *subtitle = gtk_label_new(NULL);
    gtk_label_set_text(GTK_LABEL(subtitle), "Generar y Escanear"); // the text
    gtk_widget_add_css_class(subtitle, "subtitle-label"); // the name of the class in the css
    gtk_box_append(GTK_BOX(box), subtitle); // append after title
    
    // Spacer
    GtkWidget *spacer = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_set_size_request(spacer, -1, 50); // this one is fixed 50 pixels
    gtk_box_append(GTK_BOX(box), spacer); // append the spacing
    
    // Button box
    GtkWidget *button_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 15);  // box, 15 spacing
    gtk_widget_set_halign(button_box, GTK_ALIGN_CENTER); // align center
    
    // Generar button
    GtkWidget *btn_generar = gtk_button_new_with_label("GENERAR"); // el btn de generar
    gtk_widget_set_size_request(btn_generar, 200, 50); // asign the size
    g_signal_connect(btn_generar, "clicked", G_CALLBACK(on_menu_generar_clicked), data); //  asssign the function
    gtk_box_append(GTK_BOX(button_box), btn_generar); //  append to the page
    
    // Escanear button
    GtkWidget *btn_escanear = gtk_button_new_with_label("ESCANEAR"); // btn to go to scan menu
    gtk_widget_set_size_request(btn_escanear, 200, 50); // size of button
    g_signal_connect(btn_escanear, "clicked", G_CALLBACK(on_menu_escanear_clicked), data); //  fuction to go to scan
    gtk_box_append(GTK_BOX(button_box), btn_escanear); // append the button
    
    // Salir button
    GtkWidget *btn_salir = gtk_button_new_with_label("SALIR"); // exit buttons
    gtk_widget_set_size_request(btn_salir, 200, 50); // dimensions of btn
    g_signal_connect(btn_salir, "clicked", G_CALLBACK(on_menu_salir_clicked), data); // when clicked, salir
    gtk_box_append(GTK_BOX(button_box), btn_salir); // append the btn to btn box
    
    gtk_box_append(GTK_BOX(box), button_box); // apend the box to the window
    
    // Instructions / text to tell the user what to do
    GtkWidget *instructions = gtk_label_new(NULL); // create the label
    gtk_label_set_text(GTK_LABEL(instructions), "Selecciona una opción para continuar"); // set the text
    // the above instructions could be combined but if it works, do not change it .

    gtk_widget_add_css_class(instructions, "instructions-label"); // the style of the text
    gtk_widget_set_margin_top(instructions, 30); // spacing
    gtk_box_append(GTK_BOX(box), instructions); // append the text
    
    // Bottom spacer to center content
    GtkWidget *bottom_spacer = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0); // a new box
    gtk_widget_set_vexpand(bottom_spacer, TRUE); // take the rest of the space of the screen
    gtk_box_append(GTK_BOX(box), bottom_spacer); // append the spacing
    
    return box; // return the window
}

// Menu calls
static void on_menu_generar_clicked(GtkButton *button, gpointer user_data) {
    AppData *data = (AppData*)user_data; // the previous user data
    
    // Clear previous QR
    gtk_image_clear(GTK_IMAGE(data->gen_image)); // clear any previous QR data
    gtk_editable_set_text(GTK_EDITABLE(data->gen_entry), ""); // reset the input text
    
    if (data->qr_pixbuf) { // reset the qr pixbuf
        g_object_unref(data->qr_pixbuf);
        data->qr_pixbuf = NULL;
    }
    
    gtk_stack_set_visible_child_name(GTK_STACK(data->stack), "generar"); // set the previously generated window to visible
    data->estado = APP_GENERAR; // change app state, not rlly necessary 
}

static void on_menu_escanear_clicked(GtkButton *button, gpointer user_data) {
    AppData *data = (AppData*)user_data;
    gtk_stack_set_visible_child_name(GTK_STACK(data->stack), "escanear"); // set the previously generated scan window to visible
    data->estado = APP_ESCANEAR; // change app state
}

static void on_menu_salir_clicked(GtkButton *button, gpointer user_data) {
    AppData *data = (AppData*)user_data;
    gtk_window_close(GTK_WINDOW(data->window)); // close the window
}

// Create generator page
static GtkWidget* create_generator_page(AppData *data) {
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 20); // 20 element box
    
    // top and botton margins
    gtk_widget_set_margin_top(box, 30); 
    gtk_widget_set_margin_bottom(box, 30);

    // Left and rigth margins
    gtk_widget_set_margin_start(box, 50);
    gtk_widget_set_margin_end(box, 50);
    
    // Title
    GtkWidget *title = gtk_label_new(NULL);
    gtk_label_set_text(GTK_LABEL(title), "GENERADOR QR"); // title text
    gtk_widget_add_css_class(title, "gen-title-label"); // style for the text
    gtk_widget_set_halign(title, GTK_ALIGN_CENTER); // allign the title to the center
    gtk_box_append(GTK_BOX(box), title); // add the title
    
    // Input box, NOTEE THAT IT IS HORIZONTAL
    GtkWidget *input_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10); // the box where the user will type
    gtk_widget_set_halign(input_box, GTK_ALIGN_CENTER); // allign it to the center
    
    // Entry
    data->gen_entry = gtk_entry_new(); // the entry for the actual input
    gtk_entry_set_max_length(GTK_ENTRY(data->gen_entry), MAX_INPUT_LENGTH - 1); // max buffer
    gtk_entry_set_placeholder_text(GTK_ENTRY(data->gen_entry), "Ingresa el texto aqui..."); // placeholder text for telling the user where to output
    gtk_widget_set_size_request(data->gen_entry, 400, -1); // size, -1 for adapting to it
    gtk_box_append(GTK_BOX(input_box), data->gen_entry); // append the input box
    
    // Generate button
    data->gen_button = gtk_button_new_with_label("GENERAR"); // the button tied to generating 
    g_signal_connect(data->gen_button, "clicked", G_CALLBACK(on_gen_generar_clicked), data); // assign the function
    gtk_box_append(GTK_BOX(input_box), data->gen_button); // append the button
    
    gtk_box_append(GTK_BOX(box), input_box); // append the full input
    
    // the QR Image frame
    GtkWidget *frame = gtk_frame_new(NULL);  // a frame
    gtk_widget_set_size_request(frame, 450, 450); // size of the frame
    gtk_widget_set_halign(frame, GTK_ALIGN_CENTER); // allign it to the center
    
    data->gen_image = gtk_image_new(); // create the image to  hold the image
    gtk_frame_set_child(GTK_FRAME(frame), data->gen_image); // place the image
    gtk_box_append(GTK_BOX(box), frame); // append the frame
    
    // Back button
    GtkWidget *btn_volver = gtk_button_new_with_label("Volver al Menu"); // btn to go back
    gtk_widget_set_halign(btn_volver, GTK_ALIGN_CENTER); // allign it horizontaly
    gtk_widget_set_margin_top(btn_volver, 20); // margin from the frame
    g_signal_connect(btn_volver, "clicked", G_CALLBACK(on_gen_volver_clicked), data); // when clicked
    gtk_box_append(GTK_BOX(box), btn_volver); // append it
    
    // Instructions text
    GtkWidget *instructions = gtk_label_new(NULL); // create a new label for the instructions
    gtk_label_set_text(GTK_LABEL(instructions), 
        "Ingresa un text y presiona el boton de generar\n"
        "Maximo de Caracteres: 26 caracteres"); // Ponerle texto
    gtk_widget_add_css_class(instructions, "gen-instructions-label"); // agregar estilo
    gtk_label_set_justify(GTK_LABEL(instructions), GTK_JUSTIFY_CENTER); // align center
    gtk_box_append(GTK_BOX(box), instructions); // append the box
    
    return box; // return the window
}

// Generator callbacks
static void on_gen_generar_clicked(GtkButton *button, gpointer user_data) {
    AppData *data = (AppData*)user_data;
    
    const char *text = gtk_editable_get_text(GTK_EDITABLE(data->gen_entry)); // get the text from input
    int len = strlen(text); // count the len
    
    if (len == 0) {
        GtkAlertDialog *dialog = gtk_alert_dialog_new("Por favor ingresa algún texto antes de generar el QR"); // mensaje de error
        gtk_alert_dialog_show(dialog, GTK_WINDOW(data->window)); // show the window
        g_object_unref(dialog); // destroy the window
        return;
    }
    
    if (len > 26) {
        GtkAlertDialog *dialog = gtk_alert_dialog_new(
            "El texto es muy largo \n");
        gtk_alert_dialog_show(dialog, GTK_WINDOW(data->window));
        g_object_unref(dialog);
        return;
    }
    
    // Generate QR
    char input_copy[MAX_INPUT_LENGTH]; // send a copy to avoid pointer errors
    strncpy(input_copy, text, MAX_INPUT_LENGTH - 1); // copy the char
    input_copy[MAX_INPUT_LENGTH - 1] = '\0'; // end! char
    
    generate_qr_asm(input_copy); // call the generation
    
    // Load generated QR
    GError *error = NULL; // the error
    if (data->qr_pixbuf) {
        g_object_unref(data->qr_pixbuf); // delete the already existing pix buf
    }
    
    // we have to convert to png first cause bmp kinda sucks for gtk
    system("convert output.bmp output_temp.png 2>/dev/null"); // llamada para converrtir a png
    data->qr_pixbuf = gdk_pixbuf_new_from_file("output_temp.png", &error); // cargas imagen
    
    if (error) { // Verifica si ocurrió un error al cargar la imagen del QR
        GtkAlertDialog *dialog = gtk_alert_dialog_new("Error creando QR"); // Decir error
        gtk_alert_dialog_show(dialog, GTK_WINDOW(data->window)); //show Dialog
        g_object_unref(dialog); // free memory
        g_error_free(error); //free error
        return;
    }

    // Scale of the box / window, whatever
    // important, using gdk
    GdkPixbuf *scaled = gdk_pixbuf_scale_simple(data->qr_pixbuf, 400, 400, GDK_INTERP_NEAREST); // set size to 400 x 400 for the qr
    GdkTexture *texture = gdk_texture_new_for_pixbuf(scaled); // create texture from scaled image
    gtk_image_set_from_paintable(GTK_IMAGE(data->gen_image), GDK_PAINTABLE(texture)); // "show"/set the image
    g_object_unref(texture); // free textura
    g_object_unref(scaled); // free pixels
}

static void on_gen_volver_clicked(GtkButton *button, gpointer user_data) {
    AppData *data = (AppData*)user_data;
    gtk_stack_set_visible_child_name(GTK_STACK(data->stack), "menu"); // set the visible window back to menu
    data->estado = APP_MENU; // set the state
}

// Create scanner page
static GtkWidget* create_scanner_page(AppData *data) {
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 20); // vertical box with 20 elements capacity
    gtk_widget_set_halign(box, GTK_ALIGN_CENTER); // align center
    gtk_widget_set_valign(box, GTK_ALIGN_CENTER); // align center vertical
    gtk_widget_set_margin_top(box, 50); // margin from the top of the window
    gtk_widget_set_margin_bottom(box, 50); // margin from the bottom of the windpw
    
    // Title
    GtkWidget *title = gtk_label_new(NULL); // new texf
    gtk_label_set_text(GTK_LABEL(title), "ESCANEO QR"); // Set text of the title
    gtk_widget_add_css_class(title, "scan-title-label"); // set the style of the text
    gtk_box_append(GTK_BOX(box), title); // append the text
    
    // Spacer
    GtkWidget *spacer = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);  // box for space
    gtk_widget_set_size_request(spacer, -1, 30); // size of space
    gtk_box_append(GTK_BOX(box), spacer); // append space
    
    // Scan button
    data->scan_button = gtk_button_new_with_label("ESCANEAR QR"); // the button to trigger selection file
    gtk_widget_set_size_request(data->scan_button, 300, 60); // dimensions of the btn
    g_signal_connect(data->scan_button, "clicked", G_CALLBACK(on_scan_escanear_clicked), data); // connect the function
    gtk_box_append(GTK_BOX(box), data->scan_button); // append the btn at the end
    
    // Instructions
    GtkWidget *instructions = gtk_label_new(NULL); // create a text for the instructions
    gtk_label_set_text(GTK_LABEL(instructions),    // instruccions with what to do
        "Selecciona una imagen BMP con codigo QR\n"
        "Formatos soportados: *.bmp");
    gtk_widget_add_css_class(instructions, "scan-instructions-label"); // add css to the tetx
    gtk_label_set_justify(GTK_LABEL(instructions), GTK_JUSTIFY_CENTER); // allign center
    gtk_widget_set_margin_top(instructions, 20); // set the spacing from the top button
    gtk_box_append(GTK_BOX(box), instructions); // append the text
    
    // Back button
    GtkWidget *btn_volver = gtk_button_new_with_label("Volver al Menu"); // come back button
    gtk_widget_set_margin_top(btn_volver, 40); // distance from the above text
    g_signal_connect(btn_volver, "clicked", G_CALLBACK(on_scan_volver_clicked), data); // the function that calls 
    gtk_box_append(GTK_BOX(box), btn_volver); // append the btn
    
    return box; // return the window
}

// Scann call
static void on_file_dialog_open_callback(GObject *source, GAsyncResult *result, gpointer user_data) {
    AppData *data = (AppData*)user_data;
    GtkFileDialog *dialog = GTK_FILE_DIALOG(source); // create a Dialog to choose file
    GError *error = NULL;
    
    GFile *file = gtk_file_dialog_open_finish(dialog, result, &error); // open the Dialog
    
    if (error) {
        if (error->code != GTK_DIALOG_ERROR_DISMISSED) {
            GtkAlertDialog *alert = gtk_alert_dialog_new("Error al seleccionar archivo"); // if there was an actual error
            gtk_alert_dialog_show(alert, GTK_WINDOW(data->window)); // show a dialog
            g_object_unref(alert); // free memory for the dialog
        }
        g_error_free(error);
        return;
    }
    
    char *path = g_file_get_path(file); // else, get the path
    g_object_unref(file);
    
    if (!path) {
        GtkAlertDialog *alert = gtk_alert_dialog_new("Ruta de archivo inválida"); // if the path is NULL
        gtk_alert_dialog_show(alert, GTK_WINDOW(data->window)); // show a dialog with an alert
        g_object_unref(alert); // free memory
        return;
    }
    
    // else, we have a file, time to scan it
    char output_buffer[256] = {0}; // where the output will be
    char path_copy[512]; // where the path is
    strncpy(path_copy, path, 511); // copy the path
    path_copy[511] = '\0'; // end pointer
    
    g_free(path); // bye old string
    
    read_qr_asm(path_copy, output_buffer); //  call the assembly function
    
    // if it didn't read anything
    if (output_buffer[0] == '\0') {
        GtkAlertDialog *alert = gtk_alert_dialog_new(
            "No se pudo leer el código QR.\n"); // dialog de alerta
        gtk_alert_dialog_show(alert, GTK_WINDOW(data->window)); // show alerta
        g_object_unref(alert); // free memoria
    } else if (strncmp(output_buffer, "Error:", 6) == 0) { // the asm returns an error code
        GtkAlertDialog *alert = gtk_alert_dialog_new(output_buffer); // the buffer
        gtk_alert_dialog_show(alert, GTK_WINDOW(data->window)); // show the error code
        g_object_unref(alert); // free memory
    } else {
        // the qr is actually valid!
        char message[512];
        snprintf(message, 512, "Texto decodificado:\n\n%s", output_buffer); // copy to message formatted
        GtkAlertDialog *alert = gtk_alert_dialog_new(message); // show an alert with the meesage
        gtk_alert_dialog_show(alert, GTK_WINDOW(data->window)); // display the alert
        g_object_unref(alert); // free
    }
}

static void on_scan_escanear_clicked(GtkButton *button, gpointer user_data) {
    AppData *data = (AppData*)user_data;
    
    GtkFileDialog *dialog = gtk_file_dialog_new(); // create a dialog to search for file
    gtk_file_dialog_set_title(dialog, "Selecciona una imagen de código QR"); // the title of the dialog
    
    // Create file filter
    GtkFileFilter *filter = gtk_file_filter_new(); // create filters
    gtk_file_filter_set_name(filter, "Imagen (*.bmp)"); // look for bmp files
    gtk_file_filter_add_pattern(filter, "*.bmp"); // the pattern to look for
    
    GListStore *filters = g_list_store_new(GTK_TYPE_FILE_FILTER); // save the filters
    g_list_store_append(filters, filter); // add the filters
    gtk_file_dialog_set_filters(dialog, G_LIST_MODEL(filters)); // apply the filders
    g_object_unref(filters); //free mem for the filters
    
    // Open file
    gtk_file_dialog_open(dialog, GTK_WINDOW(data->window), NULL, 
        on_file_dialog_open_callback, data);
}

static void on_scan_volver_clicked(GtkButton *button, gpointer user_data) {
    AppData *data = (AppData*)user_data;
    gtk_stack_set_visible_child_name(GTK_STACK(data->stack), "menu"); // go back to menu window
    data->estado = APP_MENU; // change state
}
