# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/DepoXy/gnome-window-calls#🪟
# License: MIT. Please find more in the LICENSE file.

# Copyright (c) © 2024-2025 Landon Bouma. All Rights Reserved.

# USAGE: Wire into your app.
# - REFER: See DepoXy users:
#     https://github.com/DepoXy/sh-humble-prompt#🙇
#     https://github.com/DepoXy/gvim-open-kindness#🐬

# REFER: Depends on `window-calls` GNOME Shell extension:
#   https://extensions.gnome.org/extension/4724/window-calls/
#   https://github.com/ickyicky/window-calls

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# DEVEL: Uncomment to capture trace files in the current directory.
# - The trace files are named with number prefixes, e.g., "01", "02",
#   etc., so you can easily review using `less 0*` and then :n and :p
#   to navigate next and previous in less.
#
#  RAISELOWER_TRACE_DIR="."

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

print_window_list() {
  gdbus call --session --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/Windows \
    --method org.gnome.Shell.Extensions.Windows.List
}

print_window_details() {
  local window_id="$1"

  gdbus call --session --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/Windows \
    --method org.gnome.Shell.Extensions.Windows.Details \
    "${window_id}"
}

window_activate() {
  local window_id="$1"

  gdbus call --session --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/Windows \
    --method org.gnome.Shell.Extensions.Windows.Activate \
    -- "${window_id}"
}

