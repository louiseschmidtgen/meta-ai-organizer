# Prompts

This directory holds the prompts used to instruct AI agents, making them reusable and version-controlled.

## Structure

Group prompts by agent, workflow, or use-case in subdirectories where it makes sense (e.g. `prompts/summarisation/`, `prompts/code-review/`).

## Naming Convention

```
<agent-or-task-name>_<short-description>.md
```

**Example:** `research-agent_web-search.md`

## What to Include in a Prompt File

- **Purpose** – one-line description of what this prompt achieves.
- **Model / Agent** – the target model or agent (e.g. GPT-4, Claude 3).
- **Prompt** – the full prompt text.
- **Variables** – list any `{{placeholders}}` and their expected values.
- **Example Output** – an illustrative sample response, if available.
- **Changelog** – brief notes on prompt revisions.
