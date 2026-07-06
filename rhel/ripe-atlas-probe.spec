%define     git_repo         ripe-atlas-software-probe
%define     build_dirname    %{git_repo}
%define     base_path        ripe-atlas
%define     service_name     ripe-atlas.service
%define     version          %(find . -name VERSION | head -1 | xargs -I {} sh -c "cat {}")

# define user to perform measurements
%define     atlas_measurement  ripe-atlas-measurement
%define     atlas_user         ripe-atlas
%define     atlas_group        ripe-atlas

# flag to ignore files installed in builddir but not packaged in the final RPM
%define	    _unpackaged_files_terminate_build	0

# prevent creation of the build ids in /usr/lib -> see https://access.redhat.com/discussions/5045161
%define	    _build_id_links none

# Files to migrate
%define	    atlas_olddir       /var/atlas-probe
%define	    atlas_oldkey       %{atlas_olddir}/etc/probe_key
%define	    atlas_oldmode      %{atlas_olddir}/state/mode
%define	    atlas_oldconfig    %{atlas_olddir}/state/config.txt
%define	    atlas_newdir       %{_sysconfdir}/%{base_path}
%define	    atlas_newkey       %{atlas_newdir}/probe_key
%define	    atlas_newmode      %{atlas_newdir}/mode
%define	    atlas_newconfig    %{atlas_newdir}/config.txt

# Workaround for systems using autoconf 2.69 and older
%if 0%{?rhel} >= 9
%define	    fix_rundir         %{_rundir}
%else
%define	    fix_rundir         %{_localstatedir}/run
%endif

%define     rpm_statedir       %{_localstatedir}/lib/rpm-state/%{base_path}

# Keep scripts intact
%define     __brp_mangle_shebangs_exclude_from ^%{_libexecdir}/%{base_path}/scripts/.*$

Name:	    	ripe-atlas-common
Summary:    	RIPE Atlas Software Probe Essentials
Group:      	Applications/Internet
Version:    	%{version}
Release:    	1%{?dist}
License:    	GPLv3.0
Requires:   	%{?el6:daemontools} %{?el7:psmisc} %{?el8:psmisc} openssh-clients iproute %{?el7:sysvinit-tools} %{?el8:procps-ng} %{?el9:procps-ng} %{?el10:procps-ng} net-tools hostname /bin/sh bash
Requires(pre):  %{_sbindir}/semanage %{_bindir}/systemd-sysusers %{_bindir}/systemd-tmpfiles
Requires(post): %{_sbindir}/semanage
BuildRequires:	rpm systemd-rpm-macros %{?el7:systemd} %{?el8:systemd} openssl-devel autoconf automake libtool make
URL:            https://atlas.ripe.net/
%{systemd_requires}

%description
Essential core assets used in all probe flavours. This package must be installed for a probe to operate as expected.

%package -n ripe-atlas-probe
Summary:	RIPE Atlas Software Probe
Group:		Applications/Internet
BuildArch:      noarch 
Requires:	ripe-atlas-common = %{version}-%{release}
Provides:	ripe-atlas-software-probe
Obsoletes:	atlasswprobe < 5080-3%{?dist}
Conflicts:      atlasprobe, atlasswprobe, ripe-atlas-anchor
URL:            https://atlas.ripe.net/register/swprobe

%description -n ripe-atlas-probe
Probe specific files and configurations that form a working software probe. Please visit https://atlas.ripe.net/register/swprobe to register.

%prep
echo "Building for probe version: %{version}"

# performing the steps of '%setup' manually since we are pulling from a remote git repo
echo "Cleaning build dir"
cd %{_builddir}
rm -rf %{_builddir}/%{build_dirname}
echo "Getting Sources..."

