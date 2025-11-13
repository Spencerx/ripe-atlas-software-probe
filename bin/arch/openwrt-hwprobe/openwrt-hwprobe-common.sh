. ${ATLAS_SCRIPTS}/generic-common.sh

RI_REPLY="${ATLAS_STATUS}/reg_init_reply.txt"
SET_LEDS_CMD=wrt_set_leds
SETUP_NETWORK_CMD=setup_network
INSTALL_FIRMWARE_CMD=install_firmware

_wrt_syscall()
{
	local env=''

	while [ -n "${1}" ]; do
		env="${env}, \"${1}\""
		shift
	done

	ubus call hotplug.ripe-atlas call "{ \"env\": [ ${env:2} ] }"
}

_map_key_to_netconfig_file()
{
	local key="${1}"

	# Map $key to respective file
	case "$key" in
		*DHCPV4*)       mapped_file="${NETCONFIG_V4_VOL}" ;;
		*DHCPV6*)       mapped_file="${NETCONFIG_V6_VOL}" ;;
		*DNS_SERVERS*)  mapped_file="${RESOLV_CONF_VOL}" ;;
		*)              return 1 ;;
	esac

	# Check if file exists
	if [ -f "${mapped_file}" ]; then
		echo "${mapped_file}"
		return 0
	else
		return 1
	fi
}

_netconfig_generate()
{
	local key="${1}"
	local netconfig_file="${2}"

	# Map $key to respective function
	case "$key" in
		*DHCPV4*)       return 1 ;;
		*DHCPV6*)       return 1 ;;
		*DNS_SERVERS*)  return 1 ;;
		*)              return 1 ;;
	esac
}

# Parses the line starting with $1 (key) out of reginit, and echos it
_ri_parse()
{
	local key="${1}"

	if [ ! -r "${RI_REPLY}" ]; then
		return 1
	fi

	while read param; do
		if [ "${param%% *}" = "${key}" ]; then
			echo "${param}"
			break
		fi
	done < "${RI_REPLY}"
}

# Get network configuration for given key ($1)
_get_netconfig()
{
	local key="${1}"
	local netconfig_file

	# 1. RegInit_Reply contains up-to-date settings
	if output="$(_ri_parse "${key}")"; then
		echo "${output}"
	# 2. NETCONFIG files contain configuration
	# See: `atlasinit.c` for more information
	# If configfile exists && netconfig generation works
	elif netconfig_file=$(_map_key_to_netconfig_file "${key}") && output="$(_netconfig_generate "${key}" "${netconfig_file}")"; then
		echo "${output}"
	# 3. No pre-existing configuration (defaults to DHCP)
	else
		return
	fi
}

# Parses individual values out of a reginit line, and echos it
_ri_value()
{
	local key="${1}"
	local param

	shift
	while [ -n "${1}" ]; do
		param="${1}"
		shift
		if [ "${param}" = "${key}" ]; then
			echo "${1}"
			break
		fi
		shift
	done
}

_handle_dns()
{
	local settings=$(_get_netconfig DNS_SERVERS)
	local filter="${1}"
	local res=''

	set -- ${settings}
	# First is the name DNS_SERVERS
	shift
	while [ -n "${1}" ]; do
		if [ "${1//${filter}/}" != "${1}" ]; then
			res="${res} ${1}"
		fi
		shift
	done

	echo "${res:1}"
}

set_ipv4()
{
	local settings=$(_get_netconfig DHCPV4)
	local mode=''
	local dns
	local gw
	local ip
	local mask

	if [ "$(_ri_value DHCPV4 ${settings})" != "False" ]; then
		mode='dhcp'
	else
		mode='static'
	fi

	ip=$(_ri_value IPV4ADDRESS ${settings})
	mask=$(_ri_value IPV4NETMASK ${settings})
	gw=$(_ri_value IPV4GATEWAY ${settings})
	dns=$(_handle_dns '.')
	if ( [ "${mode}" != 'dhcp' ] && ( [ -z "${ip}" ] || [ -z "${mask}" ] || [ -z "${gw}" ] ) ); then
		return
	fi

	_wrt_syscall 'action=network' 'proto=ipv4' "mode=${mode}" "ip=${ip}" "net=${mask}" "gw=${gw}" "dns=${dns}"
}

set_ipv6()
{
	local settings=$(_get_netconfig DHCPV6)
	local mode=''
	local dns
	local gw
	local ip
	local len

	if [ "$(_ri_value DHCPV6 ${settings})" != "False" ]; then
		mode='dhcp'
	else
		mode='static'
	fi

	ip=$(_ri_value IPV6ADDRESS ${settings})
	len=$(_ri_value IPV6PREFIXLEN ${settings})
	gw=$(_ri_value IPV6GATEWAY ${settings})
	dns=$(_handle_dns ':')
	if ( [ "${mode}" != 'dhcp' ] && ( [ -z "${ip}" ] || [ -z "${len}" ] || [ -z "${gw}" ] ) ); then
		return
	fi

	_wrt_syscall 'action=network' 'proto=ipv6' "mode=${mode}" "ip=${ip}" "net=${len}" "gw=${gw}" "dns=${dns}"
}

wrt_set_leds()
{
	local state="${1}"
	
	_wrt_syscall 'action=leds' "state=${state}"
}
