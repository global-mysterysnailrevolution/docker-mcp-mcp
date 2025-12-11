/**
 * Sample MCP Workflow - Code Execution Pattern
 * 
 * This demonstrates how to orchestrate multiple MCP tools
 * WITHOUT flooding your AI's context window.
 * 
 * BEFORE (traditional):
 *   Agent → fetch → 10KB in context
 *   Agent → fetch → 10KB in context  
 *   Agent → DB    → 5KB in context
 *   Total: 25KB in context window 😱
 * 
 * AFTER (code-execution workflow):
 *   Agent → code-exec (runs this script) → 200 byte summary
 *   Total: 200 bytes in context window 🎉
 * 
 * HOW TO USE:
 *   1. Add a code-execution MCP server (Node.js Sandbox, QuickJS Runner, etc.)
 *   2. Have your AI call it with this script
 *   3. Only the return value enters your context
 */

async function fetchAndProcess(callTool, options = {}) {
  const {
    urls = ["https://api.github.com/zen", "https://httpbin.org/uuid"],
    outputFile = "./results.json"
  } = options;

  const results = { fetched: [], errors: [] };

  // Fetch multiple URLs (data stays in sandbox, NOT in AI context)
  for (const url of urls) {
    try {
      const response = await callTool("fetch", { url });
      results.fetched.push({
        url,
        size: JSON.stringify(response).length,
        preview: JSON.stringify(response).slice(0, 50)
      });
    } catch (e) {
      results.errors.push({ url, error: e.message });
    }
  }

  // Save full data to file (AI can read later if needed)
  try {
    await callTool("filesystem.write_file", {
      path: outputFile,
      content: JSON.stringify(results, null, 2)
    });
    results.savedTo = outputFile;
  } catch (e) {
    results.savedTo = null;
  }

  // ONLY this summary goes back to the AI
  return {
    summary: `Fetched ${results.fetched.length}/${urls.length} URLs`,
    totalBytes: results.fetched.reduce((sum, f) => sum + f.size, 0),
    savedTo: results.savedTo,
    errors: results.errors.length > 0 ? results.errors : undefined
  };
}

// Example: Database ETL workflow
async function databaseSync(callTool, options = {}) {
  const { sourceQuery = "SELECT * FROM users LIMIT 100" } = options;
  
  // Extract
  const data = await callTool("postgres.query", { query: sourceQuery });
  
  // Transform (all in sandbox)
  const processed = (data.rows || []).map(row => ({
    ...row,
    synced_at: new Date().toISOString()
  }));
  
  // Load
  let inserted = 0;
  for (const row of processed) {
    try {
      await callTool("postgres.query", {
        query: "INSERT INTO users_backup (data) VALUES ($1)",
        params: [JSON.stringify(row)]
      });
      inserted++;
    } catch (e) { }
  }
  
  // Only summary returns to AI
  return {
    summary: `Synced ${inserted}/${processed.length} rows`,
    success: inserted === processed.length
  };
}

// Export for module usage
if (typeof module !== 'undefined') {
  module.exports = { fetchAndProcess, databaseSync };
}

// Direct execution
if (typeof callTool === 'function') {
  fetchAndProcess(callTool)
    .then(result => console.log("Result:", JSON.stringify(result, null, 2)))
    .catch(console.error);
}

