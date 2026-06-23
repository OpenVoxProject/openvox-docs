# VHS tape: the OpenVox docs MCP server used live from Claude Code.
#
# Prereqs:
#   - vhs installed (https://github.com/charmbracelet/vhs)
#   - the server registered with Claude Code (see ../README.md), e.g. pointing at
#     a local corpus via OPENVOX_DOCS_SOURCE
#   - the mcp__openvox-docs__* tools allowed (so the run isn't blocked on a
#     permission prompt)
#
# Render from the repo root:
#   vhs tools/mcp/demo/demo.tape

Output tools/mcp/demo/demo.gif

Require claude

Set Shell zsh
Set FontSize 16
Set Width 1200
Set Height 860
Set Padding 18
Set Theme "Catppuccin Mocha"
Set Framerate 12
Set TypingSpeed 50ms

# Quietly land in the repo root with a clean screen.
Hide
Type "cd /Users/michaelharp/projects/openvox-docs && clear"
Enter
Sleep 1s
Show

Type "claude"
Sleep 1s
Enter
Sleep 8s

Type@35ms "Using the openvox-docs MCP server's search_docs tool, find the OpenVoxDB PostgreSQL configuration page. Reply with only the page title and URL on one line."
Sleep 1s
Enter

# Wait for the model to call search_docs and write its (one-line) answer.
Sleep 35s

# Hold on the finished answer.
Sleep 3s
