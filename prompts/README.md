# Prompts

This directory holds the prompts used to instruct AI agents, making them reusable and version-controlled.

## What to Include in a Prompt File

- **Purpose** – one-line description of what this prompt achieves.
- **Model / Agent** – the target model or agent (e.g. GPT-4, Claude 3).
- **Prompt** – the full prompt text.
- **Variables** – list any `{{placeholders}}` and their expected values.
- **Example Output** – an illustrative sample response, if available.
- **Changelog** – brief notes on prompt revisions.

## How to Use a Prompt

### In VS Code with GitHub Copilot

Reference a prompt file in the chat input using `#file`, then supply your variable values:

```
#file:prompts/batch-processing.md

Use this workflow with:
- ORG: charmed-kubernetes
- SCRIPT_PATH: projects/pin-actions-to-sha/scripts/pin-actions.sh
- BRANCH_NAME: KU-5612/pin-actions-to-sha
- COMMIT_MESSAGE: "ci: pin GitHub Actions to commit SHAs"
- STAGE_PATHS: .github/
- PROGRESS_FILE: projects/pin-actions-to-sha/PROGRESS.yaml
- BATCH_SIZE: 10

Repos: cdk-addons, cdk-shrinkwrap, charm-aws-integrator
```

You can also be brief — just point at the prompt and describe what you need:

```
Resume the pin-actions campaign following #file:prompts/resume-session.md
— project dir is projects/pin-actions-to-sha/
```

The agent reads the template, substitutes the variables, and follows the workflow.

### For a new campaign

1. Create a project directory under `projects/` with `scripts/`, `context/`, and a `PROGRESS.yaml`.
2. Reference `#file:prompts/enumerate-repos.md` to list and batch the target repos.
3. Reference `#file:prompts/batch-processing.md` with your campaign's variables to process each batch.
4. In a new session, reference `#file:prompts/resume-session.md` to pick up where you left off.
