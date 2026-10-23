#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "config.h"
#include "cmark-gfm.h"
#include "syntax_extension.h"
#include "registry.h"
#include "plugin.h"

extern cmark_mem stream_CMARK_DEFAULT_MEM_ALLOCATOR;

static cmark_llist *syntax_extensions = NULL;

void stream_cmark_register_plugin(cmark_plugin_init_func reg_fn) {
  cmark_plugin *plugin = stream_cmark_plugin_new();

  if (!reg_fn(plugin)) {
    stream_cmark_plugin_free(plugin);
    return;
  }

  cmark_llist *syntax_extensions_list = stream_cmark_plugin_steal_syntax_extensions(plugin),
              *it;

  for (it = syntax_extensions_list; it; it = it->next) {
    syntax_extensions = stream_cmark_llist_append(&stream_CMARK_DEFAULT_MEM_ALLOCATOR, syntax_extensions, it->data);
  }

  stream_cmark_llist_free(&stream_CMARK_DEFAULT_MEM_ALLOCATOR, syntax_extensions_list);
  stream_cmark_plugin_free(plugin);
}

void stream_cmark_release_plugins(void) {
  if (syntax_extensions) {
    stream_cmark_llist_free_full(
        &stream_CMARK_DEFAULT_MEM_ALLOCATOR,
        syntax_extensions,
        (cmark_free_func) stream_cmark_syntax_extension_free);
    syntax_extensions = NULL;
  }
}

cmark_llist *stream_cmark_list_syntax_extensions(cmark_mem *mem) {
  cmark_llist *it;
  cmark_llist *res = NULL;

  for (it = syntax_extensions; it; it = it->next) {
    res = stream_cmark_llist_append(mem, res, it->data);
  }
  return res;
}

cmark_syntax_extension *stream_cmark_find_syntax_extension(const char *name) {
  cmark_llist *tmp;

  for (tmp = syntax_extensions; tmp; tmp = tmp->next) {
    cmark_syntax_extension *ext = (cmark_syntax_extension *) tmp->data;
    if (!strcmp(ext->name, name))
      return ext;
  }
  return NULL;
}
