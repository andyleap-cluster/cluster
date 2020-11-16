{
    pairList(tab,
             kfield="name",
             vfield="value"):: [
        { [kfield]: k, [vfield]: tab[k] }
        for k in std.objectFields(tab)
    ],

    namedObjectList(tab, name_field="name"):: [
        $.output(tab[name]) + { [name_field]: name }
        for name in std.objectFields(tab)
    ],

    namedList(tab, name_field="name", value_field="value"):: [
        (if std.type(tab[name]) == "object" then $.output(tab[name]) else { [value_field]: tab[name] }) + { [name_field]: name }
        for name in std.objectFields(tab)
    ],

    output(item):: if std.objectHasAll(item, "output") then
        (if item.output != null && std.type(item.output) == "function" then
             item.output(item)
         else item.output)
    else item,

    optional(spec, name):: if spec[name] != null then name,

    mergeObjects(objects):: std.foldl(function(state, next) state + next, objects, {}),
}
