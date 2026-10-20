#include "cmark-gfm-core-extensions.h"
#include "autolink.h"
#include "strikethrough.h"
#include "table.h"
#include "tagfilter.h"
#include "tasklist.h"
#include "registry.h"
#include "plugin.h"

static int core_extensions_registration(cmark_plugin *plugin) {
  stream_cmark_plugin_register_syntax_extension(plugin, stream_create_table_extension());
  stream_cmark_plugin_register_syntax_extension(plugin,
                                         stream_create_strikethrough_extension());
  stream_cmark_plugin_register_syntax_extension(plugin, stream_create_autolink_extension());
  stream_cmark_plugin_register_syntax_extension(plugin, stream_create_tagfilter_extension());
  stream_cmark_plugin_register_syntax_extension(plugin, stream_create_tasklist_extension());
  return 1;
}

void stream_cmark_gfm_core_extensions_ensure_registered(void) {
  static int registered = 0;

  if (!registered) {
    stream_cmark_register_plugin(core_extensions_registration);
    registered = 1;
  }
}
