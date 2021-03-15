local deployment = import "common/deployment.libsonnet";
local pod = import "common/pod.libsonnet";
local container = import "common/container.libsonnet";
local volumes = import "common/volumes.libsonnet";
local env = import "common/env.libsonnet";
local service = import "common/service.libsonnet";

local c = container {
    env: {
        "S3_KEY": env.secret("s3-api-token", "key"),
        "S3_SECRET": env.secret("s3-api-token", "secret"),
        "S3_BUCKET": "andyleap-static",
    },
    image: "andyleap/static",
    ports: {
        http: 8080,
    },
};

local p = pod {
    containers: {
        "static": c,
    },
};

local d = deployment {
    name: "static",
    pod: p,
    maxUnavailable: 0,
    maxSurge: 1,
};

local s = service {
    name: "static",
    annotations: {
        "git.andyleap.dev/singress-target": "static.andyleap.dev",
    },
    selector: d.selector,
    ports: {
        http: {
            port: 8080,
            targetPort: "http",
        },
    },
};

[d.output, s.output]