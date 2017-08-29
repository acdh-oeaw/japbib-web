xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "/tmp/dba/vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:db-name := 'japbib_06';

declare function _:select-entries() as element(mods:mods)* {
  collection($_:db-name)//mods:mods[mods:genre[@authority="local" and . eq 'Series'] and mods:originInfo[matches(., '^[^:]+:[^,]+,\s\d{4}-\d{0,4}$')]]
};

declare function _:transform($e as element(mods:mods)) as element(mods:mods) {
  let $comment := 'Changed!'
  return $e update
  { insert node comment {$comment}  as first into . }
};

declare %updating function _:main() {
  for $e in _:select-entries()
  return
    let $transformed-entry := hist:add-change-record(_:transform($e))
    return (hist:save-entry-in-history($_:db-name, $e),
     replace node $e with $transformed-entry,
     db:output($transformed-entry))
};

_:main()