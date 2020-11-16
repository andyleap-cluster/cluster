local deployment = import "common/deployment.libsonnet";
local pod = import "common/pod.libsonnet";
local container = import "common/container.libsonnet";
local volumes = import "common/volumes.libsonnet";
local env = import "common/env.libsonnet";
local service = import "common/service.libsonnet";

local c = container {
    args: [
        "--privkey=/mnt/secrets/privkey/id_rsa"
    ],
    image: importstr "sshsweeper.image",
    ports: {
        ssh: 2200,
    },
    volumeMounts: {
        "/mnt/secrets/privkey/": "privkey",
    },
};

local p = pod {
    containers: {
        "sshsweeper": c,
    },
    volumes: {
        "privkey": volumes.secret("privkey"),
    },
};

local d = deployment {
    name: "sshsweeper",
    pod: p,
    maxUnavailable: 0,
    maxSurge: 1,
};

local s = service {
    name: "sshsweeper",
    selector: d.selector,
    ports: {
        http: {
            port: 2200,
            targetPort: "ssh",
        },
    },
};

[d.output, s.output]