#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "cmark_ctype.h"
#include "config.h"
#include "cmark-gfm.h"
#include "houdini.h"
#include "scanners.h"
#include "syntax_extension.h"
#include "html.h"
#include "render.h"

// Functions to convert cmark_nodes to HTML strings.

static void escape_html(cmark_strbuf *dest, const unsigned char *source,
                        bufsize_t length) {
  stream_houdini_escape_html0(dest, source, length, 0);
}

static void filter_html_block(cmark_html_renderer *renderer, uint8_t *data, size_t len) {
  cmark_strbuf *html = renderer->html;
  cmark_llist *it;
  cmark_syntax_extension *ext;
  bool filtered;
  uint8_t *match;

  while (len) {
    match = (uint8_t *) memchr(data, '<', len);
    if (!match)
      break;

    if (match != data) {
      stream_cmark_strbuf_put(html, data, (bufsize_t)(match - data));
      len -= (match - data);
      data = match;
    }

    filtered = false;
    for (it = renderer->filter_extensions; it; it = it->next) {
      ext = ((cmark_syntax_extension *) it->data);
      if (!ext->html_filter_func(ext, data, len)) {
        filtered = true;
        break;
      }
    }

    if (!filtered) {
      stream_cmark_strbuf_putc(html, '<');
    } else {
      stream_cmark_strbuf_puts(html, "&lt;");
    }

    ++data;
    --len;
  }

  if (len)
    stream_cmark_strbuf_put(html, data, (bufsize_t)len);
}

static bool S_put_footnote_backref(cmark_html_renderer *renderer, cmark_strbuf *html, cmark_node *node) {
  if (renderer->written_footnote_ix >= renderer->footnote_ix)
    return false;
  renderer->written_footnote_ix = renderer->footnote_ix;

  stream_cmark_strbuf_puts(html, "<a href=\"#fnref-");
  stream_houdini_escape_href(html, node->as.literal.data, node->as.literal.len);
  stream_cmark_strbuf_puts(html, "\" class=\"footnote-backref\" data-footnote-backref aria-label=\"Back to content\">↩</a>");

  if (node->footnote.def_count > 1)
  {
    for(int i = 2; i <= node->footnote.def_count; i++) {
      char n[32];
      snprintf(n, sizeof(n), "%d", i);

      stream_cmark_strbuf_puts(html, " <a href=\"#fnref-");
      stream_houdini_escape_href(html, node->as.literal.data, node->as.literal.len);
      stream_cmark_strbuf_puts(html, "-");
      stream_cmark_strbuf_puts(html, n);
      stream_cmark_strbuf_puts(html, "\" class=\"footnote-backref\" data-footnote-backref aria-label=\"Back to content\">↩<sup class=\"footnote-ref\">");
      stream_cmark_strbuf_puts(html, n);
      stream_cmark_strbuf_puts(html, "</sup></a>");
    }
  }

  return true;
}

