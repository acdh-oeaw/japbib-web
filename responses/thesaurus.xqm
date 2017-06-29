xquery version "3.0";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/thesaurus";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace xslt = "http://basex.org/modules/xslt";
import module namespace map = "http://www.w3.org/2005/xpath-functions/map";
import module namespace cache = "japbib:cache" at "sru/cache.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../model.xqm";

declare namespace output = "https://www.w3.org/2010/xslt-xquery-serialization";

declare namespace mods = "http://www.loc.gov/mods/v3";

declare variable $api:path-to-thesaurus := "../thesaurus.xml";
declare variable $api:thesaurus2html := "../xsl/thesaurus2html.xsl";

declare 
    %rest:path("japbib-web/thesaurus")
    %rest:GET
    %rest:query-param("x-mode", "{$x-mode}")
    %rest:produces("text/xml")
    %output:method("xml")
    %updating
function api:taxonomy-as-xml($x-mode) {
    let $data-with-stats := api:create-data-with-stats($x-mode)
    return (db:output($data-with-stats), api:taxonomy-cahce-as-xml($x-mode, $data-with-stats))
};

declare %updating function api:taxonomy-cahce-as-xml($x-mode as xs:string?, $data-with-stats as document-node()) {
    if ($x-mode eq 'refresh') then cache:thesaurus($data-with-stats) else ()
};

declare function api:create-data-with-stats($x-mode as xs:string?) as document-node()? {
    let $input-data := if ($x-mode eq 'refresh') then doc($api:path-to-thesaurus) else (),
        $stats-map := if ($x-mode eq 'refresh') then api:topics-to-map($model:db) else ()
    return if (exists($stats-map)) then document{api:addStatsToThesaurus($stats-map)} else api:taxonomy-as-xml-cached()
};

declare function api:taxonomy-as-xml-cached() {
    if (cache:thesaurus()) then cache:thesaurus() else doc($api:path-to-thesaurus)
};

(:declare function api:taxonomy-as-xml-with-stats($stats as element(subjects)) {
    api:taxonomy-as-html(api:addStatsToThesaurus(api:taxonomy-as-xml-cached(), $stats))
};
:)
declare function api:addStatsToThesaurus($stats as map(*)) {
    api:addStatsToThesaurus(api:taxonomy-as-xml-cached(), $stats)
};

declare %private function api:addStatsToThesaurus($thesaurus as item(), $stats as map(*)) {
    typeswitch ($thesaurus)
        case document-node() return api:addStatsToThesaurus($thesaurus/*, $stats)
        case element(category) return 
            let $cat-stats := map:get($stats, $thesaurus/catDesc) 
            let $sub-topics := $thesaurus/*!api:addStatsToThesaurus(., $stats)
            return 
                if (exists($cat-stats) or exists($sub-topics//numberOfRecords))
                then 
                    element {QName(namespace-uri($thesaurus), local-name($thesaurus))} {(
                        $thesaurus/@*!api:addStatsToThesaurus(., $stats),
                        if ($cat-stats)
                        then <numberOfRecords>{$cat-stats}</numberOfRecords>
                        else (),
                        $sub-topics
                    )}
                else ()
        case element() return element {QName(namespace-uri($thesaurus), local-name($thesaurus))} { ($thesaurus/@*, $thesaurus/node())!api:addStatsToThesaurus(., $stats) }
        case attribute() return $thesaurus
        default return $thesaurus
};

declare 
    %rest:path("japbib-web/thesaurus")
    %rest:GET
    %rest:query-param("x-mode", "{$x-mode}")
    %rest:produces("text/html", "application/xml+xhtml")
    %output:method("xml")
    %updating
function api:taxonomy-as-html-cached($x-mode) {
    let $data-with-stats := api:create-data-with-stats($x-mode),
        $ret := api:taxonomy-as-html($data-with-stats/*)
    return (db:output($ret) , api:taxonomy-cahce-as-xml($x-mode, $data-with-stats))
};

declare function api:taxonomy-as-html($xml as element(taxonomy)) as node() {
    xslt:transform($xml, doc($api:thesaurus2html))
};

declare function api:topics-to-map($r) as map(*) {
    map:merge(
        for $t in $r//mods:subject[not(@displayLabel)]/mods:topic
        let $v := data($t)
        group by $v
        return map:entry($v, count($t))
    )
};