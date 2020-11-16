local deployment = import "common/deployment.libsonnet";
local pod = import "common/pod.libsonnet";
local container = import "common/container.libsonnet";
local volumes = import "common/volumes.libsonnet";
local env = import "common/env.libsonnet";
local service = import "common/service.libsonnet";

local c = container {
    env: {
        "GITUPDATE_USER": "gitupdate",
        "GITUPDATE_EMAIL": "gitupdate@andyleap.dev",
    },
    image: importstr "gitupdate.image",
    ports: {
        http: 8080,
    },
    volumeMounts: {
        "/mnt/secret/gitupdate/": "gitupdate",
    },
};

local p = pod {
    containers: {
        "gitupdate": c,
    },
    volumes: {
        "gitupdate": volumes.secret("gitupdate"),
    },
};

local d = deployment {
    name: "gitupdate",
    pod: p,
    maxUnavailable: 0,
    maxSurge: 1,
};

local s = service {
    name: "gitupdate",
    selector: d.selector,
    ports: {
        http: {
            port: 8080,
            targetPort: "http",
        },
    },
};

[d.output, s.output]