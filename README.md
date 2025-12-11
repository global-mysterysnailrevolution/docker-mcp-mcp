# 🐳 Docker MCP Gateway - One-Click Setup

**Consolidate all your MCP servers into ONE gateway. Reduce context window usage by 90%+.**

Instead of 5 MCP servers with 50 tools flooding your AI's context (~20,000 tokens), you get 1 gateway that dynamically loads only what you need (~500 tokens).

---

## ⚡ Quick Install

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/docker-mcp-setup/main/install.ps1 | iex
```

Or download and double-click `install.bat`

### What it does

1. ✅ Installs Docker Desktop (if needed)
2. ✅ Enables MCP Toolkit
3. ✅ Configures **Claude Code**, **Cursor**, and **Claude Desktop**
4. ✅ Adds essential MCP servers (GitHub, filesystem, fetch, etc.)

---

## 📁 Files

| File | Description |
|------|-------------|
| `install.bat` | Double-click to run (Windows) |
| `install.ps1` | Main PowerShell setup script |
| `sample-workflow.js` | Example code-execution workflow |

---

## 🔧 Manual Setup

If the script doesn't work, do this manually:

### 1. Install Docker Desktop

Download from https://www.docker.com/products/docker-desktop/

### 2. Enable MCP Toolkit

- Open Docker Desktop
- **Settings** → **Features in development**
- Enable **"MCP Toolkit"**
- Click **Apply & Restart**

### 3. Add MCP config to your AI tool

**Claude Code** (`~/.claude.json` or `%USERPROFILE%\.claude.json`):

```json
{
  "mcpServers": {
    "MCP_DOCKER": {
      "command": "docker",
      "args": ["mcp", "gateway", "run"],
      "type": "stdio"
    }
  }
}
```

**Cursor** (`~/.cursor/mcp.json` or `%USERPROFILE%\.cursor\mcp.json`):

```json
{
  "mcpServers": {
    "MCP_DOCKER": {
      "command": "docker",
      "args": ["mcp", "gateway", "run"],
      "type": "stdio"
    }
  }
}
```

**Claude Desktop** (`%APPDATA%\Claude\claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "MCP_DOCKER": {
      "command": "docker",
      "args": ["mcp", "gateway", "run"],
      "type": "stdio"
    }
  }
}
```

### 4. Add MCP Servers

In Docker Desktop → MCP Toolkit → Catalog, add:
- `github` - GitHub API
- `filesystem` - Local file access
- `fetch` - HTTP requests
- `puppeteer` - Browser automation
- `memory` - Persistent storage

---

## 🧪 Test It

After setup, restart your AI tool and ask:

> "List the MCP tools available to you"

You should see `MCP_DOCKER` with tools from the gateway.

---

## 🚀 Why This Matters

### Before (Traditional MCP)
```
Agent → MCP Server 1 (10 tools) → context
Agent → MCP Server 2 (10 tools) → context
Agent → MCP Server 3 (10 tools) → context
Total: 30 tool definitions = ~15,000 tokens in context
```

### After (Docker MCP Gateway)
```
Agent → Docker Gateway (searches tools on-demand) → context
Total: 1 gateway + selected tools = ~500 tokens
```

### Code Execution Workflows

Even better: use a code-execution MCP to orchestrate tools WITHOUT flooding context:

```javascript
// This runs in a sandbox - only the summary returns to your AI
async function workflow(callTool) {
  const data = await callTool("fetch", { url: "..." });  // 10KB stays in sandbox
  const more = await callTool("fetch", { url: "..." }); // 10KB stays in sandbox
  await callTool("filesystem.write", { path: "out.json", content: data });
  return { summary: "Fetched 2 URLs, saved to out.json" };  // Only this goes to AI
}
```

---

## 📚 Resources

- [Docker MCP Docs](https://docs.docker.com/ai/mcp-catalog-and-toolkit/)
- [MCP Server Catalog](https://hub.docker.com/mcp)
- [Dynamic MCP Blog Post](https://www.docker.com/blog/dynamic-mcps-stop-hardcoding-your-agents-world/)
- [Anthropic MCP Announcement](https://www.anthropic.com/news/model-context-protocol)
- [MCP Protocol Spec](https://modelcontextprotocol.io/)

---

## 🤝 Contributing

PRs welcome! This is a community tool to make MCP setup easier.

---

## 📄 License

MIT - Do whatever you want with it.

