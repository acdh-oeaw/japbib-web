xquery version "3.0";

module namespace c = "japbib:cache";

import module namespace db = "http://basex.org/modules/db";
import module namespace l = "http://basex.org/modules/admin";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";

declare variable $c:dbname := $model:dbname||"__cache";

declare %updating function c:scan($terms as item(), $scanClause as xs:string, $sort as xs:string) {
    let $fn := c:scan-filename($scanClause, $sort)
    return
    if (exists($terms)) then
      if (exists(c:scan($scanClause, $sort)))
      then 
        let $log := l:write-log('cache:scan replacing cached scan in '||$c:dbname||': '||$fn)
        return db:replace($c:dbname, $fn,$terms)
      else
        let $log := l:write-log('cache:scan creating cached scan in '||$c:dbname||': '||$fn)
        return db:create($c:dbname, $terms, $fn)
    else ()
};

declare function c:scan($scanClause as xs:string, $sort as xs:string) {
    let $log := l:write-log('cache:scan $scanClause := '||$scanClause||' $sort := '||$sort, 'DEBUG'),
        $ret := if (db:exists($c:dbname)) 
                then db:open($c:dbname, c:scan-filename($scanClause, $sort))
                else (),
        $logRest := l:write-log('cache:scan return '||substring(if (exists($ret)) then serialize($ret) else '()', 1, 240), 'DEBUG')
    return $ret
};

declare function c:scan-filename($scanClause as xs:string, $sort as xs:string) {
    $scanClause||"-"||$sort||".xml"
};