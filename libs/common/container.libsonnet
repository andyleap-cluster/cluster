local utils = import "common/utils.libsonnet";

{
    args:: null,
    command:: null,
    workingDir:: null,
    env:: {},
    image:: error "IMAGE REQUIRED",
    imagePullPolicy:: "Always",
    ports:: {},
    resources:: null,
    volumeMounts:: null,

    local spec = self,
    output:: {
        [if spec.args != null then "args"]: spec.args,
        [if spec.command != null then "command"]: spec.command,
        [if spec.env != {} then "env"]: utils.namedList(spec.env),
        [if spec.workingDir != null then "workingDir"]: spec.workingDir,
        image: spec.image,
        imagePullPolicy: spec.imagePullPolicy,
        [if spec.ports != {} then "ports"]: utils.namedList(spec.ports, value_field="containerPort"),
        [if spec.resources != null then "resources"]: spec.resources,
        [if spec.volumeMounts != null then "volumeMounts"]: utils.namedList(spec.volumeMounts, name_field="mountPath", value_field="name"),
    },
}

