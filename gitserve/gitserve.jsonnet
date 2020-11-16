local deployment = import "common/deployment.libsonnet";
local pod = import "common/pod.libsonnet";
local container = import "common/container.libsonnet";
local volumes = import "common/volumes.libsonnet";
local env = import "common/env.libsonnet";
local service = import "common/service.libsonnet";

local c = container {
    args: [
        "--watchy=http://watchy.events:8080/git",
        "--argo=http://argo-server.argo:2746/api/v1/events/build/gitserve",
        "--argo-token=/mnt/secrets/trigger-token/token",
    ],
    env: {
        "S3_KEY": env.secret("s3-api-token", "key"),
        "S3_SECRET": env.secret("s3-api-token", "secret"),
        "S3_BUCKET": "andyleap-git",
    },
    image: importstr "gitserve.image",
    ports: {
        http: 8080,
    },
    volumeMounts: {
        "/mnt/secrets/trigger-token/": "trigger-token",
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
    maxUnavailable: 0,
    maxSurge: 1,
};

local s = service {
    name: "gitserve",
    annotations: {
        "git.andyleap.dev/singress-target": "git.andyleap.dev",
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