static int S_render_node(cmark_html_renderer *renderer, cmark_node *node,
                         cmark_event_type ev_type, int options) {
  cmark_node *parent;
  cmark_node *grandparent;
  cmark_strbuf *html = renderer->html;
  cmark_llist *it;
  cmark_syntax_extension *ext;
  char start_heading[] = "<h0";
  char end_heading[] = "</h0";
  bool tight;
  bool filtered;
  char buffer[BUFFER_SIZE];

  bool entering = (ev_type == CMARK_EVENT_ENTER);

  if (renderer->plain == node) { // back at original node
    renderer->plain = NULL;
  }

  if (renderer->plain != NULL) {
    switch (node->type) {
    case CMARK_NODE_TEXT:
    case CMARK_NODE_CODE:
    case CMARK_NODE_HTML_INLINE:
      escape_html(html, node->as.literal.data, node->as.literal.len);
      break;

    case CMARK_NODE_LINEBREAK:
    case CMARK_NODE_SOFTBREAK:
      stream_cmark_strbuf_putc(html, ' ');
      break;

    default:
      break;
    }
    return 1;
  }

  if (node->extension && node->extension->html_render_func) {
    node->extension->html_render_func(node->extension, renderer, node, ev_type, options);
    return 1;
  }

  switch (node->type) {
  case CMARK_NODE_DOCUMENT:
    break;

  case CMARK_NODE_BLOCK_QUOTE:
    if (entering) {
      cmark_html_render_cr(html);
      stream_cmark_strbuf_puts(html, "<blockquote");
      cmark_html_render_sourcepos(node, html, options);
      stream_cmark_strbuf_puts(html, ">\n");
    } else {
      cmark_html_render_cr(html);
      stream_cmark_strbuf_puts(html, "</blockquote>\n");
    }
    break;

  case CMARK_NODE_LIST: {
    cmark_list_type list_type = node->as.list.list_type;
    int start = node->as.list.start;

    if (entering) {
      cmark_html_render_cr(html);
      if (list_type == CMARK_BULLET_LIST) {
        stream_cmark_strbuf_puts(html, "<ul");
        cmark_html_render_sourcepos(node, html, options);
        stream_cmark_strbuf_puts(html, ">\n");
      } else if (start == 1) {
        stream_cmark_strbuf_puts(html, "<ol");
        cmark_html_render_sourcepos(node, html, options);
        stream_cmark_strbuf_puts(html, ">\n");
      } else {
        snprintf(buffer, BUFFER_SIZE, "<ol start=\"%d\"", start);
        stream_cmark_strbuf_puts(html, buffer);
        cmark_html_render_sourcepos(node, html, options);
        stream_cmark_strbuf_puts(html, ">\n");
      }
    } else {
      stream_cmark_strbuf_puts(html,
                        list_type == CMARK_BULLET_LIST ? "</ul>\n" : "</ol>\n");
    }
    break;
  }

  case CMARK_NODE_ITEM:
    if (entering) {
      cmark_html_render_cr(html);
      stream_cmark_strbuf_puts(html, "<li");
      cmark_html_render_sourcepos(node, html, options);
      stream_cmark_strbuf_putc(html, '>');
    } else {
      stream_cmark_strbuf_puts(html, "</li>\n");
    }
    break;

  case CMARK_NODE_HEADING:
    if (entering) {
      cmark_html_render_cr(html);
      start_heading[2] = (char)('0' + node->as.heading.level);
      stream_cmark_strbuf_puts(html, start_heading);
      cmark_html_render_sourcepos(node, html, options);
      stream_cmark_strbuf_putc(html, '>');
    } else {
      end_heading[3] = (char)('0' + node->as.heading.level);
      stream_cmark_strbuf_puts(html, end_heading);
      stream_cmark_strbuf_puts(html, ">\n");
    }
    break;

  case CMARK_NODE_CODE_BLOCK:
    cmark_html_render_cr(html);

    if (node->as.code.info.len == 0) {
      stream_cmark_strbuf_puts(html, "<pre");
      cmark_html_render_sourcepos(node, html, options);
      stream_cmark_strbuf_puts(html, "><code>");
    } else {
      bufsize_t first_tag = 0;
      while (first_tag < node->as.code.info.len &&
             !stream_cmark_isspace(node->as.code.info.data[first_tag])) {
        first_tag += 1;
      }

      if (options & CMARK_OPT_GITHUB_PRE_LANG) {
        stream_cmark_strbuf_puts(html, "<pre");
        cmark_html_render_sourcepos(node, html, options);
        stream_cmark_strbuf_puts(html, " lang=\"");
        escape_html(html, node->as.code.info.data, first_tag);
        if (first_tag < node->as.code.info.len && (options & CMARK_OPT_FULL_INFO_STRING)) {
          stream_cmark_strbuf_puts(html, "\" data-meta=\"");
          escape_html(html, node->as.code.info.data + first_tag + 1, node->as.code.info.len - first_tag - 1);
        }
        stream_cmark_strbuf_puts(html, "\"><code>");
      } else {
        stream_cmark_strbuf_puts(html, "<pre");
        cmark_html_render_sourcepos(node, html, options);
        stream_cmark_strbuf_puts(html, "><code class=\"language-");
        escape_html(html, node->as.code.info.data, first_tag);
        if (first_tag < node->as.code.info.len && (options & CMARK_OPT_FULL_INFO_STRING)) {
          stream_cmark_strbuf_puts(html, "\" data-meta=\"");
          escape_html(html, node->as.code.info.data + first_tag + 1, node->as.code.info.len - first_tag - 1);
        }
        stream_cmark_strbuf_puts(html, "\">");
      }
    }

    escape_html(html, node->as.code.literal.data, node->as.code.literal.len);
    stream_cmark_strbuf_puts(html, "</code></pre>\n");
    break;

  case CMARK_NODE_HTML_BLOCK:
    cmark_html_render_cr(html);
    if (!(options & CMARK_OPT_UNSAFE)) {
      stream_cmark_strbuf_puts(html, "<!-- raw HTML omitted -->");
    } else if (renderer->filter_extensions) {
      filter_html_block(renderer, node->as.literal.data, node->as.literal.len);
    } else {
      stream_cmark_strbuf_put(html, node->as.literal.data, node->as.literal.len);
    }
    cmark_html_render_cr(html);
    break;

  case CMARK_NODE_CUSTOM_BLOCK:
    cmark_html_render_cr(html);
    if (entering) {
      stream_cmark_strbuf_put(html, node->as.custom.on_enter.data,
                       node->as.custom.on_enter.len);
    } else {
      stream_cmark_strbuf_put(html, node->as.custom.on_exit.data,
                       node->as.custom.on_exit.len);
    }
    cmark_html_render_cr(html);
    break;

  case CMARK_NODE_THEMATIC_BREAK:
    cmark_html_render_cr(html);
    stream_cmark_strbuf_puts(html, "<hr");
    cmark_html_render_sourcepos(node, html, options);
    stream_cmark_strbuf_puts(html, " />\n");
    break;

  case CMARK_NODE_PARAGRAPH:
    parent = stream_cmark_node_parent(node);
    grandparent = stream_cmark_node_parent(parent);
    if (grandparent != NULL && grandparent->type == CMARK_NODE_LIST) {
      tight = grandparent->as.list.tight;
    } else {
      tight = false;
    }
    if (!tight) {
      if (entering) {
        cmark_html_render_cr(html);
        stream_cmark_strbuf_puts(html, "<p");
        cmark_html_render_sourcepos(node, html, options);
        stream_cmark_strbuf_putc(html, '>');
      } else {
        if (parent->type == CMARK_NODE_FOOTNOTE_DEFINITION && node->next == NULL) {
          stream_cmark_strbuf_putc(html, ' ');
          S_put_footnote_backref(renderer, html, parent);
        }
        stream_cmark_strbuf_puts(html, "</p>\n");
      }
    }
    break;

  case CMARK_NODE_TEXT:
    escape_html(html, node->as.literal.data, node->as.literal.len);
    break;

  case CMARK_NODE_LINEBREAK:
    stream_cmark_strbuf_puts(html, "<br />\n");
    break;

  case CMARK_NODE_SOFTBREAK:
    if (options & CMARK_OPT_HARDBREAKS) {
      stream_cmark_strbuf_puts(html, "<br />\n");
    } else if (options & CMARK_OPT_NOBREAKS) {
      stream_cmark_strbuf_putc(html, ' ');
    } else {
      stream_cmark_strbuf_putc(html, '\n');
    }
    break;

  case CMARK_NODE_CODE:
    stream_cmark_strbuf_puts(html, "<code>");
    escape_html(html, node->as.literal.data, node->as.literal.len);
    stream_cmark_strbuf_puts(html, "</code>");
    break;

  case CMARK_NODE_HTML_INLINE:
    if (!(options & CMARK_OPT_UNSAFE)) {
      stream_cmark_strbuf_puts(html, "<!-- raw HTML omitted -->");
    } else {
      filtered = false;
      for (it = renderer->filter_extensions; it; it = it->next) {
        ext = (cmark_syntax_extension *) it->data;
        if (!ext->html_filter_func(ext, node->as.literal.data, node->as.literal.len)) {
          filtered = true;
          break;
        }
      }
      if (!filtered) {
        stream_cmark_strbuf_put(html, node->as.literal.data, node->as.literal.len);
      } else {
        stream_cmark_strbuf_puts(html, "&lt;");
        stream_cmark_strbuf_put(html, node->as.literal.data + 1, node->as.literal.len - 1);
      }
    }
    break;

  case CMARK_NODE_CUSTOM_INLINE:
    if (entering) {
      stream_cmark_strbuf_put(html, node->as.custom.on_enter.data,
                       node->as.custom.on_enter.len);
    } else {
      stream_cmark_strbuf_put(html, node->as.custom.on_exit.data,
                       node->as.custom.on_exit.len);
    }
    break;

  case CMARK_NODE_STRONG:
    if (entering) {
      stream_cmark_strbuf_puts(html, "<strong>");
    } else {
      stream_cmark_strbuf_puts(html, "</strong>");
    }
    break;

  case CMARK_NODE_EMPH:
    if (entering) {
      stream_cmark_strbuf_puts(html, "<em>");
    } else {
      stream_cmark_strbuf_puts(html, "</em>");
    }
    break;

  case CMARK_NODE_LINK:
    if (entering) {
      stream_cmark_strbuf_puts(html, "<a href=\"");
      if ((options & CMARK_OPT_UNSAFE) ||
            !(scan_dangerous_url(&node->as.link.url, 0))) {
        stream_houdini_escape_href(html, node->as.link.url.data,
                            node->as.link.url.len);
      }
      if (node->as.link.title.len) {
        stream_cmark_strbuf_puts(html, "\" title=\"");
        escape_html(html, node->as.link.title.data, node->as.link.title.len);
      }
      stream_cmark_strbuf_puts(html, "\">");
    } else {
      stream_cmark_strbuf_puts(html, "</a>");
    }
    break;

  case CMARK_NODE_IMAGE:
    if (entering) {
      stream_cmark_strbuf_puts(html, "<img src=\"");
      if ((options & CMARK_OPT_UNSAFE) ||
            !(scan_dangerous_url(&node->as.link.url, 0))) {
        stream_houdini_escape_href(html, node->as.link.url.data,
                            node->as.link.url.len);
      }
      stream_cmark_strbuf_puts(html, "\" alt=\"");
      renderer->plain = node;
    } else {
      if (node->as.link.title.len) {
        stream_cmark_strbuf_puts(html, "\" title=\"");
        escape_html(html, node->as.link.title.data, node->as.link.title.len);
      }

      stream_cmark_strbuf_puts(html, "\" />");
    }
    break;

  case CMARK_NODE_FOOTNOTE_DEFINITION:
    if (entering) {
      if (renderer->footnote_ix == 0) {
        stream_cmark_strbuf_puts(html, "<section class=\"footnotes\" data-footnotes>\n<ol>\n");
      }
      ++renderer->footnote_ix;

      stream_cmark_strbuf_puts(html, "<li id=\"fn-");
      stream_houdini_escape_href(html, node->as.literal.data, node->as.literal.len);
      stream_cmark_strbuf_puts(html, "\">\n");
    } else {
      if (S_put_footnote_backref(renderer, html, node)) {
        stream_cmark_strbuf_putc(html, '\n');
      }
      stream_cmark_strbuf_puts(html, "</li>\n");
    }
    break;

  case CMARK_NODE_FOOTNOTE_REFERENCE:
    if (entering) {
      stream_cmark_strbuf_puts(html, "<sup class=\"footnote-ref\"><a href=\"#fn-");
      stream_houdini_escape_href(html, node->parent_footnote_def->as.literal.data, node->parent_footnote_def->as.literal.len);
      stream_cmark_strbuf_puts(html, "\" id=\"fnref-");
      stream_houdini_escape_href(html, node->parent_footnote_def->as.literal.data, node->parent_footnote_def->as.literal.len);

      if (node->footnote.ref_ix > 1) {
        char n[32];
        snprintf(n, sizeof(n), "%d", node->footnote.ref_ix);
        stream_cmark_strbuf_puts(html, "-");
        stream_cmark_strbuf_puts(html, n);
      }

      stream_cmark_strbuf_puts(html, "\" data-footnote-ref>");
      stream_houdini_escape_href(html, node->as.literal.data, node->as.literal.len);
      stream_cmark_strbuf_puts(html, "</a></sup>");
    }
    break;

  default:
    assert(false);
    break;
  }

  return 1;
}

