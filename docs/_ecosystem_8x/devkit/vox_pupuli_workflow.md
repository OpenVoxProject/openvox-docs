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

Maintainers can add a commit directly to a contributor's pull request branch when the author has enabled [**Allow edits by maintainers**](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/allowing-changes-to-a-pull-request-branch-created-from-a-fork) and your account has the required permissions.
This is useful for a small fix, a rebase, or a follow-up change that must land with the pull request.

Use direct pushes only when the change belongs with the pull request and the author is reachable.
For an independent fix, open a separate pull request instead.

First, confirm that maintainer edits are allowed and identify the head repository and branch:

```console
gh pr view <number> --repo <base-owner>/<base-repo> \
  --json maintainerCanModify,headRepositoryOwner,headRepository,headRefName \
  --jq '{maintainerCanModify, owner: .headRepositoryOwner.login, repo: .headRepository.name, branch: .headRefName}'
```

If you do not use the GitHub CLI, query the REST API directly.
Public repositories work without authentication.
Add an `Authorization: Bearer $GITHUB_TOKEN` header for private repositories or to avoid the anonymous rate limit:

```console
curl -fsSL -H 'Accept: application/vnd.github+json' \
  https://api.github.com/repos/<base-owner>/<base-repo>/pulls/<number> \
  | jq '{maintainer_can_modify, owner: .head.repo.owner.login, repo: .head.repo.name, branch: .head.ref}'
```

The same values are visible on the pull request page: the head owner and branch appear under the title, and `maintainer_can_modify` corresponds to the author allowing edits by maintainers.

Fetch the pull request branch and work on a local copy:

```console
git fetch upstream pull/<number>/head:pr-<number>
git switch pr-<number>
```

Make and commit the change with the usual Vox Pupuli requirements:

```console
git commit -s -S
```

Push to the **head repository and branch** from the command output, not to the base repository.
Add the fork as a temporary remote and use a dry run first:

```console
git remote add pr-head git@github.com:<head-owner>/<head-repo>.git
git push --dry-run pr-head HEAD:refs/heads/<branch>
git push pr-head HEAD:refs/heads/<branch>
```

The push must be a fast-forward.
Do not rewrite or force-push a contributor's branch without agreement.
If a rebase is necessary, coordinate it with the author first, use `--force-with-lease`, and tell the author to reset their local branch to the new head.

If maintainer edits are disabled, or you do not have push access to the fork, push the fix to your own fork and open a separate pull request.
Ask the author to cherry-pick it, or document the dependency and rebase the original pull request after the fix merges.

After pushing, confirm that the pull request shows the new commit and that CI has started again.
{: .tip }
