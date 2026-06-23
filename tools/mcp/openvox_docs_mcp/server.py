"""FastMCP server exposing the OpenVox docs corpus to MCP clients.

Tools:

- ``list_projects`` — the documentation projects available.
- ``list_docs`` — page titles + URLs, optionally filtered to one project.
- ``search_docs`` — BM25 keyword search returning title / URL / snippet.
- ``get_doc`` — the full plain text of one page, by URL, path, or title.
- ``refresh_corpus`` — force a re-fetch of the underlying llms files.

The corpus is loaded lazily on first use and reused across calls.
"""

from __future__ import annotations

from mcp.server.fastmcp import FastMCP

from .corpus import Corpus, Doc, load_corpus
from .search import DocSearch

mcp = FastMCP("openvox-docs")

_state: dict[str, object] = {"corpus": None, "search": None}


def _ensure_loaded(force: bool = False) -> Corpus:
    corpus = _state.get("corpus")
    if corpus is None or force:
        corpus = load_corpus(force=force)
        _state["corpus"] = corpus
        _state["search"] = DocSearch(corpus)
    return corpus  # type: ignore[return-value]


def _find_doc(corpus: Corpus, ref: str) -> Doc | None:
    """Resolve a doc by exact URL, URL path, then case-insensitive title."""
    ref = ref.strip()
    for doc in corpus.docs:
        if doc.url == ref:
            return doc
    for doc in corpus.docs:
        if doc.path == ref:
            return doc
    lowered = ref.lower()
    for doc in corpus.docs:
        if doc.title.lower() == lowered:
            return doc
    return None


@mcp.tool()
def list_projects() -> list[str]:
    """List the OpenVox documentation projects (e.g. openvox, openvox-server)."""
    return _ensure_loaded().projects


@mcp.tool()
def list_docs(project: str | None = None) -> list[dict[str, str]]:
    """List documentation pages as ``{project, title, url}``.

    Pass ``project`` to limit results to a single project.
    """
    corpus = _ensure_loaded()
    entries = corpus.index or corpus.docs
    return [
        {"project": d.project, "title": d.title, "url": d.url}
        for d in entries
        if project is None or d.project == project
    ]


@mcp.tool()
def search_docs(
    query: str, project: str | None = None, limit: int = 5
) -> list[dict[str, object]]:
    """Search the docs by keyword (BM25), returning the best-matching pages.

    Each result is ``{title, url, project, score, snippet}``. Optionally restrict
    to one ``project``.
    """
    _ensure_loaded()
    search: DocSearch = _state["search"]  # type: ignore[assignment]
    results = search.search(query, project=project, limit=limit)
    return [
        {
            "title": r.doc.title,
            "url": r.doc.url,
            "project": r.doc.project,
            "score": round(r.score, 3),
            "snippet": r.snippet,
        }
        for r in results
    ]


@mcp.tool()
def get_doc(ref: str, max_chars: int = 40000) -> dict[str, object]:
    """Return one page's full text. ``ref`` may be a URL, URL path, or exact title.

    A few generated reference pages (the single-page function and resource-type
    references) are very large, so the body is capped at ``max_chars`` (default
    40000) to avoid flooding the context; raise it to fetch more. The result is
    ``{title, url, project, content, total_chars, truncated}``. ``content`` is
    empty if the page is in the index but not the full-text bundle.
    """
    corpus = _ensure_loaded()
    doc = _find_doc(corpus, ref)
    if doc is None:
        raise ValueError(
            f"no document matched '{ref}'. Use search_docs or list_docs to find a URL or title."
        )
    total = len(doc.body)
    truncated = max_chars > 0 and total > max_chars
    content = doc.body
    if truncated:
        content = (
            doc.body[:max_chars].rstrip()
            + f"\n\n[truncated: showing {max_chars} of {total} characters. "
            f"Re-call get_doc with a larger max_chars, or open {doc.url} for the full page.]"
        )
    return {
        "title": doc.title,
        "url": doc.url,
        "project": doc.project,
        "content": content,
        "total_chars": total,
        "truncated": truncated,
    }


@mcp.tool()
def refresh_corpus() -> dict[str, object]:
    """Force a re-fetch of the llms files and rebuild the search index."""
    corpus = _ensure_loaded(force=True)
    return {
        "source": corpus.source,
        "projects": len(corpus.projects),
        "indexed_pages": len(corpus.index),
        "full_text_pages": len(corpus.docs),
    }


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
