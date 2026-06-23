"""Tests for BM25 search ranking, filtering, and snippets."""

from __future__ import annotations

from openvox_docs_mcp.corpus import Corpus
from openvox_docs_mcp.search import DocSearch


def test_ranks_most_relevant_first(search):
    results = search.search("postgresql tuning")
    assert results
    assert results[0].doc.title == "Alpha One"


def test_finds_body_term(search):
    results = search.search("certificate authority")
    assert results[0].doc.title == "Alpha Two"


def test_title_is_weighted(search):
    # "beta" appears only in the title/url of Beta Overview.
    results = search.search("beta")
    assert results[0].doc.title == "Beta Overview"


def test_project_filter(search):
    results = search.search("postgresql", project="alpha")
    assert results
    assert all(r.doc.project == "alpha" for r in results)


def test_limit_is_respected(search):
    results = search.search("postgresql", limit=1)
    assert len(results) == 1


def test_empty_query_returns_nothing(search):
    assert search.search("") == []
    assert search.search("   ") == []


def test_no_match_returns_nothing(search):
    assert search.search("zzzznonexistentterm") == []


def test_snippet_contains_query_term(search):
    results = search.search("certificate")
    assert "certificate" in results[0].snippet.lower()


def test_empty_corpus_is_safe():
    s = DocSearch(Corpus(docs=[], index=[]))
    assert s.search("anything") == []
