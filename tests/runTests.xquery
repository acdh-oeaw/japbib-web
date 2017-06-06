xquery version "3.0";

import module namespace cql = "http://exist-db.org/xquery/cql" at "file:/C:/Users/Daniel/repo/japbib-web/cql.xqm";

declare function local:runTests($item as document-node()){
    local:handle($item/tests)
};

declare function local:handle ($item as item()) {
    typeswitch ($item) 
        case element(test) return local:handleTestElt ($item)
        (: @outcome and <actual> are always generated anew :)
        case attribute(outcome) return ()
        case element(actual) return ()
        case element() return element {QName(namespace-uri($item), local-name($item))} { for $n in ($item/@*, $item/node()) return local:handle($n) }
        case document-node() return document { for $n in $item/node() return local:handle($n) }
        default return $item
};

declare function local:handleTestElt($item as element(test)) as element(test){
    let $xcql := cql:parse($item/query)
    let $expected := $item/expected/*
    let $matches-expected := saxon:deep-equal($xcql, $expected, (), 'wS')  
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