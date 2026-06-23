"""Shared fixtures: a small, deterministic in-memory corpus."""

from __future__ import annotations

import pytest

from openvox_docs_mcp.corpus import Corpus, Doc
from openvox_docs_mcp.search import DocSearch

# Mirrors the real file formats closely enough to exercise the parsers.
SAMPLE_INDEX = """\
# Sample Docs

> A throwaway corpus.

Intro paragraph that should be ignored.

## alpha

- [Alpha One](https://docs.openvoxproject.org/alpha/latest/one.html)
- [Alpha Two](https://docs.openvoxproject.org/alpha/latest/two.html)

## beta

- [Beta Overview](https://docs.openvoxproject.org/beta/latest/index.html)
"""

SAMPLE_FULL = """\
# Sample Docs

> A throwaway corpus.

Intro paragraph that should be ignored.

# Project: alpha


---

## Alpha One

Source: https://docs.openvoxproject.org/alpha/latest/one.html

PostgreSQL tuning and performance notes for alpha one.


---

## Alpha Two

Source: https://docs.openvoxproject.org/alpha/latest/two.html

Configuring an external certificate authority (CA) for alpha two.


# Project: beta


---

## Beta Overview

Source: https://docs.openvoxproject.org/beta/latest/index.html

Beta overview body text mentioning postgresql once.
"""


@pytest.fixture
def sample_source(tmp_path):
    """A directory holding llms.txt / llms-full.txt, usable as OPENVOX_DOCS_SOURCE."""
    (tmp_path / "llms.txt").write_text(SAMPLE_INDEX, encoding="utf-8")
    (tmp_path / "llms-full.txt").write_text(SAMPLE_FULL, encoding="utf-8")
    return tmp_path


@pytest.fixture
def corpus() -> Corpus:
    docs = [
        Doc("alpha", "Alpha One", "https://docs.openvoxproject.org/alpha/latest/one.html",
            "PostgreSQL tuning and performance notes for alpha one."),
        Doc("alpha", "Alpha Two", "https://docs.openvoxproject.org/alpha/latest/two.html",
            "Configuring an external certificate authority (CA) for alpha two."),
        Doc("beta", "Beta Overview", "https://docs.openvoxproject.org/beta/latest/index.html",
            "Beta overview body text mentioning postgresql once."),
    ]
    index = [Doc(d.project, d.title, d.url, "") for d in docs]
    return Corpus(docs=docs, index=index, source="memory")


@pytest.fixture
def search(corpus) -> DocSearch:
    return DocSearch(corpus)
