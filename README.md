# Agent Skills

A collection of skills for AI coding agents. Skills are packaged instructions and scripts that extend agent capabilities.

Skills follow the [Agent Skills](https://agentskills.io/) format.

## Available Skills

- **circleci-investigate** - Investigate CircleCI jobs, workflows, and pipelines. Fetches step logs, test results, artifacts, and resource usage from a job/pipeline URL or branch+job name. Use when debugging CI failures or analyzing build status.
- **cluster-creator-kit-script** - Search the Cluster Creator Kit Script API reference from its type definitions (`index.d.ts`). Looks up methods, signatures, and arguments for handles like `ItemHandle` and `PlayerHandle`. Use when you need Cluster Script API specs.
- **git-rebase** - Run `git rebase` non-interactively from natural language instructions. Handles commit reorganization (squash/fixup/reword/drop/split/reorder), upstream incorporation, conflict resolution, and stacked rebase (`--update-refs`). Use when reorganizing commit history.
- **github-pr-review-operation** - GitHub Pull Request review operations using `gh` CLI. Use when performing PR reviews, reading diffs, posting comments, or replying to review threads.
- **gws-docs-to-markdown** - Convert a Google Docs URL into a Markdown file with embedded images extracted to local files, using the `gws` CLI. Use when reading a Google Docs document.
- **search-cluster-creators-guide** - Search the Cluster Creators Guide (creator.cluster.mu) for how-to articles and fetch their full text as Markdown. Use when looking up how to do something in the Cluster Creator Kit (world/item creation guides, gimmicks, triggers).

## Installation

```bash
npx skills add shibayu36/agent-skills
```

## License

MIT