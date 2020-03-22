#! /usr/bin/env bash

### 1. fetch shiboken2
### 2. Extract APIExtractor and dumpcodemodel into branch
### 3. add subtree into meta-qtah directory

if [ "$#" -ne 2 ]; then
  echo "USAGE: script upstream_branch target_path_from_repo_root"
  exit
fi

set -euo pipefail
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source="$1"
target="$2"
branch="dumpcode_fork_$RANDOM"
upstream_branch="$source"

temp=$(mktemp -d)
git worktree add "$temp"
pushd "$temp"

#TODO are these operations possible without checkin out a worktree?

#1.
url="http://code.qt.io/pyside/pyside-setup.git"
upstream_rev="$(git ls-remote "$url" "$upstream_branch" | cut -f 1)" #hack to work around worktrees not having a proper .git from which to get FETCH_HEAD #TODO assert only one result?
git fetch "$url" "$upstream_rev"
git checkout "$(git rev-parse "$upstream_rev")"

#2.
dump=$(git subtree split --prefix=sources/shiboken2/tests/dumpcodemodel )
apiex=$(git subtree split --prefix=sources/shiboken2/ApiExtractor )
#dump=a36746c9e07576625615f46a5f7bb6525d602e05 #cached for testing
#apiex=378223825ddd334f061f162bc90a4a298a92a843

git checkout --orphan "$branch"
git reset --hard

git config --local user.name "name"
git config --local user.email "email"

git commit --allow-empty -m "initial" #needed because otherwise things break

git subtree add --prefix=dumpcodemodel "$dump"
git subtree add --prefix=ApiExtractor "$apiex"
#add cannibalized CMakeLists
#add eclipse project
#add changelog?
#test/add upstreaming info (split)

popd
git worktree remove "$temp"
newrev=$(git rev-parse "$branch")
git branch -D "$branch"

#3.
pushd $(git rev-parse --show-toplevel) #needs to be done from the root for some reason
git subtree add -P "$target" "$newrev"
popd
