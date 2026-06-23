"""Load and parse the OpenVox ``llms.txt`` / ``llms-full.txt`` corpus.

The two files are produced by the docs site build (see the repository README's
"LLM-friendly documentation files" section). They are designed for machine
consumption and use stable delimiters, so we can parse them into structured
documents without scraping HTML:

- ``llms.txt`` is the index: ``## <project>`` headers followed by
  ``- [Title](url)`` links.
- ``llms-full.txt`` is the full text: ``# Project: <project>`` banners followed,
  per document, by a ``---`` rule, a ``## <title>`` heading, a ``Source: <url>``
  line, and the document body.

The loader fetches both from the live docs site by default, caching them on disk
with conditional requests so repeated runs are cheap and offline use falls back
to the last good copy. A local source (e.g. a Jekyll ``_site`` build) can be used
instead via ``OPENVOX_DOCS_SOURCE`` for development or fully offline operation.
"""

from __future__ import annotations

import json
import os
import re
import time
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import urlparse

import httpx

DEFAULT_BASE_URL = "https://docs.openvoxproject.org"
INDEX_FILE = "llms.txt"
FULL_FILE = "llms-full.txt"

# Refresh the cache when it is older than this (seconds) unless forced.
DEFAULT_TTL = 24 * 60 * 60

# Per-document boundary in llms-full.txt: a horizontal rule on its own line
# followed by an ATX h2. We split on the rule and keep the heading.
_DOC_SPLIT_RE = re.compile(r"\n-{3,}\n+(?=## )")
_PROJECT_BANNER_RE = re.compile(r"^# Project: (.+)$", re.MULTILINE)
_INDEX_LINK_RE = re.compile(r"^- \[(?P<title>.+)\]\((?P<url>\S+)\)\s*$")
_INDEX_HEADER_RE = re.compile(r"^## (?P<project>.+)$")


@dataclass
class Doc:
    """A single documentation page extracted from the corpus."""

    project: str
    title: str
    url: str
    body: str

    @property
    def path(self) -> str:
        """The URL path (no scheme/host), handy for matching and display."""
        return urlparse(self.url).path or self.url


@dataclass
class Corpus:
    """The parsed docs corpus and its index."""

    docs: list[Doc] = field(default_factory=list)
    # Index entries (title + url per project) parsed from llms.txt. This can
    # include pages whose body is not in llms-full.txt and vice versa, so the
    # two are tracked independently.
    index: list[Doc] = field(default_factory=list)
    fetched_at: float = 0.0
    source: str = ""

    @property
    def projects(self) -> list[str]:
        seen: list[str] = []
        for doc in self.index or self.docs:
            if doc.project not in seen:
                seen.append(doc.project)
        return seen


def _cache_dir() -> Path:
    base = os.environ.get("XDG_CACHE_HOME") or os.path.join(
        os.path.expanduser("~"), ".cache"
    )
    path = Path(base) / "openvox-docs-mcp"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _read_local(source: str, name: str) -> str | None:
    candidate = Path(source) / name
    if candidate.is_file():
        return candidate.read_text(encoding="utf-8")
    return None


def _fetch_remote(base_url: str, name: str, cache: Path) -> str:
    """Fetch ``name`` from ``base_url`` with a conditional request.

    Stores the body and validators (ETag / Last-Modified) next to it so the next
    run can send ``If-None-Match`` / ``If-Modified-Since`` and reuse the cache on
    a 304. On any network error, falls back to the cached body if present.
    """
    url = f"{base_url.rstrip('/')}/{name}"
    body_path = cache / name
    meta_path = cache / f"{name}.meta.json"
    headers: dict[str, str] = {}
    meta: dict[str, str] = {}
    if meta_path.is_file():
        try:
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
        except (ValueError, OSError):
            meta = {}
    if body_path.is_file():
        if etag := meta.get("etag"):
            headers["If-None-Match"] = etag
        if last_modified := meta.get("last_modified"):
            headers["If-Modified-Since"] = last_modified

    try:
        resp = httpx.get(url, headers=headers, timeout=30.0, follow_redirects=True)
    except httpx.HTTPError as exc:
        if body_path.is_file():
            return body_path.read_text(encoding="utf-8")
        raise RuntimeError(f"failed to fetch {url} and no cache available: {exc}") from exc

    if resp.status_code == 304 and body_path.is_file():
        return body_path.read_text(encoding="utf-8")
    resp.raise_for_status()

    body = resp.text
    body_path.write_text(body, encoding="utf-8")
    new_meta = {}
    if etag := resp.headers.get("ETag"):
        new_meta["etag"] = etag
    if last_modified := resp.headers.get("Last-Modified"):
        new_meta["last_modified"] = last_modified
    meta_path.write_text(json.dumps(new_meta), encoding="utf-8")
    return body


