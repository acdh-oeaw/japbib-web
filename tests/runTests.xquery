xquery version "3.0";

import module namespace cql = "http://exist-db.org/xquery/cql" at "../cql.xqm";
declare namespace saxon = "http://saxon.sf.net/";

declare function local:runTests($item as document-node()){
    local:handle($item/tests)
};

declare function local:compare($s1, $s2) {
    try {
        if (not(empty(function-lookup(xs:QName('saxon:parse'), 1))))
        then saxon:deep-equal($s1, $s2, (), 'wS')
        else false()
    } catch * {
        ()
    }
};

declare function local:handle ($item as item()) {
    typeswitch ($item) 
        case element(test) return try { local:handleTestElt ($item) } catch * {($item, <error>{$err:code||": "||$err:description|| " (module "||$err:module||", line "||$err:line-number||")"}</error>)}
        (: @outcome is always generated anew :)
        case attribute(outcome) return ()
        (: <actual> is always generated anew :)
        case element(actual) return ()
        (: <error> is always generated anew :)
        case element(error) return ()
        case element() return element {QName(namespace-uri($item), local-name($item))} { for $n in ($item/@*, $item/node()) return local:handle($n) }
        case document-node() return document { for $n in $item/node() return local:handle($n) }
        default return $item
};

declare function local:handleTestElt($item as element(test)) as element(test){
    let $xcql := cql:parse($item/query)
    let $expected := $item/expected/*
    let $matches-expected := local:compare($xcql, $expected)
    return
    element {QName(namespace-uri($item), local-name($item))} {(
        for $att in $item/@* return local:handle($att),
        attribute outcome {if ($matches-expected) then 'success' else 'failure'},
        for $n in $item/node() return local:handle($n),
        if (not($matches-expected))
        then <actual>{$xcql}</actual>
        else ()
    )}
};

local:runTests(.)