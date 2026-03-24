# Contributing to OpenVox Docs

## Reporting issues

Use the [GitHub issue tracker](https://github.com/OpenVoxProject/openvox-docs/issues) to report errors, suggest improvements, or request new content. Please include the URL of the affected page when reporting a docs issue.

## Contributing changes

1. Fork the repository and create a branch for your change.
2. For documentation edits, modify the relevant files under `docs/`.
3. Preview your changes locally:

   ```bash
   python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
   .venv/bin/mkdocs serve
   ```

4. Open a pull request against `master` with a clear description of what changed and why.

## Regenerating reference docs

Reference documentation (resource types, functions, man pages, facts) is generated from OpenVox and Facter source code. To regenerate for a new release:

```bash
bundle install
bundle exec rake references:puppet VERSION=<tag-or-commit>
bundle exec rake references:facter VERSION=<tag-or-commit>
```

Copy the output from `references_output/` into the appropriate `docs/` subdirectory and open a pull request.

## Writing guidelines

- Use plain, direct language. Prefer active voice.
- Use second person ("you") for task instructions.
- Use the serial comma.
- Format: file names and code in backticks, GUI labels in **bold**, user-replaceable values in `<ANGLE_BRACKETS>`.
- Headings: use noun phrases for concepts, verb phrases for tasks.
