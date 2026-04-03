# Lizi Shell

`lizi/` is the personal outer shell for a future "Lizi Edition CCB".

This layer is intentionally separated from the upstream core:
- `ccb`
- `install.ps1`
- `install.cmd`
- `lib/`

Current first-version scope:
- Keep a personal Windows entrypoint.
- Keep a personal PowerShell launcher wrapper.
- Keep Lizi-specific docs separate from upstream docs.

Current file roles:
- `bin/lizi.cmd`: Windows command-line outer entry.
- `bin/lizi.ps1`: PowerShell outer entry that will later call upstream `ccb`.
- `config/lizi.workbench.json`: Personal workbench config placeholder.

Current behavior:
- `lizi.cmd` forwards to `lizi.ps1`.
- `lizi.ps1` prints a clear placeholder message only.
- No core startup logic is changed.
