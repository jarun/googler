#!/usr/bin/env python3
#
# Copyright © 2008 Henri Hakkinen
# Copyright © 2015-2021 Arun Prakash Jana <engineerarun@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import argparse
import atexit
import base64
import collections
import codecs
import functools
import gzip
import html.entities
import html.parser
import http.client
from http.client import HTTPSConnection
import locale
import logging
import os
import platform
import shutil
import signal
import socket
import ssl
import subprocess
from subprocess import Popen, PIPE, DEVNULL
import sys
import textwrap
import unicodedata
import urllib.parse
import uuid
import webbrowser

# Python optional dependency compatibility layer
try:
    import readline
except ImportError:
    pass

try:
    import setproctitle
    setproctitle.setproctitle('googler')
except (ImportError, Exception):
    pass

from typing import (
    Any,
    Dict,
    Generator,
    Iterable,
    Iterator,
    List,
    Match,
    Optional,
    Sequence,
    Tuple,
    Union,
    cast,
)

# Basic setup

logging.basicConfig(format='[%(levelname)s] %(message)s')
logger = logging.getLogger()


def sigint_handler(signum, frame):
    print('\nInterrupted.', file=sys.stderr)
    sys.exit(1)

try:
    signal.signal(signal.SIGINT, sigint_handler)
except ValueError:
    # signal only works in main thread
    pass


# Constants

_VERSION_ = '4.3.2'
_EPOCH_ = '20210115'

COLORMAP = {k: '\x1b[%sm' % v for k, v in {
    'a': '30', 'b': '31', 'c': '32', 'd': '33',
    'e': '34', 'f': '35', 'g': '36', 'h': '37',
    'i': '90', 'j': '91', 'k': '92', 'l': '93',
    'm': '94', 'n': '95', 'o': '96', 'p': '97',
    'A': '30;1', 'B': '31;1', 'C': '32;1', 'D': '33;1',
    'E': '34;1', 'F': '35;1', 'G': '36;1', 'H': '37;1',
    'I': '90;1', 'J': '91;1', 'K': '92;1', 'L': '93;1',
    'M': '94;1', 'N': '95;1', 'O': '96;1', 'P': '97;1',
    'x': '0', 'X': '1', 'y': '7', 'Y': '7;1',
}.items()}

USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36'

text_browsers = ['elinks', 'links', 'lynx', 'w3m', 'www-browser']

# Self-upgrade parameters
#
# Downstream packagers are recommended to turn off the entire self-upgrade
# mechanism through
#
#     make disable-self-upgrade
#
# before running `make install'.

ENABLE_SELF_UPGRADE_MECHANISM = True
API_REPO_BASE = 'https://api.github.com/repos/jarun/googler'
RAW_DOWNLOAD_REPO_BASE = 'https://raw.githubusercontent.com/jarun/googler'

debugger = False


# Monkeypatch textwrap for CJK wide characters.

def monkeypatch_textwrap_for_cjk():
    try:
        if textwrap.wrap.patched:
            return
    except AttributeError:
        pass
    psl_textwrap_wrap = textwrap.wrap

    def textwrap_wrap(text, width=70, **kwargs):
        if width <= 2:
            width = 2
        # We first add a U+0000 after each East Asian Fullwidth or East
        # Asian Wide character, then fill to width - 1 (so that if a NUL
        # character ends up on a new line, we still have one last column
        # to spare for the preceding wide character). Finally we strip
        # all the NUL characters.
        #
        # East Asian Width: https://www.unicode.org/reports/tr11/
        return [
            line.replace('\0', '')
            for line in psl_textwrap_wrap(
                ''.join(
                    ch + '\0' if unicodedata.east_asian_width(ch) in ('F', 'W') else ch
                    for ch in unicodedata.normalize('NFC', text)
                ),
                width=width - 1,
                **kwargs
            )
        ]

    def textwrap_fill(text, width=70, **kwargs):
        return '\n'.join(textwrap_wrap(text, width=width, **kwargs))

    textwrap.wrap = textwrap_wrap
    textwrap.fill = textwrap_fill
    textwrap.wrap.patched = True
    textwrap.fill.patched = True


monkeypatch_textwrap_for_cjk()


CoordinateType = Tuple[int, int]


class TrackedTextwrap:
    """
    Implements a text wrapper that tracks the position of each source
    character, and can correctly insert zero-width sequences at given
    offsets of the source text.

    Wrapping result should be the same as that from PSL textwrap.wrap
    with default settings except expand_tabs=False.
    """

    def __init__(self, text: str, width: int):
        self._original = text

        # Do the job of replace_whitespace first so that we can easily
        # match text to wrapped lines later. Note that this operation
        # does not change text length or offsets.
        whitespace = "\t\n\v\f\r "
        whitespace_trans = str.maketrans(whitespace, " " * len(whitespace))
        text = text.translate(whitespace_trans)

        self._lines = textwrap.wrap(
            text, width, expand_tabs=False, replace_whitespace=False
        )

        # self._coords track the (row, column) coordinate of each source
        # character in the result text. It is indexed by offset in
        # source text.
        self._coords = []  # type: List[CoordinateType]
        offset = 0
        try:
            if not self._lines:
                # Source text only has whitespaces. We add an empty line
                # in order to produce meaningful coordinates.
                self._lines = [""]
            for row, line in enumerate(self._lines):
                assert text[offset : offset + len(line)] == line
                col = 0
                for _ in line:
                    self._coords.append((row, col))
                    offset += 1
                    col += 1
                # All subsequent dropped whitespaces map to the last, imaginary column
                # (the EOL character if you wish) of the current line.
                while offset < len(text) and text[offset] == " ":
                    self._coords.append((row, col))
                    offset += 1
            # One past the final character (think of it as EOF) should
            # be treated as a valid offset.
            self._coords.append((row, col))
        except AssertionError:
            raise RuntimeError(
                "TrackedTextwrap: the impossible happened at offset {} of text {!r}".format(
                    offset, self._original
                )
            )

    # seq should be a zero-width sequence, e.g., an ANSI escape sequence.
    # May raise IndexError if offset is out of bounds.
    def insert_zero_width_sequence(self, seq: str, offset: int) -> None:
        row, col = self._coords[offset]
        line = self._lines[row]
        self._lines[row] = line[:col] + seq + line[col:]

        # Shift coordinates of all characters after the given character
        # on the same line.
        shift = len(seq)
        offset += 1
        while offset < len(self._coords) and self._coords[offset][0] == row:
            _, col = self._coords[offset]
            self._coords[offset] = (row, col + shift)
            offset += 1

    @property
    def original(self) -> str:
        return self._original

    @property
    def lines(self) -> List[str]:
        return self._lines

    @property
    def wrapped(self) -> str:
        return "\n".join(self._lines)

    # May raise IndexError if offset is out of bounds.
    def get_coordinate(self, offset: int) -> CoordinateType:
        return self._coords[offset]


### begin dim (DOM implementation with CSS support) ###
### https://github.com/zmwangx/dim/blob/master/dim.py ###

import html
import re
from collections import OrderedDict
from enum import Enum
from html.parser import HTMLParser


SelectorGroupLike = Union[str, "SelectorGroup", "Selector"]


class Node(object):
    """
    Represents a DOM node.

    Parts of JavaScript's DOM ``Node`` API and ``Element`` API are
    mirrored here, with extensions. In particular, ``querySelector`` and
    ``querySelectorAll`` are mirrored.

    Notable properties and methods: :meth:`attr()`, :attr:`classes`,
    :attr:`html`, :attr:`text`, :meth:`ancestors()`,
    :meth:`descendants()`, :meth:`select()`, :meth:`select_all()`,
    :meth:`matched_by()`,

    Attributes:
        tag      (:class:`Optional`\\[:class:`str`])
        attrs    (:class:`Dict`\\[:class:`str`, :class:`str`])
        parent   (:class:`Optional`\\[:class:`Node`])
        children (:class:`List`\\[:class:`Node`])
    """

    # Meant to be reimplemented by subclasses.
    def __init__(self) -> None:
        self.tag = None  # type: Optional[str]
        self.attrs = {}  # type: Dict[str, str]
        self.parent = None  # type: Optional[Node]
        self.children = []  # type: List[Node]

        # Used in DOMBuilder.
        self._partial = False
        self._namespace = None  # type: Optional[str]

    # HTML representation of the node. Meant to be implemented by
    # subclasses.
    def __str__(self) -> str:  # pragma: no cover
        raise NotImplementedError

    def select(self, selector: SelectorGroupLike) -> Optional["Node"]:
        """DOM ``querySelector`` clone. Returns one match (if any)."""
        selector = self._normalize_selector(selector)
        for node in self._select_all(selector):
            return node
        return None

    def query_selector(self, selector: SelectorGroupLike) -> Optional["Node"]:
        """Alias of :meth:`select`."""
        return self.select(selector)

    def select_all(self, selector: SelectorGroupLike) -> List["Node"]:
        """DOM ``querySelectorAll`` clone. Returns all matches in a list."""
        selector = self._normalize_selector(selector)
        return list(self._select_all(selector))

    def query_selector_all(self, selector: SelectorGroupLike) -> List["Node"]:
        """Alias of :meth:`select_all`."""
        return self.select_all(selector)

    def matched_by(
        self, selector: SelectorGroupLike, root: Optional["Node"] = None
    ) -> bool:
        """
        Checks whether this node is matched by `selector`.

        See :meth:`SelectorGroup.matches()`.
        """
        selector = self._normalize_selector(selector)
        return selector.matches(self, root=root)

    @staticmethod
    def _normalize_selector(selector: SelectorGroupLike) -> "SelectorGroup":
        if isinstance(selector, str):
            return SelectorGroup.from_str(selector)
        if isinstance(selector, SelectorGroup):
            return selector
        if isinstance(selector, Selector):
            return SelectorGroup([selector])
        raise ValueError("not a selector or group of selectors: %s" % repr(selector))

    def _select_all(self, selector: "SelectorGroup") -> Generator["Node", None, None]:
        for descendant in self.descendants():
            if selector.matches(descendant, root=self):
                yield descendant

    def child_nodes(self) -> List["Node"]:
        return self.children

    def first_child(self) -> Optional["Node"]:
        if self.children:
            return self.children[0]
        else:
            return None

    def first_element_child(self) -> Optional["Node"]:
        for child in self.children:
            if isinstance(child, ElementNode):
                return child
        return None

    def last_child(self) -> Optional["Node"]:
        if self.children:
            return self.children[-1]
        else:
            return None

    def last_element_child(self) -> Optional["Node"]:
        for child in reversed(self.children):
            if isinstance(child, ElementNode):
                return child
        return None

    def next_sibling(self) -> Optional["Node"]:
        """.. note:: Not O(1), use with caution."""
        next_siblings = self.next_siblings()
        if next_siblings:
            return next_siblings[0]
        else:
            return None

    def next_siblings(self) -> List["Node"]:
        parent = self.parent
        if not parent:
            return []
        try:
            index = parent.children.index(self)
            return parent.children[index + 1 :]
        except ValueError:  # pragma: no cover
            raise ValueError("node is not found in children of its parent")

    def next_element_sibling(self) -> Optional["ElementNode"]:
        """.. note:: Not O(1), use with caution."""
        for sibling in self.next_siblings():
            if isinstance(sibling, ElementNode):
                return sibling
        return None

    def previous_sibling(self) -> Optional["Node"]:
        """.. note:: Not O(1), use with caution."""
        previous_siblings = self.previous_siblings()
        if previous_siblings:
            return previous_siblings[0]
        else:
            return None

    def previous_siblings(self) -> List["Node"]:
        """
        Compared to the natural DOM order, the order of returned nodes
        are reversed. That is, the adjacent sibling (if any) is the
        first in the returned list.
        """
        parent = self.parent
        if not parent:
            return []
        try:
            index = parent.children.index(self)
            if index > 0:
                return parent.children[index - 1 :: -1]
            else:
                return []
        except ValueError:  # pragma: no cover
            raise ValueError("node is not found in children of its parent")

    def previous_element_sibling(self) -> Optional["ElementNode"]:
        """.. note:: Not O(1), use with caution."""
        for sibling in self.previous_siblings():
            if isinstance(sibling, ElementNode):
                return sibling
        return None

    def ancestors(
        self, *, root: Optional["Node"] = None
    ) -> Generator["Node", None, None]:
        """
        Ancestors are generated in reverse order of depth, stopping at
        `root`.

        A :class:`RuntimeException` is raised if `root` is not in the
        ancestral chain.
        """
        if self is root:
            return
        ancestor = self.parent
        while ancestor is not root:
            if ancestor is None:
                raise RuntimeError("provided root node not found in ancestral chain")
            yield ancestor
            ancestor = ancestor.parent
        if root:
            yield root

    def descendants(self) -> Generator["Node", None, None]:
        """Descendants are generated in depth-first order."""
        for child in self.children:
            yield child
            yield from child.descendants()

    def attr(self, attr: str) -> Optional[str]:
        """Returns the attribute if it exists on the node, otherwise ``None``."""
        return self.attrs.get(attr)

    @property
    def html(self) -> str:
        """
        HTML representation of the node.

        (For a :class:`TextNode`, :meth:`html` returns the escaped version of the
        text.
        """
        return str(self)

    def outer_html(self) -> str:
        """Alias of :attr:`html`."""
        return self.html

    def inner_html(self) -> str:
        """HTML representation of the node's children."""
        return "".join(child.html for child in self.children)

    @property
    def text(self) -> str:  # pragma: no cover
        """This property is expected to be implemented by subclasses."""
        raise NotImplementedError

    def text_content(self) -> str:
        """Alias of :attr:`text`."""
        return self.text

    @property
    def classes(self) -> List[str]:
        return self.attrs.get("class", "").split()

    def class_list(self) -> List[str]:
        return self.classes


