#!/usr/bin/env bash

# See usage (uninstall.sh -h).
# Uninstalls Iris

#set -x
set -u
set -e

SHELL_DETECTION=$(ps -p $$ -oargs= )

if [[ ! "$SHELL_DETECTION" == *bash* ]]; then
  echo >&2 "Need Bash. Found \"$SHELL_DETECTION\""
  exit 1
else
  echo ""
fi

if [[ "$BASH_VERSION" == 3. ]]; then
  echo >&2 "Need Bash version 4 and up. Now $BASH_VERSION"
  exit 1
fi

START=$(date "+%s")

export LOGS_TOPIC=iris_logs_topic


uninstall_for_proj=
uninstall_for_org=

while getopts 'poh' opt; do

  case $opt in
  p)
    uninstall_for_proj=true

    ;;
  o)
    uninstall_for_org=true
    ;;
  *)
    cat <<EOF
      Usage uninstall.sh PROJECT_ID 
          Argument:
                  The project to which Iris was  deployed
          Options, to be given before project ID.
            If neither -p nor -o is given, the default behavior is used:
            Both are uninstalled;  equivalent to -p -o
            Flags:
                  -p: Uninstall project-level elements of Iris.
                  This is useful if you deployed Iris to two projects
                  in an org and want to delete it on one of those.
                  -o: Uninstall org-level elements like Log Sink
EOF
    exit 1
    ;;
  esac
done
shift $(expr "$OPTIND" - 1 )

if [ "$#" -eq 0 ]; then
    echo Missing project id argument. Run with -h for usage.
    exit 1
fi

export PROJECT_ID=$1

pip3 install -r requirements.txt >/dev/null

if [[ "$uninstall_for_org" != "true" ]] && [[ "$uninstall_for_proj" != "true" ]]; then
  uninstall_for_org=true
  uninstall_for_proj=true
fi


gcloud projects describe "$PROJECT_ID" >/dev/null`` || {
  echo "Project $PROJECT_ID not found"
  exit 1
}

echo "Project ID $PROJECT_ID"
gcloud config set project "$PROJECT_ID"


if [[ "$uninstall_for_org" == "true" ]]; then
  ./uninstall_scripts/_uninstall-for-org.sh || exit 1
fi

if [[ "$uninstall_for_proj" == "true" ]]; then
  ./uninstall_scripts/_uninstall-for-project.sh || exit 1
fi

FINISH=$(date "+%s")
ELAPSED_SEC=$((FINISH - START))
echo >&2 "Elapsed time for $(basename "$0") ${ELAPSED_SEC} s"