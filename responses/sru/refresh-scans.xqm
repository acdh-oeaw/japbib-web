xquery version "3.1";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/refresh";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace request = "http://exquery.org/ns/request";
import module namespace db = "http://basex.org/modules/db";
import module namespace l = "http://basex.org/modules/admin";
import module namespace xslt = "http://basex.org/modules/xslt";

import module namespace sru-api = "http://acdh.oeaw.ac.at/japbib/api/sru" at "../sru.xqm";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "diagnostics.xqm";
import module namespace scan = "http://acdh.oeaw.ac.at/japbib/api/sru/scan" at "scan.xqm";
import module namespace index = "japbib:index" at "../../index.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace zr = "http://explain.z3950.org/dtd/2.1/";

(: Looks up alle configured indexes and (re)generates the scan responses
   cached for them.
:)
declare 
    %rest:path("japbib-web/sru/refresh-scans")
    %output:media-type("application/json")
    %output:method("json")
    %output:json("format=direct")
    %rest:GET
    %rest:produces("text/json")
function api:refresh-cache() {
    let $context := $sru-api:HOSTNAME,
        $indexes := index:map-to-indexInfo()//zr:name,
        $ns := index:namespaces($context),
        $scanClauses := for $i in $indexes return if ($i = ('cql.serverChoice', 'id')) then () else xs:string($i),
        $scans := for $s in $scanClauses return for $sort in ('size', 'text') return <_>{scan:scan('1.2', $s, 20, 1, $sort, 'refresh', '', false())/sru:*}</_>
    return
        api:prepared-scans-for-json-direct($scans)
};

(: Does a little transform so a bunch of scanResponses (renamed to _ for this purpose)
   can be transformed to json using the direct method
   see http://docs.basex.org/wiki/JSON_Module#Direct
   Basically replaces the sru:terms/sru:term+ construct with the XML used to generate a sru:terms array in JSON
   The "type" of object that each XML element is mapped to can be seen in the json wrapper tag.
   All texts in the sru response XML are interpreted as strings.
   @param items: a set of scan responses but renamed to _
:)
declare %private function api:prepared-scans-for-json-direct($items as element(_)+) {
    let $envelope := <json type="object" arrays="sru:scanResponse sru:terms" objects="_ sru:extraTermData sru:echoedScanRequest"><sru:scanResponse>{$items}</sru:scanResponse></json>
    return copy $ret := $envelope
    modify (
      for $t in $ret//sru:term
      return rename node $t as '_'
    )
    return $ret
};
