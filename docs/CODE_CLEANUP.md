# Code Cleanup & Comment Style

Goal: concise, academic, precise.

Rules:
- Function-level docstring: one line summary + short param comment
- Remove verbose or conversational comments
- Use small inline notes only when necessary
- Tag unfinished work with:  # TODO: description
- Use lower_snake_case for variables and functions

Check for long comment blocks:
    Select-String -Path "scripts\**\*.gd" -Pattern "^\s*#.*" -Context 0,5 | Where-Object { \.Context.PostContext.Length -gt 2 }
