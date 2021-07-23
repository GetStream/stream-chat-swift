import React from 'react';
import Viz from 'viz.js';
import DOMPurify from 'dompurify';

const style = `
digraph G {
    node [
        shape=rect
        fontcolor=white
        fontname = "helvetica"
        color="#349beb"
        style="rounded,filled"
    ]
    edge [
        arrowhead=none
    ]
`

export default function Digraph(props) {
    const graph = Viz(style + props.children + '}', { format: "svg", scale: 2, engine: 'dot' });
    return (
      <div dangerouslySetInnerHTML={{__html: DOMPurify.sanitize(graph)}} />
    );
  }