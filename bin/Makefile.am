include $(top_srcdir)/rules.mk

sbin_SCRIPTS = \
               ripe-atlas

atlas_scripts_SCRIPTS = \
                        arch/generic/generic-ATLAS.sh \
                        arch/generic/generic-common.sh \
                        arch/generic/generic-reginit.sh \
                        arch/linux/linux-functions.sh \
                        array.lib.sh \
                        atlas_log.lib.sh \
                        class.lib.sh \
                        json.lib.sh \
                        paths.lib.sh \
                        support.lib.sh \
                        common.sh \
                        common-pre.sh \
                        config.sh \
                        reginit.sh \
                        resolvconf

if PROBE_TYPE_HW
atlas_scripts_SCRIPTS += \
                        arch/openwrt-hwprobe/openwrt-hwprobe-ATLAS.sh \
                        arch/openwrt-hwprobe/openwrt-hwprobe-common.sh \
                        arch/openwrt-hwprobe/openwrt-hwprobe-reginit.sh
endif

CLEANFILES = \
             paths.lib.sh \
             common.sh \
             common-pre.sh \
             config.sh \
             reginit.sh \
             ripe-atlas \
             resolvconf

ripe-atlas:	ripe-atlas.in
	@rm -f $@
	$(AM_V_GEN)$(SUBST_PATHS) $< > $@
if SHELL_FIXUP
	$(AM_V_FIXUP)$(SHEFIX) $@
endif

resolvconf:	resolvconf.in
	@rm -f $@
	$(AM_V_GEN)$(SUBST_PATHS) $< > $@
if SHELL_FIXUP
	$(AM_V_FIXUP)$(SHEFIX) $@
endif
