local container = import "common/container.libsonnet";
local utils = import "common/utils.libsonnet";

local spec = {
    containers:: error "POD CONTAINERS REQUIRED",
    initContainers:: {},
    restartPolicy:: null,
    tolerations:: null,
    volumes:: {},

    local spec = self,
    output:: {
        containers: utils.namedObjectList(spec.containers),
        [if spec.initContainers != {} then "initContainers"]: utils.namedObjectList(spec.initContainers),
        [if spec.restartPolicy != null then "restartPolicy"]: spec.restartPolicy,
        [if spec.tolerations != null then "tolerations"]: spec.tolerations,
        volumes: utils.namedObjectList(spec.volumes),
    },
};

spec
