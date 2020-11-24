local deployment = import "common/deployment.libsonnet";
local pod = import "common/pod.libsonnet";
local container = import "common/container.libsonnet";
local volumes = import "common/volumes.libsonnet";
local env = import "common/env.libsonnet";
local service = import "common/service.libsonnet";

local c = container {
    args: [
    ],
    env: {
        "S3_KEY": env.secret("s3-api-token", "key"),
        "S3_SECRET": env.secret("s3-api-token", "secret"),
        "S3_BUCKET": "andyleap-puppytrack",
    },
    image: importstr "puppytrack.image",
    ports: {
        http: 8080,
    },
    volumeMounts: {
        "/mnt/secrets/trigger-token/": "trigger-token",
    },
};

local p = pod {
    containers: {
        "puppytrack": c,
    },
    volumes: {
        "trigger-token": volumes.secret("argo-trigger"),
    },
};

local d = deployment {
    name: "puppytrack",
    pod: p,
    maxUnavailable: 0,
    maxSurge: 1,
};

local s = service {
    name: "puppytrack",
    annotations: {
        "git.andyleap.dev/singress-target": "puppytrack.andyleap.dev",
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