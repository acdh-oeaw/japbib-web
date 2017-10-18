xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';

declare function _:select-entries() as element(mods:mods)+ {
  collection($_:db-name)//mods:mods[.//mods:namePart[matches(., '/ (\()?Hrsg\.(\))?$')]]
};

declare %updating function _:transform($e as element(mods:mods)) {
  for $name in .//mods:name[mods:namePart[matches(., '/ (\()?Hrsg\.(\))?$')]]  
    return (replace value of node $name/mods:namePart with replace($name/mods:namePart, '/ (\()?Hrsg\.(\))?$', ''),
            insert node comment{'Bug #9281 '||$name/mods:namePart} as first into $name,
            replace value of node $name/mods:role/mods:roleTerm/@type with 'personal')
};

declare %updating function _:main() {
  let $entries-subset := _:select-entries(),
      $store-in-history := hist:save-entry-in-history($_:db-name, $entries-subset)
  return (
  for $e in $entries-subset
  return (
     _:transform($e),     
     hist:add-change-record($e) ,
     db:output(serialize($e update
     { _:transform(.),     
       hist:add-change-record(.) })) ),
  jobs:wait($store-in-history)
  )
};

_:main()