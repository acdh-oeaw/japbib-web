xquery version "3.0";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/sru/scan";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace jobs = "http://basex.org/modules/jobs";
import module namespace l = "http://basex.org/modules/admin";

import module namespace sru-api = "http://acdh.oeaw.ac.at/japbib/api/sru" at "../sru.xqm";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "diagnostics.xqm";
import module namespace cache = "japbib:cache" at "cache.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";
import module namespace cql = "http://exist-db.org/xquery/cql" at "cql.xqm";
import module namespace index = "japbib:index" at "../../index.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace fcs = "http://clarin.eu/fcs/1.0";

(:~ Returns a sru scan.
 : @param $version: required, must be equal to $api:SRU.SUPPORTEDVERSION
 : @param $scanClause: required, must be a known index
 : @param $responsePosition: which term should be the first in the list, defaults to 1
 : @param $maxumumTerms: number of terms in the list, defaults to 50
 : @param $x-sort: sorting of the term list. Possible values: 'size' (number of occurences) or 'text' (alphabetically by the term)
 : @param $x-debug: do not return scan but show some debugging information 
~:)
declare 
    %rest:path("japbib-web/sru/scan")
    %rest:query-param("version", "{$version}")
    %rest:query-param("scanClause", "{$scanClause}")
    %rest:query-param("responsePosition", "{$responsePosition}", 1)
    %rest:query-param("maximumTerms", "{$maximumTerms}", 50)
    %rest:query-param("x-sort", "{$x-sort}", "size")
    %rest:query-param("x-filter", "{$x-filter}")
    %rest:query-param("x-mode", "{$x-mode}")
    %rest:query-param("x-debug", "{$x-debug}", "false")
    %rest:GET
    %rest:produces("text/xml")
    %output:method("xml")
function api:scan($version, $scanClause, 
                  $maximumTerms as xs:integer?, $responsePosition as xs:integer?,
                  $x-sort as xs:string?, $x-mode,
                  $x-filter, $x-debug as xs:boolean) {
    let $log := l:write-log('scan:scan', 'DEBUG'),
        $sort := if (lower-case($x-sort) eq 'text') then 'text' else 'size'
    return if (not(exists($scanClause))) then diag:diagnostics("param-missing", "scanClause") else 
           if (not($version)) then diag:diagnostics("param-missing", "version")
           else api:scan-filter-limit-response-and-cache($scanClause, $maximumTerms, $responsePosition, $sort, $x-mode, $x-filter, $x-debug) 
};

declare %private function api:scan-filter-limit-response-and-cache($scanClause as xs:string,  
                  $maximumTerms as xs:integer?, $responsePosition as xs:integer?,
                  $x-sort as xs:string?, $x-mode as xs:string?,
                  $x-filter as xs:string?, $x-debug as xs:boolean) {
   let $try-scan-query := ``[import module namespace api = "http://acdh.oeaw.ac.at/japbib/api/sru/scan" at "scan.xqm";
       api:scan-filter-limit-response('`{$scanClause => replace("'", "''") => replace('&amp;', '&amp;amp;') (: highlighter fix " ' :)}`', `{$maximumTerms}`, `{$responsePosition}`, "`{$x-sort}`", "`{$x-mode}`", "`{$x-filter}`", `{$x-debug}`(), false())]``,
       $jid := jobs:eval($try-scan-query, (), map {'cache': true()}), $_ := jobs:wait($jid),
       $try-scan := jobs:result($jid),
       $ret := if ($try-scan[1] instance of element(api:empty)) then () else $try-scan[1],
       $terms := $try-scan[2],
       $cached-scan := $try-scan[3],
       $cacheScanIfNeeded := if ($terms instance of document-node() and empty($cached-scan)) then cache:scan($terms, api:parseScanClause($scanClause), $x-sort) else ()
   return $ret
};

declare function api:scan-filter-limit-response($scanClause as xs:string,  
                  $maximumTerms as xs:integer?, $responsePosition as xs:integer?,
                  $x-sort as xs:string?, $x-mode as xs:string?,
                  $x-filter as xs:string?, $x-debug as xs:boolean,
                  $fail-on-not-cached as xs:boolean) as item()+ {
   let (: $start := prof:current-ns(), :)
       $sort := if (lower-case($x-sort) eq 'text') then 'text' else 'size',
       $scanClauseParsed := api:parseScanClause($scanClause),
       $scanClauseIndex :=  $scanClauseParsed/index,
       $cached-scan := if ($x-mode eq "refresh") then () else cache:scan($scanClauseParsed, $x-sort),
       $fail := if (empty($cached-scan) and $fail-on-not-cached) then error(xs:QName('diag:scanNotCached'), 'Scan for index '||$scanClauseParsed/index||' needs to be cached!') else (),
       $terms := if (empty($cached-scan) or $x-mode eq 'refresh') then api:do-scan($scanClauseParsed, $sort, $x-debug) else $cached-scan,
       $ret := if ($terms instance of document-node())
               then api:scanResponse($scanClause, $scanClauseParsed, $terms, $maximumTerms, $responsePosition, $x-sort, $x-filter)
               else $terms
       (:, $runtime := ((prof:current-ns() - $start) idiv 10000) div 100,
       $logScanClause := if ($runtime > 10) then l:write-log('api:scan-filter-limit-response slow $scanClauseParsed := '||serialize($scanClauseParsed), 'DEBUG') else (),
       $logRuntime := if ($runtime > 10) then l:write-log('api:scan-filter-limit-response runtime ms: '||$runtime) else () :)
   return (if (empty($ret)) then (<api:empty/>, <api:empty/>, <api:empty/>) else ($ret, $terms, $cached-scan))
};

