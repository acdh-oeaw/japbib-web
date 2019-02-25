xquery version "3.0";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/thesaurus";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace request = "http://exquery.org/ns/request";
import module namespace xslt = "http://basex.org/modules/xslt";
import module namespace ft = "http://basex.org/modules/ft";
import module namespace map = "http://www.w3.org/2005/xpath-functions/map";
import module namespace cache = "japbib:cache" at "sru/cache.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../model.xqm";
import module namespace sru-api = "http://acdh.oeaw.ac.at/japbib/api/sru" at "sru.xqm";
import module namespace l = "http://basex.org/modules/admin";
import module namespace u = "http://acdh.oeaw.ac.at/japbib/api/sru/util" at "sru/util.xqm";
import module namespace _ = "urn:sur2html" at "localization.xqm";

declare namespace output = "https://www.w3.org/2010/xslt-xquery-serialization";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace scan-api = "http://acdh.oeaw.ac.at/japbib/api/sru/scan";

declare variable $api:thesaurus2html := $sru-api:path-to-stylesheets||"thesaurus2html.xsl";

declare function api:taxonomy-cache-as-xml($x-mode as xs:string?, $data-with-stats as document-node()) {
    if ($x-mode eq 'refresh') then cache:thesaurus($data-with-stats) else ()
};