class ElementNode(Node):
    """
    Represents an element node.

    Note that tag and attribute names are case-insensitive; attribute
    values are case-sensitive.
    """

    def __init__(
        self,
        tag: str,
        attrs: Iterable[Tuple[str, Optional[str]]],
        *,
        parent: Optional["Node"] = None,
        children: Optional[Sequence["Node"]] = None
    ) -> None:
        Node.__init__(self)
        self.tag = tag.lower()  # type: str
        self.attrs = OrderedDict((attr.lower(), val or "") for attr, val in attrs)
        self.parent = parent
        self.children = list(children or [])

    def __repr__(self) -> str:
        s = "<" + self.tag
        if self.attrs:
            s += " attrs=%s" % repr(list(self.attrs.items()))
        if self.children:
            s += " children=%s" % repr(self.children)
        s += ">"
        return s

    # https://ipython.readthedocs.io/en/stable/api/generated/IPython.lib.pretty.html
    def _repr_pretty_(self, p: Any, cycle: bool) -> None:  # pragma: no cover
        if cycle:
            raise RuntimeError("cycle detected in DOM tree")
        p.text("<\x1b[1m%s\x1b[0m" % self.tag)
        if self.attrs:
            p.text(" attrs=%s" % repr(list(self.attrs.items())))
        if self.children:
            p.text(" children=[")
            if len(self.children) == 1 and isinstance(self.first_child(), TextNode):
                p.text("\x1b[4m%s\x1b[0m" % repr(self.first_child()))
            else:
                with p.indent(2):
                    for child in self.children:
                        p.break_()
                        if hasattr(child, "_repr_pretty_"):
                            child._repr_pretty_(p, False)  # type: ignore
                        else:
                            p.text("\x1b[4m%s\x1b[0m" % repr(child))
                        p.text(",")
                p.break_()
            p.text("]")
        p.text(">")

    def __str__(self) -> str:
        """HTML representation of the node."""
        s = "<" + self.tag
        for attr, val in self.attrs.items():
            s += ' %s="%s"' % (attr, html.escape(val))
        if self.children:
            s += ">"
            s += "".join(str(child) for child in self.children)
            s += "</%s>" % self.tag
        else:
            if _tag_is_void(self.tag):
                s += "/>"
            else:
                s += "></%s>" % self.tag
        return s

    @property
    def text(self) -> str:
        """The concatenation of all descendant text nodes."""
        return "".join(child.text for child in self.children)


class TextNode(str, Node):
    """
    Represents a text node.

    Subclasses :class:`Node` and :class:`str`.
    """

    def __new__(cls, text: str) -> "TextNode":
        s = str.__new__(cls, text)  # type: ignore
        s.parent = None
        return s  # type: ignore

    def __init__(self, text: str) -> None:
        Node.__init__(self)

    def __repr__(self) -> str:
        return "<%s>" % str.__repr__(self)

    # HTML-escaped form of the text node. use text() for unescaped
    # version.
    def __str__(self) -> str:
        return html.escape(self)

    def __eq__(self, other: object) -> bool:
        """
        Two text nodes are equal if and only if they are the same node.

        For string comparison, use :attr:`text`.
        """
        return self is other

    def __ne__(self, other: object) -> bool:
        """
        Two text nodes are non-equal if they are not the same node.

        For string comparison, use :attr:`text`.
        """
        return self is not other

    @property
    def text(self) -> str:
        return str.__str__(self)


class DOMBuilderException(Exception):
    """
    Exception raised when :class:`DOMBuilder` detects a bad state.

    Attributes:
        pos (:class:`Tuple`\\[:class:`int`, :class:`int`]):
            Line number and offset in HTML input.
        why (:class:`str`):
            Reason of the exception.
    """

    def __init__(self, pos: Tuple[int, int], why: str) -> None:
        self.pos = pos
        self.why = why

    def __str__(self) -> str:  # pragma: no cover
        return "DOM builder aborted at %d:%d: %s" % (self.pos[0], self.pos[1], self.why)


class DOMBuilder(HTMLParser):
    """
    HTML parser / DOM builder.

    Subclasses :class:`html.parser.HTMLParser`.

    Consume HTML and builds a :class:`Node` tree. Once finished, use
    :attr:`root` to access the root of the tree.

    This parser cannot parse malformed HTML with tag mismatch.
    """

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        # _stack is the stack for nodes. Each node is pushed to the
        # stack when its start tag is processed, and remains on the
        # stack until its parent node is completed (end tag processed),
        # at which point the node is attached to the parent node as a
        # child and popped from the stack.
        self._stack = []  # type: List[Node]
        # _namespace_stack is another stack tracking the parsing
        # context, which is generally the default namespace (None) but
        # changes when parsing foreign objects (e.g. 'svg' when parsing
        # an <svg>). The top element is always the current parsing
        # context, so popping works differently from _stack: an element
        # is popped as soon as the corresponding end tag is processed.
        self._namespace_stack = [None]  # type: List[Optional[str]]

    def handle_starttag(
        self, tag: str, attrs: Sequence[Tuple[str, Optional[str]]]
    ) -> None:
        node = ElementNode(tag, attrs)
        node._partial = True
        self._stack.append(node)
        namespace = (
            tag.lower()
            if _tag_encloses_foreign_namespace(tag)
            else self._namespace_stack[-1]  # Inherit parent namespace
        )
        node._namespace = namespace
        self._namespace_stack.append(namespace)
        # For void elements (not in a foreign context), immediately
        # invoke the end tag handler (see handle_startendtag()).
        if not namespace and _tag_is_void(tag):
            self.handle_endtag(tag)

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        children = []
        while self._stack and not self._stack[-1]._partial:
            children.append(self._stack.pop())
        if not self._stack:
            raise DOMBuilderException(self.getpos(), "extra end tag: %s" % repr(tag))
        parent = self._stack[-1]
        if parent.tag != tag:
            raise DOMBuilderException(
                self.getpos(),
                "expecting end tag %s, got %s" % (repr(parent.tag), repr(tag)),
            )
        parent.children = list(reversed(children))
        parent._partial = False
        for child in children:
            child.parent = parent
        self._namespace_stack.pop()

    # Make parser behavior for explicitly and implicitly void elements
    # (e.g., <hr> vs <hr/>) consistent. The former triggers
    # handle_starttag only, whereas the latter triggers
    # handle_startendtag (which by default triggers both handle_starttag
    # and handle_endtag). See https://bugs.python.org/issue25258.
    #
    # An exception is foreign elements, which aren't considered void
    # elements but can be explicitly marked as self-closing according to
    # the HTML spec (e.g. <path/> is valid but <path> is not).
    # Therefore, both handle_starttag and handle_endtag must be called,
    # and handle_endtag should not be triggered from within
    # handle_starttag in that case.
    #
    # Note that for simplicity we do not check whether the foreign
    # element in question is allowed to be self-closing by spec. (The
    # SVG spec unfortunately doesn't provide a readily available list of
    # such elements.)
    #
    # https://html.spec.whatwg.org/multipage/syntax.html#foreign-elements
    def handle_startendtag(
        self, tag: str, attrs: Sequence[Tuple[str, Optional[str]]]
    ) -> None:
        if self._namespace_stack[-1] or _tag_encloses_foreign_namespace(tag):
            self.handle_starttag(tag, attrs)
            self.handle_endtag(tag)
        else:
            self.handle_starttag(tag, attrs)

    def handle_data(self, text: str) -> None:
        if not self._stack:
            # Ignore text nodes before the first tag.
            return
        self._stack.append(TextNode(text))

    @property
    def root(self) -> "Node":
        """
        Finishes processing and returns the root node.

        Raises :class:`DOMBuilderException` if there is no root tag or
        root tag is not closed yet.
        """
        if not self._stack:
            raise DOMBuilderException(self.getpos(), "no root tag")
        if self._stack[0]._partial:
            raise DOMBuilderException(self.getpos(), "root tag not closed yet")
        return self._stack[0]


def parse_html(html: str, *, ParserClass: type = DOMBuilder) -> "Node":
    """
    Parses HTML string, builds DOM, and returns root node.

    The parser may raise :class:`DOMBuilderException`.

    Args:
        html: input HTML string
        ParserClass: :class:`DOMBuilder` or a subclass

    Returns:
        Root note of the parsed tree. If the HTML string contains
        multiple top-level elements, only the first is returned and the
        rest are lost.
    """
    builder = ParserClass()  # type: DOMBuilder
    builder.feed(html)
    builder.close()
    return builder.root


class SelectorParserException(Exception):
    """
    Exception raised when the selector parser fails to parse an input.

    Attributes:
        s (:class:`str`):
            The input string to be parsed.
        cursor (:class:`int`):
            Cursor position where the failure occurred.
        why (:class:`str`):
            Reason of the failure.
    """

    def __init__(self, s: str, cursor: int, why: str) -> None:
        self.s = s
        self.cursor = cursor
        self.why = why

    def __str__(self) -> str:  # pragma: no cover
        return "selector parser aborted at character %d of %s: %s" % (
            self.cursor,
            repr(self.s),
            self.why,
        )


class SelectorGroup:
    """
    Represents a group of CSS selectors.

    A group of CSS selectors is simply a comma-separated list of
    selectors. [#]_ See :class:`Selector` documentation for the scope of
    support.

    Typically, a :class:`SelectorGroup` is constructed from a string
    (e.g., ``th.center, td.center``) using the factory function
    :meth:`from_str`.

    .. [#] https://www.w3.org/TR/selectors-3/#grouping
    """

    def __init__(self, selectors: Iterable["Selector"]) -> None:
        self._selectors = list(selectors)

    def __repr__(self) -> str:
        return "<SelectorGroup %s>" % repr(str(self))

    def __str__(self) -> str:
        return ", ".join(str(selector) for selector in self._selectors)

    def __len__(self) -> int:
        return len(self._selectors)

    def __getitem__(self, index: int) -> "Selector":
        return self._selectors[index]

    def __iter__(self) -> Iterator["Selector"]:
        return iter(self._selectors)

    @classmethod
    def from_str(cls, s: str) -> "SelectorGroup":
        """
        Parses input string into a group of selectors.

        :class:`SelectorParserException` is raised on invalid input. See
        :class:`Selector` documentation for the scope of support.

        Args:
            s: input string

        Returns:
            Parsed group of selectors.
        """
        i = 0
        selectors = []
        while i < len(s):
            selector, i = Selector.from_str(s, i)
            selectors.append(selector)
        if not selectors:
            raise SelectorParserException(s, i, "selector group is empty")
        return cls(selectors)

    def matches(self, node: "Node", root: Optional["Node"] = None) -> bool:
        """
        Decides whether the group of selectors matches `node`.

        The group of selectors matches `node` as long as one of the
        selectors matches `node`.

        If `root` is provided and child and/or descendant combinators
        are involved, parent/ancestor lookup terminates at `root`.
        """
        return any(selector.matches(node, root=root) for selector in self)


