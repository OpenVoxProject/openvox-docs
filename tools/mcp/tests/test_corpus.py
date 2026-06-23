"""Tests for corpus loading, parsing, and caching."""

from __future__ import annotations

import json

import httpx
import pytest

from openvox_docs_mcp import corpus as corpus_mod
from openvox_docs_mcp.corpus import Doc, _fetch_remote, _parse_full, load_corpus


def test_doc_path():
    d = Doc("p", "T", "https://docs.openvoxproject.org/p/latest/x.html", "")
    assert d.path == "/p/latest/x.html"


def test_load_from_source(sample_source):
    c = load_corpus(source=str(sample_source))
    assert c.source == str(sample_source)
    assert c.projects == ["alpha", "beta"]
    # index (llms.txt) and full text (llms-full.txt) each yield three pages.
    assert len(c.index) == 3
    assert len(c.docs) == 3


def test_parse_index_fields(sample_source):
    c = load_corpus(source=str(sample_source))
    one = next(d for d in c.index if d.title == "Alpha One")
    assert one.project == "alpha"
    assert one.url == "https://docs.openvoxproject.org/alpha/latest/one.html"


def test_parse_full_fields(sample_source):
    c = load_corpus(source=str(sample_source))
    one = next(d for d in c.docs if d.title == "Alpha One")
    assert one.project == "alpha"
    assert one.url == "https://docs.openvoxproject.org/alpha/latest/one.html"
    assert "PostgreSQL tuning" in one.body
    # the Source: line must not leak into the body
    assert "Source:" not in one.body


def test_parse_full_handles_missing_source_line():
    text = (
        "# Project: solo\n\n\n---\n\n## No Source Doc\n\n"
        "Body without a source line.\n"
    )
    docs = _parse_full(text)
    assert len(docs) == 1
    assert docs[0].title == "No Source Doc"
    assert docs[0].url == ""
    assert "Body without a source line." in docs[0].body


def test_load_from_source_missing_files_raises(tmp_path):
    with pytest.raises(RuntimeError):
        load_corpus(source=str(tmp_path))


# --- remote fetch / caching -------------------------------------------------


class _FakeResp:
    def __init__(self, status_code, text="", headers=None):
        self.status_code = status_code
        self.text = text
        self.headers = headers or {}

    def raise_for_status(self):
        if self.status_code >= 400:
            raise httpx.HTTPStatusError("err", request=None, response=None)


def test_fetch_remote_writes_cache_then_reuses_on_304(tmp_path, monkeypatch):
    calls = []

    def fake_get(url, headers=None, timeout=None, follow_redirects=None):
        calls.append(headers or {})
        if len(calls) == 1:
            return _FakeResp(200, text="hello body", headers={"ETag": '"v1"'})
        # second call should send the conditional header and get a 304
        assert headers.get("If-None-Match") == '"v1"'
        return _FakeResp(304)

    monkeypatch.setattr(corpus_mod.httpx, "get", fake_get)

    first = _fetch_remote("https://example.test", "llms.txt", tmp_path)
    assert first == "hello body"
    assert (tmp_path / "llms.txt").read_text() == "hello body"
    assert json.loads((tmp_path / "llms.txt.meta.json").read_text())["etag"] == '"v1"'

    second = _fetch_remote("https://example.test", "llms.txt", tmp_path)
    assert second == "hello body"
    assert len(calls) == 2


def test_fetch_remote_falls_back_to_cache_when_offline(tmp_path, monkeypatch):
    (tmp_path / "llms.txt").write_text("cached body", encoding="utf-8")

    def boom(*args, **kwargs):
        raise httpx.ConnectError("no network")

    monkeypatch.setattr(corpus_mod.httpx, "get", boom)
    assert _fetch_remote("https://example.test", "llms.txt", tmp_path) == "cached body"


def test_fetch_remote_raises_when_offline_and_no_cache(tmp_path, monkeypatch):
    def boom(*args, **kwargs):
        raise httpx.ConnectError("no network")

    monkeypatch.setattr(corpus_mod.httpx, "get", boom)
    with pytest.raises(RuntimeError):
        _fetch_remote("https://example.test", "llms.txt", tmp_path)


def test_load_corpus_remote_uses_cache_within_ttl(tmp_path, monkeypatch):
    # Point the cache dir at tmp and pre-populate a fresh cache so load_corpus
    # should not touch the network at all.
    monkeypatch.setenv("XDG_CACHE_HOME", str(tmp_path))
    cache = tmp_path / "openvox-docs-mcp"
    cache.mkdir(parents=True)
    (cache / "llms.txt").write_text(
        "## alpha\n\n- [A](https://docs.openvoxproject.org/alpha/latest/a.html)\n",
        encoding="utf-8",
    )
    (cache / "llms-full.txt").write_text(
        "# Project: alpha\n\n\n---\n\n## A\n\n"
        "Source: https://docs.openvoxproject.org/alpha/latest/a.html\n\nBody.\n",
        encoding="utf-8",
    )
    import time

    (cache / ".fetched_at").write_text(str(time.time()))

    def boom(*args, **kwargs):  # pragma: no cover - must not be called
        raise AssertionError("network was used despite a fresh cache")

    monkeypatch.setattr(corpus_mod.httpx, "get", boom)
    c = load_corpus()  # no source -> remote path, but cache is fresh
    assert c.projects == ["alpha"]
    assert len(c.docs) == 1
