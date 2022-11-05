#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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

docker_kill_tails_jobs () {
  # Kill all background jobs. Works only from terminal/session/shell
  # in which the jobs were created, naturally.
  echo "Stopping tails: $(jobs -p | tr '\n' ' ')"
  # Using `sh -c` so that if some have exited, that error will
  # not prevent further tails from being killed.
  jobs -p | tr '\n' ' ' | xargs -I % sh -c "kill % || true"
  echo "Done"
}

docker_kill_tails_ps () {
  # Kill all `docker logs` processes.
  #  proc_ids=$(ps aux | grep "docker logs -f" | awk '{print $2}')
  proc_ids=$(ps aux | grep "docker logs" | awk '{print $2}')
  echo -e "proc_ids: \n${proc_ids}"
  if [[ "$proc_ids" != "" ]]; then
    echo $proc_ids | xargs kill -s 9 >/dev/null 2>&1
  fi
}

docker_logs_all () {
  # Docker default logging is to write application stdout to a file
  # somewhere (in JSON format, apparently) that you can view using
  # `docker logs`. This fcn. tails all running containers' logs
  # until you Ctrl-C to stop it. Note the `trap` trick, since docker
  # only lets you tail one log per process. So we just shove a bunch
  # of processes into the background and let their outputs flow up
  # and interleave in one terminal window.

  # Wait for user to Ctrl-C the fcn. to stop logging
  # (otherwise, since we background all the jobs, user
  # would have to call docker_kill_tails from the same
  # terminal window, or docker_kill_tails_ps from any
  # terminal window).
  # https://en.wikipedia.org/wiki/Unix_signal#SIGINT
  trap docker_kill_tails_jobs SIGINT

  # Here's a nifty trick to background multiple `docker logs -f` commands
  # so that you can interleave messages from multiple containers inside 1
  # terminal window.
  #
  # One issue is that you cannot Ctrl-C or control the output without
  # finding the processes and killing them, i.e., see docker_kill_tails.

  # http://stackoverflow.com/questions/32076878/logging-solution-for-multiple-containers-running-on-same-host

  # Just a note that there's probably a better way to handling logging.
  echo "DEV: You should consider using the syslog logger instead and tailing its log, e.g.,"
  echo
  echo "     tail -F /exo/clients/genie/ps-genie-thirdwish/dev/syslog.log"

  names=$(docker ps --format "{{.Names}}")
  echo "tailing $names"
  while read -r name; do
    echo "Tailing $name"
    # Show the container name in jobs list.
    #echo eval "docker logs -f --tail=5 \"$name\" | /usr/bin/env sed -e \"s/^/[-- $name --] /\" &"
    #eval "docker logs -f --tail=5 \"$name\" | /usr/bin/env sed -e \"s/^/[-- $name --] /\" &"
    eval "docker logs -f --tail=100 \"$name\" | /usr/bin/env sed -e \"s/^/[-- $name --] /\" &"
  done <<< "$names"

  # Don't exit this script until a Ctrl+C or all tails exit.
  wait

  trap - SIGINT

  # Sleep for a second while the jobs exit.
  # Each one spits of its death, e.g.,
  #  [2]   Done    docker logs -f --tail=100 ...
  # which come after the prompt and clutter up
  # the terminal unless we sleep and then finish.
  sleep 1
}

