xquery version "3.0";

(: The cache database __sru_cache_de_data__ is shared between all dictionary instances
   that can use German specialised full text search.
   The reason is locking. If the database name in 8.6.x is not a string literal a global read or write
   lock will be the consequence. This is not an option when running multiple jobs.
   If opening the cache database runs in its own job the result, which is the contents
   of a rather big XML file, is passed around in memory which slows down execution
   noticeably. :)

module namespace c = "japbib:cache";

import module namespace db = "http://basex.org/modules/db";
import module namespace prof = "http://basex.org/modules/prof";
import module namespace l = "http://basex.org/modules/admin";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace bxerr = "http://basex.org/errors";

declare variable $c:thesaurus-fn := $model:dbname||'-thesaurus.xml';
(: Note that the cache full text index is specialised for german! May work with English but other languages may vary. :)
declare variable $c:index-options := map{'textindex': true(), 'tokenindex': true(), 'ftindex': true(), 'casesens': false(), 'diacritics': false(), 'language': 'de'};

declare function c:scan($terms as document-node(), $scanClauseParsed as element(scanClause), $sort as xs:string) {
    let $fn := c:scan-filename($scanClauseParsed, $sort)
    return c:save-fn($terms, $fn)
};

declare function c:thesaurus($xml as document-node()) {
   c:save-fn($xml, $c:thesaurus-fn)
};

declare function c:save-fn($xml as document-node(), $fn as xs:string) {
 let $query := ``[import module namespace c = "japbib:cache" at "cache.xqm";
      import module namespace l = "http://basex.org/modules/admin";      
      declare namespace bxerr = "http://basex.org/errors";
      declare variable $xml external;
      try {
      if (exists(c:get-fn("`{$fn}`")))
      then 
        let $log := l:write-log('cache:scan replacing cached scan in __sru_cache_de_data__: `{$fn}`')
        return (db:replace("__sru_cache_de_data__", "`{$fn}`" ,$xml), db:optimize("__sru_cache_de_data__", true(), $c:index-options))
      else if (db:exists("__sru_cache_de_data__")) then
        let $log := l:write-log('cache:scan creating cached scan in __sru_cache_de_data__: `{$fn}`')
        return (db:add("__sru_cache_de_data__", $xml, "`{$fn}`"), db:optimize("__sru_cache_de_data__", true(), $c:index-options))
      else
        let $log := l:write-log('cache:scan creating cached scan and db __sru_cache_de_data__: `{$fn}`')
        return db:create("__sru_cache_de_data__", $xml, "`{$fn}`", $c:index-options)
    } catch err:FODC0007 | bxerr:BXDB0002 | db:open {
         ()
    }
   ]``,
      $saveJobId := jobs:eval($query, map{'xml': $xml }, map {
      'cache': true(),
      'id': 'cache-'||$fn||'.xq',
      'base-uri': string-join(tokenize(static-base-uri(), '/')[last() > position()], '/')||'/'||'cache-'||$fn||'.xq'}), $_ := jobs:wait($saveJobId)
  return jobs:result($saveJobId)
};

declare function c:scan($scanClauseParsed as element(scanClause), $sort as xs:string) as document-node()? {
    (: Beware: logging here is expensive (in searchRetrieve requests) :)
    let (:$log := l:write-log('cache:scan $scanClause := '||$scanClauseParsed/index||' $sort := '||$sort, 'DEBUG'),:)
        $fn := c:scan-filename($scanClauseParsed, $sort)
    return c:get-fn($fn)
};

declare function c:thesaurus() as document-node()? {
  c:get-fn($c:thesaurus-fn)
};

declare function c:get-fn($fn as xs:string) as document-node()? {
try {
  db:open("__sru_cache_de_data__", $fn)
} catch err:FODC0007 | bxerr:BXDB0002 | db:open {
  ()
}
};

declare function c:scan-filename($scanClauseParsed as element(scanClause), $sort as xs:string) as xs:string {
    (: could also be import module namespace w = "http://basex.org/modules/web"; w:encode-url() but oXygen does not like url encoded filenames :) 
    $model:dbname||'-'||$scanClauseParsed/index||"-"||$sort||".xml"
};

(: hand optimization, don not use without thorough consideration :)
declare function c:text-nodes-in-cached-file-equal($string as xs:string, $dn as document-node()) as text()* {
  db:text("__sru_cache_de_data__", $string)[base-uri(.) eq base-uri($dn)]
};