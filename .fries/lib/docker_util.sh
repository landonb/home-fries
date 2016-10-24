# File: .fries/lib/docker_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.10.20
# Project Page: https://github.com/landonb/home-fries
# Summary: Docker Helpers: I'm new to Docker, Fall, 2016. These are my bash.
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

docker_remove_exited () {
  # http://blog.yohanliyanage.com/2015/05/docker-clean-up-after-yourself/
  docker rm -v $(docker ps -a -q -f status=exited)
# 2016-10-20: The remove-exited containers did not remove any project containers.
#             I expected otherwise...
}

docker_remove_dangling () {
  # Remove dangling containers (cache images)
  docker rmi $(docker images -f "dangling=true" -q)
# 2016-10-20: The remove-dangling removed a ton of project containers but not any others.
}

docker_net_binding () {
  # https://docs.docker.com/engine/userguide/networking/default_network/binding/
  sudo iptables -t nat -L -n
}

#docker_show_ips () {}
docker_list_ips () {
  docker ps \
    | tail -n +2 \
    | while read cid b; do
      echo -n -e "$cid\t"
      docker inspect --format "{{ .Name }} @ {{ .NetworkSettings.IPAddress }}" $cid
    done
}