declare function api:create-data-with-stats($x-mode as xs:string?) as document-node()? {
    let $log := l:write-log('api:create-data-with-stats $x-mode := '||$x-mode, 'DEBUG'),
        $db := <db xmlns="">{db:node-pre(collection("japbib_06")//mods:mods)!<n>{.}</n>}</db>,
        $stats-map := if ($x-mode eq 'refresh') then api:topics-to-map($db) else ()
    return if (exists($stats-map)) then document{api:addStatsToThesaurus($stats-map, $x-mode)} else api:taxonomy-as-xml-cached()
};

declare function api:taxonomy-as-xml-cached() {
    if (cache:thesaurus()) then cache:thesaurus() else doc("../thesaurus.xml")
};

(:declare function api:taxonomy-as-xml-with-stats($stats as element(subjects)) {
    api:taxonomy-as-html(api:addStatsToThesaurus(api:taxonomy-as-xml-cached(), $stats))
};
:)

declare function api:addStatsToThesaurus($stats as map(*)) {
    api:addStatsToThesaurus($stats, ())
};

declare function api:addStatsToThesaurus($stats as map(*), $x-mode as xs:string?) {
    api:doAddStatsToThesaurus(if ($x-mode eq 'refresh') 
    then (doc("../thesaurus.xml"), l:write-log('loading doc ../thesaurus.xml and adding stats', 'DEBUG'))
    else (api:taxonomy-as-xml-cached(), l:write-log('loading doc cached thesaurus and adding stats', 'DEBUG')), $stats, $x-mode = 'refresh')
};

declare %private function api:doAddStatsToThesaurus($thesaurus as item(), $stats as map(*), $copyAll as xs:boolean) {
    typeswitch ($thesaurus)
        case document-node() return api:doAddStatsToThesaurus($thesaurus/*, $stats, $copyAll)
        case element(category) return 
            let $cat-stats := map:get($stats, $thesaurus/catDesc) 
            let $sub-topics := $thesaurus/*!api:doAddStatsToThesaurus(., $stats, $copyAll)
            return 
                if ($copyAll or exists($cat-stats) or exists($sub-topics//numberOfRecords))
                then 
                    element {QName(namespace-uri($thesaurus), local-name($thesaurus))} {(
                        $thesaurus/@*!api:doAddStatsToThesaurus(., $stats, $copyAll),
                        if ($cat-stats)
                        then <numberOfRecords>{$cat-stats}</numberOfRecords>
                        else (),
                        $sub-topics
                    )}
                else ()
        case element(numberOfRecords) return ()
        case element(numberOfRecordsInGroup) return ()
        case element() return element {QName(namespace-uri($thesaurus), local-name($thesaurus))} { ($thesaurus/@*, $thesaurus/node())!api:doAddStatsToThesaurus(., $stats, $copyAll) }
        case attribute() return $thesaurus
        default return $thesaurus
};

(: %rest:produces will not work without problems until at least 8.7: https://github.com/BaseXdb/basex/issues/1220 :)
(: If there is no Accept header or the Accept header contains */* (like what oXygenXML sends) more than one functions :)
(: is selected and that is an error :)
(: %rest:produces("text/html", "application/xhtml+xml"):)
declare 
    %rest:path("japbib-web/thesaurus")
    %rest:GET
    %rest:query-param("x-mode", "{$x-mode}")
    %rest:query-param("x-style", "{$x-style}")
    %output:method("xhtml")
function api:taxonomy-as-html-cached($x-mode, $x-style) {
    let $data-with-stats-query := ``[import module namespace api = "http://acdh.oeaw.ac.at/japbib/api/thesaurus" at "thesaurus.xqm";
        api:create-data-with-stats("`{$x-mode}`")]``,
        $jid := jobs:eval($data-with-stats-query, (), map {'cache': true(), 'base-uri': static-base-uri()}), $_ := jobs:wait($jid),
        $data-with-stats := jobs:result($jid),
        $style := if (some $a in tokenize(request:header("ACCEPT"), ',') satisfies $a = ('text/xml', 'application/xml')) then 'none' else $x-style,
        $ret := api:taxonomy-as-html($data-with-stats/*, $style)
    return ($ret, api:taxonomy-cache-as-xml($x-mode, $data-with-stats))
};

declare function api:taxonomy-as-html($xml as element(taxonomy), $x-style as xs:string?) as node() {
    let $xsl := u:get-xml-file-or-default($sru-api:path-to-stylesheets||$x-style, $api:thesaurus2html, $x-style != ''),
        $log := l:write-log('api:taxonomy-as-html $xml := '||substring(serialize($xml), 1, 240)||' $xsl := '||substring(serialize($xsl), 1, 240)||' stylesheet '||$sru-api:path-to-stylesheets||$x-style||', '||$api:thesaurus2html, 'DEBUG')
    return if ($x-style eq 'none') then $xml else xslt:transform($xml, $xsl, if ($x-style) then map{"x-style": $x-style} else map{})
};

declare function api:_topics-to-map($db as element(db)) as map(*) {
    map {}
};

declare function api:topics-to-map($db as element(db)) as map(*) {
    let $r := $db/n!db:open-pre("japbib_06", .),
        $log := l:write-log('api:topics-to-map base-uri($r) = '||base-uri(($r//mods:genre)[1]), 'DEBUG'),
        $matching-texts := distinct-values(($r//mods:genre!(tokenize(., ' ')), $r//mods:subject[not(@displayLabel)]/mods:topic))
(:       , $log-matching-texts := l:write-log('api:topics-to-map $matching-texts := '||string-join(subsequence($matching-texts, 1, 30), '; '), 'DEBUG'),:),
        $start := prof:current-ns(),
        $ret := map:merge(api:get-count-for-matching-texts($db, $matching-texts)),
        $runtime := ((prof:current-ns() - $start) idiv 10000) div 100,
        $logRuntime := l:write-log('api:get-count-for-matching-texts ms: '||$runtime)
        return $ret       
};

declare %private function api:mj-get-count-for-matching-texts($db as element(db), $matching-texts as xs:string*) as map(*)* {
    let $queries := $matching-texts!``[import module namespace api = "http://acdh.oeaw.ac.at/japbib/api/thesaurus" at "../thesaurus.xqm";
    declare variable $db external;
    <_>{api:get-count-for-matching-text($db/n, '`{. => replace("'", "''") => replace('&amp;', '&amp;amp;')(: highlighter fix " ' :)}`', ())}</_>
    ]``,
       $result-pairs := u:evals($queries, map{'db': $db}, 'get-count-for-matching-texts', true())
    return $result-pairs!map:entry(./_[1]/text(), ./_[2]/text())
};

declare %private function api:mt-get-count-for-matching-texts($db as element(db), $matching-texts as xs:string*) as map(*)* {
    let $ret := for $t in $matching-texts
        let $funcs := function() {
            let $count-for-matching-text := api:get-count-for-matching-text($db/n, $t, ())
            return map:entry($count-for-matching-text[1]/text(), $count-for-matching-text[2]/text())
        }
    return xquery:fork-join($funcs)
    return $ret
};

declare %private function api:get-count-for-matching-texts($db as element(db), $matching-texts as xs:string*) as map(*)* {
    let $subject-terms := cache:scan(<scanClause><index>subject</index></scanClause>, 'text')
    return for $t in $matching-texts 
        let $count-for-matching-text := api:get-count-for-matching-text($db/n, $t, $subject-terms) 
    return map:entry($count-for-matching-text[1]/text(), $count-for-matching-text[2]/text())
};

declare function api:get-count-for-matching-text($mods-mods-node-pres as xs:integer*, $s as xs:string, $subject-terms-cache as document-node()) as element(_)+ {
let (: $all-occurences-mods-mods-node-pres := db:node-pre(ft:search("japbib_06", $s, map{'mode': 'phrase', 'content': 'entire'})[(ancestor::mods:genre|ancestor::mods:subject[not(@displayLabel)])]/ancestor::mods:mods), :)
    $matching-subjects := cache:text-nodes-in-cached-file-equal($s, $subject-terms-cache)/ancestor::sru:term,
    (: $log := if (count($matching-subjects > 1)) then l:write-log('more than one matching subject ?! '||$s||': '||string-join($matching-subjects/(sru:displayTerm|sru:numberOfRecords), ', '), 'DEBUG') else (), :)
    $all-occurences-mods-mods-node-pres := tokenize($matching-subjects[1]//scan-api:node-pre/@value, ' ')!xs:integer(.),
    (: $log := l:write-log('$all-occurences := '||count($all-occurences-mods-mods-node-pres)||' $all-results := '||count($mods-mods-node-pres), 'DEBUG'), :)
    (: changing the parameters in the following equation leads to wrong results. Intersection is not cummutative ?! :)
    $intersection := $all-occurences-mods-mods-node-pres[. = $mods-mods-node-pres],
    $ret := (<_>{$s}</_>, <_>{count($intersection)}</_>)
  (: , $log := l:write-log(serialize($ret), 'DEBUG') :)
return $ret
};