class Selector:
    """
    Represents a CSS selector.

    Recall that a CSS selector is a chain of one or more *sequences of
    simple selectors* separated by *combinators*. [#selectors-3]_ This
    concept is represented as a cons list of sequences of simple
    selectors (in right to left order). This class in fact holds a
    single sequence, with an optional combinator and reference to the
    previous sequence.

    For instance, ``main#main p.important.definition >
    a.term[id][href]`` would be parsed into (schematically) the
    following structure::

        ">" tag='a' classes=('term') attrs=([id], [href]) ~>
        " " tag='p' classes=('important', 'definition') ~>
        tag='main' id='main'

    Each line is held in a separate instance of :class:`Selector`,
    linked together by the :attr:`previous` attribute.

    Supported grammar (from selectors level 3 [#selectors-3]_):

    - Type selectors;
    - Universal selectors;
    - Class selectors;
    - ID selectors;
    - Attribute selectors;
    - Combinators.

    Unsupported grammar:

    - Pseudo-classes;
    - Pseudo-elements;
    - Namespace prefixes (``ns|``, ``*|``, ``|``) in any part of any
      selector.

    Rationale:

    - Pseudo-classes have too many variants, a few of which even
      complete with an admittedly not-so-complex minilanguage. These add
      up to a lot of code.
    - Pseudo-elements are useless outside rendering contexts, hence out of
      scope.
    - Namespace support is too niche to be worth the parsing headache.
      *Using namespace prefixes may confuse the parser!*

    Note that the parser only loosely follows the spec and priotizes
    ease of parsing (which includes readability and *writability* of
    regexes), so some invalid selectors may be accepted (in fact, false
    positives abound, but accepting valid inputs is a much more
    important goal than rejecting invalid inputs for this library), and
    some valid selectors may be rejected (but as long as you stick to
    the scope outlined above and common sense you should be fine; the
    false negatives shouldn't be used by actual human beings anyway).

    In particular, whitespace character is simplified to ``\\s`` (ASCII
    mode) despite CSS spec not counting U+000B (VT) as whitespace,
    identifiers are simplified to ``[\\w-]+`` (ASCII mode), and strings
    (attribute selector values can be either identifiers or strings)
    allow escaped quotes (i.e., ``\\'`` inside single-quoted strings and
    ``\\"`` inside double-quoted strings) but everything else is
    interpreted literally. The exact specs for CSS identifiers and
    strings can be found at [#]_.

    Certain selectors and combinators may be implemented in the parser
    but not implemented in matching and/or selection APIs.

    .. [#selectors-3] https://www.w3.org/TR/selectors-3/
    .. [#] https://www.w3.org/TR/CSS21/syndata.html

    Attributes:
        tag (:class:`Optional`\\[:class:`str`]):
            Type selector.
        classes (:class:`List`\\[:class:`str`]):
            Class selectors.
        id (:class:`Optional`\\[:class:`str`]):
            ID selector.
        attrs (:class:`List`\\[:class:`AttributeSelector`]):
            Attribute selectors.
        combinator (:class:`Optional`\\[:class:`Combinator`]):
            Combinator with the previous sequence of simple selectors in
            chain.
        previous (:class:`Optional`\\[:class:`Selector`]):
            Reference to the previous sequence of simple selectors in
            chain.

    """

    def __init__(
        self,
        *,
        tag: Optional[str] = None,
        classes: Optional[Sequence[str]] = None,
        id: Optional[str] = None,
        attrs: Optional[Sequence["AttributeSelector"]] = None,
        combinator: Optional["Combinator"] = None,
        previous: Optional["Selector"] = None
    ) -> None:
        self.tag = tag.lower() if tag else None
        self.classes = list(classes or [])
        self.id = id
        self.attrs = list(attrs or [])
        self.combinator = combinator
        self.previous = previous

    def __repr__(self) -> str:
        return "<Selector %s>" % repr(str(self))

    def __str__(self) -> str:
        sequences = []
        delimiters = []
        seq = self
        while True:
            sequences.append(seq._sequence_str_())
            if seq.previous:
                if seq.combinator == Combinator.DESCENDANT:
                    delimiters.append(" ")
                elif seq.combinator == Combinator.CHILD:
                    delimiters.append(" > ")
                elif seq.combinator == Combinator.NEXT_SIBLING:
                    delimiters.append(" + ")
                elif seq.combinator == Combinator.SUBSEQUENT_SIBLING:
                    delimiters.append(" ~ ")
                else:  # pragma: no cover
                    raise RuntimeError(
                        "unimplemented combinator: %s" % repr(self.combinator)
                    )
                seq = seq.previous
            else:
                delimiters.append("")
                break
        return "".join(
            delimiter + sequence
            for delimiter, sequence in zip(reversed(delimiters), reversed(sequences))
        )

    # Format a single sequence of simple selectors, without combinator.
    def _sequence_str_(self) -> str:
        s = ""
        if self.tag:
            s += self.tag
        if self.classes:
            s += "".join(".%s" % class_ for class_ in self.classes)
        if self.id:
            s += "#%s" % self.id
        if self.attrs:
            s += "".join(str(attr) for attr in self.attrs)
        return s if s else "*"

    @classmethod
    def from_str(cls, s: str, cursor: int = 0) -> Tuple["Selector", int]:
        """
        Parses input string into selector.

        This factory function only parses out one selector (up to a
        comma or EOS), so partial consumption is allowed --- an optional
        `cursor` is taken as input (0 by default) and the moved cursor
        (either after the comma or at EOS) is returned as part of the
        output.

        :class:`SelectorParserException` is raised on invalid input. See
        :class:`Selector` documentation for the scope of support.

        If you need to completely consume a string representing
        (potentially) a group of selectors, use
        :meth:`SelectorGroup.from_str()`.

        Args:
            s:      input string
            cursor: initial cursor position on `s`

        Returns:
            A tuple containing the parsed selector and the moved the
            cursor (either after a comma-delimiter, or at EOS).
        """
        # Simple selectors.
        TYPE_SEL = re.compile(r"[\w-]+", re.A)
        UNIVERSAL_SEL = re.compile(r"\*")
        ATTR_SEL = re.compile(
            r"""\[
            \s*(?P<attr>[\w-]+)\s*
            (
                (?P<op>[~|^$*]?=)\s*
                (
                    (?P<val_identifier>[\w-]+)|
                    (?P<val_string>
                        (?P<quote>['"])
                        (?P<val_string_inner>.*?)
                        (?<!\\)(?P=quote)
                    )
                )\s*
            )?
            \]""",
            re.A | re.X,
        )
        CLASS_SEL = re.compile(r"\.([\w-]+)", re.A)
        ID_SEL = re.compile(r"#([\w-]+)", re.A)
        PSEUDO_CLASS_SEL = re.compile(r":[\w-]+(\([^)]+\))?", re.A)
        PSEUDO_ELEM_SEL = re.compile(r"::[\w-]+", re.A)

        # Combinators
        DESCENDANT_COM = re.compile(r"\s+")
        CHILD_COM = re.compile(r"\s*>\s*")
        NEXT_SIB_COM = re.compile(r"\s*\+\s*")
        SUB_SIB_COM = re.compile(r"\s*~\s*")

        # Misc
        WHITESPACE = re.compile(r"\s*")
        END_OF_SELECTOR = re.compile(r"\s*($|,)")

        tag = None
        classes = []
        id = None
        attrs = []
        combinator = None

        selector = None
        previous_combinator = None

        i = cursor

        # Skip leading whitespace
        m = WHITESPACE.match(s, i)
        if m:
            i = m.end()

        while i < len(s):
            # Parse one simple selector.
            #
            # PEP 572 (assignment expressions; the one that burned Guido
            # so much that he resigned as BDFL) would have been nice; it
            # would have saved us from all the regex match
            # reassignments, and worse still, the casts, since mypy
            # complains about getting Optional[Match[str]] instead of
            # Match[str].
            if TYPE_SEL.match(s, i):
                if tag:
                    raise SelectorParserException(s, i, "multiple type selectors found")
                m = cast(Match[str], TYPE_SEL.match(s, i))
                tag = m.group()
            elif UNIVERSAL_SEL.match(s, i):
                m = cast(Match[str], UNIVERSAL_SEL.match(s, i))
            elif ATTR_SEL.match(s, i):
                m = cast(Match[str], ATTR_SEL.match(s, i))

                attr = m.group("attr")
                op = m.group("op")
                val_identifier = m.group("val_identifier")
                quote = m.group("quote")
                val_string_inner = m.group("val_string_inner")
                if val_identifier is not None:
                    val = val_identifier
                elif val_string_inner is not None:
                    val = val_string_inner.replace("\\" + quote, quote)
                else:
                    val = None

                if op is None:
                    type = AttributeSelectorType.BARE
                elif op == "=":
                    type = AttributeSelectorType.EQUAL
                elif op == "~=":
                    type = AttributeSelectorType.TILDE
                elif op == "|=":
                    type = AttributeSelectorType.PIPE
                elif op == "^=":
                    type = AttributeSelectorType.CARET
                elif op == "$=":
                    type = AttributeSelectorType.DOLLAR
                elif op == "*=":
                    type = AttributeSelectorType.ASTERISK
                else:  # pragma: no cover
                    raise SelectorParserException(
                        s,
                        i,
                        "unrecognized operator %s in attribute selector" % repr(op),
                    )

                attrs.append(AttributeSelector(attr, val, type))
            elif CLASS_SEL.match(s, i):
                m = cast(Match[str], CLASS_SEL.match(s, i))
                classes.append(m.group(1))
            elif ID_SEL.match(s, i):
                if id:
                    raise SelectorParserException(s, i, "multiple id selectors found")
                m = cast(Match[str], ID_SEL.match(s, i))
                id = m.group(1)
            elif PSEUDO_CLASS_SEL.match(s, i):
                raise SelectorParserException(s, i, "pseudo-classes not supported")
            elif PSEUDO_ELEM_SEL.match(s, i):
                raise SelectorParserException(s, i, "pseudo-elements not supported")
            else:
                raise SelectorParserException(
                    s, i, "expecting simple selector, found none"
                )
            i = m.end()

            # Try to parse a combinator, or end the selector.
            if CHILD_COM.match(s, i):
                m = cast(Match[str], CHILD_COM.match(s, i))
                combinator = Combinator.CHILD
            elif NEXT_SIB_COM.match(s, i):
                m = cast(Match[str], NEXT_SIB_COM.match(s, i))
                combinator = Combinator.NEXT_SIBLING
            elif SUB_SIB_COM.match(s, i):
                m = cast(Match[str], SUB_SIB_COM.match(s, i))
                combinator = Combinator.SUBSEQUENT_SIBLING
            elif END_OF_SELECTOR.match(s, i):
                m = cast(Match[str], END_OF_SELECTOR.match(s, i))
                combinator = None
            # Need to parse descendant combinator at the very end
            # because it could be a prefix to all previous cases.
            elif DESCENDANT_COM.match(s, i):
                m = cast(Match[str], DESCENDANT_COM.match(s, i))
                combinator = Combinator.DESCENDANT
            else:
                continue
            i = m.end()

            if combinator and i == len(s):
                raise SelectorParserException(s, i, "unexpected end at combinator")

            selector = cls(
                tag=tag,
                classes=classes,
                id=id,
                attrs=attrs,
                combinator=previous_combinator,
                previous=selector,
            )
            previous_combinator = combinator

            # End of selector.
            if combinator is None:
                break

            tag = None
            classes = []
            id = None
            attrs = []
            combinator = None

        if not selector:
            raise SelectorParserException(s, i, "selector is empty")

        return selector, i

    def matches(self, node: "Node", root: Optional["Node"] = None) -> bool:
        """
        Decides whether the selector matches `node`.

        Each sequence of simple selectors in the selector's chain must
        be matched for a positive.

        If `root` is provided and child and/or descendant combinators
        are involved, parent/ancestor lookup terminates at `root`.
        """
        if self.tag:
            if not node.tag or node.tag != self.tag:
                return False
        if self.id:
            if node.attrs.get("id") != self.id:
                return False
        if self.classes:
            classes = node.classes
            for class_ in self.classes:
                if class_ not in classes:
                    return False
        if self.attrs:
            for attr_selector in self.attrs:
                if not attr_selector.matches(node):
                    return False

        if not self.previous:
            return True

        if self.combinator == Combinator.DESCENDANT:
            return any(
                self.previous.matches(ancestor, root=root)
                for ancestor in node.ancestors()
            )
        elif self.combinator == Combinator.CHILD:
            if node is root or node.parent is None:
                return False
            else:
                return self.previous.matches(node.parent)
        elif self.combinator == Combinator.NEXT_SIBLING:
            sibling = node.previous_element_sibling()
            if not sibling:
                return False
            else:
                return self.previous.matches(sibling)
        elif self.combinator == Combinator.SUBSEQUENT_SIBLING:
            return any(
                self.previous.matches(sibling, root=root)
                for sibling in node.previous_siblings()
                if isinstance(sibling, ElementNode)
            )
        else:  # pragma: no cover
            raise RuntimeError("unimplemented combinator: %s" % repr(self.combinator))


class AttributeSelector:
    """
    Represents an attribute selector.

    Attributes:
        attr (:class:`str`)
        val  (:class:`Optional`\\[:class:`str`])
        type (:class:`AttributeSelectorType`)
    """

    def __init__(
        self, attr: str, val: Optional[str], type: "AttributeSelectorType"
    ) -> None:
        self.attr = attr.lower()
        self.val = val
        self.type = type

    def __repr__(self) -> str:
        return "<AttributeSelector %s>" % repr(str(self))

    def __str__(self) -> str:
        if self.type == AttributeSelectorType.BARE:
            fmt = "[{attr}{val:.0}]"
        elif self.type == AttributeSelectorType.EQUAL:
            fmt = "[{attr}={val}]"
        elif self.type == AttributeSelectorType.TILDE:
            fmt = "[{attr}~={val}]"
        elif self.type == AttributeSelectorType.PIPE:
            fmt = "[{attr}|={val}]"
        elif self.type == AttributeSelectorType.CARET:
            fmt = "[{attr}^={val}]"
        elif self.type == AttributeSelectorType.DOLLAR:
            fmt = "[{attr}$={val}]"
        elif self.type == AttributeSelectorType.ASTERISK:
            fmt = "[{attr}*={val}]"
        return fmt.format(attr=self.attr, val=repr(self.val))

    def matches(self, node: "Node") -> bool:
        val = node.attrs.get(self.attr)
        if val is None:
            return False
        if self.type == AttributeSelectorType.BARE:
            return True
        elif self.type == AttributeSelectorType.EQUAL:
            return val == self.val
        elif self.type == AttributeSelectorType.TILDE:
            return self.val in val.split()
        elif self.type == AttributeSelectorType.PIPE:
            return val == self.val or val.startswith("%s-" % self.val)
        elif self.type == AttributeSelectorType.CARET:
            return bool(self.val and val.startswith(self.val))
        elif self.type == AttributeSelectorType.DOLLAR:
            return bool(self.val and val.endswith(self.val))
        elif self.type == AttributeSelectorType.ASTERISK:
            return bool(self.val and self.val in val)
        else:  # pragma: no cover
            raise RuntimeError("unimplemented attribute selector: %s" % repr(self.type))


# Enum: basis for poor man's algebraic data type.
class AttributeSelectorType(Enum):
    """
    Attribute selector types.

    Members correspond to the following forms of attribute selector:

    - :attr:`BARE`: ``[attr]``;
    - :attr:`EQUAL`: ``[attr=val]``;
    - :attr:`TILDE`: ``[attr~=val]``;
    - :attr:`PIPE`: ``[attr|=val]``;
    - :attr:`CARET`: ``[attr^=val]``;
    - :attr:`DOLLAR`: ``[attr$=val]``;
    - :attr:`ASTERISK`: ``[attr*=val]``.
    """

    # [attr]
    BARE = 1
    # [attr=val]
    EQUAL = 2
    # [attr~=val]
    TILDE = 3
    # [attr|=val]
    PIPE = 4
    # [attr^=val]
    CARET = 5
    # [attr$=val]
    DOLLAR = 6
    # [attr*=val]
    ASTERISK = 7


class Combinator(Enum):
    """
    Combinator types.

    Members correspond to the following combinators:

    - :attr:`DESCENDANT`: ``A B``;
    - :attr:`CHILD`: ``A > B``;
    - :attr:`NEXT_SIBLING`: ``A + B``;
    - :attr:`SUBSEQUENT_SIBLING`: ``A ~ B``.
    """

    # ' '
    DESCENDANT = 1
    # >
    CHILD = 2
    # +
    NEXT_SIBLING = 3
    # ~
    SUBSEQUENT_SIBLING = 4


def _tag_is_void(tag: str) -> bool:
    """
    Checks whether the tag corresponds to a void element.

    https://www.w3.org/TR/html5/syntax.html#void-elements
    https://html.spec.whatwg.org/multipage/syntax.html#void-elements
    """
    return tag.lower() in (
        "area",
        "base",
        "br",
        "col",
        "embed",
        "hr",
        "img",
        "input",
        "link",
        "meta",
        "param",
        "source",
        "track",
        "wbr",
    )


def _tag_encloses_foreign_namespace(tag: str) -> bool:
    """
    Checks whether the tag encloses a foreign namespace (MathML or SVG).

    https://html.spec.whatwg.org/multipage/syntax.html#foreign-elements
    """
    return tag.lower() in ("math", "svg")


### end dim ###


# Global helper functions

def open_url(url):
    """Open an URL in the user's default web browser.

    The string attribute ``open_url.url_handler`` can be used to open URLs
    in a custom CLI script or utility. A subprocess is spawned with url as
    the parameter in this case instead of the usual webbrowser.open() call.

    Whether the browser's output (both stdout and stderr) are suppressed
    depends on the boolean attribute ``open_url.suppress_browser_output``.
    If the attribute is not set upon a call, set it to a default value,
    which means False if BROWSER is set to a known text-based browser --
    elinks, links, lynx, w3m or 'www-browser'; or True otherwise.

    The string attribute ``open_url.override_text_browser`` can be used to
    ignore env var BROWSER as well as some known text-based browsers and
    attempt to open url in a GUI browser available.
    Note: If a GUI browser is indeed found, this option ignores the program
          option `show-browser-logs`
    """
    logger.debug('Opening %s', url)

    # Custom URL handler gets max priority
    if hasattr(open_url, 'url_handler'):
        subprocess.run([open_url.url_handler, url])
        return

    browser = webbrowser.get()
    if open_url.override_text_browser:
        browser_output = open_url.suppress_browser_output
        for name in [b for b in webbrowser._tryorder if b not in text_browsers]:
            browser = webbrowser.get(name)
            logger.debug(browser)

            # Found a GUI browser, suppress browser output
            open_url.suppress_browser_output = True
            break

    if open_url.suppress_browser_output:
        _stderr = os.dup(2)
        os.close(2)
        _stdout = os.dup(1)
        # Patch for GUI browsers on WSL
        if "microsoft" not in platform.uname()[3].lower():
            os.close(1)
        fd = os.open(os.devnull, os.O_RDWR)
        os.dup2(fd, 2)
        os.dup2(fd, 1)
    try:
        browser.open(url, new=2)
    finally:
        if open_url.suppress_browser_output:
            os.close(fd)
            os.dup2(_stderr, 2)
            os.dup2(_stdout, 1)

    if open_url.override_text_browser:
        open_url.suppress_browser_output = browser_output


