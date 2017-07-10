xquery version "3.0";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/thesaurus";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace request = "http://exquery.org/ns/request";
import module namespace xslt = "http://basex.org/modules/xslt";
import module namespace db = "http://basex.org/modules/db";
import module namespace map = "http://www.w3.org/2005/xpath-functions/map";
import module namespace cache = "japbib:cache" at "sru/cache.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../model.xqm";
import module namespace sru-api = "http://acdh.oeaw.ac.at/japbib/api/sru" at "sru.xqm";
import module namespace l = "http://basex.org/modules/admin";
import module namespace _ = "urn:sur2html" at "localization.xqm";

declare namespace output = "https://www.w3.org/2010/xslt-xquery-serialization";

declare namespace mods = "http://www.loc.gov/mods/v3";

declare variable $api:path-to-thesaurus := "../thesaurus.xml";
declare variable $api:path-to-stylesheets := replace($sru-api:path-to-stylesheets, '../(.*)', '$1');
declare variable $api:thesaurus2html := $api:path-to-stylesheets||"thesaurus2html.xsl";

declare %updating function api:taxonomy-cahce-as-xml($x-mode as xs:string?, $data-with-stats as document-node()) {
    if ($x-mode eq 'refresh') then cache:thesaurus($data-with-stats) else ()
};

declare function api:create-data-with-stats($x-mode as xs:string?) as document-node()? {
    let $log := l:write-log('api:create-data-with-stats $x-mode := '||$x-mode, 'DEBUG'),
        $stats-map := if ($x-mode eq 'refresh') then api:topics-to-map($model:db) else ()
    return if (exists($stats-map)) then document{api:addStatsToThesaurus($stats-map, $x-mode)} else ()
};

declare function api:taxonomy-as-xml-cached() {
    if (cache:thesaurus()) then cache:thesaurus() else doc($api:path-to-thesaurus)
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
    then (doc($api:path-to-thesaurus), l:write-log('loading doc '||$api:path-to-thesaurus||' and adding stats', 'DEBUG'))
    else (api:taxonomy-as-xml-cached(), l:write-log('loading doc cached thesaurus and adding stats', 'DEBUG')), $stats)
};

declare %private function api:doAddStatsToThesaurus($thesaurus as item(), $stats as map(*)) {
    typeswitch ($thesaurus)
        case document-node() return api:doAddStatsToThesaurus($thesaurus/*, $stats)
        case element(category) return 
            let $cat-stats := map:get($stats, $thesaurus/catDesc) 
            let $sub-topics := $thesaurus/*!api:doAddStatsToThesaurus(., $stats)
            return 
                if (exists($cat-stats) or exists($sub-topics//numberOfRecords))
                then 
                    element {QName(namespace-uri($thesaurus), local-name($thesaurus))} {(
                        $thesaurus/@*!api:doAddStatsToThesaurus(., $stats),
                        if ($cat-stats)
                        then <numberOfRecords>{$cat-stats}</numberOfRecords>
                        else (),
                        if ($sub-topics//numberOfRecords)
                        then <numberOfRecordsInGroup>{sum(($cat-stats, $sub-topics//numberOfRecords))}</numberOfRecordsInGroup>
                        else (),
                        $sub-topics
                    )}
                else ()
        case element(numberOfRecords) return ()
        case element(numberOfRecordsInGroup) return ()
        case element() return element {QName(namespace-uri($thesaurus), local-name($thesaurus))} { ($thesaurus/@*, $thesaurus/node())!api:doAddStatsToThesaurus(., $stats) }
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
    %updating
function api:taxonomy-as-html-cached($x-mode, $x-style) {
    let $data-with-stats := api:create-data-with-stats($x-mode),
        $style := if (some $a in tokenize(request:header("ACCEPT"), ',') satisfies $a = ('text/xml', 'application/xml')) then 'none' else $x-style,
        $ret := api:taxonomy-as-html($data-with-stats/*, $style)
    return (db:output($ret) , api:taxonomy-cahce-as-xml($x-mode, $data-with-stats))
};

declare function api:taxonomy-as-html($xml as element(taxonomy), $x-style as xs:string?) as node() {
    let $xsl := if ($x-style != '' and doc-available($api:path-to-stylesheets||$x-style)) then doc($api:path-to-stylesheets||$x-style) else doc($api:thesaurus2html),
        $log := l:write-log('api:taxonomy-as-html $xml := '||substring(serialize($xml), 1, 240)||' $xsl := '||substring(serialize($xsl), 1, 240)||' stylesheet '||$api:path-to-stylesheets||$x-style||', '||$api:thesaurus2html, 'DEBUG')
    return if ($x-style eq 'none') then $xml else xslt:transform($xml, $xsl, if ($x-style) then map{"x-style": $x-style} else map{})
};

declare function api:topics-to-map($r) as map(*) {
    let $log := l:write-log('api:topics-to-map base-uri($r) = '||base-uri(($r//mods:genre)[1]), 'DEBUG'),
        $matching-texts := (: prof:time( :)
        for $s in distinct-values(($r//mods:genre!(tokenize(., ' ')), $r//mods:subject[not(@displayLabel)]/mods:topic))
        return db:text($model:dbname, $s)[(ancestor::mods:genre|ancestor::mods:subject)],
(:        false(), 'api:topics-to-map all texts '),:)
        $intersection := (: prof:time( :)
        $matching-texts intersect ($r//mods:genre|$r//mods:subject)//text()
(:        , false(), 'api:topics-to-map intersection '):)
    return map:merge(
        for $t in $intersection
        let $v := _:dict($t)
        group by $v
        return map:entry($v, count($t))
    )
};