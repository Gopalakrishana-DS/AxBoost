# AxBoost installer script. This file is sourced by the AxManager installer.

if [ "${AXERON:-false}" != "true" ]; then
  abort "AxBoost v0.8.1 is intended for AxManager."
fi

ui_print "- Installing AxBoost v0.8.1"
ui_print "- Architecture: ${ARCH:-unknown}"
ui_print "- Android API: ${API:-unknown}"
ui_print "- AxManager server: ${AXERONVER:-unknown}"
ui_print "- Profiles are user-triggered; no boot-time performance tweaks."

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm_recursive "$MODPATH/scripts" 0 0 0755 0755
set_perm_recursive "$MODPATH/system/bin" 0 0 0755 0755
