xquery version "3.1";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/sru";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "sru/diagnostics.xqm";
import module namespace searchRetrieve = "http://acdh.oeaw.ac.at/japbib/api/sru/searchRetrieve" at "sru/searchRetrieve.xqm";
import module namespace scan = "http://acdh.oeaw.ac.at/japbib/api/sru/scan" at "sru/scan.xqm";

import module namespace index = "japbib:index" at "../index.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../model.xqm";

declare variable $api:SRU.SUPPORTEDVERSION := "1.2";
declare variable $api:HOSTNAME := "http://jb80.acdh.oeaw.ac.at";
declare variable $api:SRU.DATABASE := $model:dbname;
declare variable $api:SRU.DATABASETITLE := "JB 80: Deutschsprachige Japan-Bibliographie 1980–2000";

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
    %rest:query-param("x-debug", "{$x-debug}", "false")
    %rest:GET
    %rest:produces("text/xml")
    %output:method("xml")
function api:sru($operation, $query as xs:string?, $version, $maximumRecords as xs:integer, $startRecord as xs:integer, $scanClause, $maximumTerms, $responsePosition, $x-sort as xs:string, $x-style, $x-debug) {
    let $context := "http://jp80.acdh.oeaw.ac.at"
    let $ns := index:namespaces($context)
    return
        if (not($version)) then diag:diagnostics('param-missing', 'version') else
        if ($version != $api:SRU.SUPPORTEDVERSION) then diag:diagnostics('unsupported-version', $version) else
        switch($operation)
            case "searchRetrieve" return searchRetrieve:searchRetrieve($query, $version, $maximumRecords, $startRecord, $x-style, $x-debug)
            case "scan" return scan:scan($version, $scanClause, $maximumTerms, $responsePosition, $x-sort, $x-debug)
            default return api:explain()
};

declare 
    %rest:path("japbib-web/sru/explain")
    %rest:GET
    %rest:produces("text/xml")
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