def printerr(msg):
    """Print message, verbatim, to stderr.

    ``msg`` could be any stringifiable value.
    """
    print(msg, file=sys.stderr)


def unwrap(text):
    """Unwrap text."""
    lines = text.split('\n')
    result = ''
    for i in range(len(lines) - 1):
        result += lines[i]
        if not lines[i]:
            # Paragraph break
            result += '\n\n'
        elif lines[i + 1]:
            # Next line is not paragraph break, add space
            result += ' '
    # Handle last line
    result += lines[-1] if lines[-1] else '\n'
    return result


def check_stdout_encoding():
    """Make sure stdout encoding is utf-8.

    If not, print error message and instructions, then exit with
    status 1.

    This function is a no-op on win32 because encoding on win32 is
    messy, and let's just hope for the best. /s
    """
    if sys.platform == 'win32':
        return

    # Use codecs.lookup to resolve text encoding alias
    encoding = codecs.lookup(sys.stdout.encoding).name
    if encoding != 'utf-8':
        locale_lang, locale_encoding = locale.getlocale()
        if locale_lang is None:
            locale_lang = '<unknown>'
        if locale_encoding is None:
            locale_encoding = '<unknown>'
        ioencoding = os.getenv('PYTHONIOENCODING', 'not set')
        sys.stderr.write(unwrap(textwrap.dedent("""\
        stdout encoding '{encoding}' detected. googler requires utf-8 to
        work properly. The wrong encoding may be due to a non-UTF-8
        locale or an improper PYTHONIOENCODING. (For the record, your
        locale language is {locale_lang} and locale encoding is
        {locale_encoding}; your PYTHONIOENCODING is {ioencoding}.)

        Please set a UTF-8 locale (e.g., en_US.UTF-8) or set
        PYTHONIOENCODING to utf-8.
        """.format(
            encoding=encoding,
            locale_lang=locale_lang,
            locale_encoding=locale_encoding,
            ioencoding=ioencoding,
        ))))
        sys.exit(1)


def time_it(description=None):
    def decorator(func):
        @functools.wraps(func)
        def wrapped(*args, **kwargs):
            # Only profile in debug mode.
            if not logger.isEnabledFor(logging.DEBUG):
                return func(*args, **kwargs)

            import time
            mark = time.perf_counter()
            ret = func(*args, **kwargs)
            duration = time.perf_counter() - mark
            logger.debug('%s completed in \x1b[33m%.3fs\x1b[0m', description or func.__name__, duration)
            return ret

        return wrapped

    return decorator


# Classes

class HardenedHTTPSConnection(HTTPSConnection):
    """Overrides HTTPSConnection.connect to specify TLS version

    NOTE: TLS 1.2 is supported from Python 3.4
    """

    def __init__(self, host, address_family=0, **kwargs):
        HTTPSConnection.__init__(self, host, **kwargs)
        self.address_family = address_family

    def connect(self, notweak=False):
        sock = self.create_socket_connection()

        # Optimizations not available on OS X
        if not notweak and sys.platform.startswith('linux'):
            try:
                sock.setsockopt(socket.SOL_TCP, socket.TCP_DEFER_ACCEPT, 1)
                sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_QUICKACK, 1)
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 524288)
            except OSError:
                # Doesn't work on Windows' Linux subsystem (#179)
                logger.debug('setsockopt failed')

        if getattr(self, '_tunnel_host', None):
            self.sock = sock
        elif not notweak:
            # Try to use TLS 1.2
            ssl_context = None
            if hasattr(ssl, 'PROTOCOL_TLS'):
                # Since Python 3.5.3
                ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS)
                if hasattr(ssl_context, "minimum_version"):
                    # Python 3.7 with OpenSSL 1.1.0g or later
                    ssl_context.minimum_version = ssl.TLSVersion.TLSv1_2
                else:
                    ssl_context.options |= (ssl.OP_NO_SSLv2 | ssl.OP_NO_SSLv3 |
                                            ssl.OP_NO_TLSv1 | ssl.OP_NO_TLSv1_1)
            elif hasattr(ssl, 'PROTOCOL_TLSv1_2'):
                # Since Python 3.4
                ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
            if ssl_context:
                self.sock = ssl_context.wrap_socket(sock)
                return

        # Fallback
        HTTPSConnection.connect(self)

    # Adapted from socket.create_connection.
    # https://github.com/python/cpython/blob/bce4ddafdd188cc6deb1584728b67b9e149ca6a4/Lib/socket.py#L771-L813
    def create_socket_connection(self):
        err = None
        results = socket.getaddrinfo(self.host, self.port, self.address_family, socket.SOCK_STREAM)
        # Prefer IPv4 if address family isn't explicitly specified.
        if self.address_family == 0:
            results = sorted(results, key=lambda res: 1 if res[0] == socket.AF_INET else 2)
        for af, socktype, proto, canonname, sa in results:
            sock = None
            try:
                sock = socket.socket(af, socktype, proto)
                if self.timeout is not None:
                    sock.settimeout(self.timeout)
                if self.source_address:
                    sock.bind(self.source_address)
                sock.connect(sa)
                # Break explicitly a reference cycle
                err = None
                self.address_family = af
                logger.debug('Opened socket to %s:%d',
                             sa[0] if af == socket.AF_INET else ('[%s]' % sa[0]),
                             sa[1])
                return sock

            except socket.error as _:
                err = _
                if sock is not None:
                    sock.close()

        if err is not None:
            try:
                raise err
            finally:
                # Break explicitly a reference cycle
                err = None
        else:
            raise socket.error("getaddrinfo returns an empty list")


class GoogleUrl(object):
    """
    This class constructs the Google Search/News URL.

    This class is modelled on urllib.parse.ParseResult for familiarity,
    which means it supports reading of all six attributes -- scheme,
    netloc, path, params, query, fragment -- of
    urllib.parse.ParseResult, as well as the geturl() method.

    However, the attributes (properties) and methods listed below should
    be the preferred methods of access to this class.

    Parameters
    ----------
    opts : dict or argparse.Namespace, optional
        See the ``opts`` parameter of `update`.

    Other Parameters
    ----------------
    See "Other Parameters" of `update`.

    Attributes
    ----------
    hostname : str
        Read-write property.
    keywords : str or list of strs
        Read-write property.
    news : bool
        Read-only property.
    videos : bool
        Read-only property.
    url : str
        Read-only property.

    Methods
    -------
    full()
    relative()
    update(opts=None, **kwargs)
    set_queries(**kwargs)
    unset_queries(*args)
    next_page()
    prev_page()
    first_page()

    """

    def __init__(self, opts=None, **kwargs):
        self.scheme = 'https'
        # self.netloc is a calculated property
        self.path = '/search'
        self.params = ''
        # self.query is a calculated property
        self.fragment = ''

        self._tld = None
        self._num = 10
        self._start = 0
        self._keywords = []
        self._sites = None
        self._exclude = None

        self._query_dict = {
            'ie': 'UTF-8',
            'oe': 'UTF-8',
            #'gbv': '1',  # control the presence of javascript on the page, 1=no js, 2=js
            'sei': base64.encodebytes(uuid.uuid4().bytes).decode("ascii").rstrip('=\n').replace('/', '_'),
        }

        # In preloaded HTML parsing mode, set keywords to something so
        # that we are not tripped up by require_keywords.
        if opts.html_file and not opts.keywords:
            opts.keywords = ['<debug>']

        self.update(opts, **kwargs)

    def __str__(self):
        return self.url

    @property
    def url(self):
        """The full Google URL you want."""
        return self.full()

    @property
    def hostname(self):
        """The hostname."""
        return self.netloc

    @hostname.setter
    def hostname(self, hostname):
        self.netloc = hostname

    @property
    def keywords(self):
        """The keywords, either a str or a list of strs."""
        return self._keywords

    @keywords.setter
    def keywords(self, keywords):
        self._keywords = keywords

    @property
    def news(self):
        """Whether the URL is for Google News."""
        return 'tbm' in self._query_dict and self._query_dict['tbm'] == 'nws'

    @property
    def videos(self):
        """Whether the URL is for Google Videos."""
        return 'tbm' in self._query_dict and self._query_dict['tbm'] == 'vid'

    def full(self):
        """Return the full URL.

        Returns
        -------
        str

        """
        url = (self.scheme + ':') if self.scheme else ''
        url += '//' + self.netloc + self.relative()
        return url

    def relative(self):
        """Return the relative URL (without scheme and authority).

        Authority (see RFC 3986 section 3.2), or netloc in the
        terminology of urllib.parse, basically means the hostname
        here. The relative URL is good for making HTTP(S) requests to a
        known host.

        Returns
        -------
        str

        """
        rel = self.path
        if self.params:
            rel += ';' + self.params
        if self.query:
            rel += '?' + self.query
        if self.fragment:
            rel += '#' + self.fragment
        return rel

    def update(self, opts=None, **kwargs):
        """Update the URL with the given options.

        Parameters
        ----------
        opts : dict or argparse.Namespace, optional
            Carries options that affect the Google Search/News URL. The
            list of currently recognized option keys with expected value
            types:

                duration: str (GooglerArgumentParser.is_duration)
                exact: bool
                keywords: str or list of strs
                lang: str
                news: bool
                videos: bool
                num: int
                site: str
                start: int
                tld: str
                unfilter: bool

        Other Parameters
        ----------------
        kwargs
            The `kwargs` dict extends `opts`, that is, options can be
            specified either way, in `opts` or as individual keyword
            arguments.

        """

        if opts is None:
            opts = {}
        if hasattr(opts, '__dict__'):
            opts = opts.__dict__
        opts.update(kwargs)

        qd = self._query_dict
        if opts.get('duration'):
            qd['tbs'] = 'qdr:%s' % opts['duration']
        if 'exact' in opts:
            if opts['exact']:
                qd['nfpr'] = 1
            else:
                qd.pop('nfpr', None)
        if opts.get('from') or opts.get('to'):
            cd_min = opts.get('from') or ''
            cd_max = opts.get('to') or ''
            qd['tbs'] = 'cdr:1,cd_min:%s,cd_max:%s' % (cd_min, cd_max)
        if 'keywords' in opts:
            self._keywords = opts['keywords']
        if 'lang' in opts and opts['lang']:
            qd['hl'] = opts['lang']
        if 'geoloc' in opts and opts['geoloc']:
            qd['gl'] = opts['geoloc']
        if 'news' in opts and opts['news']:
            qd['tbm'] = 'nws'
        elif 'videos' in opts and opts['videos']:
            qd['tbm'] = 'vid'
        else:
            qd.pop('tbm', None)
        if 'num' in opts:
            self._num = opts['num']
        if 'sites' in opts:
            self._sites = opts['sites']
        if 'exclude' in opts:
            self._exclude = opts['exclude']
        if 'start' in opts:
            self._start = opts['start']
        if 'tld' in opts:
            self._tld = opts['tld']
        if 'unfilter' in opts and opts['unfilter']:
            qd['filter'] = 0

    def set_queries(self, **kwargs):
        """Forcefully set queries outside the normal `update` mechanism.

        Other Parameters
        ----------------
        kwargs
            Arbitrary key value pairs to be set in the query string. All
            keys and values should be stringifiable.

            Note that certain keys, e.g., ``q``, have their values
            constructed on the fly, so setting those has no actual
            effect.

        """
        for k, v in kwargs.items():
            self._query_dict[k] = v

    def unset_queries(self, *args):
        """Forcefully unset queries outside the normal `update` mechanism.

        Other Parameters
        ----------------
        args
            Arbitrary keys to be unset. No exception is raised if a key
            does not exist in the first place.

            Note that certain keys, e.g., ``q``, are always included in
            the resulting URL, so unsetting those has no actual effect.

        """
        for k in args:
            self._query_dict.pop(k, None)

    def next_page(self):
        """Navigate to the next page."""
        self._start += self._num

    def prev_page(self):
        """Navigate to the previous page.

        Raises
        ------
        ValueError
            If already at the first page (``start=0`` in the current
            query string).

        """
        if self._start == 0:
            raise ValueError('Already at the first page.')
        self._start = (self._start - self._num) if self._start > self._num else 0

    def first_page(self):
        """Navigate to the first page.

        Raises
        ------
        ValueError
            If already at the first page (``start=0`` in the current
            query string).

        """
        if self._start == 0:
            raise ValueError('Already at the first page.')
        self._start = 0

    # Data source: https://web.archive.org/web/20170615200243/https://en.wikipedia.org/wiki/List_of_Google_domains
    # Scraper script: https://gist.github.com/zmwangx/b976e83c14552fe18b71
    TLD_TO_DOMAIN_MAP = {
        'ac': 'google.ac',      'ad': 'google.ad',      'ae': 'google.ae',
        'af': 'google.com.af',  'ag': 'google.com.ag',  'ai': 'google.com.ai',
        'al': 'google.al',      'am': 'google.am',      'ao': 'google.co.ao',
        'ar': 'google.com.ar',  'as': 'google.as',      'at': 'google.at',
        'au': 'google.com.au',  'az': 'google.az',      'ba': 'google.ba',
        'bd': 'google.com.bd',  'be': 'google.be',      'bf': 'google.bf',
        'bg': 'google.bg',      'bh': 'google.com.bh',  'bi': 'google.bi',
        'bj': 'google.bj',      'bn': 'google.com.bn',  'bo': 'google.com.bo',
        'br': 'google.com.br',  'bs': 'google.bs',      'bt': 'google.bt',
        'bw': 'google.co.bw',   'by': 'google.by',      'bz': 'google.com.bz',
        'ca': 'google.ca',      'cat': 'google.cat',    'cc': 'google.cc',
        'cd': 'google.cd',      'cf': 'google.cf',      'cg': 'google.cg',
        'ch': 'google.ch',      'ci': 'google.ci',      'ck': 'google.co.ck',
        'cl': 'google.cl',      'cm': 'google.cm',      'cn': 'google.cn',
        'co': 'google.com.co',  'cr': 'google.co.cr',   'cu': 'google.com.cu',
        'cv': 'google.cv',      'cy': 'google.com.cy',  'cz': 'google.cz',
        'de': 'google.de',      'dj': 'google.dj',      'dk': 'google.dk',
        'dm': 'google.dm',      'do': 'google.com.do',  'dz': 'google.dz',
        'ec': 'google.com.ec',  'ee': 'google.ee',      'eg': 'google.com.eg',
        'es': 'google.es',      'et': 'google.com.et',  'fi': 'google.fi',
        'fj': 'google.com.fj',  'fm': 'google.fm',      'fr': 'google.fr',
        'ga': 'google.ga',      'ge': 'google.ge',      'gf': 'google.gf',
        'gg': 'google.gg',      'gh': 'google.com.gh',  'gi': 'google.com.gi',
        'gl': 'google.gl',      'gm': 'google.gm',      'gp': 'google.gp',
        'gr': 'google.gr',      'gt': 'google.com.gt',  'gy': 'google.gy',
        'hk': 'google.com.hk',  'hn': 'google.hn',      'hr': 'google.hr',
        'ht': 'google.ht',      'hu': 'google.hu',      'id': 'google.co.id',
        'ie': 'google.ie',      'il': 'google.co.il',   'im': 'google.im',
        'in': 'google.co.in',   'io': 'google.io',      'iq': 'google.iq',
        'is': 'google.is',      'it': 'google.it',      'je': 'google.je',
        'jm': 'google.com.jm',  'jo': 'google.jo',      'jp': 'google.co.jp',
        'ke': 'google.co.ke',   'kg': 'google.kg',      'kh': 'google.com.kh',
        'ki': 'google.ki',      'kr': 'google.co.kr',   'kw': 'google.com.kw',
        'kz': 'google.kz',      'la': 'google.la',      'lb': 'google.com.lb',
        'lc': 'google.com.lc',  'li': 'google.li',      'lk': 'google.lk',
        'ls': 'google.co.ls',   'lt': 'google.lt',      'lu': 'google.lu',
        'lv': 'google.lv',      'ly': 'google.com.ly',  'ma': 'google.co.ma',
        'md': 'google.md',      'me': 'google.me',      'mg': 'google.mg',
        'mk': 'google.mk',      'ml': 'google.ml',      'mm': 'google.com.mm',
        'mn': 'google.mn',      'ms': 'google.ms',      'mt': 'google.com.mt',
        'mu': 'google.mu',      'mv': 'google.mv',      'mw': 'google.mw',
        'mx': 'google.com.mx',  'my': 'google.com.my',  'mz': 'google.co.mz',
        'na': 'google.com.na',  'ne': 'google.ne',      'nf': 'google.com.nf',
        'ng': 'google.com.ng',  'ni': 'google.com.ni',  'nl': 'google.nl',
        'no': 'google.no',      'np': 'google.com.np',  'nr': 'google.nr',
        'nu': 'google.nu',      'nz': 'google.co.nz',   'om': 'google.com.om',
        'pa': 'google.com.pa',  'pe': 'google.com.pe',  'pg': 'google.com.pg',
        'ph': 'google.com.ph',  'pk': 'google.com.pk',  'pl': 'google.pl',
        'pn': 'google.co.pn',   'pr': 'google.com.pr',  'ps': 'google.ps',
        'pt': 'google.pt',      'py': 'google.com.py',  'qa': 'google.com.qa',
        'ro': 'google.ro',      'rs': 'google.rs',      'ru': 'google.ru',
        'rw': 'google.rw',      'sa': 'google.com.sa',  'sb': 'google.com.sb',
        'sc': 'google.sc',      'se': 'google.se',      'sg': 'google.com.sg',
        'sh': 'google.sh',      'si': 'google.si',      'sk': 'google.sk',
        'sl': 'google.com.sl',  'sm': 'google.sm',      'sn': 'google.sn',
        'so': 'google.so',      'sr': 'google.sr',      'st': 'google.st',
        'sv': 'google.com.sv',  'td': 'google.td',      'tg': 'google.tg',
        'th': 'google.co.th',   'tj': 'google.com.tj',  'tk': 'google.tk',
        'tl': 'google.tl',      'tm': 'google.tm',      'tn': 'google.tn',
        'to': 'google.to',      'tr': 'google.com.tr',  'tt': 'google.tt',
        'tw': 'google.com.tw',  'tz': 'google.co.tz',   'ua': 'google.com.ua',
        'ug': 'google.co.ug',   'uk': 'google.co.uk',   'uy': 'google.com.uy',
        'uz': 'google.co.uz',   'vc': 'google.com.vc',  've': 'google.co.ve',
        'vg': 'google.vg',      'vi': 'google.co.vi',   'vn': 'google.com.vn',
        'vu': 'google.vu',      'ws': 'google.ws',      'za': 'google.co.za',
        'zm': 'google.co.zm',   'zw': 'google.co.zw',
    }

    @property
    def netloc(self):
        """The hostname."""
        try:
            return 'www.' + self.TLD_TO_DOMAIN_MAP[self._tld]
        except KeyError:
            return 'www.google.com'

    @property
    def query(self):
        """The query string."""
        qd = {}
        qd.update(self._query_dict)
        if self._num != 10:  # Skip sending the default
            qd['num'] = self._num
        if self._start:  # Skip sending the default
            qd['start'] = self._start

        # Construct the q query
        q = ''
        keywords = self._keywords
        sites = self._sites
        exclude = self._exclude
        if keywords:
            if isinstance(keywords, list):
                q += '+'.join(urllib.parse.quote_plus(kw) for kw in keywords)
            else:
                q += urllib.parse.quote_plus(keywords)
        if sites:
            q += '+OR'.join('+site:' + urllib.parse.quote_plus(site) for site in sites)
        if exclude:
            q += ''.join('+-site:' + urllib.parse.quote_plus(e) for e in exclude)
        qd['q'] = q
        return '&'.join('%s=%s' % (k, qd[k]) for k in sorted(qd.keys()))