window_minimize() {
  local window_id="$1"

  gdbus call --session --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/Windows \
    --method org.gnome.Shell.Extensions.Windows.Minimize \
    -- "${window_id}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

get_window_ids_Wayland() {
  get_window_ids_Wayland_filtered ""
}

get_window_ids_Wayland_focused() {
  local jq_filter="select(.focus == true)"

  get_window_ids_Wayland_filtered "${jq_filter}"
}

get_window_ids_Wayland_filtered() {
  local jq_filter="$1"

  # Returns JSON blob as embedded string, either like
  #   ('[{JSON}]',)
  # or like
  #   ("[{ESCAPED-JSON}]",)
  local windows_list_raw
  if ! windows_list_raw="$(print_window_list 2> /dev/null)"; then
    # E.g. — Error: GDBus.Error:org.freedesktop.DBus.Error.UnknownMethod:
    #   Object does not exist at path “/org/gnome/Shell/Extensions/Foo”
    #
    # SAVVY: check_deps should make this path unreachable.
    alert_missing_gnome_extension_window_calls

    return 1
  fi

  # USAGE: E.g.,
  #   (RAISELOWER_TRACE_DIR=/tmp/rltrace && get_window_ids_Wayland)
  if [ -n "${RAISELOWER_TRACE_DIR}" ]; then
    mkdir -p -- "${RAISELOWER_TRACE_DIR}"

    echo "${windows_list_raw}" > "${RAISELOWER_TRACE_DIR}/01--windows_list_raw"
  fi

  # ***

  # Note the window-calls response defaults to a single-
  # quoted stream of JSON text, where the JSON fields
  # are double-quoted.
  # - But if the window title is named with a single-
  #   quote, then the stream of JSON text is double-
  #   quoted instead, and thusly the field quotes
  #   need to be escaped.
  #
  # - When double-quoted, the response looks like this:
  #     ('[{"in_current_workspace":true,..."focus":true}]',)
  # - And if a value within contains double quotes, they
  #   themselves will be double-escaped, e.g., a webpage
  #   titled `air "quotes"` might look like this:
  #     ..."title":"air \\"quotes\\" - Google Chrome",...
  #
  # - But if a value contains a single quote, then the whole
  #   blob is double-quoted instead, e.g.,
  #     ("[{\"in_current_workspace\":true,...\"focus\":true}]",)
  # - And if a value within contains double quotes, they're
  #   obviously additionally escaped, e.g.,
  #     ...\"title\":\"\\\"destiny's child\\\" - Google Chrome\",...
  #
  # To avoid jq issues, we'll remove escaped quotes within
  # values first — then we'll unescape escaped field quotes.

  test_double_quoted() { echo "$1" | grep -q -e '^("'; }

  test_single_quoted() { echo "$1" | grep -q -e "^('"; }

  local is_double_quoted=false
  local is_single_quoted=false
  if test_double_quoted "${windows_list_raw}"; then
    is_double_quoted=true
  elif test_single_quoted "${windows_list_raw}"; then
    is_single_quoted=true
  else
    >&2 "ERROR: Unrecognized D-Bus response format: Not quoted?"

    exit_1
  fi

  # Remove 2 leading (tail -c +3) and 4 trailing (head -c -4)
  # characters (inner-quoted parenthetical):
  #   (' and ',)\n
  # or
  #   (" and ",)\n

  local windows_list_blob
  windows_list_blob="$(
    printf '%s\n' "${windows_list_raw}" \
      | head -c -4 \
      | tail -c +3
  )"

  if [ -n "${RAISELOWER_TRACE_DIR}" ]; then
    local blobby
    blobby="${RAISELOWER_TRACE_DIR}/02--windows_list_blob--$(
      ${is_double_quoted} && echo "double" || echo "single"
    )"

    echo "${windows_list_blob}" > "${blobby}"
  fi

  # ***

  # BWARE: Initially, this used an intermediate variable:
  #   local windows_list_json
  #   if ${is_double_quoted}; then
  #     windows_list_json="$(
  #       echo "${windows_list_blob}" \
  #         | sed -e 's/\\\(\\\)\+"//g' \
  #         | sed -e 's/\\"/"/g'
  #     )"
  #   elif ${is_single_quoted}; then
  #     windows_list_json="$(
  #       echo "${windows_list_blob}" \
  #         | sed -e 's/\(\\\)\+"//g'
  #     )"
  #   fi
  # but then properly-escaped values are themselves un-escaped
  # (and then, e.g.,
  #   ~/.depoxy/ambers/bin/windows/toggle-numbered 3
  #   # Or, more explicitly:
  #   ~/.depoxy/ambers/bin/windows/toggle-visibility "^3\." "^3․"
  # fails).
  # - I couldn't quite suss the issue (e.g., I'd see different output
  #   if I added a trace `echo` and compared it to a trace `cat >` file).
  #   - It seemed like either `echo "${windows_list_json}" | ...` or
  #     `echo "${windows_list_blob}" | ...` was removing escape chars.
  #   - Fortunately, single-shotting in a pipeline avoids the problem.

  local window_ids
  if ! window_ids="$(
    if ${is_double_quoted}; then
      echo "${windows_list_blob}" \
        | sed -e 's/\\\(\\\)\+"//g' \
        | sed -e 's/\\"/"/g' \
        | jq ".[] | ${jq_filter} ${jq_filter:+|} .id"
    elif ${is_single_quoted}; then
      echo "${windows_list_blob}" \
        | sed -e 's/\(\\\)\+"//g' \
        | jq ".[] | ${jq_filter} ${jq_filter:+|} .id"
    fi
  )"; then

    # DEVEL: Run with RAISELOWER_TRACE_DIR=. to debug.
    >&2 echo "ERROR: Cannot determine windows ID(s) (from window-calls)"
    if [ -n "${RAISELOWER_TRACE_DIR}" ]; then
      echo -e "\njq_filter: ${jq_filter}" >> "${RAISELOWER_TRACE_DIR}/03--windows_list_json"
    fi

    return 1
  fi

  echo "${window_ids}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# args: one or more window title(s) to try to match.