def _parse_index(text: str) -> list[Doc]:
    docs: list[Doc] = []
    project = ""
    for line in text.splitlines():
        if header := _INDEX_HEADER_RE.match(line):
            project = header.group("project").strip()
            continue
        if link := _INDEX_LINK_RE.match(line):
            docs.append(
                Doc(
                    project=project,
                    title=link.group("title").strip(),
                    url=link.group("url").strip(),
                    body="",
                )
            )
    return docs


def _parse_full(text: str) -> list[Doc]:
    docs: list[Doc] = []
    # Split the file into project sections on the banner lines.
    banners = list(_PROJECT_BANNER_RE.finditer(text))
    sections: list[tuple[str, str]] = []
    for i, match in enumerate(banners):
        project = match.group(1).strip()
        start = match.end()
        end = banners[i + 1].start() if i + 1 < len(banners) else len(text)
        sections.append((project, text[start:end]))

    for project, section in sections:
        for chunk in _DOC_SPLIT_RE.split(section):
            chunk = chunk.strip()
            if not chunk.startswith("## "):
                continue
            lines = chunk.splitlines()
            title = lines[0][3:].strip()
            url = ""
            body_start = 1
            for idx in range(1, min(len(lines), 4)):
                stripped = lines[idx].strip()
                if stripped.startswith("Source:"):
                    url = stripped[len("Source:"):].strip()
                    body_start = idx + 1
                    break
            body = "\n".join(lines[body_start:]).strip()
            docs.append(Doc(project=project, title=title, url=url, body=body))
    return docs


def load_corpus(
    *,
    base_url: str | None = None,
    source: str | None = None,
    ttl: int = DEFAULT_TTL,
    force: bool = False,
) -> Corpus:
    """Load the corpus from a local source or the live docs site.

    ``source`` (or ``OPENVOX_DOCS_SOURCE``) reads ``llms.txt`` / ``llms-full.txt``
    from a directory (e.g. a Jekyll ``_site`` build). Otherwise the files are
    fetched from ``base_url`` (or ``OPENVOX_DOCS_BASE_URL``, default the live
    site) using the on-disk cache. ``force`` bypasses the TTL/conditional reuse.
    """
    source = source or os.environ.get("OPENVOX_DOCS_SOURCE")
    base_url = base_url or os.environ.get("OPENVOX_DOCS_BASE_URL") or DEFAULT_BASE_URL

    if source:
        index_text = _read_local(source, INDEX_FILE)
        full_text = _read_local(source, FULL_FILE)
        if index_text is None or full_text is None:
            raise RuntimeError(
                f"{INDEX_FILE} / {FULL_FILE} not found under source '{source}'"
            )
        used_source = source
    else:
        cache = _cache_dir()
        # Honour the TTL: if the cache is fresh and not forced, reuse without a
        # network round-trip at all.
        stamp = cache / ".fetched_at"
        fresh = (
            not force
            and stamp.is_file()
            and (time.time() - float(stamp.read_text() or 0)) < ttl
            and (cache / INDEX_FILE).is_file()
            and (cache / FULL_FILE).is_file()
        )
        if fresh:
            index_text = (cache / INDEX_FILE).read_text(encoding="utf-8")
            full_text = (cache / FULL_FILE).read_text(encoding="utf-8")
        else:
            index_text = _fetch_remote(base_url, INDEX_FILE, cache)
            full_text = _fetch_remote(base_url, FULL_FILE, cache)
            stamp.write_text(str(time.time()))
        used_source = base_url

    return Corpus(
        docs=_parse_full(full_text),
        index=_parse_index(index_text),
        fetched_at=time.time(),
        source=used_source,
    )