class GoogleConnectionError(Exception):
    pass


class GoogleConnection(object):
    """
    This class facilitates connecting to and fetching from Google.

    Parameters
    ----------
    See http.client.HTTPSConnection for documentation of the
    parameters.

    Raises
    ------
    GoogleConnectionError

    Attributes
    ----------
    host : str
        The currently connected host. Read-only property. Use
        `new_connection` to change host.

    Methods
    -------
    new_connection(host=None, port=None, timeout=45)
    renew_connection(timeout=45)
    fetch_page(url)
    close()

    """

    def __init__(self, host, port=None, address_family=0, timeout=45, proxy=None, notweak=False):
        self._host = None
        self._port = None
        self._address_family = address_family
        self._proxy = proxy
        self._notweak = notweak
        self._conn = None
        self.new_connection(host, port=port, timeout=timeout)
        self.cookie = ''

    @property
    def host(self):
        """The host currently connected to."""
        return self._host

    @time_it()
    def new_connection(self, host=None, port=None, timeout=45):
        """Close the current connection (if any) and establish a new one.

        Parameters
        ----------
        See http.client.HTTPSConnection for documentation of the
        parameters. Renew the connection (i.e., reuse the current host
        and port) if host is None or empty.

        Raises
        ------
        GoogleConnectionError

        """
        if self._conn:
            self._conn.close()

        if not host:
            host = self._host
            port = self._port
        self._host = host
        self._port = port
        host_display = host + (':%d' % port if port else '')

        proxy = self._proxy

        if proxy:
            proxy_user_passwd, proxy_host_port = parse_proxy_spec(proxy)

            logger.debug('Connecting to proxy server %s', proxy_host_port)
            self._conn = HardenedHTTPSConnection(proxy_host_port,
                                                 address_family=self._address_family, timeout=timeout)

            logger.debug('Tunnelling to host %s' % host_display)
            connect_headers = {}
            if proxy_user_passwd:
                connect_headers['Proxy-Authorization'] = 'Basic %s' % base64.b64encode(
                    proxy_user_passwd.encode('utf-8')
                ).decode('utf-8')
            self._conn.set_tunnel(host, port=port, headers=connect_headers)

            try:
                self._conn.connect(self._notweak)
            except Exception as e:
                msg = 'Failed to connect to proxy server %s: %s.' % (proxy, e)
                raise GoogleConnectionError(msg)
        else:
            logger.debug('Connecting to new host %s', host_display)
            self._conn = HardenedHTTPSConnection(host, port=port,
                                                 address_family=self._address_family, timeout=timeout)
            try:
                self._conn.connect(self._notweak)
            except Exception as e:
                msg = 'Failed to connect to %s: %s.' % (host_display, e)
                raise GoogleConnectionError(msg)

    def renew_connection(self, timeout=45):
        """Renew current connection.

        Equivalent to ``new_connection(timeout=timeout)``.

        """
        self.new_connection(timeout=timeout)

    @time_it()
    def fetch_page(self, url):
        """Fetch a URL.

        Allows one reconnection and multiple redirections before failing
        and raising GoogleConnectionError.

        Parameters
        ----------
        url : str
            The URL to fetch, relative to the host.

        Raises
        ------
        GoogleConnectionError
            When not getting HTTP 200 even after the allowed one
            reconnection and/or one redirection, or when Google is
            blocking query due to unusual activity.

        Returns
        -------
        str
            Response payload, gunzipped (if applicable) and decoded (in UTF-8).

        """
        try:
            self._raw_get(url)
        except (http.client.HTTPException, OSError) as e:
            logger.debug('Got exception: %s.', e)
            logger.debug('Attempting to reconnect...')
            self.renew_connection()
            try:
                self._raw_get(url)
            except http.client.HTTPException as e:
                logger.debug('Got exception: %s.', e)
                raise GoogleConnectionError("Failed to get '%s'." % url)

        resp = self._resp
        redirect_counter = 0
        while resp.status != 200 and redirect_counter < 3:
            if resp.status in {301, 302, 303, 307, 308}:
                redirection_url = resp.getheader('location', '')
                if 'sorry/IndexRedirect?' in redirection_url or 'sorry/index?' in redirection_url:
                    msg = "Connection blocked due to unusual activity.\n"
                    if self._conn.address_family == socket.AF_INET6:
                        msg += textwrap.dedent("""\
                        You are connecting over IPv6 which is likely the problem. Try to make
                        sure the machine has a working IPv4 network interface configured.
                        See also the -4, --ipv4 option of googler.\n""")
                    msg += textwrap.dedent("""\
                    THIS IS NOT A BUG, please do NOT report it as a bug unless you have specific
                    information that may lead to the development of a workaround.
                    You IP address is temporarily or permanently blocked by Google and requires
                    reCAPTCHA-solving to use the service, which googler is not capable of.
                    Possible causes include issuing too many queries in a short time frame, or
                    operating from a shared / low reputation IP with a history of abuse.
                    Please do NOT use googler for automated scraping.""")
                    msg = " ".join(msg.splitlines())
                    raise GoogleConnectionError(msg)
                self._redirect(redirection_url)
                resp = self._resp
                redirect_counter += 1
            else:
                break

        if resp.status != 200:
            raise GoogleConnectionError('Got HTTP %d: %s' % (resp.status, resp.reason))

        payload = resp.read()
        try:
            return gzip.decompress(payload).decode('utf-8')
        except OSError:
            # Not gzipped
            return payload.decode('utf-8')

    def _redirect(self, url):
        """Redirect to and fetch a new URL.

        Like `_raw_get`, the response is stored in ``self._resp``. A new
        connection is made if redirecting to a different host.

        Parameters
        ----------
        url : str
            If absolute and points to a different host, make a new
            connection.

        Raises
        ------
        GoogleConnectionError

        """
        logger.debug('Redirecting to URL %s', url)
        segments = urllib.parse.urlparse(url)

        host = segments.netloc
        if host != self._host:
            self.new_connection(host)

        relurl = urllib.parse.urlunparse(('', '') + segments[2:])
        try:
            self._raw_get(relurl)
        except http.client.HTTPException as e:
            logger.debug('Got exception: %s.', e)
            raise GoogleConnectionError("Failed to get '%s'." % url)

    def _raw_get(self, url):
        """Make a raw HTTP GET request.

        No status check (which implies no redirection). Response can be
        accessed from ``self._resp``.

        Parameters
        ----------
        url : str
            URL relative to the host, used in the GET request.

        Raises
        ------
        http.client.HTTPException

        """
        logger.debug('Fetching URL %s', url)
        self._conn.request('GET', url, None, {
            'Accept': 'text/html',
            'Accept-Encoding': 'gzip',
            'User-Agent': USER_AGENT,
            'Cookie': self.cookie,
            'Connection': 'keep-alive',
            'DNT': '1',
        })
        self._resp = self._conn.getresponse()
        if self.cookie == '':
            complete_cookie = self._resp.getheader('Set-Cookie')
            # Cookie won't be available if already blocked
            if complete_cookie is not None:
                self.cookie = complete_cookie[:complete_cookie.find(';')]
                logger.debug('Cookie: %s' % self.cookie)

    def close(self):
        """Close the connection (if one is active)."""
        if self._conn:
            self._conn.close()