raise_window_Wayland_titled() {
  if [ $# -eq 0 ]; then
    >&2 echo "ERROR: Please specify one or more window titles to match"

    return 1

  fi

  # INERT/2025-09-20: Why not query window list for title,
  # rather than getting IDs and probing each one separately?
  # - DUNNO: Author doesn't remember why they wrote it this
  #   way. But it works, so not much reason to futz with it.
  local window_ids

  local found_wm_class=false
  if [ $# -eq 1 ]; then
    local jq_filter="select(.wm_class == \"$1\")"
    if window_ids="$(get_window_ids_Wayland_filtered "${jq_filter}")"; then
      if [ -n "${window_ids}" ]; then
        found_wm_class=true
      fi
    fi
  fi

  if ! ${found_wm_class}; then
    if ! window_ids="$(get_window_ids_Wayland)"; then

      return 1
    fi
  fi

  # ***

  # Ignore errors, e.g.,
  #   "Error: GDBus.Error:org.gnome.gjs.JSError.Error: Not found"
  # though that probably only happens when you're debugging, and you're
  # manually replaying windows_list you captured previously.

  # ANFYI: If you later learn you need to process separate lines
  # differently, perhaps you could pipe to a while loop, e.g.:
  #
  #   export -f print_window_details
  #   echo "${window_ids}" \
  #     | xargs -I{} bash -c 'print_window_details "{}"' 2> /dev/null \
  #     | gawk 'match($0, /\{.*\}/, a) {print a[0]}' \
  #     | while IFS= read -r line; do
  #       printf "»%s«\n" "${line}"
  #     done

  # - Remove ('{ and }',) or ("{ and }",) from each line with gawk-match.
  # - If outer container was ("{ and }",), the inner response is
  #   escape-quoted (because single-quote(s) in window title) so
  #   remove all double-or-more escaped quotes (those within a
  #   window title); then convert escape-quotes to normal quotes.
  # - USYNC: See similar pipeline in downstream app:
  #   ~/.kit/sh/sh-humble-prompt/lib/show-command-name-in-window-title.sh
  export -f print_window_details
  local window_details
  window_details="$(
    echo "${window_ids}" \
      | xargs -I{} bash -c 'print_window_details "{}" 2> /dev/null' \
      | gawk 'match($0, /\{.*\}/, a) {print a[0]}' \
      | sed -e 's/\\\(\\\)\+"//g' | sed -e 's/\\"/"/g'
  )"

  if [ -n "${RAISELOWER_TRACE_DIR}" ]; then
    echo "${window_details}" > "${RAISELOWER_TRACE_DIR}/04--window_details"
  fi

  # ***

  local title_and_ids
  title_and_ids="$(
    printf "%s" "${window_details}" \
      | jq -r '"\(.title)\t\(.id)"' \
        2>&1
  )"

  if [ $? -ne 0 ]; then
    >&2 echo "ERROR: Failed to identify window:"
    >&2 echo "  $ printf \"%s\" \"\${window_details}\" |"
    >&2 echo "    jq -r '\"\\(.title)\\t\\(.id)\"'"
    printf "%s" "${window_details}" \
      | 1>&2 jq -r '"\(.title)\t\(.id)"'

    return 1
  fi

  if [ -n "${RAISELOWER_TRACE_DIR}" ]; then
    echo "${title_and_ids}" > "${RAISELOWER_TRACE_DIR}/05--title_and_ids"
  fi

  # ***

  local window_id
  if ${found_wm_class}; then
    window_id="$(echo "${title_and_ids}" | sed 's/.*\t//')"
  else
    local pattern
    for pattern in "$@"; do
      local title_and_id
      # Use Perl regex, or \t doesn't work (though literal "${pattern}.*	"
      # works, but not "${pattern}.*"$'\t', which is a Bashism anyway).
      title_and_id="$(
        echo "${title_and_ids}" | grep -P -e "${pattern}.*\t" | head -n1
      )"

      if [ -n "${title_and_id}" ]; then
        window_id="$(echo "${title_and_id}" | sed 's/.*\t//')"

        break
      fi
    done
  fi

  if [ -n "${window_id}" ]; then
    window_activate "${window_id}" > /dev/null

    if [ -n "${RAISELOWER_TRACE_DIR}" ]; then
      echo -e "\nwindow_id: ${window_id}" >> "${RAISELOWER_TRACE_DIR}/05--title_and_ids"
    fi
  else
    >&2 echo "ALERT: No matching window identified for: $@"

    return 1
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

minimize_window_Wayland() {
  local window_id="$1"

  # OUTPUTs: ()
  window_minimize "${window_id}" > /dev/null
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps_gnome_extension_window_calls() {
  # Check that the extension path exists.
  # - This might be excessive; the dconf-read might be sufficient
  #   (and less fragile than checking the bespoke path here).
  local uuid="window-calls@domandoman.xyz"
  if ! [ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/gnome-shell/extensions/${uuid}" ]; then
    alert_missing_gnome_extension_window_calls

    return 1
  fi

  local arr_index=""
  arr_index=$(
    dconf read /org/gnome/shell/enabled-extensions \
      | sed "s/'/\"/g" \
      | jq -r ". | index(\"${uuid}\")"
  )

  if [ "${arr_index}" = "null" ]; then

    return 1
  fi
}

alert_missing_gnome_extension_window_calls() {
  >&2 echo "ERROR: Missing GNOME Extension: window-calls"
  >&2 echo "  https://extensions.gnome.org/extension/4724/window-calls/"
  >&2 echo "  https://github.com/ickyicky/window-calls"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
