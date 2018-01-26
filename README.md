# repro-helm-issue-1873

This reproduces the helm issue at https://github.com/kubernetes/helm/issues/1873.

It performs three helm upgrade commands each changing the readinessProbePath.
1. sets readinessProbePath to '/'. This passes.
1. sets readinessProbePath to '/bad-path'. This fails as expected.
1. sets readinessProbePath to '/'. This should pass but fails.

## Requirements

kubernetes 1.8.3
helm 2.7.2 or 2.8.0

Run like:

    ./repro.sh