class GoogleParser(object):

    def __init__(self, html, *, news=False, videos=False):
        self.news = news
        self.videos = videos
        self.autocorrected = False
        self.showing_results_for = None
        self.filtered = False
        self.results = []
        self.parse(html)

    @time_it()
    def parse(self, html):
        tree = parse_html(html)

        if debugger:
            printerr('\x1b[1mInspect the DOM through the \x1b[4mtree\x1b[24m variable.\x1b[0m')
            printerr('')
            try:
                import IPython
                IPython.embed()
            except ImportError:
                import pdb
                pdb.set_trace()

        # cw is short for collapse_whitespace.
        cw = lambda s: re.sub(r'[ \t\n\r]+', ' ', s) if s is not None else s

        index = 0
        for div_g in tree.select_all('div.g'):
            if div_g.select('.hp-xpdbox'):
                # Skip smart cards.
                continue
            try:
                if div_g.select('.st'):
                    # Old class structure, stopped working some time in
                    # September 2020, but kept just in case.
                    h3 = div_g.select('div.r h3')
                    if h3:
                        title = h3.text
                        a = h3.parent
                    else:
                        h3 = div_g.select('h3.r')
                        a = h3.select('a')
                        title = a.text
                        mime = div_g.select('.mime')
                        if mime:
                            title = mime.text + ' ' + title
                    abstract_node = div_g.select('.st')
                    metadata_node = div_g.select('.f')
                else:
                    # Current structure as of October 2020.
                    # Note that a filetype tag (e.g. PDF) is now pretty
                    # damn hard to parse with confidence (that it'll
                    # survive the slighest further change), so we don't.

                    # As of January 15th 2021, the html class is not rc anymore, it's tF2Cxc.
                    # This approach is not very resilient to changes by Google, but it works for now.
                    # title_node, details_node, *_ = div_g.select_all('div.rc > div')
                    title_node, details_node, *_ = div_g.select_all('div.tF2Cxc > div')
                    if 'yuRUbf' not in title_node.classes:
                        logger.debug('unexpected title node class(es): expected %r, got %r',
                                     'yuRUbf', ' '.join(title_node.classes))
                    if 'IsZvec' not in details_node.classes:
                        logger.debug('unexpected details node class(es): expected %r, got %r',
                                     'IsZvec', ' '.join(details_node.classes))
                    a = title_node.select('a')
                    h3 = a.select('h3')
                    title = h3.text
                    abstract_node = details_node.select('span')
                    metadata_node = details_node.select('.f, span ~ div')
                url = self.unwrap_link(a.attr('href'))
                matched_keywords = []
                abstract = ''
                # BFS descendant nodes. Necessary to locate matches (b,
                # em) while skipping metadata (.f).
                abstract_nodes = collections.deque([abstract_node])
                while abstract_nodes:
                    node = abstract_nodes.popleft()
                    if 'f' in node.classes:
                        # .f is handled as metadata instead.
                        continue
                    if node.tag in ['b', 'em']:
                        matched_keywords.append({'phrase': node.text, 'offset': len(abstract)})
                        abstract += node.text
                        continue
                    if not node.children:
                        abstract += node.text
                        continue
                    for child in node.children:
                        abstract_nodes.append(child)
                metadata = None
                try:
                    # Sometimes there are multiple metadata fields
                    # associated with a single entry, e.g. "Released",
                    # "Producer(s)", "Genre", etc. for a song (sample
                    # query: "never gonna give you up"). These need to
                    # be delimited when displayed.
                    metadata_fields = metadata_node.select_all('div > div.wFMWsc')
                    if metadata_fields:
                        metadata = ' | '.join(field.text for field in metadata_fields)
                    elif not metadata_node.select('a') and not metadata_node.select('g-expandable-container'):
                        metadata = metadata_node.text
                    if metadata:
                        metadata = (
                            metadata
                            .replace('\u200e', '')
                            .replace(' - ', ', ')
                            .replace(' \u2014 ', ', ')
                            .strip().rstrip(',')
                        )
                except AttributeError:
                    pass
            except (AttributeError, ValueError):
                continue
            sitelinks = []
            for td in div_g.select_all('td'):
                try:
                    a = td.select('a')
                    sl_title = a.text
                    sl_url = self.unwrap_link(a.attr('href'))
                    sl_abstract = td.select('div.s.st, div.s .st').text
                    sitelink = Sitelink(cw(sl_title), sl_url, cw(sl_abstract))
                    if sitelink not in sitelinks:
                        sitelinks.append(sitelink)
                except (AttributeError, ValueError):
                    continue
            # cw cannot be applied to abstract here since it may screw
            # up offsets of matches. Instead, each relevant node's text
            # is whitespace-collapsed before being appended to abstract.
            # We then hope for the best.
            result = Result(index + 1, cw(title), url, abstract,
                            metadata=cw(metadata), sitelinks=sitelinks, matches=matched_keywords)
            if result not in self.results:
                self.results.append(result)
                index += 1

        if not self.results:
            for card in tree.select_all('g-card'):
                a = card.select('a[href]')
                if not a:
                    continue
                url = self.unwrap_link(a.attr('href'))
                text_nodes = []
                for node in a.descendants():
                    if isinstance(node, TextNode) and node.strip():
                        text_nodes.append(node.text)
                if len(text_nodes) != 4:
                    continue
                publisher, title, abstract, publishing_time = text_nodes
                metadata = '%s, %s' % (publisher, publishing_time)
                index += 1
                self.results.append(Result(index, cw(title), url, cw(abstract), metadata=cw(metadata)))

        # Showing results for ...
        # Search instead for ...
        spell_orig = tree.select("span.spell_orig")
        if spell_orig:
            showing_results_for_link = next(
                filter(lambda el: el.tag == "a", spell_orig.previous_siblings()), None
            )
            if showing_results_for_link:
                self.autocorrected = True
                self.showing_results_for = showing_results_for_link.text

        # No results found for ...
        # Results for ...:
        alt_query_infobox = tree.select('#topstuff')
        if alt_query_infobox:
            bolds = alt_query_infobox.select_all('div b')
            if len(bolds) == 2:
                self.showing_results_for = bolds[1].text

        # In order to show you the most relevant results, we have
        # omitted some entries very similar to the N already displayed.
        # ...
        self.filtered = tree.select('p#ofr') is not None

    # Unwraps /url?q=http://...&sa=...
    # TODO: don't unwrap if URL isn't in this form.
    @staticmethod
    def unwrap_link(link):
        qs = urllib.parse.urlparse(link).query
        try:
            url = urllib.parse.parse_qs(qs)['q'][0]
        except KeyError:
            return link
        else:
            if "://" in url:
                return url
            else:
                # Google's internal services link, e.g.,
                # /search?q=google&..., which cannot be unwrapped into
                # an actual URL.
                raise ValueError(link)


class Sitelink(object):
    """Container for a sitelink."""

    def __init__(self, title, url, abstract):
        self.title = title
        self.url = url
        self.abstract = abstract
        self.index = ''

    def __eq__(self, other):
        return (
            self.title == other.title and
            self.url == other.url and
            self.abstract == other.abstract
        )

    def __hash__(self):
        return hash((self.title, self.url, self.abstract))


Colors = collections.namedtuple('Colors', 'index, title, url, metadata, abstract, prompt, reset')


class Result(object):
    """
    Container for one search result, with output helpers.

    Parameters
    ----------
    index : int or str
    title : str
    url : str
    abstract : str
    metadata : str, optional
        Only applicable to Google News results, with publisher name and
        publishing time.
    sitelinks : list, optional
        List of ``SiteLink`` objects.

    Attributes
    ----------
    index : str
    title : str
    url : str
    abstract : str
    metadata : str or None
    sitelinks : list
    matches : list

    Class Variables
    ---------------
    colors : str

    Methods
    -------
    print()
    jsonizable_object()
    urltable()

    """

    # Class variables
    colors = None
    urlexpand = True

    def __init__(self, index, title, url, abstract, metadata=None, sitelinks=None, matches=None):
        index = str(index)
        self.index = index
        self.title = title
        self.url = url
        self.abstract = abstract
        self.metadata = metadata
        self.sitelinks = [] if sitelinks is None else sitelinks
        self.matches = [] if matches is None else matches

        self._urltable = {index: url}
        subindex = 'a'
        for sitelink in self.sitelinks:
            fullindex = index + subindex
            sitelink.index = fullindex
            self._urltable[fullindex] = sitelink.url
            subindex = chr(ord(subindex) + 1)

    def __eq__(self, other):
        return (
            self.title == other.title and
            self.url == other.url and
            self.abstract == other.abstract and
            self.metadata == other.metadata and
            self.sitelinks == other.sitelinks and
            self.matches == other.matches
        )

    def __hash__(self):
        sitelinks_hashable = tuple(self.sitelinks) if self.sitelinks is not None else None
        matches_hashable = tuple(self.matches) if self.matches is not None else None
        return hash(self.title, self.url, self.abstract, self.metadata, sitelinks_hashable, matches_hashable)

    def _print_title_and_url(self, index, title, url, indent=0):
        colors = self.colors

        if not self.urlexpand:
            url = '[' + urllib.parse.urlparse(url).netloc + ']'

        if colors:
            # Adjust index to print result index clearly
            print(" %s%s%-3s%s" % (' ' * indent, colors.index, index + '.', colors.reset), end='')
            if not self.urlexpand:
                print(' ' + colors.title + title + colors.reset + ' ' + colors.url + url + colors.reset)
            else:
                print(' ' + colors.title + title + colors.reset)
                print(' ' * (indent + 5) + colors.url + url + colors.reset)
        else:
            if self.urlexpand:
                print(' %s%-3s %s' % (' ' * indent, index + '.', title))
                print(' %s%s' % (' ' * (indent + 4), url))
            else:
                print(' %s%-3s %s %s' % (' ' * indent, index + '.', title, url))

    def _print_metadata_and_abstract(self, abstract, metadata=None, matches=None, indent=0):
        colors = self.colors
        try:
            columns, _ = os.get_terminal_size()
        except OSError:
            columns = 0

        if metadata:
            if colors:
                print(' ' * (indent + 5) + colors.metadata + metadata + colors.reset)
            else:
                print(' ' * (indent + 5) + metadata)

        if abstract:
            fillwidth = (columns - (indent + 6)) if columns > indent + 6 else len(abstract)
            wrapped_abstract = TrackedTextwrap(abstract, fillwidth)
            if colors:
                # Highlight matches.
                for match in matches or []:
                    offset = match['offset']
                    span = len(match['phrase'])
                    wrapped_abstract.insert_zero_width_sequence('\x1b[1m', offset)
                    wrapped_abstract.insert_zero_width_sequence('\x1b[0m', offset + span)

            if colors:
                print(colors.abstract, end='')
            for line in wrapped_abstract.lines:
                print('%s%s' % (' ' * (indent + 5), line))
            if colors:
                print(colors.reset, end='')

        print('')

    def print(self):
        """Print the result entry."""
        self._print_title_and_url(self.index, self.title, self.url)
        self._print_metadata_and_abstract(self.abstract, metadata=self.metadata, matches=self.matches)

        for sitelink in self.sitelinks:
            self._print_title_and_url(sitelink.index, sitelink.title, sitelink.url, indent=4)
            self._print_metadata_and_abstract(sitelink.abstract, indent=4)

    def jsonizable_object(self):
        """Return a JSON-serializable dict representing the result entry."""
        obj = {
            'title': self.title,
            'url': self.url,
            'abstract': self.abstract
        }
        if self.metadata:
            obj['metadata'] = self.metadata
        if self.sitelinks:
            obj['sitelinks'] = [sitelink.__dict__ for sitelink in self.sitelinks]
        if self.matches:
            obj['matches'] = self.matches
        return obj

    def urltable(self):
        """Return a index-to-URL table for the current result.

        Normally, the table contains only a single entry, but when the result
        contains sitelinks, all sitelinks are included in this table.

        Returns
        -------
        dict
            A dict mapping indices (strs) to URLs (also strs). Indices of
            sitelinks are the original index appended by lowercase letters a,
            b, c, etc.

        """
        return self._urltable

    @staticmethod
    def collapse_whitespace(s):
        return re.sub(r'[ \t\n\r]+', ' ', s)


class GooglerCmdException(Exception):
    pass


class NoKeywordsException(GooglerCmdException):
    pass


def require_keywords(method):
    # Require keywords to be set before we run a GooglerCmd method. If
    # no keywords have been set, raise a NoKeywordsException.
    @functools.wraps(method)
    def enforced_method(self, *args, **kwargs):
        if not self.keywords:
            raise NoKeywordsException('No keywords.')
        method(self, *args, **kwargs)

    return enforced_method


def no_argument(method):
    # Normalize a do_* method of GooglerCmd that takes no argument to
    # one that takes an arg, but issue a warning when an nonempty
    # argument is given.
    @functools.wraps(method)
    def enforced_method(self, arg):
        if arg:
            method_name = arg.__name__
            command_name = method_name[3:] if method_name.startswith('do_') else method_name
            logger.warning("Argument to the '%s' command ignored.", command_name)
        method(self)

    return enforced_method


