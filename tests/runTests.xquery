xquery version "3.0";

import module namespace cql = "http://exist-db.org/xquery/cql" at "../responses/sru/cql.xqm";
declare namespace saxon = "http://saxon.sf.net/";

declare function local:runTests($item as document-node()){
    local:handle($item/tests)
};

declare function local:compare($s1, $s2) {
    try {
        let $deep-equal := function-lookup(xs:QName('saxon:deep-equal'), 4)
        return
          if (exists($deep-equal))
          then $deep-equal($s1, $s2, default-collation(), 'wS')
          else deep-equal($s1, $s2, default-collation())
    } catch * {
        ()
    }
};

declare function local:handle ($item as item()) {
    typeswitch ($item) 
        case element(test) return try { local:handleTestElt ($item) } catch * {($item, <error>{$err:code||": "||$err:description|| " (module "||$err:module||", line "||$err:line-number||")"}</error>)}
        (: @result is always generated anew :)
        case attribute(result) return ()
        (: <actual> is always generated anew :)
        case element(actual) return ()
        (: <error> is always generated anew :)
        case element(error) return ()
        (: if there are comments in the input file ignore them :)
        case comment() return ()
        case text() return if ($item/ancestor::test) then $item else ()
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
        attribute result {if ($matches-expected) then 'success' else 'failure'},
        if (not($matches-expected)) then
        (for $n in $item/node() return local:handle($n),
         <actual>{$xcql}</actual>)
        else ()
    )}
};

local:runTests(.)