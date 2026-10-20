#ifndef CMARK_GFM_TABLE_H
#define CMARK_GFM_TABLE_H

#include "cmark-gfm-core-extensions.h"


extern cmark_node_type stream_CMARK_NODE_TABLE, stream_CMARK_NODE_TABLE_ROW,
    stream_CMARK_NODE_TABLE_CELL;

cmark_syntax_extension *stream_create_table_extension(void);

#endif
