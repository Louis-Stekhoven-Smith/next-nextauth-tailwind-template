echo Using pscale CLI from latest docker image ...
mkdir -p $HOME/.config/planetscale

function pscaleImage {
    local PSCALE_VERSION='v0.131.0'
    command="docker run -e PS_TOKEN=${PLANETSCALE_SERVICE_TOKEN:-""} -e PS_TOKEN_ID=$PLANETSCALE_SERVICE_TOKEN_ID -e HOME=/tmp -e PSCALE_ALLOW_NONINTERACTIVE_SHELL=true --user $(id -u):$(id -g) --rm -i planetscale/pscale:${PSCALE_VERSION} $@"
    $command
}