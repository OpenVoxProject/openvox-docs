"""BM25 keyword search over the parsed corpus.

The body text in ``llms-full.txt`` is plain text (HTML stripped at build time),
so a simple word-token BM25 index gives good results for the term-oriented
lookups docs search is used for, with no model or network dependency.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

from rank_bm25 import BM25Okapi

from .corpus import Corpus, Doc

_TOKEN_RE = re.compile(r"[a-z0-9_]+")


def _tokenize(text: str) -> list[str]:
    return _TOKEN_RE.findall(text.lower())


@dataclass
class SearchResult:
    doc: Doc
    score: float
    snippet: str


class DocSearch:
    """A BM25 index over a corpus's documents.

    The title is weighted by repetition so a query term in the title outranks the
    same term buried in the body.
    """

    TITLE_WEIGHT = 3

    def __init__(self, corpus: Corpus) -> None:
        self.docs = corpus.docs
        tokenized = [
            _tokenize(doc.title) * self.TITLE_WEIGHT + _tokenize(doc.body)
            for doc in self.docs
        ]
        # BM25Okapi requires at least one non-empty document.
        self._bm25 = BM25Okapi(tokenized) if any(tokenized) else None

    def search(
        self, query: str, *, project: str | None = None, limit: int = 5
    ) -> list[SearchResult]:
        if self._bm25 is None or not query.strip():
            return []
        tokens = _tokenize(query)
        if not tokens:
            return []
        scores = self._bm25.get_scores(tokens)
        ranked = sorted(
            zip(self.docs, scores), key=lambda pair: pair[1], reverse=True
        )
        results: list[SearchResult] = []
        for doc, score in ranked:
            if score <= 0:
                break
            if project and doc.project != project:
                continue
            results.append(
                SearchResult(doc=doc, score=float(score), snippet=_snippet(doc.body, tokens))
            )
            if len(results) >= limit:
                break
        return results


def _snippet(body: str, query_tokens: list[str], *, width: int = 240) -> str:
    """Return a short excerpt around the first query-term hit."""
    if not body:
        return ""
    lowered = body.lower()
    pos = -1
    for token in query_tokens:
        found = lowered.find(token)
        if found != -1 and (pos == -1 or found < pos):
            pos = found
    if pos == -1:
        excerpt = body[:width]
        suffix = "…" if len(body) > width else ""
        return " ".join(excerpt.split()) + suffix
    start = max(0, pos - width // 3)
    end = min(len(body), pos + (2 * width) // 3)
    excerpt = body[start:end]
    prefix = "…" if start > 0 else ""
    suffix = "…" if end < len(body) else ""
    return prefix + " ".join(excerpt.split()) + suffix