class GooglerCmd(object):
    """
    Command line interpreter and executor class for googler.

    Inspired by PSL cmd.Cmd.

    Parameters
    ----------
    opts : argparse.Namespace
        Options and/or arguments.

    Attributes
    ----------
    options : argparse.Namespace
        Options that are currently in effect. Read-only attribute.
    keywords : str or list or strs
        Current keywords. Read-only attribute

    Methods
    -------
    fetch()
    display_results(prelude='\n', json_output=False)
    fetch_and_display(prelude='\n', json_output=False, interactive=True)
    read_next_command()
    help()
    cmdloop()
    """

    # Class variables
    colors = None
    re_url_index = re.compile(r"\d+(a-z)?")

    def __init__(self, opts):
        super().__init__()

        self._opts = opts

        self._google_url = GoogleUrl(opts)

        if opts.html_file:
            # Preloaded HTML parsing mode, do not initialize connection.
            self._preload_from_file = opts.html_file
            self._conn = None
        else:
            self._preload_from_file = None
            proxy = opts.proxy if hasattr(opts, 'proxy') else None
            self._conn = GoogleConnection(self._google_url.hostname,
                                        address_family=opts.address_family,
                                        proxy=proxy,
                                        notweak=opts.notweak)
            atexit.register(self._conn.close)

        self.results = []
        self._autocorrected = None
        self._showing_results_for = None
        self._results_filtered = False
        self._urltable = {}

        self.promptcolor = True if os.getenv('DISABLE_PROMPT_COLOR') is None else False

        self.no_results_instructions_shown = False

    @property
    def options(self):
        """Current options."""
        return self._opts

    @property
    def keywords(self):
        """Current keywords."""
        return self._google_url.keywords

    @require_keywords
    def fetch(self):
        """Fetch a page and parse for results.

        Results are stored in ``self.results``.

        Raises
        ------
        GoogleConnectionError

        See Also
        --------
        fetch_and_display

        """
        # This method also sets self._results_filtered and
        # self._urltable.
        if self._preload_from_file:
            with open(self._preload_from_file, encoding='utf-8') as fp:
                page = fp.read()
        else:
            page = self._conn.fetch_page(self._google_url.relative())
            if logger.isEnabledFor(logging.DEBUG):
                import tempfile
                fd, tmpfile = tempfile.mkstemp(prefix='googler-response-', suffix='.html')
                os.close(fd)
                with open(tmpfile, 'w', encoding='utf-8') as fp:
                    fp.write(page)
                logger.debug("Response body written to '%s'.", tmpfile)

        parser = GoogleParser(page, news=self._google_url.news, videos=self._google_url.videos)

        self.results = parser.results
        self._autocorrected = parser.autocorrected
        self._showing_results_for = parser.showing_results_for
        self._results_filtered = parser.filtered
        self._urltable = {}
        for r in self.results:
            self._urltable.update(r.urltable())

    def warn_no_results(self):
        printerr('No results.')
        if self.no_results_instructions_shown:
            return

        try:
            import json
            import urllib.error
            import urllib.request
            info_json_url = '%s/master/info.json' % RAW_DOWNLOAD_REPO_BASE
            logger.debug('Fetching %s for project status...', info_json_url)
            try:
                with urllib.request.urlopen(info_json_url, timeout=5) as response:
                    try:
                        info = json.load(response)
                    except Exception:
                        logger.error('Failed to decode project status from %s', info_json_url)
                        raise RuntimeError
            except urllib.error.HTTPError as e:
                logger.error('Failed to fetch project status from %s: HTTP %d', info_json_url, e.code)
                raise RuntimeError
            epoch = info.get('epoch')
            if epoch > _EPOCH_:
                printerr('Your version of googler is broken due to Google-side changes.')
                tracking_issue = info.get('tracking_issue')
                fixed_on_master = info.get('fixed_on_master')
                fixed_in_release = info.get('fixed_in_release')
                if fixed_in_release:
                    printerr('A new version, %s, has been released to address the changes.' % fixed_in_release)
                    printerr('Please upgrade to the latest version.')
                elif fixed_on_master:
                    printerr('The fix has been pushed to master, pending a release.')
                    printerr('Please download the master version https://git.io/googler or wait for a release.')
                else:
                    printerr('The issue is tracked at https://github.com/jarun/googler/issues/%s.' % tracking_issue)
                return
        except RuntimeError:
            pass

        printerr('If you believe this is a bug, please review '
                 'https://git.io/googler-no-results before submitting a bug report.')
        self.no_results_instructions_shown = True

    @require_keywords
    def display_results(self, prelude='\n', json_output=False):
        """Display results stored in ``self.results``.

        Parameters
        ----------
        See `fetch_and_display`.

        """
        if json_output:
            # JSON output
            import json
            results_object = [r.jsonizable_object() for r in self.results]
            print(json.dumps(results_object, indent=2, sort_keys=True, ensure_ascii=False))
        else:
            # Regular output
            if not self.results:
                self.warn_no_results()
            else:
                sys.stderr.write(prelude)
                for r in self.results:
                    r.print()

    @require_keywords
    def showing_results_for_alert(self, interactive=True):
        colors = self.colors
        if self._showing_results_for:
            if colors:
                # Underline the query
                actual_query = '\x1b[4m' + self._showing_results_for + '\x1b[24m'
            else:
                actual_query = self._showing_results_for
            if self._autocorrected:
                if interactive:
                    info = 'Showing results for %s; enter "x" for an exact search.' % actual_query
                else:
                    info = 'Showing results for %s; use -x, --exact for an exact search.' % actual_query
            else:
                info = 'No results found; showing results for %s.' % actual_query
            if interactive:
                printerr('')
            if colors:
                printerr(colors.prompt + info + colors.reset)
            else:
                printerr('** ' + info)

    @require_keywords
    def fetch_and_display(self, prelude='\n', json_output=False, interactive=True):
        """Fetch a page and display results.

        Results are stored in ``self.results``.

        Parameters
        ----------
        prelude : str, optional
            A string that is written to stderr before showing actual results,
            usually serving as a separator. Default is an empty line.
        json_output : bool, optional
            Whether to dump results in JSON format. Default is False.
        interactive : bool, optional
            Whether to show contextual instructions, when e.g. Google
            has filtered the results. Default is True.

        Raises
        ------
        GoogleConnectionError

        See Also
        --------
        fetch
        display_results

        """
        self.fetch()
        self.showing_results_for_alert()
        self.display_results(prelude=prelude, json_output=json_output)
        if self._results_filtered:
            colors = self.colors
            info = 'Enter "unfilter" to show similar results Google omitted.'
            if colors:
                printerr(colors.prompt + info + colors.reset)
            else:
                printerr('** ' + info)
            printerr('')

    def read_next_command(self):
        """Show omniprompt and read user command line.

        Command line is always stripped, and each consecutive group of
        whitespace is replaced with a single space character. If the
        command line is empty after stripping, when ignore it and keep
        reading. Exit with status 0 if we get EOF or an empty line
        (pre-strip, that is, a raw <enter>) twice in a row.

        The new command line (non-empty) is stored in ``self.cmd``.

        """
        colors = self.colors
        message = 'googler (? for help)'
        prompt = (colors.prompt + message + colors.reset + ' ') if (colors and self.promptcolor) else (message + ': ')
        enter_count = 0
        while True:
            try:
                cmd = input(prompt)
            except EOFError:
                sys.exit(0)

            if not cmd:
                enter_count += 1
                if enter_count == 2:
                    # Double <enter>
                    sys.exit(0)
            else:
                enter_count = 0

            cmd = ' '.join(cmd.split())
            if cmd:
                self.cmd = cmd
                break

    @staticmethod
    def help():
        GooglerArgumentParser.print_omniprompt_help(sys.stderr)
        printerr('')

    @require_keywords
    @no_argument
    def do_first(self):
        try:
            self._google_url.first_page()
        except ValueError as e:
            print(e, file=sys.stderr)
            return

        self.fetch_and_display()

    def do_google(self, arg):
        # Update keywords and reconstruct URL
        self._opts.keywords = arg
        self._google_url = GoogleUrl(self._opts)
        self.fetch_and_display()

    @require_keywords
    @no_argument
    def do_next(self):
        # If > 5 results are being fetched each time,
        # block next when no parsed results in current fetch
        if not self.results and self._google_url._num > 5:
            printerr('No results.')
        else:
            self._google_url.next_page()
            self.fetch_and_display()

    @require_keywords
    def do_open(self, *args):
        if not args:
            open_url(self._google_url.full())
            return

        for nav in args:
            if nav == 'a':
                for key, value in sorted(self._urltable.items()):
                    open_url(self._urltable[key])
            elif nav in self._urltable:
                open_url(self._urltable[nav])
            elif '-' in nav:
                try:
                    vals = [int(x) for x in nav.split('-')]
                    if (len(vals) != 2):
                        printerr('Invalid range %s.' % nav)
                        continue

                    if vals[0] > vals[1]:
                        vals[0], vals[1] = vals[1], vals[0]

                    for _id in range(vals[0], vals[1] + 1):
                        if str(_id) in self._urltable:
                            open_url(self._urltable[str(_id)])
                        else:
                            printerr('Invalid index %s.' % _id)
                except ValueError:
                    printerr('Invalid range %s.' % nav)
            else:
                printerr('Invalid index %s.' % nav)

    @require_keywords
    @no_argument
    def do_previous(self):
        try:
            self._google_url.prev_page()
        except ValueError as e:
            print(e, file=sys.stderr)
            return

        self.fetch_and_display()

    @require_keywords
    @no_argument
    def do_exact(self):
        # Reset start to 0 when exact is applied.
        self._google_url.update(start=0, exact=True)
        self.fetch_and_display()

    @require_keywords
    @no_argument
    def do_unfilter(self):
        # Reset start to 0 when unfilter is applied.
        self._google_url.update(start=0)
        self._google_url.set_queries(filter=0)
        self.fetch_and_display()

    def copy_url(self, idx):
        try:
            try:
                content = self._urltable[idx].encode('utf-8')
            except KeyError:
                printerr('Invalid index.')
                return

            # try copying the url to clipboard using native utilities
            copier_params = []
            if sys.platform.startswith(('linux', 'freebsd', 'openbsd')):
                if shutil.which('xsel') is not None:
                    copier_params = ['xsel', '-b', '-i']
                elif shutil.which('xclip') is not None:
                    copier_params = ['xclip', '-selection', 'clipboard']
                elif shutil.which('wl-copy') is not None:
                    copier_params = ['wl-copy']
                elif shutil.which('termux-clipboard-set') is not None:
                    copier_params = ['termux-clipboard-set']
            elif sys.platform == 'darwin':
                copier_params = ['pbcopy']
            elif sys.platform == 'win32':
                copier_params = ['clip']

            if copier_params:
                Popen(copier_params, stdin=PIPE, stdout=DEVNULL, stderr=DEVNULL).communicate(content)
                return

            # If native clipboard utilities are absent, try to use terminal multiplexers
            # tmux
            if os.getenv('TMUX_PANE'):
                copier_params = ['tmux', 'set-buffer']
                Popen(copier_params + [content], stdin=DEVNULL, stdout=DEVNULL, stderr=DEVNULL).communicate()
                return

            # GNU Screen paste buffer
            if os.getenv('STY'):
                import tempfile
                copier_params = ['screen', '-X', 'readbuf', '-e', 'utf8']
                tmpfd, tmppath = tempfile.mkstemp()
                try:
                    with os.fdopen(tmpfd, 'wb') as fp:
                        fp.write(content)
                    copier_params.append(tmppath)
                    Popen(copier_params, stdin=DEVNULL, stdout=DEVNULL, stderr=DEVNULL).communicate()
                finally:
                    os.unlink(tmppath)
                return

            printerr('failed to locate suitable clipboard utility')
        except Exception:
            raise NoKeywordsException

    def cmdloop(self):
        """Run REPL."""
        if self.keywords:
            self.fetch_and_display()
        else:
            printerr('Please initiate a query.')

        while True:
            self.read_next_command()
            # TODO: Automatic dispatcher
            #
            # We can't write a dispatcher for now because that could
            # change behaviour of the prompt. However, we have already
            # laid a lot of ground work for the dispatcher, e.g., the
            # `no_argument' decorator.
            try:
                cmd = self.cmd
                if cmd == 'f':
                    self.do_first('')
                elif cmd.startswith('g '):
                    self.do_google(cmd[2:])
                elif cmd == 'n':
                    self.do_next('')
                elif cmd == 'o':
                    self.do_open()
                elif cmd.startswith('o '):
                    self.do_open(*cmd[2:].split())
                elif cmd.startswith('O '):
                    open_url.override_text_browser = True
                    self.do_open(*cmd[2:].split())
                    open_url.override_text_browser = False
                elif cmd == 'p':
                    self.do_previous('')
                elif cmd == 'q':
                    break
                elif cmd == 'x':
                    self.do_exact('')
                elif cmd == 'unfilter':
                    self.do_unfilter('')
                elif cmd == '?':
                    self.help()
                elif cmd in self._urltable:
                    open_url(self._urltable[cmd])
                elif self.keywords and cmd.isdigit() and int(cmd) < 100:
                    printerr('Index out of bound. To search for the number, use g.')
                elif cmd == 'u':
                    Result.urlexpand = not Result.urlexpand
                    self.display_results()
                elif cmd.startswith('c ') and self.re_url_index.match(cmd[2:]):
                    self.copy_url(cmd[2:])
                else:
                    self.do_google(cmd)
            except NoKeywordsException:
                printerr('Initiate a query first.')


class GooglerArgumentParser(argparse.ArgumentParser):
    """Custom argument parser for googler."""

    # Print omniprompt help
    @staticmethod
    def print_omniprompt_help(file=None):
        file = sys.stderr if file is None else file
        file.write(textwrap.dedent("""
        omniprompt keys:
          n, p                  fetch the next or previous set of search results
          index                 open the result corresponding to index in browser
          f                     jump to the first page
          o [index|range|a ...] open space-separated result indices, numeric ranges
                                (sitelinks unsupported in ranges), or all, in browser
                                open the current search in browser, if no arguments
          O [index|range|a ...] like key 'o', but try to open in a GUI browser
          g keywords            new Google search for 'keywords' with original options
                                should be used to search omniprompt keys and indices
          c index               copy url to clipboard
          u                     toggle url expansion
          q, ^D, double Enter   exit googler
          ?                     show omniprompt help
          *                     other inputs issue a new search with original options
        """))

    # Print information on googler
    @staticmethod
    def print_general_info(file=None):
        file = sys.stderr if file is None else file
        file.write(textwrap.dedent("""
        Version %s
        Copyright © 2008 Henri Hakkinen
        Copyright © 2015-2021 Arun Prakash Jana <engineerarun@gmail.com>
        Zhiming Wang <zmwangx@gmail.com>
        License: GPLv3
        Webpage: https://github.com/jarun/googler
        """ % _VERSION_))

    # Augment print_help to print more than synopsis and options
    def print_help(self, file=None):
        super().print_help(file)
        self.print_omniprompt_help(file)
        self.print_general_info(file)

    # Automatically print full help text on error
    def error(self, message):
        sys.stderr.write('%s: error: %s\n\n' % (self.prog, message))
        self.print_help(sys.stderr)
        self.exit(2)

    # Type guards
    @staticmethod
    def positive_int(arg):
        """Try to convert a string into a positive integer."""
        try:
            n = int(arg)
            assert n > 0
            return n
        except (ValueError, AssertionError):
            raise argparse.ArgumentTypeError('%s is not a positive integer' % arg)

    @staticmethod
    def nonnegative_int(arg):
        """Try to convert a string into a nonnegative integer."""
        try:
            n = int(arg)
            assert n >= 0
            return n
        except (ValueError, AssertionError):
            raise argparse.ArgumentTypeError('%s is not a non-negative integer' % arg)

    @staticmethod
    def is_duration(arg):
        """Check if a string is a valid duration accepted by Google.

        A valid duration is of the form dNUM, where d is a single letter h
        (hour), d (day), w (week), m (month), or y (year), and NUM is a
        non-negative integer.
        """
        try:
            if arg[0] not in ('h', 'd', 'w', 'm', 'y') or int(arg[1:]) < 0:
                raise ValueError
        except (TypeError, IndexError, ValueError):
            raise argparse.ArgumentTypeError('%s is not a valid duration' % arg)
        return arg

    @staticmethod
    def is_date(arg):
        """Check if a string is a valid date/month/year accepted by Google."""
        if re.match(r'^(\d+/){0,2}\d+$', arg):
            return arg
        else:
            raise argparse.ArgumentTypeError('%s is not a valid date/month/year; '
                                             'use the American date format with slashes')

    @staticmethod
    def is_colorstr(arg):
        """Check if a string is a valid color string."""
        try:
            assert len(arg) == 6
            for c in arg:
                assert c in COLORMAP
        except AssertionError:
            raise argparse.ArgumentTypeError('%s is not a valid color string' % arg)
        return arg


# Self-upgrade mechanism

def system_is_windows():
    """Checks if the underlying system is Windows (Cygwin included)."""
    return sys.platform in {'win32', 'cygwin'}


def get_latest_ref(include_git=False):
    """Helper for download_latest_googler."""
    import urllib.request

    if include_git:
        # Get SHA of latest commit on master
        request = urllib.request.Request('%s/commits/master' % API_REPO_BASE,
                                         headers={'Accept': 'application/vnd.github.v3.sha'})
        response = urllib.request.urlopen(request)
        if response.status != 200:
            raise http.client.HTTPException(response.reason)
        return response.read().decode('utf-8')
    else:
        # Get name of latest tag
        request = urllib.request.Request('%s/releases?per_page=1' % API_REPO_BASE,
                                         headers={'Accept': 'application/vnd.github.v3+json'})
        response = urllib.request.urlopen(request)
        if response.status != 200:
            raise http.client.HTTPException(response.reason)
        import json
        return json.loads(response.read().decode('utf-8'))[0]['tag_name']


def download_latest_googler(include_git=False):
    """Download latest googler to a temp file.

    By default, the latest released version is downloaded, but if
    `include_git` is specified, then the latest git master is downloaded
    instead.

    Parameters
    ----------
    include_git : bool, optional
        Download from git master. Default is False.

    Returns
    -------
    (git_ref, path): tuple
         A tuple containing the git reference (either name of the latest
         tag or SHA of the latest commit) and path to the downloaded
         file.

    """
    # Download googler to a tempfile
    git_ref = get_latest_ref(include_git=include_git)
    googler_download_url = '%s/%s/googler' % (RAW_DOWNLOAD_REPO_BASE, git_ref)
    printerr('Downloading %s' % googler_download_url)
    request = urllib.request.Request(googler_download_url,
                                     headers={'Accept-Encoding': 'gzip'})
    import tempfile
    fd, path = tempfile.mkstemp()
    atexit.register(lambda: os.remove(path) if os.path.exists(path) else None)
    os.close(fd)
    with open(path, 'wb') as fp:
        with urllib.request.urlopen(request) as response:
            if response.status != 200:
                raise http.client.HTTPException(response.reason)
            payload = response.read()
            try:
                fp.write(gzip.decompress(payload))
            except OSError:
                fp.write(payload)
    return git_ref, path


