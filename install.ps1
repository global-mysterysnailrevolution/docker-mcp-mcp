# Docker MCP Gateway - One-Click Setup
# 
# Quick install:
#   irm https://raw.githubusercontent.com/global-mysterysnailrevolution/docker-mcp-mcp/main/install.ps1 | iex
#
# Or download and run:
#   powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

Write-Host @"

  ____             _               __  __  ____ ____  
 |  _ \  ___   ___| | _____ _ __  |  \/  |/ ___|  _ \ 
 | | | |/ _ \ / __| |/ / _ \ '__| | |\/| | |   | |_) |
 | |_| | (_) | (__|   <  __/ |    | |  | | |___|  __/ 
 |____/ \___/ \___|_|\_\___|_|    |_|  |_|\____|_|    
                                                      
       Gateway Setup - One MCP to Rule Them All
       
"@ -ForegroundColor Cyan

function Write-Step { param([string]$M) Write-Host "`n[>] $M" -ForegroundColor Cyan }
function Write-OK { param([string]$M) Write-Host "[+] $M" -ForegroundColor Green }
function Write-Warn { param([string]$M) Write-Host "[!] $M" -ForegroundColor Yellow }

function Add-McpConfig {
    param([string]$Path)
    
    $config = @{ mcpServers = @{} }
    
    if (Test-Path $Path) {
        try {
            $content = Get-Content $Path -Raw -ErrorAction SilentlyContinue
            if ($content -and $content.Trim()) {
                $existing = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($existing) {
                    $config = @{}
                    $existing.PSObject.Properties | ForEach-Object {
                        if ($_.Name -eq "mcpServers" -and $_.Value) {
                            $servers = @{}
                            $_.Value.PSObject.Properties | ForEach-Object { $servers[$_.Name] = $_.Value }
                            $config["mcpServers"] = $servers
                        } else {
                            $config[$_.Name] = $_.Value
                        }
                    }
                }
            }
        } catch { }
    }
    
    if (-not $config.mcpServers) { $config["mcpServers"] = @{} }
    
    $config["mcpServers"]["MCP_DOCKER"] = @{
        command = "docker"
        args = @("mcp", "gateway", "run")
        type = "stdio"
    }
    
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    
    $config | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
}

# Step 1: Check/Install Docker
Write-Step "Checking Docker Desktop..."

$hasDocker = $null -ne (Get-Command docker -ErrorAction SilentlyContinue)
$needsRestart = $false

if (-not $hasDocker) {
    Write-Warn "Docker not installed"
    
    $hasWinget = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
    
    if ($hasWinget) {
        Write-Host "  Installing Docker Desktop via winget..."
        winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Docker Desktop installed!"
            $needsRestart = $true
        } else {
            Write-Warn "Install failed. Please install manually: https://docker.com/products/docker-desktop/"
            Start-Process "https://www.docker.com/products/docker-desktop/"
        }
    } else {
        Write-Warn "Please install Docker Desktop: https://docker.com/products/docker-desktop/"
        Start-Process "https://www.docker.com/products/docker-desktop/"
    }
} else {
    Write-OK "Docker is installed"
}

# Step 2: Configure all clients
Write-Step "Configuring MCP clients..."

# Claude Code
$claudeCodePath = "$env:USERPROFILE\.claude.json"
Write-Host "  Claude Code: $claudeCodePath"
try { Add-McpConfig $claudeCodePath; Write-OK "Claude Code configured" } catch { Write-Warn "Could not configure Claude Code" }

# Cursor
$cursorPath = "$env:USERPROFILE\.cursor\mcp.json"
Write-Host "  Cursor: $cursorPath"
try { Add-McpConfig $cursorPath; Write-OK "Cursor configured" } catch { Write-Warn "Could not configure Cursor" }

# Claude Desktop
$claudeDesktopPath = "$env:APPDATA\Claude\claude_desktop_config.json"
Write-Host "  Claude Desktop: $claudeDesktopPath"
try { Add-McpConfig $claudeDesktopPath; Write-OK "Claude Desktop configured" } catch { Write-Warn "Could not configure Claude Desktop" }

# Step 3: Try Docker MCP CLI
Write-Step "Configuring Docker MCP..."

$dockerRunning = $false
try {
    docker info 2>&1 | Out-Null
    $dockerRunning = ($LASTEXITCODE -eq 0)
} catch { }

if ($dockerRunning) {
    Write-OK "Docker is running"
    
    # Check MCP CLI
    $hasMcp = $false
    try {
        docker mcp --help 2>&1 | Out-Null
        $hasMcp = ($LASTEXITCODE -eq 0)
    } catch { }
    
    if ($hasMcp) {
        Write-OK "MCP Toolkit is enabled"
        
        Write-Host "  Adding MCP servers..."
        @("github", "filesystem", "fetch", "memory") | ForEach-Object {
            try {
                docker mcp server add $_ 2>&1 | Out-Null
                Write-Host "    + $_" -ForegroundColor Gray
            } catch { }
        }
        
        Write-Host "  Connecting clients..."
        @("cursor", "claude") | ForEach-Object {
            try { docker mcp client connect $_ 2>&1 | Out-Null } catch { }
        }
        Write-OK "MCP servers added"
    } else {
        Write-Warn "MCP Toolkit not enabled yet"
        Write-Host "    Enable it: Docker Desktop > Settings > Features in development > MCP Toolkit" -ForegroundColor Gray
    }
} elseif (-not $needsRestart) {
    Write-Warn "Docker not running. Please start Docker Desktop."
}

# Done!
Write-Host @"

==============================================================================
                              SETUP COMPLETE!
==============================================================================

"@ -ForegroundColor Green

if ($needsRestart) {
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host @"
  1. RESTART WINDOWS (required after Docker install)
  2. Open Docker Desktop, accept the license
  3. Settings > Features in development > Enable 'MCP Toolkit'
  4. Run this script again to add MCP servers
"@
} else {
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host @"
  1. Restart Cursor / Claude Desktop / Claude Code
  2. Test: "List the MCP tools available to you"
  3. Add more servers: Docker Desktop > MCP Toolkit > Catalog
"@
}

Write-Host @"

DOCS: https://docs.docker.com/ai/mcp-catalog-and-toolkit/

"@ -ForegroundColor Gray

Read-Host "Press Enter to exit"

