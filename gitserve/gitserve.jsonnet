local deployment = import "common/deployment.libsonnet";
local pod = import "common/pod.libsonnet";
local container = import "common/container.libsonnet";
local volumes = import "common/volumes.libsonnet";
local service = import "common/service.libsonnet";

local c = container {
    args: [
        "--watchy=http://watchy.events:8080/git",
        "--argo=http://argo-server.argo:2746/api/v1/events/build/gitserve",
        "--argo-token=/mnt/secrets/trigger-token/token",
    ],
    image: std.extVar("gitserve-image"),
    ports: {
        "http": "8080",
    },
    volumeMounts: {
        "/mnt/secrets/trigger-token": "trigger-token",
    },
};

local p = pod {
    containers: {
        "gitserve": c,
    },
    volumes: {
        "trigger-token": volumes.secret("argo-trigger"),
    },
};

local d = deployment {
    name: "gitserve",
    pod: p,
};

local s = service {
    name: "gitserve",
    selector: d.selector,
    ports: {
        "8080": "8080",
    },
};

std.manifestYamlStream([d.output, s.output])