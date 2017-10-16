xquery version "3.1";

module namespace _ = "https://acdh.oeaw.ac.at/vle/history";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace session = "http://basex.org/modules/session";

declare %updating function _:add-change-record($e as element()) {
  let $user := try {session:get('dba')} catch bxerr:BXSE0003 {user:current()},
      $newEntry :=
      element {QName($e/namespace-uri(),'fs')} {
        namespace {''} {$e/namespace-uri()},
        attribute type {'change'},
        <f name="who">
          <symbol>{attribute value {$user}}</symbol>
        </f>,
        <f name="when">
          <symbol>{attribute value {format-dateTime(current-dateTime(),'[Y0001]_[M01]_[D01]')}}</symbol>
        </f>
      }
  return insert node $newEntry as last into $e
};

declare %updating function _:save-entry-in-history($db-base-name as xs:string, $cur-nodes as node()+) {
  let $hist-db-name := $db-base-name||'__hist',
      $hist-nodes := <_>{$cur-nodes}</_> update {./*!_:add-timestamp(.) }
  return try {
    insert node $hist-nodes/* as last into collection($hist-db-name)/hist
  } catch err:* {
    _:create-hist-db($hist-db-name, $hist-nodes/*)
  }
};

declare %updating function _:create-hist-db($dict as xs:string, $hist-element as element()?) {
   if (not(db:exists($dict)))
   then db:create($dict, <hist>{$hist-element}</hist>, $dict||'.xml')
   else ()
};

declare %updating function _:add-timestamp($cur-node as node()) {
   insert node (attribute dt {format-dateTime(current-dateTime(),'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')}) into $cur-node 
};