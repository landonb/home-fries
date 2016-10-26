# File: .fries/lib/docker_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.10.25
# Project Page: https://github.com/landonb/home-fries
# Summary: Docker Helpers: I'm new to Docker, Fall, 2016. These are my bash.
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

docker_remove_exited () {
  # http://blog.yohanliyanage.com/2015/05/docker-clean-up-after-yourself/
  docker rm -v $(docker ps -a -q -f status=exited)
# 2016-10-20: The remove-exited containers did not remove any project containers.
#             I expected otherwise...
  # Stop and remove all docker containers
  # docker stop $(docker ps -a -q)
  # docker rm $(docker ps -a -q)
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

docker_ps () {

  # "Valid placeholders for the Go template are listed below:"
  #   .ID	Container ID
  #   .Image	Image ID
  #   .Command	Quoted command
  #   .CreatedAt	Time when the container was created.
  #   .RunningFor	Elapsed time since the container was started.
  #   .Ports	Exposed ports.
  #   .Status	Container status.
  #   .Size	Container disk size.
  #   .Names	Container names.
  #   .Labels	All labels assigned to the container.
  #   .Label	Value of a specific label for this container. For example '{{.Label "com.docker.swarm.cpu"}}'
  #   .Mounts
  # As of 2016-10-24.
  # https://docs.docker.com/engine/reference/commandline/ps/#formatting

  #  docker ps --format "table {{.ID}}\t{{.Labels}}"
  #  docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.RunningFor}}\t{{.Ports}}\t{{.Status}}\t{{.Size}}\t{{.Names}}\t{{.Labels}}\t{{.Mounts}}"
  #docker ps --format "table {{.Image}}\t{{.Command}}\t{{.RunningFor}}\t{{.Ports}}\t{{.Status}}\t{{.Names}}"
  docker ps --format "table {{.Image}}\t{{.Command}}\t{{.Ports}}\t{{.Status}}\t{{.Names}}"

}

