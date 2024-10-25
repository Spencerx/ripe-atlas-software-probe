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


_ri_parse()
{
	local key="${1}"

	if [ ! -r "${RI_REPLY}" ]; then
	       return
	fi

	while read param; do
		if [ "${param%% *}" = "${key}" ]; then
			echo "${param}"
			break
		fi
	done < "${RI_REPLY}"
}

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
	local settings=$(_ri_parse DNS_SERVERS)
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
	local settings=$(_ri_parse DHCPV4)
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
	if ( [ -z "${ip}" ] || [ -z "${mask}" ] || [ -z "${gw}" ] ); then
		return
	fi

	_wrt_syscall 'action=network' 'proto=ipv4' "mode=${mode}" "ip=${ip}" "net=${mask}" "gw=${gw}" "dns=${dns}"
}

set_ipv6()
{
	local settings=$(_ri_parse DHCPV6)
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
	if ( [ -z "${ip}" ] || [ -z "${len}" ] || [ -z "${gw}" ] ); then
		return
	fi

	_wrt_syscall 'action=network' 'proto=ipv6' "mode=${mode}" "ip=${ip}" "net=${len}" "gw=${gw}" "dns=${dns}"
}

wrt_set_leds()
{
	local state="${1}"
	
	_wrt_syscall 'action=leds' "state=${state}"
}
