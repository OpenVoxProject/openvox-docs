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

## Reference documentation

Resource types, functions, man pages, and facts are generated automatically from OpenVox and Facter source code when a release is published. You do not need to regenerate or commit these files.

If you need to change how docs are generated (e.g. fix a generator bug or add a new reference type), modify the tooling under `lib/puppet_references/` and open a pull request. You can test locally with:

```bash
bundle install
bundle exec rake references:puppet VERSION=<tag-or-commit>
```

Output lands in `references_output/` for local preview.

## Writing guidelines

- Use plain, direct language. Prefer active voice.
- Use second person ("you") for task instructions.
- Use the serial comma.
- Format: file names and code in backticks, GUI labels in **bold**, user-replaceable values in `<ANGLE_BRACKETS>`.
- Headings: use noun phrases for concepts, verb phrases for tasks.