(:~
 : Computes the full scan scan
 : @param $scanClausePaarsed: required, translated to an XML snippet, must be a known index
 : @param $x-sort: sorting of the term list. Possible values: 'size' (number of occurences, default) or 'text' (alphabetically by the term)
 : @param $x-debug: do not return scan but show some debugging information
 : @return either element(sru:terms) or element(sru:diagnostics) or element(debug)
~:)
declare %private function api:do-scan($scanClauseParsed as element(scanClause), $x-sort as xs:string?,
                                      $x-debug as xs:boolean?) as item() {
    let $log := l:write-log('api:do-scan $x-debug := '||$x-debug||' $scanClauseParsed := '||serialize($scanClauseParsed), 'DEBUG'),
        $context := $sru-api:HOSTNAME,
        $map as element(map) := index:map($context), 
        $ns := index:namespaces($context),
        $scanClauseIndex :=  $scanClauseParsed/index,
        $index-xpath := index:index-as-xpath-from-map($scanClauseIndex, $map, 'path-only'),
        $index-match := index:index-as-xpath-from-map($scanClauseIndex, $map, 'match-only'),
        $label-xpath := index:index-as-xpath-from-map($scanClauseIndex, $map, 'label'),
        $xpath_or_diagnostics := 
            if (some $x in ($index-xpath, $index-match) satisfies $x instance of element(sru:diagnostics)) 
            then ($index-xpath, $index-match)[self::sru:diagnostics] 
            else "//"||$index-xpath,
        $label-rel-xpath := if (exists($label-xpath)) then replace($label-xpath, $index-xpath, '', 'q') else $index-match,
        $xquery := if ($xpath_or_diagnostics instance of xs:string) then
                     concat(
                         string-join(for $n in $ns return "declare namespace "||$n/@prefix||" = '"||$n/@uri||"';"),
                         "import module namespace _ = 'urn:sur2html' at '../localization.xqm';
                          for $t in db:open('", $model:dbname, "')", $xpath_or_diagnostics, "
                          let $v := normalize-space(string-join($t/", $index-match,"/data(), ' ')) 
                          group by $v
                          let $c := count($t),
                              $l := string-join(data(($t", $label-rel-xpath,")[1]), ' ') 
                          order by ", if ($x-sort = 'text') then '$v ascending' else '$c descending', "
                          return <_>
                              <sru:term xmlns:sru='http://www.loc.gov/zing/srw/' xmlns:fcs='http://clarin.eu/fcs/1.0'>
                                 <sru:numberOfRecords>{$c}</sru:numberOfRecords>
                                 <sru:value>{$v}</sru:value>
                                 <sru:displayTerm>{$l}</sru:displayTerm>
                              </sru:term>,
                              <node-pre value='{string-join(db:node-pre($t/ancestor::mods:mods), &quot; &quot;)}'/></_>"
                     ) else '()',
        $logXQuery := l:write-log('api:do-scan $xpath_or_diagnostics := '||$xpath_or_diagnostics||' $xquery := '||$xquery, 'DEBUG'),
        $terms_or_diagnostics := 
            if (not($xpath_or_diagnostics instance of xs:string)) then $xpath_or_diagnostics
            else try {
                    let $jid := jobs:eval($xquery, (), map {'cache': true()}), $_ := jobs:wait($jid),
                        $jres := jobs:result($jid), 
                        $terms :=
                    <sru:terms>
                        {$jres/sru:term}
                    </sru:terms>,
                        $numbered-terms := api:numberTerms($terms, $jres/node-pre)
                    return document {$numbered-terms}
                } catch * {
                    diag:diagnostics('general-error', 'Error evaluating expression '||$xquery||' '||$err:description)
                },
        $ret :=
            if ($x-debug = true()) then <debug>{$xquery}</debug>
            else $terms_or_diagnostics
(:        , $logRet := l:write-log('api:do-scan return '||substring(serialize($ret), 1, 240)||' instance of document-node() '||$ret instance of document-node(), 'DEBUG'):)
    return $ret
};

declare function api:parseScanClause($scanClause as xs:string) as element(scanClause) {
   let $context := $sru-api:HOSTNAME,
       $map as element(map):= index:map($context)
   return api:parseScanClause($scanClause, $map)
};