%{!?git_tag:%define git_tag master}
%{!?git_source:%define git_source https://github.com/RIPE-NCC}

git clone -b %{git_tag} %{git_source}/%{git_repo}.git %{_builddir}/%{build_dirname}

cd %{_builddir}/%{build_dirname}
%{?git_commit:git checkout %{git_commit}}

%build
cd %{_builddir}/%{build_dirname}
autoreconf -iv
./configure \
	--prefix=%{_prefix} \
	--sysconfdir=%{_sysconfdir} \
	--localstatedir=%{_localstatedir} \
	--libdir=%{_libdir} \
%if 0%{?rhel} >= 9
	--runstatedir=%{fix_rundir} \
%endif
	--with-user=%{atlas_user} \
	--with-group=%{atlas_group} \
	--with-measurement-user=%{atlas_measurement} \
	--enable-systemd \
	--disable-chown \
	--disable-setcap-install \
	--with-install-mode=probe
%make_build

%install
cd %{_builddir}/%{build_dirname}
%make_install
touch %{buildroot}%{atlas_newdir}/reg_servers.sh

%files
%{_sbindir}/*
%dir %{_datadir}/%{base_path}
%{_sysusersdir}/ripe-atlas.conf
%{_tmpfilesdir}/ripe-atlas.conf
%attr(0644, root, root) %{_datadir}/%{base_path}/measurement.conf
%{_datadir}/%{base_path}/FIRMWARE_APPS_VERSION
%config(noreplace) %attr(0644, %{atlas_user}, %{atlas_group}) %{atlas_newmode}
%attr(0770, %{atlas_user}, %{atlas_group}) %dir %{atlas_newdir}
%dir %{_libexecdir}/%{base_path}
%dir %{_libexecdir}/%{base_path}/measurement/
%{_libexecdir}/%{base_path}/measurement/a*
%{_libexecdir}/%{base_path}/measurement/buddyinfo
%{_libexecdir}/%{base_path}/measurement/c*
%{_libexecdir}/%{base_path}/measurement/d*
%{_libexecdir}/%{base_path}/measurement/e*
%{_libexecdir}/%{base_path}/measurement/h*
%{_libexecdir}/%{base_path}/measurement/o*
%{_libexecdir}/%{base_path}/measurement/p*
%{_libexecdir}/%{base_path}/measurement/r*
%{_libexecdir}/%{base_path}/measurement/t*
%caps(cap_net_raw=ep) %attr(4750, %{atlas_measurement}, %{atlas_group}) %{_libexecdir}/%{base_path}/measurement/busybox
%dir %{_libexecdir}/%{base_path}/scripts
%exclude %{_libexecdir}/%{base_path}/scripts/reg_servers.sh.*
%exclude %{atlas_newdir}/reg_servers.sh
%{_libexecdir}/%{base_path}/scripts/resolvconf
%{_libexecdir}/%{base_path}/scripts/*.sh

%files -n ripe-atlas-probe
%{_unitdir}/%{service_name}
%{_datadir}/%{base_path}/known_hosts.reg
%{_libexecdir}/%{base_path}/scripts/reg_servers.sh.*
%ghost %attr(0755, %{atlas_user}, %{atlas_group}) %{atlas_newdir}/reg_servers.sh

%define get_state() [ -f "%{rpm_statedir}/%1" ]

%define init_state() \
mkdir -p %{rpm_statedir} \
systemctl "%1" --quiet %{service_name} 1>/dev/null 2>&1 \
if [ $? -eq 0 ]; then \
	touch "%{rpm_statedir}/%1" 2>/dev/null \
else \
	rm -f "%{rpm_statedir}/%1" 2>/dev/null \
fi \
%{nil}

%define clear_state() rm -rf %{rpm_statedir} 1>/dev/null 2>&1

%define ensure_newdir_is_present() \
if (! [ -d "%{atlas_newdir}" ]); then \
	mkdir -p "%{atlas_newdir}" \
	chown -R "%{atlas_user}:%{atlas_group}" "%{atlas_newdir}" \
fi \
%{nil}

%define generate_key() \
encoder_safe_hostname=$(hostname -s | tr -cd 'a-zA-Z0-9._-') \
ssh-keygen -t ed25519 -P '' -C "$encoder_safe_hostname" -f "%{atlas_newkey}" \
chown -R "%{atlas_user}:%{atlas_group}" "%{atlas_newkey}" \
chown -R "%{atlas_user}:%{atlas_group}" "%{atlas_newkey}.pub" \
%{nil}

%pre -n ripe-atlas-common
%init_state is-enabled
%init_state is-active

if %{get_state is-enabled}; then
    systemctl disable %{service_name} 1>/dev/null 2>&1
fi

if %{get_state is-active}; then
    systemctl stop %{service_name} 1>/dev/null 2>&1
fi

%{_bindir}/systemd-sysusers --replace=%{_sysusersdir}/ripe-atlas.conf - <<EOF
g %{atlas_group} -
u %{atlas_user} - "RIPE Atlas" %{fix_rundir}/%{base_path} -
m %{atlas_user} %{atlas_group}
u %{atlas_measurement} - "RIPE Atlas Measurements" %{_localstatedir}/spool/%{base_path} -
m %{atlas_measurement} %{atlas_group}
EOF

%{_sbindir}/semanage fcontext -a -f a -t bin_t -r s0 %{_sbindir}/ripe-atlas 1>/dev/null 2>&1 || :
exit 0

%post -n ripe-atlas-common
%{_bindir}/systemd-tmpfiles --create %{_tmpfilesdir}/ripe-atlas.conf

if [ $1 -eq 0 ]; then
	%{_sbindir}/semanage fcontext -d -f a -t bin_t -r s0 %{_sbindir}/ripe-atlas > /dev/null 2>&1 || :
fi
exit 0

%define migrate_file() \
if ( [ -f "%1" ] && ! cmp -s "%1" "%2" 1>/dev/null 2>&1 ); then \
	install -D -p -m "%3" -o "%4" -g "%5" "%1" "%2" 1>/dev/null 2>&1; \
fi \
%{nil}

%define display_reginfo() \
url_encode_probe_key() { \
	printf '%%s' "$1" | sed \\\
		-e 's/%%/%%25/g' \\\
		-e 's/ /%%20/g' \\\
		-e 's/+/%%2B/g' \\\
		-e 's,/,%%2F,g' \\\
		-e 's/=/%%3D/g' ; \
} \
atlas_newkey_pub="%{atlas_newkey}.pub" \
atlas_probe_pubkey="$(cat "${atlas_newkey_pub}")" \
atlas_register_url_base="https://atlas.ripe.net/register/swprobe" \
atlas_register_url_with_key="${atlas_register_url_base}?key=$(url_encode_probe_key "$atlas_probe_pubkey")" \
if [ -z "${NO_COLOR-}" ] && [ -n "${TERM-}" ] && [ "${TERM-}" != dumb ] && { [ -t 2 ] || { : > /dev/tty; } 2>/dev/null; }; then \
	B='\\033[1m' \
	U='\\033[4m' \
	GRN='\\033[1;32m' \
	YEL='\\033[1;33m' \
	DIM='\\033[2m' \
	REV='\\033[7m' \
	NRV='\\033[27m' \
	R='\\033[0m' \
else \
	B='' GRN='' YEL='' DIM='' REV='' NRV='' R='' \
fi \
badge="${YEL}${REV} ACTION REQUIRED ${NRV}" \
printf '%b\\n' "${DIM}------------------------------------------------------------${R}" \
printf '%b\\n\\n' "${GRN}RIPE Atlas software probe installed.${R}" \
printf '%b\\n    %s\\n\\n' "${badge} ${U}Register your probe at:${R}" "$atlas_register_url_with_key" \
printf '%b\\n    %s\\n\\n' "${B}Your probe's public key (${atlas_newkey_pub}):${R}" "$atlas_probe_pubkey" \
printf '%b\\n    %b\\n' "${badge} ${U}After registering, start the service with:${R}" "${YEL}systemctl enable --now %{service_name}${R}" \
printf '%b\\n' "${DIM}------------------------------------------------------------${R}" \
%{nil}

%post -n ripe-atlas-probe
# Migrate configuration files
%migrate_file %{atlas_oldkey}     %{atlas_newkey}     0600 %{atlas_user} %{atlas_group}
%migrate_file %{atlas_oldkey}.pub %{atlas_newkey}.pub 0644 %{atlas_user} %{atlas_group}
%migrate_file %{atlas_oldmode}    %{atlas_newmode}    0644 %{atlas_user} %{atlas_group}
%migrate_file %{atlas_oldconfig}  %{atlas_newconfig}  0644 %{atlas_user} %{atlas_group}

# clean up old atlas installation, it is now obsolete
if ( [ -f "%{atlas_newkey}" ] &&
     [ -f "%{atlas_newkey}.pub" ] &&
     [ -f "%{atlas_newmode}" ] &&
     [ -d "%{atlas_olddir}" ] ); then
	# NOTE: %{atlas_newconfig} may not exist
	# if %{atlas_oldconfig} did not either
	rm -rf "%{atlas_olddir}"
fi

# clean environment of previous version (if any)
# on upgrade systemd restarts after this
rm -fr %{fix_rundir}/%{base_path}/status/* %{_sysconfdir}/%{base_path}/reg_servers.sh

%ensure_newdir_is_present

if (! [ -f "%{atlas_newkey}" ] ); then
	%generate_key
	%display_reginfo
fi

%systemd_post %{service_name}

if %{get_state is-enabled}; then
    systemctl enable %{service_name} 1>/dev/null 2>&1
fi

if %{get_state is-active}; then
	# Ensure any changes to the systemd unit
	# become known to the system before
	# restarting the service
	systemctl daemon-reload
	systemctl start %{service_name} 1>/dev/null 2>&1
fi

%clear_state
exit 0

%preun -n ripe-atlas-probe
if [ $1 -eq 0 ]; then
	systemctl disable %{service_name} 1>/dev/null 2>&1
	systemctl stop %{service_name} 1>/dev/null 2>&1
fi
exit 0

%preun -n ripe-atlas-common
# Uninstall
if [ $1 -eq 0 ]; then
	systemctl stop %{service_name} 1>/dev/null 2>&1
	systemctl disable %{service_name} 1>/dev/null 2>&1
	# clean environment; %files doesn't support leaving directories but removing files
	rm -f %{fix_rundir}/%{base_path}/pids/* \
	      %{fix_rundir}/%{base_path}/status/* \
	      %{_localstatedir}/spool/%{base_path}/crons/* \
	      %{_localstatedir}/spool/%{base_path}/crons/*/* \
	      %{_localstatedir}/spool/%{base_path}/data/*/* \
	      1>/dev/null 2>&1
fi
exit 0

%postun -n ripe-atlas-common
exit 0

%postun -n ripe-atlas-probe
exit 0

%include rhel/changelog
