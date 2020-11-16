local utils = import "common/utils.libsonnet";

local spec = {
    name:: error "NAME REQUIRED",
    namespace:: std.extVar("namespace"),
    pod:: error "POD SPEC REQUIRED",
    replicas:: 1,
    selector:: {
        app: $.name,
    },
    podLabels:: $.selector,
    maxUnavailable:: 1,
    maxSurge:: 0,

    local spec = self,
    output:: {
        apiVersion: "apps/v1",
        kind: "Deployment",
        metadata: {
            name: spec.name,
            namespace: spec.namespace,
        },
        spec: {
            replicas: spec.replicas,
            selector: {
                matchLabels: spec.selector,
            },
            revisionHistoryLimit: 5,
            strategy: {
                type: "RollingUpdate",
                rollingUpdate: {
                    maxSurge: spec.maxSurge,
                    maxUnavailable: spec.maxUnavailable,
                },
            },
            template: {
                metadata: {
                    labels: spec.podLabels,
                },
                spec: spec.pod.output,
            },
        },
    },
};

spec
