xquery version "3.1";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/sru";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace request = "http://exquery.org/ns/request";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "sru/diagnostics.xqm";
import module namespace searchRetrieve = "http://acdh.oeaw.ac.at/japbib/api/sru/searchRetrieve" at "sru/searchRetrieve.xqm";
import module namespace scan = "http://acdh.oeaw.ac.at/japbib/api/sru/scan" at "sru/scan.xqm";

import module namespace index = "japbib:index" at "../index.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../model.xqm";

declare namespace output = "https://www.w3.org/2010/xslt-xquery-serialization";
declare namespace bxerr = "http://basex.org/errors";

declare variable $api:SRU.SUPPORTEDVERSION := "1.2";
declare variable $api:HOSTNAME := "http://jb80.acdh.oeaw.ac.at";
declare variable $api:SRU.DATABASE := $model:dbname;
declare variable $api:SRU.DATABASETITLE := "JB 80: Deutschsprachige Japan-Bibliographie 1980–2000";

declare variable $api:path-to-stylesheets := "../../xsl/";

declare 
    %rest:path("japbib-web/sru")
    %rest:query-param("version", "{$version}")
    %rest:query-param("operation", "{$operation}", "explain")
    %rest:query-param("query", "{$query}")
    %rest:query-param("startRecord", "{$startRecord}", 1)
    %rest:query-param("maximumRecords", "{$maximumRecords}", 50)
    %rest:query-param("scanClause", "{$scanClause}")
    %rest:query-param("responsePosition", "{$responsePosition}", 1)
    %rest:query-param("maximumTerms", "{$maximumTerms}", 50)
    %rest:query-param("x-sort", "{$x-sort}", "text")
    %rest:query-param("x-style", "{$x-style}")
    %rest:query-param("x-mode", "{$x-mode}")
    %rest:query-param("x-filter", "{$x-filter}")
    %rest:query-param("x-debug", "{$x-debug}", "false")
    %rest:query-param("x-no-search-filter", "{$x-no-search-filter}", "false")
    %rest:GET
    %output:method("xml")
function api:sru($operation as xs:string, $query, 
                 $version, $maximumRecords as xs:integer,
                 $startRecord as xs:integer, $scanClause,
                 $maximumTerms as xs:integer, $responsePosition as xs:integer,
                 $x-sort as xs:string, $x-style,
                 $x-mode, $x-filter,
                 $x-debug as xs:boolean,
                 $x-no-search-filter as xs:boolean) {
    let $context := "http://jp80.acdh.oeaw.ac.at"
    let $ns := index:namespaces($context),
        $accept := try{ request:header('ACCEPT') } catch bxerr:BASX0000 | basex:http {'text/html'}
    return
        if (not($version)) then diag:diagnostics('param-missing', 'version') else
        if ($version != $api:SRU.SUPPORTEDVERSION) then diag:diagnostics('unsupported-version', $version) else
        try {
            switch($operation)
                case "searchRetrieve" return searchRetrieve:searchRetrieve($query, $version, $maximumRecords, $startRecord, $x-style, $x-debug, $x-no-search-filter, $accept)
                case "scan" return api:scan($version, $scanClause, $maximumTerms, $responsePosition, $x-sort, $x-mode, $x-filter, $x-debug)
                default return api:explain()
        } catch diag:* {
            diag:diagnostics('general-error', 
       $err:code||': '||$err:description||' '||$err:value||' in '||$err:module||' at '||$err:line-number||': '||$err:column-number||': '||$err:additional)
        }
};

declare %private function api:scan($version, $scanClause, 
                  $maximumTerms as xs:integer?, $responsePosition as xs:integer?,
                  $x-sort as xs:string?, $x-mode,
                  $x-filter, $x-debug as xs:boolean) {
(: refresh dead locks. Needs to be executed in it's own job.
   searchRetrieve needs to be written in a way that forces a read lock on the cache db which scan wants to write to on refresh. :)
if ($x-mode = "refresh") then error(xs:QName('diag:not-implemented'), 'use sru/scan') else scan:scan($version, $scanClause, $maximumTerms, $responsePosition, $x-sort, $x-mode, $x-filter, $x-debug)
};

declare 
    %rest:path("japbib-web/sru/explain")
    %rest:GET
    %output:method("xml")
function api:explain() {
    <sru:explainResponse xmlns:sru="//www.loc.gov/zing/srw/">
        <sru:version>{$api:SRU.SUPPORTEDVERSION}</sru:version>
        <sru:record>
        <sru:recordPacking>XML</sru:recordPacking>
        <sru:recordSchema>http://explain.z3950.org/dtd/2.1/</sru:recordSchema>
        <sru:recordData>
            <zr:explain xmlns:zr="http://explain.z3950.org/dtd/2.1/">
                <zr:serverInfo protocol="SRU" version="{$api:SRU.SUPPORTEDVERSION}" transport="http" method="GET POST">
                    <zr:host>{$api:HOSTNAME}</zr:host>
                    <zr:port>80</zr:port>
                    <zr:database>{$api:SRU.DATABASE}</zr:database>
                </zr:serverInfo>
                <zr:databaseInfo>
                    <title lang="en" primary="true">{$api:SRU.DATABASETITLE}</title>
                </zr:databaseInfo>
                {index:map-to-indexInfo()}
                {index:map-to-schemaInfo()}
                <zr:configInfo>
                    <zr:default type="numberOfRecords">1</zr:default>
                    <zr:setting type="maximumRecords">50</zr:setting>
                </zr:configInfo>
            </zr:explain>
        </sru:recordData>
        </sru:record>
    </sru:explainResponse>
};