declare function api:parseScanClause($scanClause as xs:string, $map as element(map)) as element(scanClause) {
    if ($scanClause = $map//index/@key/data(.))
    then <scanClause><index>{$scanClause}</index></scanClause>
    else 
        if (matches($scanClause,$cql:modifierRegex))
        then 
            let $parsed := cql:parse($scanClause)
            return 
                if ($parsed instance of element(sru:diagnostics))
                then $parsed
                else <scanClause>{$parsed/*}</scanClause>
        else diag:diagnostics('general-error', 'Unparsed scanClause '||$scanClause) 
};

(:~
 : Wraps a (sub)sequence of sru:terms in a sru:scanResponse element.
 : @param $scanClause: The scanClause as string. Only used for error reporting
 : @param $scanClauseParsed: The scanClause parsed into an XML fragment
 : @param $terms: the source terms to be filtered according to position and number 
 : @param $maxumumTerms: number of terms in the list. If empty, all terms are returned (used for caching)
 : @param $responsePosition: which term should be the first in the list
 : @param $x-filter: TODO to be implemented
~:)
declare %private function api:scanResponse($scanClause as xs:string,
                                           $scanClauseParsed as element(scanClause), $terms as document-node(),
                                           $maximumTerms as xs:integer?, $responsePosition as xs:integer,
                                           $x-sort as xs:string?, $x-filter as xs:string?){
    let $anchor-term :=
        try {
        switch($scanClauseParsed/relation)
(:            case "==" return $terms/sru:terms/*[.//sru:value eq $scanClauseParsed/term] (\:does not get optimized ?!:\) :)
(: hand optimization, don not reuse without thorough consideration :)
            case "==" return cache:text-nodes-in-cached-file-equal(api:t-unmask-quotes($scanClauseParsed/term), $terms)[parent::sru:value]/ancestor::sru:term
            case "=" return $terms//sru:term[starts-with(.//sru:value, api:t-unmask-quotes($scanClauseParsed/term))]
            case "contains" return $terms//sru:term[contains(.//sru:value, api:t-unmask-quotes($scanClauseParsed/term))]
            case "any" return $terms//sru:term[contains(.//sru:value, api:t-unmask-quotes($scanClauseParsed/term))]
            case () return $terms//sru:terms[1]
            default  return error(xs:QName('diag:unimplementedRelation'), "Don't know how to handle relation"||$scanClauseParsed/relation||" for scan")
        } catch * {
            error(xs:QName('diag:unableToInterpretScanClause'), $err:code||': '||$err:description||': '||$err:additional||' '||$scanClause||' parsed as XML scanClause: '||serialize($scanClauseParsed))
        },
        $error := if (normalize-space($scanClauseParsed/term) ne '' and empty($anchor-term)) then error(xs:QName('diag:noAnchor'), 'Anchor term '||$scanClauseParsed/term||' was not found in scan using relation '||$scanClauseParsed/relation||' '||$scanClause) else (),
        $start-term-position := (count($anchor-term/preceding-sibling::*) + 1) + (-$responsePosition + 1),
        $scan-clause := xs:string($scanClauseParsed),
        $ret :=
    if (normalize-space($scanClauseParsed/term) ne '' or $maximumTerms ne 1) then
    <sru:scanResponse xmlns:diag="//www.loc.gov/zing/srw/diagnostic/" xmlns:sru='http://www.loc.gov/zing/srw/' xmlns:fcs='http://clarin.eu/fcs/1.0'>
        <sru:version>{$sru-api:SRU.SUPPORTEDVERSION}</sru:version>
        <sru:terms>
        {subsequence($terms/sru:terms/sru:term, $start-term-position, $maximumTerms)}
        </sru:terms>
        <sru:echoedScanRequest>
            <sru:scanClause>{$scan-clause}</sru:scanClause>
            <sru:maximumTerms>{$maximumTerms}</sru:maximumTerms>
            <fcs:x-filter>{$x-filter}</fcs:x-filter>
            <fcs:x-sort>{$x-sort}</fcs:x-sort>
        </sru:echoedScanRequest>
    </sru:scanResponse>
    else ()
(:        , $logRet := l:write-log('api:scanResponse return '||substring(serialize($ret), 1, 240), 'DEBUG'):)
    return $ret
};

declare %private function api:t-unmask-quotes($t as element(term)) as xs:string {
  replace($t, '\\&quot;', '&quot;')
};

declare %private function api:numberTerms($terms as element(sru:terms), $pres as element(node-pre)*) as element(sru:terms) {
let $numbered-terms :=
    <sru:terms>{
    for $t at $pos in $terms/sru:term
    return $t update insert node   
        <sru:extraTermData>
           <fcs:position>{$pos}</fcs:position>
           <api:node-pre>{$pres[$pos]/text()}</api:node-pre>
        </sru:extraTermData>
    after ./sru:displayTerm}
    </sru:terms>
return $numbered-terms
};