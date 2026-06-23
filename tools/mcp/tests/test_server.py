"""Tests for the MCP tool functions.

The tools are plain functions (the FastMCP decorator returns them unchanged), so
they can be called directly once the module's lazy-loaded state is seeded.
"""

from __future__ import annotations

import pytest

from openvox_docs_mcp import server
from openvox_docs_mcp.corpus import Corpus, Doc
from openvox_docs_mcp.search import DocSearch


@pytest.fixture
def loaded(corpus, search, monkeypatch):
    """Seed the server's lazy state so the tools use the fixture corpus."""
    monkeypatch.setitem(server._state, "corpus", corpus)
    monkeypatch.setitem(server._state, "search", search)
    return server


def test_list_projects(loaded):
    assert loaded.list_projects() == ["alpha", "beta"]


def test_list_docs_all(loaded):
    docs = loaded.list_docs()
    assert len(docs) == 3
    assert set(docs[0]) == {"project", "title", "url"}


def test_list_docs_filtered(loaded):
    docs = loaded.list_docs(project="alpha")
    assert len(docs) == 2
    assert all(d["project"] == "alpha" for d in docs)


def test_search_docs(loaded):
    hits = loaded.search_docs("postgresql tuning", limit=2)
    assert hits
    assert hits[0]["title"] == "Alpha One"
    assert set(hits[0]) == {"title", "url", "project", "score", "snippet"}


def test_search_docs_project_filter(loaded):
    hits = loaded.search_docs("postgresql", project="beta")
    assert all(h["project"] == "beta" for h in hits)


def test_get_doc_by_url(loaded):
    d = loaded.get_doc("https://docs.openvoxproject.org/alpha/latest/two.html")
    assert d["title"] == "Alpha Two"
    assert d["truncated"] is False
    assert d["total_chars"] == len(d["content"])


def test_get_doc_by_path(loaded):
    d = loaded.get_doc("/alpha/latest/one.html")
    assert d["title"] == "Alpha One"


def test_get_doc_by_title_case_insensitive(loaded):
    d = loaded.get_doc("beta overview")
    assert d["url"].endswith("/beta/latest/index.html")


def test_get_doc_unknown_raises(loaded):
    with pytest.raises(ValueError):
        loaded.get_doc("nope")


def test_get_doc_truncation(monkeypatch):
    long_body = "x" * 500
    c = Corpus(
        docs=[Doc("p", "Big", "https://docs.openvoxproject.org/p/latest/big.html", long_body)],
        index=[],
    )
    monkeypatch.setitem(server._state, "corpus", c)
    monkeypatch.setitem(server._state, "search", DocSearch(c))

    d = server.get_doc("Big", max_chars=100)
    assert d["truncated"] is True
    assert d["total_chars"] == 500
    assert "[truncated" in d["content"]
    # the marker references the canonical URL
    assert "big.html" in d["content"]


def test_refresh_corpus(monkeypatch, corpus):
    monkeypatch.setattr(server, "load_corpus", lambda **kw: corpus)
    # reset state so refresh actually (re)loads
    monkeypatch.setitem(server._state, "corpus", None)
    monkeypatch.setitem(server._state, "search", None)

    out = server.refresh_corpus()
    assert out["projects"] == 2
    assert out["indexed_pages"] == 3
    assert out["full_text_pages"] == 3
    assert server._state["corpus"] is corpus