def self_replace(path):
    """Replace the current script with a specified file.

    Both paths (the specified path and path to the current script) are
    resolved to absolute, symlink-free paths. Upon replacement, the
    owner and mode signatures of the current script are preserved. The
    caller needs to have the necessary permissions.

    Replacement won't happen if the specified file is the same
    (content-wise) as the current script.

    Parameters
    ----------
    path : str
        Path to the replacement file.

    Returns
    -------
    bool
        True if replaced, False if skipped (specified file is the same
        as the current script).

    """
    if system_is_windows():
        raise NotImplementedError('Self upgrade not supported on Windows.')

    import filecmp
    import shutil

    path = os.path.realpath(path)
    self_path = os.path.realpath(__file__)

    if filecmp.cmp(path, self_path):
        return False

    self_stat = os.stat(self_path)
    os.chown(path, self_stat.st_uid, self_stat.st_gid)
    os.chmod(path, self_stat.st_mode)

    shutil.move(path, self_path)
    return True


def self_upgrade(include_git=False):
    """Perform in-place self-upgrade.

    Parameters
    ----------
    include_git : bool, optional
        See `download_latest_googler`. Default is False.

    """
    git_ref, path = download_latest_googler(include_git=include_git)
    if self_replace(path):
        printerr('Upgraded to %s.' % git_ref)
    else:
        printerr('Already up to date.')


def check_new_version():
    try:
        from distutils.version import StrictVersion as Version
    except ImportError:
        # distutils not available (thanks distros), use a concise poor
        # man's version parser.
        class Version(tuple):
            def __new__(cls, version_str):
                def parseint(s):
                    try:
                        return int(s)
                    except ValueError:
                        return 0
                return tuple.__new__(cls, [parseint(s) for s in version_str.split('.')])

    import pathlib
    import tempfile
    import time
    cache = pathlib.Path(tempfile.gettempdir()) / 'googler-latest-version'
    latest_version_str = None
    # Try to load latest version string from cached location, if it
    # exists and is fresh enough.
    try:
        if cache.is_file() and time.time() - cache.stat().st_mtime < 86400:
            latest_version_str = cache.read_text().strip()
    except OSError:
        pass
    if not latest_version_str:
        try:
            latest_version_str = get_latest_ref().lstrip('v')
            cache.write_text(latest_version_str)
        except Exception:
            pass
    if not latest_version_str:
        return
    # Try to fetch latest version string from GitHub.
    try:
        current_version = Version(_VERSION_)
        latest_version = Version(latest_version_str)
    except ValueError:
        return
    if latest_version > current_version:
        print('\x1b[33;1mThe latest release of googler is v%s, please upgrade.\x1b[0m'
              % latest_version_str,
              file=sys.stderr)


# Miscellaneous functions

def python_version():
    return '%d.%d.%d' % sys.version_info[:3]


def https_proxy_from_environment():
    return os.getenv('https_proxy')


def parse_proxy_spec(proxyspec):
    if '://' in proxyspec:
        pos = proxyspec.find('://')
        scheme = proxyspec[:pos]
        proxyspec = proxyspec[pos+3:]
        if scheme.lower() != 'http':
            # Only support HTTP proxies.
            #
            # In particular, we don't support HTTPS proxies since we
            # only speak plain HTTP to the proxy server, so don't give
            # users a false sense of security.
            raise NotImplementedError('Unsupported proxy scheme %s.' % scheme)

    if '@' in proxyspec:
        pos = proxyspec.find('@')
        user_passwd = urllib.parse.unquote(proxyspec[:pos])
        # Remove trailing '/' if any
        host_port = proxyspec[pos+1:].rstrip('/')
    else:
        user_passwd = None
        host_port = proxyspec.rstrip('/')

    if ':' not in host_port:
        # Use port 1080 as default, following curl.
        host_port += ':1080'

    return user_passwd, host_port


def set_win_console_mode():
    # VT100 control sequences are supported on Windows 10 Anniversary Update and later.
    # https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
    # https://docs.microsoft.com/en-us/windows/console/setconsolemode
    if platform.release() == '10':
        STD_OUTPUT_HANDLE = -11
        STD_ERROR_HANDLE = -12
        ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
        try:
            from ctypes import windll, wintypes, byref
            kernel32 = windll.kernel32
            for nhandle in (STD_OUTPUT_HANDLE, STD_ERROR_HANDLE):
                handle = kernel32.GetStdHandle(nhandle)
                old_mode = wintypes.DWORD()
                if not kernel32.GetConsoleMode(handle, byref(old_mode)):
                    raise RuntimeError('GetConsoleMode failed')
                new_mode = old_mode.value | ENABLE_VIRTUAL_TERMINAL_PROCESSING
                if not kernel32.SetConsoleMode(handle, new_mode):
                    raise RuntimeError('SetConsoleMode failed')
            # Note: No need to restore at exit. SetConsoleMode seems to
            # be limited to the calling process.
        except Exception:
            pass


# Query autocompleter

# This function is largely experimental and could raise any exception;
# you should be prepared to catch anything. When it works though, it
# returns a list of strings the prefix could autocomplete to (however,
# it is not guaranteed that they start with the specified prefix; for
# instance, they won't if the specified prefix ends in a punctuation
# mark.)
def completer_fetch_completions(prefix):
    import html
    import json
    import re
    import urllib.request

    # One can pass the 'hl' query param to specify the language. We
    # ignore that for now.
    api_url = ('https://www.google.com/complete/search?client=psy-ab&q=%s' %
               urllib.parse.quote(prefix, safe=''))
    # A timeout of 3 seconds seems to be overly generous already.
    resp = urllib.request.urlopen(api_url, timeout=3)
    charset = resp.headers.get_content_charset()
    logger.debug('Completions charset: %s', charset)
    respobj = json.loads(resp.read().decode(charset))

    # The response object, once parsed as JSON, should look like
    #
    # ['git',
    #  [['git<b>hub</b>', 0],
    #   ['git', 0],
    #   ['git<b>lab</b>', 0],
    #   ['git<b> stash</b>', 0]],
    #  {'q': 'oooAhRzoChqNmMbNaaDKXk1YY4k', 't': {'bpc': False, 'tlw': False}}]
    #
    # Note the each result entry need not have two members; e.g., for
    # 'gi', there is an entry ['gi<b>f</b>', 0, [131]].
    HTML_TAG = re.compile(r'<[^>]+>')
    return [html.unescape(HTML_TAG.sub('', entry[0])) for entry in respobj[1]]


def completer_run(prefix):
    if prefix:
        completions = completer_fetch_completions(prefix)
        if completions:
            print('\n'.join(completions))
    sys.exit(0)


def parse_args(args=None, namespace=None):
    """Parse googler arguments/options.

    Parameters
    ----------
    args : list, optional
        Arguments to parse. Default is ``sys.argv``.
    namespace : argparse.Namespace
        Namespace to write to. Default is a new namespace.

    Returns
    -------
    argparse.Namespace
        Namespace with parsed arguments / options.

    """

    colorstr_env = os.getenv('GOOGLER_COLORS')

    argparser = GooglerArgumentParser(description='Google from the command-line.')
    addarg = argparser.add_argument
    addarg('-s', '--start', type=argparser.nonnegative_int, default=0,
           metavar='N', help='start at the Nth result')
    addarg('-n', '--count', dest='num', type=argparser.positive_int,
           default=10, metavar='N', help='show N results (default 10)')
    addarg('-N', '--news', action='store_true',
           help='show results from news section')
    addarg('-V', '--videos', action='store_true',
           help='show results from videos section')
    addarg('-c', '--tld', metavar='TLD',
           help="""country-specific search with top-level domain .TLD, e.g., 'in'
           for India""")
    addarg('-l', '--lang', metavar='LANG', help='display in language LANG')
    addarg('-g', '--geoloc', metavar='CC',
           help="""country-specific geolocation search with country code CC, e.g.
           'in' for India. Country codes are the same as top-level domains""")
    addarg('-x', '--exact', action='store_true',
           help='disable automatic spelling correction')
    addarg('--colorize', nargs='?', choices=['auto', 'always', 'never'],
           const='always', default='auto',
           help="""whether to colorize output; defaults to 'auto', which enables
           color when stdout is a tty device; using --colorize without an argument
           is equivalent to --colorize=always""")
    addarg('-C', '--nocolor', action='store_true',
           help='equivalent to --colorize=never')
    addarg('--colors', dest='colorstr', type=argparser.is_colorstr,
           default=colorstr_env if colorstr_env else 'GKlgxy', metavar='COLORS',
           help='set output colors (see man page for details)')
    addarg('-j', '--first', '--lucky', dest='lucky', action='store_true',
           help='open the first result in web browser and exit')
    addarg('-t', '--time', dest='duration', type=argparser.is_duration,
           metavar='dN', help='time limit search '
           '[h5 (5 hrs), d5 (5 days), w5 (5 weeks), m5 (5 months), y5 (5 years)]')
    addarg('--from', type=argparser.is_date,
           help="""starting date/month/year of date range; must use American date
           format with slashes, e.g., 2/24/2020, 2/2020, 2020; can be used in
           conjunction with --to, and overrides -t, --time""")
    addarg('--to', type=argparser.is_date,
           help='ending date/month/year of date range; see --from')
    addarg('-w', '--site', dest='sites', action='append', metavar='SITE',
           help='search a site using Google')
    addarg('-e', '--exclude', dest='exclude', action='append', metavar='SITE',
           help='exclude site from results')
    addarg('--unfilter', action='store_true', help='do not omit similar results')
    addarg('-p', '--proxy', default=https_proxy_from_environment(),
           help="""tunnel traffic through an HTTP proxy;
           PROXY is of the form [http://][user:password@]proxyhost[:port]""")
    addarg('--noua', action='store_true', help=argparse.SUPPRESS)
    addarg('--notweak', action='store_true',
           help='disable TCP optimizations and forced TLS 1.2')
    addarg('--json', action='store_true',
           help='output in JSON format; implies --noprompt')
    addarg('--url-handler', metavar='UTIL',
           help='custom script or cli utility to open results')
    addarg('--show-browser-logs', action='store_true',
           help='do not suppress browser output (stdout and stderr)')
    addarg('--np', '--noprompt', dest='noninteractive', action='store_true',
           help='search and exit, do not prompt')
    addarg('-4', '--ipv4', action='store_const', dest='address_family',
           const=socket.AF_INET, default=0,
           help="""only connect over IPv4
           (by default, IPv4 is preferred but IPv6 is used as a fallback)""")
    addarg('-6', '--ipv6', action='store_const', dest='address_family',
           const=socket.AF_INET6, default=0,
           help='only connect over IPv6')
    addarg('keywords', nargs='*', metavar='KEYWORD', help='search keywords')
    if ENABLE_SELF_UPGRADE_MECHANISM and not system_is_windows():
        addarg('-u', '--upgrade', action='store_true',
               help='perform in-place self-upgrade')
        addarg('--include-git', action='store_true',
               help='when used with --upgrade, get latest git master')
    addarg('-v', '--version', action='version', version=_VERSION_)
    addarg('-d', '--debug', action='store_true', help='enable debugging')
    # Hidden option for interacting with DOM in an IPython/pdb shell
    addarg('-D', '--debugger', action='store_true', help=argparse.SUPPRESS)
    # Hidden option for parsing dumped HTML
    addarg('--parse', dest='html_file', help=argparse.SUPPRESS)
    addarg('--complete', help=argparse.SUPPRESS)

    parsed = argparser.parse_args(args, namespace)
    if parsed.nocolor:
        parsed.colorize = 'never'

    return parsed


def main():
    try:
        opts = parse_args()

        # Set logging level
        if opts.debug:
            logger.setLevel(logging.DEBUG)
            logger.debug('googler version %s', _VERSION_)
            logger.debug('Python version %s', python_version())
            logger.debug('Platform: %s', platform.platform())
            check_new_version()

        if opts.debugger:
            global debugger
            debugger = True

        # Handle query completer
        if opts.complete is not None:
            completer_run(opts.complete)

        # Handle self-upgrade
        if hasattr(opts, 'upgrade') and opts.upgrade:
            self_upgrade(include_git=opts.include_git)
            sys.exit(0)

        check_stdout_encoding()

        if opts.keywords:
            try:
                # Add cmdline args to readline history
                readline.add_history(' '.join(opts.keywords))
            except Exception:
                pass

        # Set colors
        if opts.colorize == 'always':
            colorize = True
        elif opts.colorize == 'auto':
            colorize = sys.stdout.isatty()
        else:  # opts.colorize == 'never'
            colorize = False

        if colorize:
            colors = Colors(*[COLORMAP[c] for c in opts.colorstr], reset=COLORMAP['x'])
        else:
            colors = None
        Result.colors = colors
        Result.urlexpand = True if os.getenv('DISABLE_URL_EXPANSION') is None else False
        GooglerCmd.colors = colors

        # Try to enable ANSI color support in cmd or PowerShell on Windows 10
        if sys.platform == 'win32' and sys.stdout.isatty() and colorize:
            set_win_console_mode()

        if opts.url_handler is not None:
            open_url.url_handler = opts.url_handler
        else:
            # Set text browser override to False
            open_url.override_text_browser = False

            # Handle browser output suppression
            if opts.show_browser_logs or (os.getenv('BROWSER') in text_browsers):
                open_url.suppress_browser_output = False
            else:
                open_url.suppress_browser_output = True

        if opts.noua:
            logger.warning('--noua option has been deprecated and has no effect (see #284)')

        repl = GooglerCmd(opts)

        # Non-interactive mode
        if opts.json or opts.lucky or opts.noninteractive or opts.html_file:
            repl.fetch()
            if opts.lucky:
                if repl.results:
                    open_url(repl.results[0].url)
                else:
                    print('No results.', file=sys.stderr)
            else:
                repl.showing_results_for_alert(interactive=False)
                repl.display_results(json_output=opts.json)
            sys.exit(0)

        # Interactive mode
        repl.cmdloop()
    except Exception as e:
        # With debugging on, let the exception through for a traceback;
        # otherwise, only print the exception error message.
        if logger.isEnabledFor(logging.DEBUG):
            raise
        else:
            logger.error(e)
            sys.exit(1)

if __name__ == '__main__':
    main()
