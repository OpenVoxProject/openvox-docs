---
layout: default
title: "The Vox Pupuli module maintenance workflow"
---

Vox Pupuli has a very fine-tuned workflow developed by maintaining 300+ modules over more than a decade.
It allows people with the proper permissions to release modules with a few GitHub actions and
it allows all of these modules to be maintained with a consistent set of test matrices, licenses, supported platforms, etc.

Because it has evolved over many years, the parts are all documented in separate guides on the docs pages.
In the future, this will be consolidated into a more coherent guide.

In the meantime, see the [pages of the Vox Pupuli docs](https://voxpupuli.org/docs/).

## Pushing a fix to a contributor's pull request branch

Maintainers can add a commit directly to a contributor's pull request branch when the author has enabled [**Allow edits by maintainers**](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/allowing-changes-to-a-pull-request-branch-created-from-a-fork), you have push access to the base repository, and the fork is user-owned with no branch restrictions that block your push.
This is useful for a small fix, a rebase, or a follow-up change that must land with the pull request.

Use direct pushes only when the change belongs with the pull request and the author is reachable.
For an independent fix, open a separate pull request instead.
{: .tip }

Confirm that maintainer edits are allowed:

```console
gh pr view <number> --repo <base-owner>/<base-repo> --json maintainerCanModify --jq .maintainerCanModify
```

The command must print `true`.
If it prints `false`, use the fallback at the end of this section.

Check out the pull request branch:

```console
gh pr checkout <number> --repo <base-owner>/<base-repo>
```

When edits are allowed, `gh pr checkout` points the local branch at the contributor's fork, so `git push` updates the pull request directly.
You do not have to add a remote.

Make and commit the change:

```console
git commit -s -S
```

Push the commit:

```console
git push
```

The push must be a fast-forward.
Do not rewrite or force-push a contributor's branch without agreement.
When a rebase is agreed, coordinate it with the author first, then add the fork as a remote so that `--force-with-lease` has a fetched reference to compare against:

```console
git remote add pr-head https://github.com/<head-owner>/<head-repo>.git
git fetch pr-head
git push --force-with-lease pr-head HEAD:refs/heads/<branch>
```

Tell the author to reset their local branch to the new head.

If maintainer edits are disabled, or you do not have push access to the fork, push the fix to your own fork and open a separate pull request.
Ask the author to cherry-pick it, or document the dependency and rebase the original pull request after the fix merges.

After pushing, confirm that the pull request shows the new commit and that CI has started again.

If you do not use the GitHub CLI, follow GitHub's guide to [committing changes to a pull request branch created from a fork](https://docs.github.com/en/pull-requests/how-tos/commit-changes/committing-changes-to-a-pull-request-branch-created-from-a-fork).
