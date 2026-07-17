
## v0.9.0 WebUI redesign

- Modern mobile-first dashboard with glass-style cards and adaptive dark/light colors.
- Bottom navigation for easier one-handed use inside AxManager.
- Clearer profile, game, control, diagnostic, and log sections.
- Larger touch targets and improved small-screen layout.
- All existing v0.8.0 commands and safety behavior are preserved.

# AxBoost v0.8.0

A non-root AxManager toolkit focused on measurable, reversible Android controls.

## New in v0.8.0

- Device compatibility engine classifying features as Stable, Experimental, or Unsupported.
- Read-only performance baseline reports saved under `/data/local/tmp/axboost/benchmarks`.
- Persistent per-game profile assignments with explicit manual apply.
- Version consistency fixes across installer, status, and developer output.
- Compatibility report included in the combined diagnostic report.

## Commands

```text
axboost compatibility
axboost benchmark
axboost game-profiles list
axboost game-profiles set <package> <gaming|battery|balanced>
axboost game-profiles apply <package>
```

AxBoost does not bypass thermal protection, disable V-Sync, or write CPU/GPU governors.


## HyperOS 2 ADB tweaks

AxBoost v0.9.0 adds a whitelist of reversible Android SettingsProvider controls. Each write is backed up once and verified by reading the value back. Use `axboost tweaks list`, `axboost tweaks status`, `axboost tweaks apply <id>`, `axboost tweaks pack <responsive|battery|quiet|privacy>`, and `axboost tweaks restore`.

Excluded deliberately: fake `debug.*` properties, thermal bypass, CPU/GPU governor writes, LMK/ZRAM claims, V-Sync disabling, and FPS unlock properties.
