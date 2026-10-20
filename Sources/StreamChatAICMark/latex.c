#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#include "config.h"
#include "cmark-gfm.h"
#include "node.h"
#include "buffer.h"
#include "utf8.h"
#include "scanners.h"
#include "render.h"
#include "syntax_extension.h"

#define OUT(s, wrap, escaping) renderer->out(renderer, node, s, wrap, escaping)
#define LIT(s) renderer->out(renderer, node, s, false, LITERAL)
#define CR() renderer->cr(renderer)
#define BLANKLINE() renderer->blankline(renderer)
#define LIST_NUMBER_STRING_SIZE 20

static CMARK_INLINE void outc(cmark_renderer *renderer, cmark_node *node,
                              cmark_escaping escape,
                              int32_t c, unsigned char nextc) {
  if (escape == LITERAL) {
    stream_cmark_render_code_point(renderer, c);
    return;
  }

  switch (c) {
  case 123: // '{'
  case 125: // '}'
  case 35:  // '#'
  case 37:  // '%'
  case 38:  // '&'
    stream_cmark_render_ascii(renderer, "\\");
    stream_cmark_render_code_point(renderer, c);
    break;
  case 36: // '$'
  case 95: // '_'
    if (escape == NORMAL) {
      stream_cmark_render_ascii(renderer, "\\");
    }
    stream_cmark_render_code_point(renderer, c);
    break;
  case 45:             // '-'
    if (nextc == 45) { // prevent ligature
      stream_cmark_render_ascii(renderer, "-{}");
    } else {
      stream_cmark_render_ascii(renderer, "-");
    }
    break;
  case 126: // '~'
    if (escape == NORMAL) {
      stream_cmark_render_ascii(renderer, "\\textasciitilde{}");
    } else {
      stream_cmark_render_code_point(renderer, c);
    }
    break;
  case 94: // '^'
    stream_cmark_render_ascii(renderer, "\\^{}");
    break;
  case 92: // '\\'
    if (escape == URL) {
      // / acts as path sep even on windows:
      stream_cmark_render_ascii(renderer, "/");
    } else {
      stream_cmark_render_ascii(renderer, "\\textbackslash{}");
    }
    break;
  case 124: // '|'
    stream_cmark_render_ascii(renderer, "\\textbar{}");
    break;
  case 60: // '<'
    stream_cmark_render_ascii(renderer, "\\textless{}");
    break;
  case 62: // '>'
    stream_cmark_render_ascii(renderer, "\\textgreater{}");
    break;
  case 91: // '['
  case 93: // ']'
    stream_cmark_render_ascii(renderer, "{");
    stream_cmark_render_code_point(renderer, c);
    stream_cmark_render_ascii(renderer, "}");
    break;
  case 34: // '"'
    stream_cmark_render_ascii(renderer, "\\textquotedbl{}");
    // requires \usepackage[T1]{fontenc}
    break;
  case 39: // '\''
    stream_cmark_render_ascii(renderer, "\\textquotesingle{}");
    // requires \usepackage{textcomp}
    break;
  case 160: // nbsp
    stream_cmark_render_ascii(renderer, "~");
    break;
  case 8230: // hellip
    stream_cmark_render_ascii(renderer, "\\ldots{}");
    break;
  case 8216: // lsquo
    if (escape == NORMAL) {
      stream_cmark_render_ascii(renderer, "`");
    } else {
      stream_cmark_render_code_point(renderer, c);
    }
    break;
  case 8217: // rsquo
    if (escape == NORMAL) {
      stream_cmark_render_ascii(renderer, "\'");
    } else {
      stream_cmark_render_code_point(renderer, c);
    }
    break;
  case 8220: // ldquo
    if (escape == NORMAL) {
      stream_cmark_render_ascii(renderer, "``");
    } else {
      stream_cmark_render_code_point(renderer, c);
    }
    break;
  case 8221: // rdquo
    if (escape == NORMAL) {
      stream_cmark_render_ascii(renderer, "''");
    } else {
      stream_cmark_render_code_point(renderer, c);
    }
    break;
  case 8212: // emdash
    if (escape == NORMAL) {
      stream_cmark_render_ascii(renderer, "---");
    } else {
      stream_cmark_render_code_point(renderer, c);
    }
    break;
  case 8211: // endash
    if (escape == NORMAL) {
      stream_cmark_render_ascii(renderer, "--");
    } else {
      stream_cmark_render_code_point(renderer, c);
    }
    break;
  default:
    stream_cmark_render_code_point(renderer, c);
  }
}

