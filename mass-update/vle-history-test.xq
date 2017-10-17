xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare %updating function local:main() {
  let $save-in-histroy := hist:save-entry-in-history('test', <testNode/>),
      $test1 := serialize(
  (<mods:testNode2/> update hist:add-change-record(.),
  (<mods:testNode2/> update hist:add-change-record(.)) update hist:add-change-record(.)))
  return (db:output($test1),
         jobs:wait($save-in-histroy))  
};

local:main()