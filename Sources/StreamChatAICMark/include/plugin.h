#ifndef CMARK_PLUGIN_H
#define CMARK_PLUGIN_H

#ifdef __cplusplus
extern "C" {
#endif

#include "cmark-gfm.h"
#include "cmark-gfm-extension_api.h"

/**
 * cmark_plugin:
 *
 * A plugin structure, which should be filled by plugin's
 * init functions.
 */
struct cmark_plugin {
  cmark_llist *syntax_extensions;
};

cmark_llist *
stream_cmark_plugin_steal_syntax_extensions(cmark_plugin *plugin);

cmark_plugin *
stream_cmark_plugin_new(void);

void
stream_cmark_plugin_free(cmark_plugin *plugin);

#ifdef __cplusplus
}
#endif

#endif
