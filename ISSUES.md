# Issues

## Closed

### Duplicate IDs in catalog.json after adding PowerShell 7
When PowerShell 7 was inserted as id 4, Node.js and OpenSSH both ended up with id 5. Fixed by rewriting catalog.json with correct sequential IDs (1-14 tools, 15-21 models).

### PS1 model categories lost during catalog migration
The catalog loading code set all models to `category = "model"`, but PS1 uses "model", "model-lg", "model-cloud" for UI grouping. Fixed by adding category field to catalog.json models.

### Bash preset IDs wrong after renumbering
When PowerShell 7 was inserted, all subsequent IDs shifted. The bash script's preset arrays and Ollama check had stale IDs. Fixed: dev=(1 2 3 4 5 6 7), Ollama check uses id 12.

### Tool count mismatch in docs
README and index.html said "13 tools" but catalog had 14. Fixed to "14 tools" in both files. Added PowerShell 7 to README tools table.

## Open

None.
