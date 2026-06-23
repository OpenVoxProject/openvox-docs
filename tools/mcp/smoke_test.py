#!/usr/bin/env python
"""Stand-alone smoke test for the OpenVox docs MCP server.

Launches the server over stdio against a tiny throwaway corpus and exercises
every tool, asserting on the results. It is network- and model-free, so it runs
anywhere (including CI):

    python smoke_test.py

Exits 0 on success, 1 on the first failed check.
"""

from __future__ import annotations

import asyncio
import sys
import tempfile
from pathlib import Path

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

SAMPLE_INDEX = """\
# Sample Docs

> A throwaway corpus.

## alpha

- [Alpha One](https://docs.openvoxproject.org/alpha/latest/one.html)
- [Alpha Two](https://docs.openvoxproject.org/alpha/latest/two.html)

## beta

- [Beta Overview](https://docs.openvoxproject.org/beta/latest/index.html)
"""

SAMPLE_FULL = """\
# Sample Docs

> A throwaway corpus.

# Project: alpha


---

## Alpha One

Source: https://docs.openvoxproject.org/alpha/latest/one.html

PostgreSQL tuning notes for alpha one.


---

## Alpha Two

Source: https://docs.openvoxproject.org/alpha/latest/two.html

Configuring an external certificate authority for alpha two.


# Project: beta


---

## Beta Overview

Source: https://docs.openvoxproject.org/beta/latest/index.html

Beta overview body text.
"""


def _value(result):
    """Unwrap a tool result's structured content (scalars/lists come wrapped)."""
    sc = result.structuredContent
    if isinstance(sc, dict) and set(sc.keys()) == {"result"}:
        return sc["result"]
    return sc


class Checker:
    def __init__(self) -> None:
        self.failures = 0

    def check(self, label: str, ok: bool, detail: str = "") -> None:
        mark = "ok  " if ok else "FAIL"
        print(f"  [{mark}] {label}{f' — {detail}' if detail and not ok else ''}")
        if not ok:
            self.failures += 1


async def run(source: Path, c: Checker) -> None:
    params = StdioServerParameters(
        command=sys.executable,
        args=["-m", "openvox_docs_mcp"],
        env={"OPENVOX_DOCS_SOURCE": str(source)},
    )
    async with stdio_client(params) as (reader, writer):
        async with ClientSession(reader, writer) as session:
            await session.initialize()

            tools = {t.name for t in (await session.list_tools()).tools}
            expected = {
                "list_projects",
                "list_docs",
                "search_docs",
                "get_doc",
                "refresh_corpus",
            }
            c.check("all tools registered", expected <= tools, str(expected - tools))

            projects = _value(await session.call_tool("list_projects", {}))
            c.check("list_projects", projects == ["alpha", "beta"], str(projects))

            docs = _value(await session.call_tool("list_docs", {}))
            c.check("list_docs returns all pages", len(docs) == 3, str(len(docs)))

            alpha = _value(await session.call_tool("list_docs", {"project": "alpha"}))
            c.check(
                "list_docs project filter",
                len(alpha) == 2 and all(d["project"] == "alpha" for d in alpha),
            )

            hits = _value(
                await session.call_tool("search_docs", {"query": "postgresql"})
            )
            c.check(
                "search_docs ranks the right page",
                bool(hits) and hits[0]["title"] == "Alpha One",
                str(hits[:1]),
            )

            ca = _value(
                await session.call_tool(
                    "search_docs", {"query": "certificate authority", "project": "alpha"}
                )
            )
            c.check(
                "search_docs scoped + relevant",
                bool(ca) and ca[0]["title"] == "Alpha Two",
                str(ca[:1]),
            )

            by_title = _value(
                await session.call_tool("get_doc", {"ref": "Beta Overview"})
            )
            c.check(
                "get_doc by title",
                by_title["url"].endswith("/beta/latest/index.html")
                and "overview body" in by_title["content"],
            )

            by_path = _value(
                await session.call_tool(
                    "get_doc", {"ref": "/alpha/latest/one.html"}
                )
            )
            c.check("get_doc by path", by_path["title"] == "Alpha One")

            capped = _value(
                await session.call_tool(
                    "get_doc", {"ref": "Alpha One", "max_chars": 10}
                )
            )
            c.check(
                "get_doc honours max_chars",
                capped["truncated"] is True and "[truncated" in capped["content"],
            )

            # A tool that raises surfaces as a result with isError set, not a
            # client-side exception.
            unknown = await session.call_tool("get_doc", {"ref": "does-not-exist"})
            c.check("get_doc unknown ref errors", bool(unknown.isError))

            refreshed = _value(await session.call_tool("refresh_corpus", {}))
            c.check(
                "refresh_corpus",
                refreshed["indexed_pages"] == 3 and refreshed["full_text_pages"] == 3,
                str(refreshed),
            )


def main() -> int:
    c = Checker()
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp)
        (src / "llms.txt").write_text(SAMPLE_INDEX, encoding="utf-8")
        (src / "llms-full.txt").write_text(SAMPLE_FULL, encoding="utf-8")
        print(f"Running smoke test against {src}")
        asyncio.run(run(src, c))
    print()
    if c.failures:
        print(f"FAILED: {c.failures} check(s)")
        return 1
    print("All checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
