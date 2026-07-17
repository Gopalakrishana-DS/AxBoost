# AxBoost v0.8.0 test checklist

1. Install/update and re-ignite AxManager.
2. Confirm `axboost status` reports v0.8.0.
3. Run `axboost compatibility`; verify every feature has Stable, Experimental, or Unsupported classification.
4. Run `axboost benchmark`; verify a baseline file is created under `/data/local/tmp/axboost/benchmarks`.
5. Assign a profile: `axboost game-profiles set <package> gaming`.
6. Confirm it with `axboost game-profiles list`.
7. Apply it manually with `axboost game-profiles apply <package>`.
8. Open WebUI Diagnostics and test Compatibility and Baseline buttons.
9. Run `axboost report` and confirm compatibility is included.
10. Run `axboost balanced` and verify backed-up values restore.
