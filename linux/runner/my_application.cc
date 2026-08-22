#include "my_application.h"

#include <flutter_linux/flutter_linux.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Tamanhos publicados em _NET_WM_ICON quando o ícone vem do bundle. O PNG
// fonte tem 1024²; publicar esse tamanho encheria a propriedade X com 4 MB
// de ARGB para nada.
static const gint kBundledIconSizes[] = {48, 128, 256};

// Define o ícone da janela.
//
// O template do Flutter não define nenhum, e sem `_NET_WM_ICON` o ambiente
// cai no ícone genérico — o `.desktop` sozinho só resolve em ambientes que
// casam a janela com a entrada pelo `StartupWMClass`.
//
// Prefere o tema de ícones (respeita tema do usuário e HiDPI, quando a
// entrada foi instalada por `linux/packaging/install-desktop-entry.sh`) e
// cai no PNG que já viaja no bundle quando o app roda solto.
static void set_application_icon() {
  if (gtk_icon_theme_has_icon(gtk_icon_theme_get_default(), APPLICATION_ID)) {
    gtk_window_set_default_icon_name(APPLICATION_ID);
    return;
  }

  g_autofree gchar* executable = g_file_read_link("/proc/self/exe", nullptr);
  if (executable == nullptr) {
    return;
  }

  g_autofree gchar* bundle_dir = g_path_get_dirname(executable);
  g_autofree gchar* icon_path =
      g_build_filename(bundle_dir, "data", "flutter_assets", "assets",
                       "branding", "logo.png", nullptr);

  GList* icons = nullptr;
  for (gsize i = 0; i < G_N_ELEMENTS(kBundledIconSizes); i++) {
    g_autoptr(GError) error = nullptr;
    GdkPixbuf* icon = gdk_pixbuf_new_from_file_at_size(
        icon_path, kBundledIconSizes[i], kBundledIconSizes[i], &error);
    if (icon == nullptr) {
      g_warning("Ícone da janela indisponível (%s): %s", icon_path,
                error->message);
      break;
    }
    icons = g_list_append(icons, icon);
  }

  if (icons != nullptr) {
    gtk_window_set_default_icon_list(icons);
    g_list_free_full(icons, g_object_unref);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  // Antes de criar a janela: o default vale para toda janela criada depois.
  set_application_icon();

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Sem GtkHeaderBar (o template do Flutter cria um quando o WM é o GNOME
  // Shell): a barra de título do sistema é sempre substituída pela AppTitleBar,
  // e o header bar mudaria o caminho que o `window_manager` toma em
  // `TitleBarStyle.hidden` — com ele, o plugin apenas esconde o widget e mantém
  // a decoração do lado do cliente (sombra + margem), o que desalinha o
  // `getPosition`/`setPosition` da memória de posição da janela. Com um título
  // simples, o plugin cai em `gtk_window_set_decorated(FALSE)` e a janela fica
  // sem moldura em qualquer WM.
  gtk_window_set_title(window, "Decima");

  // Mesmo tamanho de DesktopWindowConfig.windowSize — evita flash de
  // redimensionamento antes do window_manager aplicar as WindowOptions.
  // No GTK isso é obrigatório, e não só cosmético: `setResizable(false)` faz o
  // GTK reescrever os geometry hints com o tamanho default da janela,
  // sobrescrevendo o `setSize` das WindowOptions.
  gtk_window_set_default_size(window, 360, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
