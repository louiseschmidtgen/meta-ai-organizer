# MCP Server Setup

Configuration for [Model Context Protocol](https://modelcontextprotocol.io/) servers used by AI agents in VS Code (GitHub Copilot).

## Config File Location

```
~/Library/Application Support/Code/User/mcp.json
```

## Servers

### 1. GitHub MCP (Docker — local)

Provides tools for creating PRs, searching code, managing issues, etc.

**Prerequisites:**
- Docker Desktop running
- A [GitHub Personal Access Token](https://github.com/settings/tokens) with repo scope

**Setup:**

1. Create the PAT at https://github.com/settings/tokens (fine-grained or classic)

2. Store it as an environment variable in `~/.zshenv`:

   ```bash
   echo 'export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"' >> ~/.zshenv
   source ~/.zshenv
   ```

3. Add to `mcp.json`:

   ```json
   "github": {
       "command": "docker",
       "args": [
           "run", "-i", "--rm",
           "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
           "ghcr.io/github/github-mcp-server"
       ],
       "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
       },
       "type": "stdio"
   }
   ```

4. Restart VS Code (the Docker container needs the env var at startup)

**Note:** Do NOT hardcode the token in `mcp.json`. Use `${GITHUB_PERSONAL_ACCESS_TOKEN}` to reference the env var.

### 2. GitHub MCP (Copilot-hosted)

A hosted GitHub MCP server provided by Copilot — no Docker or PAT needed. Uses your existing Copilot authentication.

```json
"io.github.github/github-mcp-server": {
    "type": "http",
    "url": "https://api.githubcopilot.com/mcp/",
    "gallery": "https://api.mcp.github.com",
    "version": "0.33.0"
}
```

No additional setup required — just add it and it works.

### 3. Atlassian (Jira + Confluence)

Provides tools for creating/editing Jira issues, transitioning statuses, adding comments, searching with JQL, and managing Confluence pages.

```json
"com.atlassian/atlassian-mcp-server": {
    "type": "http",
    "url": "https://mcp.atlassian.com/v1/mcp",
    "gallery": "https://api.mcp.github.com",
    "version": "1.1.1"
}
```

**Setup:**

1. Add the config above to `mcp.json`
2. On first use, VS Code will open a browser for Atlassian OAuth login
3. Authorize the connection — no API token needed

**Required OAuth scopes** (granted automatically via the hosted server):
- `read:jira-work` — read issues, search with JQL
- `write:jira-work` — create/edit issues, add comments, transition statuses

**Usage:**

Find your cloud ID first:
```
Tool: getAccessibleAtlassianResources
```

Then use the site URL as `cloudId` (e.g. `warthogs.atlassian.net`) in all subsequent calls.

## Full `mcp.json` Example

```json
{
    "servers": {
        "github": {
            "command": "docker",
            "args": [
                "run", "-i", "--rm",
                "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
                "ghcr.io/github/github-mcp-server"
            ],
            "env": {
                "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
            },
            "type": "stdio"
        },
        "io.github.github/github-mcp-server": {
            "type": "http",
            "url": "https://api.githubcopilot.com/mcp/",
            "gallery": "https://api.mcp.github.com",
            "version": "0.33.0"
        },
        "com.atlassian/atlassian-mcp-server": {
            "type": "http",
            "url": "https://mcp.atlassian.com/v1/mcp",
            "gallery": "https://api.mcp.github.com",
            "version": "1.1.1"
        }
    },
    "inputs": []
}
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| GitHub MCP tools not working after restart | Check `echo $GITHUB_PERSONAL_ACCESS_TOKEN` in terminal; ensure Docker is running |
| Atlassian asks to re-authenticate | OAuth token expired — re-auth via browser prompt |
| `${GITHUB_PERSONAL_ACCESS_TOKEN}` not resolved | Restart VS Code after adding to `~/.zshenv`; VS Code reads env at launch |
| Docker MCP server fails to start | Run `docker pull ghcr.io/github/github-mcp-server` to update the image |
