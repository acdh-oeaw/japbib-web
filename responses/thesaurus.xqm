xquery version "3.0";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/thesaurus";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace xslt = "http://basex.org/modules/xslt";
import module namespace map = "http://www.w3.org/2005/xpath-functions/map";

declare namespace output = "https://www.w3.org/2010/xslt-xquery-serialization";

declare variable $api:path-to-thesaurus := "../thesaurus.xml";
declare variable $api:thesaurus2html := "../xsl/thesaurus2html.xsl";

declare 
    %rest:path("japbib-web/thesaurus")
    %rest:GET
    %rest:produces("text/xml")
    %output:method("xml")
function api:taxonomy-as-xml() {
    doc($api:path-to-thesaurus)
};

declare function api:taxonomy-as-xml($stats as element(subjects)) {
    api:addStatsToThesaurus(api:taxonomy-as-html(), $stats)    
};

declare function api:addStatsToThesaurus($stats as map(*)) {
    api:addStatsToThesaurus(api:taxonomy-as-xml(), $stats)
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
    %rest:produces("text/html", "application/xml+xhtml")
    %output:method("xml")
function api:taxonomy-as-html() {
    xslt:transform(doc($api:path-to-thesaurus), doc($api:thesaurus2html))
};