#!/bin/bash

function display_usage {
  echo "Usage: $0
  Get groups configuration
    $0 --config --name GROUP_NAME
    $0 --config --id param_GROUP_ID
    $0 --config --all
  List groups names
    $0 --list-name --name GROUP_NAME
    $0 --list-name --id param_GROUP_ID
    $0 --list-name --all
  List groups ids
    $0 --list-id --name GROUP_NAME
    $0 --list-id --id param_GROUP_ID
    $0 --list-id --all
  Create group
    $0 --create --path GROUP_PATH
        [--name GROUP_NAME] [--description GROUP_DESCRIPTION] \\
        [--lfs_enabled true|false] [--membership_lock true|false] [--request_access_enabled true|false] \\
        [--share_with_group_lock true|false]] [--visibility  private|internal|public] \\
  Edit group configuration
    $0 --edit --id param_GROUP_ID --name GROUP_NAME --path GROUP_PATH \\
       --description GROUP_DESCRIPTION --visibility  private|internal|public \\
       --lfs_enabled true|false --request_access_enabled true|false
  Delete a group
    $0 --delete --id param_GROUP_ID
" >&2
  exit 100
}

#        create_group_handle_params "${param_group_path}" "${param_group_name}"  "${param_group_description}" \
#          "${param_group_lfs_enabled}" "${param_group_membership_lock}" "${param_group_request_access_enabled}" \
#          "${param_group_share_with_group_lock}" "${param_group_visibility}" \
#          | jq .
function create_group_handle_params {
  local param_group_path=$1
  local param_group_name=$2
  local param_group_description=$3
  local param_group_lfs_enabled=$4
  local param_group_membership_lock=$5
  local param_group_request_access_enabled=$6
  local param_group_share_with_group_lock=$7
  local param_group_visibility=$8

  if [ -z "${param_group_name}" ]; then
    param_group_name="${param_group_path}"
  fi
  if [ -z "${param_group_description}" ]; then
  param_group_description="${GITLAB_DEFAULT_GROUP_DESCRIPTION}"
  fi
  if [ -z "${param_group_lfs_enabled}" ]; then
    param_group_lfs_enabled="${GITLAB_DEFAULT_GROUP_LFS_ENABLED}"
  fi
  if [ -z "${param_group_membership_lock}" ]; then
    param_group_membership_lock="${GITLAB_DEFAULT_GROUP_MEMBERSHIP_LOCK}"
  fi
  if [ -z "${param_group_request_access_enabled}" ]; then
    param_group_request_access_enabled="${GITLAB_DEFAULT_GROUP_REQUEST_ACCESS_ENABLED}"
  fi
  if [ -z "${param_group_share_with_group_lock}" ]; then
    param_group_share_with_group_lock="${GITLAB_DEFAULT_GROUP_SHARE_WITH_GROUP_LOCK}"
  fi
  if [ -z "${param_group_visibility}" ]; then
    param_group_visibility="${GITLAB_DEFAULT_GROUP_VISIBILITY}"
  fi

  create_group 'path' "${param_group_path}" \
    'name' "${param_group_name}" \
    'description' "${param_group_description}" \
    'lfs_enabled' "${param_group_lfs_enabled}" \
    'membership_lock' "${param_group_membership_lock}" \
    'request_access_enabled' "${param_group_request_access_enabled}" \
    'share_with_group_lock' "${param_group_share_with_group_lock}" \
    'visibility' "${param_group_visibility}"
}

function get_group_name_or_id_or_empty {
  local p_all_group=$1
  local p_group_id=$2
  local p_group_name=$3

  local group_name_or_id_or_empty="${p_group_id}"

  if [ -z "${group_name_or_id_or_empty}" ]; then
    group_name_or_id_or_empty="${p_group_name}"
  fi

  if [ -z "${group_name_or_id_or_empty}" ]; then
    if [ ! "${p_all_group}" = true ]; then
      echo "** Missing --id, --name or --all" >&2
      exit 1
    fi
  fi

  echo "${group_name_or_id_or_empty}"
}

function list_groups_names_handle_params {
  local group_name_or_id_or_empty=$(get_group_name_or_id_or_empty $@) || exit $?

  local result=$(list_groups "${group_name_or_id_or_empty}" '')

  if [ -z "${group_name_or_id_or_empty}" ]; then
    echo "${result}" | jq '. [] | .name'
  else
    echo "${result}" | jq '. | .name'
  fi
}

function list_groups_ids_handle_params {
  local group_name_or_id_or_empty=$(get_group_name_or_id_or_empty $@) || exit $?

  local result=$(list_groups "${group_name_or_id_or_empty}" '')

  if [ -z "${group_name_or_id_or_empty}" ]; then
    echo "${result}" | jq '. [] | .id'
  else
    echo "${result}" | jq '. | .id'
  fi
}

