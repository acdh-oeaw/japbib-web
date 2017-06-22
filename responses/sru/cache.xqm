xquery version "3.0";

module namespace c = "japbib:cache";

import module namespace db = "http://basex.org/modules/db";
import module namespace l = "http://basex.org/modules/admin";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";

declare variable $c:dbname := $model:dbname||"__cache";

declare %updating function c:scan($terms as element(sru:terms), $scanClauseParsed as element(scanClause), $sort as xs:string) {
    let $fn := c:scan-filename($scanClauseParsed, $sort)
    return try {
    if (exists($terms)) then
      if (exists(c:scan($scanClauseParsed, $sort)))
      then 
        let $log := l:write-log('cache:scan replacing cached scan in '||$c:dbname||': '||$fn)
        return db:replace($c:dbname, $fn,$terms)
      else if (db:exists($c:dbname)) then
        let $log := l:write-log('cache:scan creating cached scan in '||$c:dbname||': '||$fn)
        return db:add($c:dbname, $terms, $fn)        
      else
        let $log := l:write-log('cache:scan creating cached scan and db '||$c:dbname||': '||$fn)
        return db:create($c:dbname, $terms, $fn)
    else ()
    } catch err:FODC0007 {
         ()
    }
};

declare function c:scan($scanClauseParsed as element(scanClause), $sort as xs:string) as element(sru:terms)? {
    let $log := l:write-log('cache:scan $scanClause := '||$scanClauseParsed/index||' $sort := '||$sort, 'DEBUG'),
        $ret := if (db:exists($c:dbname)) 
                then try {
                   db:open($c:dbname, c:scan-filename($scanClauseParsed, $sort))/*
                } catch err:FODC0007 {
                   ()
                }
                else (),
        $logRest := l:write-log('cache:scan return '||substring(if (exists($ret)) then serialize($ret) else '()', 1, 240), 'DEBUG')
    return $ret
};

declare function c:scan-filename($scanClauseParsed as element(scanClause), $sort as xs:string) as xs:string {
    (: could also be import module namespace w = "http://basex.org/modules/web"; w:encode-url() but oXygen does not like url encoded filenames :) 
    $scanClauseParsed/index||"-"||$sort||".xml"
};