typedef enum {
  NO_LINK,
  URL_AUTOLINK,
  EMAIL_AUTOLINK,
  NORMAL_LINK,
  INTERNAL_LINK
} link_type;

static link_type get_link_type(cmark_node *node) {
  size_t title_len, url_len;
  cmark_node *link_text;
  char *realurl;
  int realurllen;
  bool isemail = false;

  if (node->type != CMARK_NODE_LINK) {
    return NO_LINK;
  }

  const char *url = stream_cmark_node_get_url(node);
  cmark_chunk url_chunk = cmark_chunk_literal(url);

  if (url && *url == '#') {
    return INTERNAL_LINK;
  }

  url_len = strlen(url);
  if (url_len == 0 || scan_scheme(&url_chunk, 0) == 0) {
    return NO_LINK;
  }

  const char *title = stream_cmark_node_get_title(node);
  title_len = strlen(title);
  // if it has a title, we can't treat it as an autolink:
  if (title_len == 0) {

    link_text = node->first_child;
    stream_cmark_consolidate_text_nodes(link_text);

    if (!link_text)
      return NO_LINK;

    realurl = (char *)url;
    realurllen = (int)url_len;
    if (strncmp(realurl, "mailto:", 7) == 0) {
      realurl += 7;
      realurllen -= 7;
      isemail = true;
    }
    if (realurllen == link_text->as.literal.len &&
        strncmp(realurl, (char *)link_text->as.literal.data,
                link_text->as.literal.len) == 0) {
      if (isemail) {
        return EMAIL_AUTOLINK;
      } else {
        return URL_AUTOLINK;
      }
    }
  }

  return NORMAL_LINK;
}

static int S_get_enumlevel(cmark_node *node) {
  int enumlevel = 0;
  cmark_node *tmp = node;
  while (tmp) {
    if (tmp->type == CMARK_NODE_LIST &&
        stream_cmark_node_get_list_type(node) == CMARK_ORDERED_LIST) {
      enumlevel++;
    }
    tmp = tmp->parent;
  }
  return enumlevel;
}

