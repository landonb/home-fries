#!/bin/bash
# Last Modified: 2017.10.03
# vim:tw=0:ts=2:sw=2:et:norl:

# File: no_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# ============================================================================
# *** Machine I.P. address

# There are lots of ways to get the machine's IP address:
#   $ ip addr show
# or, to filter,
#   $ ip addr show eth0
#   2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP ...
#       link/ether d4:ae:52:73:42:c4 brd ff:ff:ff:ff:ff:ff
#       inet 128.101.34.16/24 brd 128.101.34.255 scope global eth0
# You can also use nslookup:
#   $ nslookup runic
#   Server:   128.101.34.21
#   Address:  128.101.34.21#53
#   Name:     ccp.server.tld
#   Address:  123.456.78.90
# Or ifconfig, again filtering by device,
#   $ ifconfig eth0
#   eth0      Link encap:Ethernet  HWaddr d4:ae:52:73:42:c4
#             inet addr:128.101.34.16  Bcast:128.101.34.255  Mask:255.255.255.0
#             ...
# But probably the easiest to parse is host:
#   $ host -t a ${CP_PRODNAME}
#   ${CS_PRODUCTION} has address 123.456.78.90

suss_machine_ip () {
  set +e

  # 2016.03.23: On a new machine install,
  #             early into the standup,
  #             and not having editing /etc/hosts,
  #             host -t a ${HOSTNAME} says:
  #               Host ${HOSTNAME} not found: 3(NXDOMAIN)
  # 2016.05.05: I don't remember writing that last comment, and it wasn't
  #             that long ago. Anyway, $(host -t a ${HOSTNAME}) still saying
  #             the same thing: not found.
  # 2016-11-15: x201 dropping wi-fi for some reason, and this host command
  #             takes a while to complete. Maybe just use the ifconfig greps?
  #MACHINE_IP=`host -t a ${HOSTNAME} | awk '{print $4}' | egrep ^[1-9]`
  #if [[ $? != 0 ]]; then
  local MACHINE_IP=""
  if true; then
    local IFCFG_DEV=""

    # 2016-07-30: This, on 16.04 VBox:
    #  $ ifconfig eth0
    #  eth0: error fetching interface information: Device not found
    # 2016-09-23:
    #   systemd's Predictable Network Interface naming started in 15.04.
    #   (predictable as in physically predictable, so devices are
    #   numbered by their physical position, as opposed to being
    #   numbered sequentially by the prober on boot)
    #   http://askubuntu.com/questions/704361/why-is-my-network-interface-named-enp0s25-instead-of-eth0
    #   On Lenovo ThinkPad X201, enp0s25 is the new eth0; wlp2s0 the new wlan0.

    /sbin/ifconfig eth0 &> /dev/null
    if [[ $? -eq 0 ]]; then
      /sbin/ifconfig eth0 2>&1 | grep "inet addr" > /dev/null
      if [[ $? -eq 0 ]]; then
        IFCFG_DEV=`/sbin/ifconfig eth0 2> /dev/null`
      else
        # 2016-07-30: This:
        #  masterb@masterb:~ ⚓ $ ifconfig wlan0
        #  wlan0: error fetching interface information: Device not found
        /sbin/ifconfig wlan0 2>&1 | grep "inet addr" > /dev/null
        if [[ $? -eq 0 ]]; then
          IFCFG_DEV=`/sbin/ifconfig wlan0 2> /dev/null`
        else
          # VirtualBox. I'm guessing.
          IFCFG_DEV=`/sbin/ifconfig enp0s3 2> /dev/null`
        fi
      fi
    else
      /sbin/ifconfig enp0s25 2>&1 | grep "inet addr" > /dev/null
      if [[ $? -eq 0 ]]; then
        IFCFG_DEV=`/sbin/ifconfig enp0s25 2> /dev/null`
      else
        /sbin/ifconfig wlp2s0 2>&1 | grep "inet addr" > /dev/null
        if [[ $? -eq 0 ]]; then
          IFCFG_DEV=`/sbin/ifconfig wlp2s0 2> /dev/null`
        else
          # 2016-11-14: Lenovo ThinkPad T460.
          # MAYBE: This fcn. is getting messy/too nested.
          /sbin/ifconfig wlp4s0 2>&1 | grep "inet addr" > /dev/null
          if [[ $? -eq 0 ]]; then
            IFCFG_DEV=`/sbin/ifconfig wlp4s0 2> /dev/null`
          else
            # VirtualBox. I'm guessing.
            IFCFG_DEV=`/sbin/ifconfig enp0s3 2> /dev/null`
          fi
        fi
      fi
    fi
    MACHINE_IP=`echo ${IFCFG_DEV} | grep "inet addr" \
                | sed "s/.*inet addr:([.0-9]+).*/\1/" \
                2> /dev/null`
    if [[ $? != 0 ]]; then
      MACHINE_IP=`echo ${IFCFG_DEV} | grep "inet addr" \
                  | sed "s/.*inet addr:\([.0-9]\+\).*/\1/" \
                  2> /dev/null`
    fi
  fi
  if [[ -z ${MACHINE_IP} ]]; then
    if [[ -z ${DUBS_MACHINE_IP_WARNED} ]]; then
      if ${HOMEFRIES_WARNINGS}; then
        echo "======================================================"
        echo "WARNING: Could not determine the machine's IP address."
        echo "======================================================"
        echo "  Maybe try"
        echo
        echo "    sudo service network-manager restart"
        echo
        echo "  Here's what was sussed:"
        # 2016.05.05: This path being followed on initial cli_gk12 go, but
        #             otherwise not just on /bin/bash... so what gives?

        # `host` is slow when disconnected.
        if false; then
          echo
          echo -e "$ host -t a ${HOSTNAME}\n`host -t a ${HOSTNAME}`\n"
        fi

        echo
        echo "$ /sbin/ifconfig eth0"
        /sbin/ifconfig eth0

        echo
        echo "$ /sbin/ifconfig wlan0"
        /sbin/ifconfig wlan0

        echo
        echo "$ /sbin/ifconfig enp0s25"
        /sbin/ifconfig enp0s25

        echo
        echo "$ /sbin/ifconfig wlp2s0"
        /sbin/ifconfig wlp2s0

        echo
        echo "$ /sbin/ifconfig wlp4s0"
        /sbin/ifconfig wlp4s0

        echo
        echo "Good luck!"
        echo "======================================================"
      fi

      DUBS_MACHINE_IP_WARNED=1
    fi
  else
    DUBS_MACHINE_IP_WARNED=$((DUBS_MACHINE_IP_WARNED + 1))
  fi
  export DUBS_MACHINE_IP_WARNED

  reset_errexit
}

main() {
  # 2017-10-03: This one seems pointless:
  #suss_machine_ip
  :
}

main "$@"