function show_group_config_handle_params {
  local group_name_or_id_or_empty=$(get_group_name_or_id_or_empty $@) || exit $1

  local result=$(show_group_config "${group_name_or_id_or_empty}")

  echo "${result}" | jq .
}

function main {
  local param=
  local param_all_groups=false
  local param_group_description=
  local param_group_id=
  local param_group_lfs_enabled=
  local param_group_name=
  local param_group_path=
  local param_group_request_access_enabled=
  local param_group_visibility=
  local param_group_visibility=
  local param_group_share_with_group_lock=
  local param_group_membership_lock=
  local action=

  while [[ $# > 0 ]]; do
    param="$1"
    shift

    case "${param}" in
      -a|--all)
        param_all_groups=true
        ;;
      --config)
        ensure_empty action
        action=showConfigAction
        ;;
      --create)
        ensure_empty action
        action=createAction
        ;;
      --delete)
        ensure_empty action
        action=deleteAction
        ;;
      --description)
        param_group_description="$1"
        shift
        ;;
      --edit)
        ensure_empty action
        action=editAction
        ;;
      -i|--id)
        param_group_id="$1"
        shift
        ;;
      --lfs_enabled)
        param_group_lfs_enabled="$1"
        shift

        ensure_boolean "${param_group_lfs_enabled}" '--lfs_enabled'
        ;;
      --list-name)
        ensure_empty action
        action=listNamesAction
        ;;
      --list-id)
        ensure_empty action
        action=listIdsAction
        ;;
      --membership_lock)
        param_group_membership_lock="$1"
        shift

        ensure_boolean "${param_group_membership_lock}" '--membership_lock'
        ;;
      -n|--name)
        param_group_name="$1"
        shift
        ;;
      --path)
        param_group_path="$1"
        shift
        ;;
      --request_access_enabled)
        param_group_request_access_enabled="$1"
        shift

        ensure_boolean "${param_group_request_access_enabled}" '--request_access_enabled'
        ;;
      --share_with_group_lock)
        param_group_share_with_group_lock="$1"
        shift

        ensure_boolean "${param_group_share_with_group_lock}" '--share_with_group_lock'
        ;;
      --visibility)
        param_group_visibility="$1"
        shift

        case "${param_group_visibility}" in
           private|internal|public)
             ;;
           *)
             echo "Illegal value '${param_group_visibility}'. --visibility should be private, internal or public." >&2
             display_usage
             ;;
        esac
        ;;
      *)
        # unknown option
        echo "Unknown parameter ${param}" >&2
        display_usage
        ;;
    esac
  done

  case "${action}" in
    createAction)
        ensure_not_empty param_group_path
        create_group_handle_params "${param_group_path}" "${param_group_name}"  "${param_group_description}" \
          "${param_group_lfs_enabled}" "${param_group_membership_lock}" "${param_group_request_access_enabled}" \
          "${param_group_share_with_group_lock}" "${param_group_visibility}" \
          | jq .
        ;;
    deleteAction)
        ensure_not_empty param_group_id
        delete_group "${param_group_id}" \
          | jq .
        ;;
    editAction)
        ensure_not_empty param_group_id
        ensure_not_empty param_group_name
        ensure_not_empty param_group_path
        ensure_not_empty param_group_visibility

        edit_group "${param_group_id}" "${param_group_name}" "${param_group_path}" "${param_group_description}" \
          "${param_group_visibility}" "${param_group_lfs_enabled}" "${param_group_request_access_enabled}" \
          | jq .
        ;;
    listNamesAction)
        list_groups_names_handle_params "${param_all_groups}" "${param_group_id}" "${param_group_name}"
        ;;
    listIdsAction)
        list_groups_ids_handle_params "${param_all_groups}" "${param_group_id}" "${param_group_name}"
        ;;
    showConfigAction)
        show_group_config_handle_params "${param_all_groups}" "${param_group_id}" "${param_group_name}"
        ;;
    *)
        # unknown option
        echo "Missing --config, --list-name, --list-id, --edit or --delete" >&2
        echo "Unexpected value for action: '${action}'" >&2
        display_usage
        ;;
  esac
}

# Configuration - BEGIN
if [ -z "$GITLAB_BASH_API_PATH" ]; then
  GITLAB_BASH_API_PATH=$(dirname $(realpath "$0"))
fi

if [ ! -f "${GITLAB_BASH_API_PATH}/api/gitlab-bash-api.sh" ]; then
  echo "gitlab-bash-api.sh not found! - Please set GITLAB_BASH_API_PATH" >&2
  exit 1
fi

source "${GITLAB_BASH_API_PATH}/api/gitlab-bash-api.sh"
# Configuration - END

# Script start here
source "${GITLAB_BASH_API_PATH}/api/gitlab-bash-api-group.sh"

if [ $# -eq 0 ]; then
  display_usage
fi

main "$@"