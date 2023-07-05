#!/usr/bin/env bash

function find_config_file {
  local working_directory=${1}
  local configuration=${2}
  local config_name=${3}

  for dir in "${configuration}" "${working_directory}" "."; do
    local path="${GITHUB_WORKSPACE}"
    if [[ ${dir} != "." ]]; then
      path+="/${dir}"
    fi

    if [[ -f "${path}/${config_name}" ]]; then
      if [[ ${dir} != "." ]]; then
        echo "${dir}/${config_name}"
        return
      else
        echo "${config_name}"
        return
      fi
    fi
  done
}

function build_settings {
  local working_directory=${1}
  local configuration=${2}
  local config_name=${3}

  # shellcheck disable=SC2155 # return values are not required
  local config_path=$(
    find_config_file \
      "${working_directory}" \
      "${configuration}" \
      "${config_name}"
  )

  if [[ -n ${config_path} ]]; then
    # Use the absolute path to avoid having to calculate the relative path
    echo -n "--config ${GITHUB_WORKSPACE}/${config_path}"
    return # quick exit
  fi

  if [[ "${OUTPUT_FORMAT}" ]]; then
    echo -n "${OUTPUT_FORMAT}"
  fi

  if [[ ${OUTPUT_FORMAT} =~ "markdown" && -n ${INDENT} ]]; then
    echo -n " --indent ${INDENT}"
  fi

  if [[ "${OUTPUT_MODE}" ]]; then
    echo -n " --mode ${OUTPUT_MODE}"
  fi

  if [[ -n ${LOCKFILE} && ${LOCKFILE} == "true" ]]; then
    echo -n " --lockfile"
  fi

  if [[ -n ${OUTPUT_TEMPLATE} ]]; then
    echo -n " --template \"${OUTPUT_TEMPLATE}\""
  fi

  if [[ ${OUTPUT_MODE} != "print" && -n ${OUTPUT_FILE} ]]; then
    echo -n " --output-file ${OUTPUT_FILE}"
  fi
}
