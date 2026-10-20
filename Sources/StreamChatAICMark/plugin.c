#include <stdlib.h>

#include "plugin.h"

extern cmark_mem stream_CMARK_DEFAULT_MEM_ALLOCATOR;

int stream_cmark_plugin_register_syntax_extension(cmark_plugin    * plugin,
                                        cmark_syntax_extension * extension) {
  plugin->syntax_extensions = stream_cmark_llist_append(&stream_CMARK_DEFAULT_MEM_ALLOCATOR, plugin->syntax_extensions, extension);
  return 1;
}

cmark_plugin *
stream_cmark_plugin_new(void) {
  cmark_plugin *res = (cmark_plugin *) stream_CMARK_DEFAULT_MEM_ALLOCATOR.calloc(1, sizeof(cmark_plugin));

  res->syntax_extensions = NULL;

  return res;
}

void
stream_cmark_plugin_free(cmark_plugin *plugin) {
  stream_cmark_llist_free_full(&stream_CMARK_DEFAULT_MEM_ALLOCATOR,
                        plugin->syntax_extensions,
                        (cmark_free_func) stream_cmark_syntax_extension_free);
  stream_CMARK_DEFAULT_MEM_ALLOCATOR.free(plugin);
}

cmark_llist *
stream_cmark_plugin_steal_syntax_extensions(cmark_plugin *plugin) {
  cmark_llist *res = plugin->syntax_extensions;

  plugin->syntax_extensions = NULL;
  return res;
}
