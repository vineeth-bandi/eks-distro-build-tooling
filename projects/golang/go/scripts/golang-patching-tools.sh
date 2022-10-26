#!/usr/bin/env bash

set -e
set -x

BASE_DIRECTORY="$(git rev-parse --show-toplevel)"
PROJECT_DIRECTORY="$BASE_DIRECTORY/projects/golang/go/"

GO_REPO="$(dirname "$BASE_DIRECTORY")/go"

GO_VERSIONS=('1.15.15' '1.16.15' '1.17.13')

function build::go::clone() {
	if [[ ! -e $GO_REPO ]]; then
		git clone "$GO_REPO_URL" "$(dirname "$GO_REPO")"
	fi
}

function build::go::create_eks_branches() {
	cd $GO_REPO
	for ver in "${GO_VERSIONS[@]}"; do
		git checkout "release-branch.go${ver:0:4}"
		git checkout -B "go-$ver-eks"
		git am $PROJECT_DIRECTORY/${ver:0:4}/patches/*.patch
	done	
}

function build::cherry_pick_commit() {
	git cherry-pick $1 || echo "Failed to cherry-pick apply manually for $2"
}

function patch::create() {
	git format-patch -1
}

function build::cleanup() {
	rm -rv "$GO_REPO"
}

build::go::clone
build::go::create_eks_branches
for ver in "${GO_VERSIONS[@]}"; do
	build::cherry_pick_commit $1 $ver
done

#TODO if cherry-pick is success create patch
#TODO add option to erase golang/go repo