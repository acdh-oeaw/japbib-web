xquery version "3.1";

(: Call this script directly to process a few hundred of entries with small
   changes.
   To update the whole database with larger changes try them and then use
   write-to-db-in-junks.xq with this script as the $script_to_run parameter
   else for large changes the list of updates will exhaust the memory. 
:)

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:maxNumberOfChangesPerJob external := 10;
declare variable $_:firstChangeJob external := 1;
declare variable $_:onlyGetNumberOfEntries external := false();
declare variable $_:db-name := 'japbib_06';

declare function _:select-entries() as element(mods:mods)* {
  collection($_:db-name)//mods:mods[mods:genre[@authority="local" and . eq 'Series'] and mods:originInfo[matches(., '^[^:]+:[^,]+')]]
};

declare %updating function _:transform($e as element(mods:mods)) {
  let $comment := 'Changed!'
  return insert node comment {$comment}  as first into $e
};

declare %updating function _:main() {
  let $entries-subset := subsequence(_:select-entries(), 1, $_:maxNumberOfChangesPerJob)
  return ( 
     hist:save-entry-in-history($_:db-name, $entries-subset),
  for $e in $entries-subset
  return (
     _:transform($e),     
     hist:add-change-record($e) ,
     db:output(serialize($e update
     { _:transform(.),     
       hist:add-change-record(.) })) )
  )
};

if ($_:onlyGetNumberOfEntries) then db:output(count(_:select-entries()))
else _:main()