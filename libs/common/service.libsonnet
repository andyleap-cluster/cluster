local utils = import "common/utils.libsonnet";

local spec = {
    name:: error "NAME REQUIRED",
    namespace:: std.extVar("namespace"),

    type:: "ClusterIP",
    clusterIP:: null,
    externalTrafficPolicy:: null,
    loadBalancerIP:: null,
    assert ($.loadBalancerIP == null) || ($.type == "LoadBalancer") : "LOADBALANCERIP CANNOT BE SET FOR NON LOADBALANCER",

    ports:: {},

    selector:: {},

    output:: {
        apiVersion: "v1",
        kind: "Service",
        metadata: {
            name: spec.name,
            namespace: spec.namespace,
        },
        spec: {
            type: spec.type,
            [utils.optional(spec, "clusterIP")]: spec.clusterIP,
            [utils.optional(spec, "externalTrafficPolicy")]: spec.externalTrafficPolicy,
            [utils.optional(spec, "loadBalancerIP")]: spec.loadBalancerIP,

            ports: utils.namedList(spec.ports, "name", "port"),

            selector: spec.selector,
        },
    }
};

spec
