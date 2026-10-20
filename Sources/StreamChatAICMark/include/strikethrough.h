#ifndef CMARK_GFM_STRIKETHROUGH_H
#define CMARK_GFM_STRIKETHROUGH_H

#include "cmark-gfm-core-extensions.h"

extern cmark_node_type stream_CMARK_NODE_STRIKETHROUGH;
cmark_syntax_extension *stream_create_strikethrough_extension(void);

#endif
