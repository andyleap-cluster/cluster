{
    configMap(name):: {
        configMap: {
            name: name,
        },
    },

    secret(name):: {
        secret: {
            secretName: name,
        },
    },
}