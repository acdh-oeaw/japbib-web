xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';

declare %updating function _:main() {
  let $entries := collection($_:db-name)//mods:mods[mods:genre[@authority="local" and . eq 'series']]
  for $e in $entries
  return
    (hist:save-entry-in-history($_:db-name, $e),
     replace value of node $e/mods:genre with 'Series',
     db:output($e/mods:genre))
};

_:main()