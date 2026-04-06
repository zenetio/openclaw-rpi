$env:OLLAMA_HOST = "0.0.0.0:11434"
$env:OLLAMA_CONTEXT_LENGTH = "16384"
Write-Host "Starting Ollama on $env:OLLAMA_HOST with context length $env:OLLAMA_CONTEXT_LENGTH"
ollama serve
