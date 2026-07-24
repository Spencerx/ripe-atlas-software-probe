include $(TOPDIR)/rules.mk

PKG_NAME:=ripe-atlas-probe
PKG_VERSION:=$(shell cat $(CURDIR)/../VERSION)
PKG_RELEASE:=1
PKG_LICENSE:=GPL
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=RIPE Atlas Team <atlas@ripe.net>
PKG_FIXUP=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

########### VARIABLES ###########

ATLAS_USER=ripe-atlas
ATLAS_GROUP=ripe-atlas
ATLAS_MEAS=ripe-atlas-measurement

# HWProbe V3
PROBE_FW_KEYS = \
	2017-11-07-dev.pem \
	2017-11-07-prod.pem \
	2017-11-07-test.pem

# HWProbe V4
PROBE_FW_KEYS += \
	2018-04-23-dev.pem \
	2018-04-23-prod.pem \
	2018-04-23-test.pem

# HWProbe V5
PROBE_FW_KEYS += \
	2021-02-02-dev.pem \
	2021-02-02-prod.pem \
	2021-02-02-test.pem

CONFIGURE_ARGS+= \
	--with-user=$(ATLAS_USER) \
	--with-group=$(ATLAS_GROUP) \
	--with-measurement-user=$(ATLAS_MEAS) \
	--disable-systemd \
	--disable-setcap-install \
	--disable-chown

########### GENERIC ###########

define Build/Prepare
	# Copy whole repo (dir above openwrt/) into build dir (22.03 & 25.12)
	$(CP) $(patsubst %/openwrt,%,$(CURDIR))/. $(PKG_BUILD_DIR)
endef

define LinkApplet
	$(LN) busybox $(1)/usr/lib/ripe-atlas/measurement/$(2)
endef

########### DEFAULTS ###########

define Package/ripe-atlas/Default
	TITLE:=RIPE Atlas
	SECTION:=net
	CATEGORY:=Network
	URL:=https://atlas.ripe.net/
endef

########### COMMON PKG ###########

define Package/ripe-atlas-common
	$(call Package/ripe-atlas/Default)
	TITLE+=(common files)
	USERID:=$(ATLAS_USER)=3333:$(ATLAS_GROUP)=3333 $(ATLAS_MEAS)=3334:$(ATLAS_GROUP)=3333
	DEPENDS+= \
                  +jsonfilter \
                  +openssh-client \
                  +openssh-keygen \
                  +libopenssl \
		  +@OPENSSL_WITH_DEPRECATED \
	          +@BUSYBOX_CONFIG_HOSTNAME \
	          +@BUSYBOX_CONFIG_KILL \
	          +@BUSYBOX_CONFIG_KILLALL \
	          +@BUSYBOX_CONFIG_PS \
	          +@BUSYBOX_CONFIG_SED \
	          +@BUSYBOX_CONFIG_TAR \
	          +@BUSYBOX_CONFIG_TEE \
                  +!PACKAGE_ntpd:chrony \
		  +!BUSYBOX_CONFIG_BUNZIP2:bzip2
	CONFLICTS:=atlasmsm \
	           atlasprobe \
	           atlas_extra_v3 \
	           atlas_extra_v4 \
	           atlas_extra_v5 \
	           atlas-sw-probe \
	           atlas-sw-probe-rpc
endef

define Package/ripe-atlas-common/conffiles
/etc/config/ripe-atlas
endef

define Package/ripe-atlas-common/description
RIPE Atlas (common files)

Essential core assets used in all probe flavours.
This package must be installed for a probe to operate
as expected.
endef

define Package/ripe-atlas-common/install
	$(INSTALL_DIR) \
		$(1)/etc/init.d \
		$(1)/etc/uci-defaults \
		$(1)/usr/lib/ripe-atlas/measurement \
		$(1)/usr/lib/ripe-atlas/scripts \
		$(1)/usr/share/ripe-atlas \
		$(1)/usr/sbin
	$(INSTALL_BIN) -t \
		$(1)/usr/lib/ripe-atlas/scripts \
		$(foreach script, \
			array.lib.sh \
			atlas_log.lib.sh \
			class.lib.sh \
			common-pre.sh \
			common.sh \
			generic-ATLAS.sh \
			generic-common.sh \
			generic-reginit.sh \
			json.lib.sh \
			linux-functions.sh \
			paths.lib.sh \
			reg_servers.sh.dev \
			reg_servers.sh.test \
			reginit.sh \
			resolvconf \
			support.lib.sh, \
			$(PKG_INSTALL_DIR)/usr/lib/ripe-atlas/scripts/$(script))
	$(INSTALL_BIN) \
		$(PKG_INSTALL_DIR)/usr/lib/ripe-atlas/measurement/busybox \
		$(1)/usr/lib/ripe-atlas/measurement/busybox
	$(INSTALL_BIN) \
		$(PKG_INSTALL_DIR)/usr/sbin/ripe-atlas \
		$(1)/usr/sbin/ripe-atlas
	$(INSTALL_DATA) -t \
		$(1)/usr/share/ripe-atlas \
		$(foreach file, \
			FIRMWARE_APPS_VERSION \
			measurement.conf, \
			$(PKG_INSTALL_DIR)/usr/share/ripe-atlas/$(file))
	$(INSTALL_DATA) -t \
		$(1)/usr/share/ripe-atlas \
		$(foreach file, \
			$(PROBE_FW_KEYS), \
			$(PKG_BUILD_DIR)/config/probe/$(file))
	$(INSTALL_BIN) files/ripe-atlas.init $(1)/etc/init.d/ripe-atlas
	$(INSTALL_BIN) files/ripe-atlas.uci-defaults $(1)/etc/uci-defaults/60_ripe-atlas
	$(INSTALL_DATA) files/capabilities.json $(1)/usr/share/ripe-atlas/capabilities.json
	$(call LinkApplet,$(1),atlasinit)
	$(call LinkApplet,$(1),buddyinfo)
	$(call LinkApplet,$(1),condmv)
	$(call LinkApplet,$(1),date)
	$(call LinkApplet,$(1),dfrm)
	$(call LinkApplet,$(1),eooqd)
	$(call LinkApplet,$(1),eperd)
	$(call LinkApplet,$(1),evhttpget)
	$(call LinkApplet,$(1),evntp)
	$(call LinkApplet,$(1),evping)
	$(call LinkApplet,$(1),evsslgetcert)
	$(call LinkApplet,$(1),evtdig)
	$(call LinkApplet,$(1),evtraceroute)
	$(call LinkApplet,$(1),httppost)
	$(call LinkApplet,$(1),onlyuptime)
	$(call LinkApplet,$(1),perd)
	$(call LinkApplet,$(1),rchoose)
	$(call LinkApplet,$(1),rptaddrs)
	$(call LinkApplet,$(1),rptra6)
	$(call LinkApplet,$(1),rptuptime)
	$(call LinkApplet,$(1),rxtxrpt)
	$(call LinkApplet,$(1),telnetd)