char *stream_cmark_render_html(cmark_node *root, int options, cmark_llist *extensions) {
  return stream_cmark_render_html_with_mem(root, options, extensions, cmark_node_mem(root));
}

char *stream_cmark_render_html_with_mem(cmark_node *root, int options, cmark_llist *extensions, cmark_mem *mem) {
  char *result;
  cmark_strbuf html = CMARK_BUF_INIT(mem);
  cmark_event_type ev_type;
  cmark_node *cur;
  cmark_html_renderer renderer = {&html, NULL, NULL, 0, 0, NULL};
  cmark_iter *iter = stream_cmark_iter_new(root);

  for (; extensions; extensions = extensions->next)
    if (((cmark_syntax_extension *) extensions->data)->html_filter_func)
      renderer.filter_extensions = stream_cmark_llist_append(
          mem,
          renderer.filter_extensions,
          (cmark_syntax_extension *) extensions->data);

  while ((ev_type = stream_cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
    cur = stream_cmark_iter_get_node(iter);
    S_render_node(&renderer, cur, ev_type, options);
  }

  if (renderer.footnote_ix) {
    stream_cmark_strbuf_puts(&html, "</ol>\n</section>\n");
  }

  result = (char *)stream_cmark_strbuf_detach(&html);

  stream_cmark_llist_free(mem, renderer.filter_extensions);

  stream_cmark_iter_free(iter);
  return result;
}
