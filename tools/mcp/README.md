# OpenVox Docs MCP server

[![MCP server](https://github.com/OpenVoxProject/openvox-docs/actions/workflows/mcp.yml/badge.svg)](https://github.com/OpenVoxProject/openvox-docs/actions/workflows/mcp.yml)

A local [Model Context Protocol](https://modelcontextprotocol.io/) server that
exposes the OpenVox documentation to MCP-aware tools (Claude Code, Cursor, Claude
Desktop, …) so an assistant can search and read the docs in-workflow.

It is the local, self-hosted counterpart to a hosted "Ask AI" widget: no third
party, no API key, no usage quota, and queries never leave your machine.

![Claude Code answering a question by calling the openvox-docs MCP server](demo/demo.gif)

> Recorded with [VHS](https://github.com/charmbracelet/vhs) from
> [`demo/demo.tape`](demo/demo.tape); regenerate with `vhs tools/mcp/demo/demo.tape`.

## How it works

The server's corpus is the two machine-readable files the docs site publishes
(see the repository README's "LLM-friendly documentation files" section):

- [`llms.txt`](https://docs.openvoxproject.org/llms.txt) — the index of pages,
  grouped by project.
- [`llms-full.txt`](https://docs.openvoxproject.org/llms-full.txt) — the full
  text of every current ("latest") page, including the generated reference pages
  (configuration, function, type, man pages).

On first use it fetches both from `https://docs.openvoxproject.org`, caches them
under `~/.cache/openvox-docs-mcp/` with conditional requests (so refreshes are
cheap and it still works offline from the last copy), parses them into one
document per page, and builds a BM25 keyword index.

## Tools

| Tool | Purpose |
|------|---------|
| `list_projects` | List the documentation projects (openvox, openvox-server, …). |
| `list_docs(project?)` | List pages as `{project, title, url}`, optionally filtered to one project. |
| `search_docs(query, project?, limit=5)` | BM25 keyword search; returns `{title, url, project, score, snippet}`. |
| `get_doc(ref, max_chars=40000)` | Full text of one page, resolved by URL, URL path, or exact title. The body is capped at `max_chars` (the single-page function/type references are very large); raise it to fetch more. |
| `refresh_corpus()` | Force a re-fetch of the llms files and rebuild the index. |

## Install

Requires Python 3.10+.

```console
cd tools/mcp
python -m venv .venv && . .venv/bin/activate
pip install -e .
```

## Register with an MCP client

All clients launch the same stdio entry point. Use the **absolute path** to the
installed executable — `tools/mcp/.venv/bin/openvox-docs-mcp` after the install
above (substitute your checkout path). Each client's config also accepts an `env`
block if you want to set the variables from [Configuration](#configuration)
(for example `OPENVOX_DOCS_SOURCE`).

### Claude Code

```console
claude mcp add openvox-docs -- /path/to/tools/mcp/.venv/bin/openvox-docs-mcp
```

Or add it to a project-scoped `.mcp.json`:

```json
{
  "mcpServers": {
    "openvox-docs": {
      "command": "/path/to/tools/mcp/.venv/bin/openvox-docs-mcp"
    }
  }
}
```

### Cursor

Add it to `~/.cursor/mcp.json` (global) or `.cursor/mcp.json` (project). Cursor
uses the same `mcpServers` schema as Claude Code:

```json
{
  "mcpServers": {
    "openvox-docs": {
      "command": "/path/to/tools/mcp/.venv/bin/openvox-docs-mcp"
    }
  }
}
```

### GitHub Copilot (VS Code)

Add it to `.vscode/mcp.json` in your workspace (or run **MCP: Add Server** from
the Command Palette). VS Code uses a top-level `servers` key, and stdio is the
default for a `command`:

```json
{
  "servers": {
    "openvox-docs": {
      "type": "stdio",
      "command": "/path/to/tools/mcp/.venv/bin/openvox-docs-mcp"
    }
  }
}
```

Or from the command line:

```console
code --add-mcp '{"name":"openvox-docs","command":"/path/to/tools/mcp/.venv/bin/openvox-docs-mcp"}'
```

### Codex CLI

Add it to `~/.codex/config.toml` (or a project-scoped `.codex/config.toml`).
Codex uses a `mcp_servers` TOML table:

```toml
[mcp_servers.openvox-docs]
command = "/path/to/tools/mcp/.venv/bin/openvox-docs-mcp"
```

## Testing

Install the dev extras, then run the suite:

```console
pip install -e '.[dev]'
pytest
```

`pytest` reports coverage and fails under 90% (configured in `pyproject.toml`).
The unit tests cover corpus parsing, remote fetch/caching (offline fallback and
304 reuse), BM25 ranking, and every tool. For an end-to-end check that launches
the server over stdio and exercises all five tools against a throwaway corpus
(network- and model-free):

```console
python smoke_test.py
```

## Configuration

The server is configured entirely through environment variables:

| Variable | Default | Effect |
|----------|---------|--------|
| `OPENVOX_DOCS_BASE_URL` | `https://docs.openvoxproject.org` | Site to fetch the llms files from. |
| `OPENVOX_DOCS_SOURCE` | _(unset)_ | Read `llms.txt` / `llms-full.txt` from a local directory instead of fetching. Point it at a Jekyll `_site/` build for offline or pre-release use. |

For example, to run against a local build of this repo:

```console
bundle exec jekyll build
OPENVOX_DOCS_SOURCE="$PWD/_site" openvox-docs-mcp
```

> **Note:** until the `llms.txt` / `llms-full.txt` feature is deployed to the live
> site, set `OPENVOX_DOCS_SOURCE` to a local `_site/` build — the live URLs will
> 404 otherwise.