static int S_render_node(cmark_renderer *renderer, cmark_node *node,
                         cmark_event_type ev_type, int options) {
  int list_number;
  int enumlevel;
  char list_number_string[LIST_NUMBER_STRING_SIZE];
  bool entering = (ev_type == CMARK_EVENT_ENTER);
  cmark_list_type list_type;
  bool allow_wrap = renderer->width > 0 && !(CMARK_OPT_NOBREAKS & options);

  if (node->extension && node->extension->latex_render_func) {
    node->extension->latex_render_func(node->extension, renderer, node, ev_type, options);
    return 1;
  }

  switch (node->type) {
  case CMARK_NODE_DOCUMENT:
    break;

  case CMARK_NODE_BLOCK_QUOTE:
    if (entering) {
      LIT("\\begin{quote}");
      CR();
    } else {
      LIT("\\end{quote}");
      BLANKLINE();
    }
    break;

  case CMARK_NODE_LIST:
    list_type = stream_cmark_node_get_list_type(node);
    if (entering) {
      LIT("\\begin{");
      LIT(list_type == CMARK_ORDERED_LIST ? "enumerate" : "itemize");
      LIT("}");
      CR();
      list_number = stream_cmark_node_get_list_start(node);
      if (list_number > 1) {
        enumlevel = S_get_enumlevel(node);
        // latex normally supports only five levels
        if (enumlevel >= 1 && enumlevel <= 5) {
          snprintf(list_number_string, LIST_NUMBER_STRING_SIZE, "%d",
                   list_number);
          LIT("\\setcounter{enum");
          switch (enumlevel) {
          case 1: LIT("i"); break;
          case 2: LIT("ii"); break;
          case 3: LIT("iii"); break;
          case 4: LIT("iv"); break;
          case 5: LIT("v"); break;
          default: LIT("i"); break;
	  }
          LIT("}{");
          OUT(list_number_string, false, NORMAL);
          LIT("}");
        }
        CR();
      }
    } else {
      LIT("\\end{");
      LIT(list_type == CMARK_ORDERED_LIST ? "enumerate" : "itemize");
      LIT("}");
      BLANKLINE();
    }
    break;

  case CMARK_NODE_ITEM:
    if (entering) {
      LIT("\\item ");
    } else {
      CR();
    }
    break;

  case CMARK_NODE_HEADING:
    if (entering) {
      switch (stream_cmark_node_get_heading_level(node)) {
      case 1:
        LIT("\\section");
        break;
      case 2:
        LIT("\\subsection");
        break;
      case 3:
        LIT("\\subsubsection");
        break;
      case 4:
        LIT("\\paragraph");
        break;
      case 5:
        LIT("\\subparagraph");
        break;
      }
      LIT("{");
    } else {
      LIT("}");
      BLANKLINE();
    }
    break;

  case CMARK_NODE_CODE_BLOCK:
    CR();
    LIT("\\begin{verbatim}");
    CR();
    OUT(stream_cmark_node_get_literal(node), false, LITERAL);
    CR();
    LIT("\\end{verbatim}");
    BLANKLINE();
    break;

  case CMARK_NODE_HTML_BLOCK:
    break;

  case CMARK_NODE_CUSTOM_BLOCK:
    CR();
    OUT(entering ? stream_cmark_node_get_on_enter(node) : stream_cmark_node_get_on_exit(node),
        false, LITERAL);
    CR();
    break;

  case CMARK_NODE_THEMATIC_BREAK:
    BLANKLINE();
    LIT("\\begin{center}\\rule{0.5\\linewidth}{\\linethickness}\\end{center}");
    BLANKLINE();
    break;

  case CMARK_NODE_PARAGRAPH:
    if (!entering) {
      BLANKLINE();
    }
    break;

  case CMARK_NODE_TEXT:
    OUT(stream_cmark_node_get_literal(node), allow_wrap, NORMAL);
    break;

  case CMARK_NODE_LINEBREAK:
    LIT("\\\\");
    CR();
    break;

  case CMARK_NODE_SOFTBREAK:
    if (options & CMARK_OPT_HARDBREAKS) {
      LIT("\\\\");
      CR();
    } else if (renderer->width == 0 && !(CMARK_OPT_NOBREAKS & options)) {
      CR();
    } else {
      OUT(" ", allow_wrap, NORMAL);
    }
    break;

  case CMARK_NODE_CODE:
    LIT("\\texttt{");
    OUT(stream_cmark_node_get_literal(node), false, NORMAL);
    LIT("}");
    break;

  case CMARK_NODE_HTML_INLINE:
    break;

  case CMARK_NODE_CUSTOM_INLINE:
    OUT(entering ? stream_cmark_node_get_on_enter(node) : stream_cmark_node_get_on_exit(node),
        false, LITERAL);
    break;

  case CMARK_NODE_STRONG:
    if (entering) {
      LIT("\\textbf{");
    } else {
      LIT("}");
    }
    break;

  case CMARK_NODE_EMPH:
    if (entering) {
      LIT("\\emph{");
    } else {
      LIT("}");
    }
    break;

  case CMARK_NODE_LINK:
    if (entering) {
      const char *url = stream_cmark_node_get_url(node);
      // requires \usepackage{hyperref}
      switch (get_link_type(node)) {
      case URL_AUTOLINK:
        LIT("\\url{");
        OUT(url, false, URL);
        LIT("}");
        return 0; // Don't process further nodes to avoid double-rendering artefacts
      case EMAIL_AUTOLINK:
        LIT("\\href{");
        OUT(url, false, URL);
        LIT("}\\nolinkurl{");
        break;
      case NORMAL_LINK:
        LIT("\\href{");
        OUT(url, false, URL);
        LIT("}{");
        break;
      case INTERNAL_LINK:
        LIT("\\protect\\hyperlink{");
        OUT(url + 1, false, URL);
        LIT("}{");
        break;
      case NO_LINK:
        LIT("{"); // error?
      }
    } else {
      LIT("}");
    }

    break;

  case CMARK_NODE_IMAGE:
    if (entering) {
      LIT("\\protect\\includegraphics{");
      // requires \include{graphicx}
      OUT(stream_cmark_node_get_url(node), false, URL);
      LIT("}");
      return 0;
    }
    break;

  case CMARK_NODE_FOOTNOTE_DEFINITION:
  case CMARK_NODE_FOOTNOTE_REFERENCE:
    // TODO
    break;

  default:
    assert(false);
    break;
  }

  return 1;
}

char *stream_cmark_render_latex(cmark_node *root, int options, int width) {
  return stream_cmark_render_latex_with_mem(root, options, width, cmark_node_mem(root));
}

char *stream_cmark_render_latex_with_mem(cmark_node *root, int options, int width, cmark_mem *mem) {
  return stream_cmark_render(mem, root, options, width, outc, S_render_node);
}