endef

########### SOFTWARE PROBE ###########

define Package/ripe-atlas-probe
	$(call Package/ripe-atlas/Default)
	TITLE+=(Software Probe)
	DEPENDS+=+ripe-atlas-common
	CONFLICTS:=ripe-atlas-hwprobe \
	           ripe-atlas-anchor
	MENU:=1
endef

define Package/ripe-atlas-probe/description
RIPE Atlas (Software Probe)

Probe specific files and configurations that
form a working software probe.

Please visit https://atlas.ripe.net/register/swprobe
to register.
endef

define Package/ripe-atlas-probe/install
	$(INSTALL_DIR) \
		$(1)/usr/lib/ripe-atlas/scripts \
		$(1)/usr/share/ripe-atlas
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/config/probe/known_hosts.reg \
		$(1)/usr/share/ripe-atlas
	$(INSTALL_BIN) \
		$(PKG_BUILD_DIR)/config/probe/reg_servers.sh.prod \
		$(1)/usr/lib/ripe-atlas/scripts
	$(INSTALL_BIN) \
		$(PKG_BUILD_DIR)/bin/config.sh \
		$(1)/usr/lib/ripe-atlas/scripts
endef

define Package/ripe-atlas-probe/conffiles
/etc/ripe-atlas/probe_key
/etc/ripe-atlas/probe_key.pub
endef

########### HARDWARE PROBE ###########

define Package/ripe-atlas-hwprobe
	$(call Package/ripe-atlas/Default)
	TITLE+=(Hardware Probe)
	DEPENDS+= \
		+ripe-atlas-common \
		+openssl-util
	PROVIDES+=ripe-atlas-probe
	CONFLICTS:=ripe-atlas-probe \
	           ripe-atlas-anchor
	MENU:=1
endef

define Package/ripe-atlas-hwprobe/description
RIPE Atlas (Hardware Probe)

Probe specific files and configurations that
form a working hardware probe.

Only install at the direction of RIPE NCC.
endef

define Package/ripe-atlas-hwprobe/install
	$(call Package/ripe-atlas-probe/install,$(1))
	$(INSTALL_BIN) -t \
		$(1)/usr/lib/ripe-atlas/scripts/ \
		$(foreach file, \
			openwrt-hwprobe-common.sh \
			openwrt-hwprobe-reginit.sh \
			openwrt-hwprobe-ATLAS.sh, \
			$(PKG_BUILD_DIR)/bin/arch/openwrt-hwprobe/$(file))

	$(SED) '1{s|=generic|=openwrt-hwprobe|}' \
		$(1)/usr/lib/ripe-atlas/scripts/config.sh
endef

define Package/ripe-atlas-hwprobe/conffiles
	$(call Package/ripe-atlas-probe/conffiles)
endef

########### ANCHOR ###########

define Package/ripe-atlas-anchor
	$(call Package/ripe-atlas/Default)
	TITLE+=(Anchor)
	DEPENDS+=+ripe-atlas-common
	PROVIDES+=ripe-atlas-probe
	CONFLICTS:=ripe-atlas-probe \
	           ripe-atlas-hwprobe
	MENU:=1
endef

define Package/ripe-atlas-anchor/description
RIPE Atlas (Anchor)

Probe specific files and configurations that form a working anchor.
Please visit https://atlas.ripe.net/anchors/apply/ to register.

Only install at the direction of RIPE NCC.
endef

define Package/ripe-atlas-anchor/install
	$(INSTALL_DIR) \
		$(1)/usr/lib/ripe-atlas/scripts \
		$(1)/usr/share/ripe-atlas
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/config/anchor/known_hosts.reg \
		$(1)/usr/share/ripe-atlas
	$(INSTALL_BIN) \
		$(PKG_BUILD_DIR)/config/anchor/reg_servers.sh.prod \
		$(1)/usr/lib/ripe-atlas/scripts
	$(INSTALL_BIN) \
		$(PKG_BUILD_DIR)/bin/config.sh \
		$(1)/usr/lib/ripe-atlas/scripts
endef

define Package/ripe-atlas-anchor/conffiles
/etc/ripe-atlas/probe_key
/etc/ripe-atlas/probe_key.pub
endef

########### PACKAGES ###########

$(eval $(call BuildPackage,ripe-atlas-common))
$(eval $(call BuildPackage,ripe-atlas-anchor))
$(eval $(call BuildPackage,ripe-atlas-hwprobe))
$(eval $(call BuildPackage,ripe-atlas-probe))
