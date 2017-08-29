xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

(hist:save-entry-in-history('test', <testNode/>), db:output(
  (hist:add-change-record(<mods:testNode2/>),
  hist:add-change-record(hist:add-change-record(<mods:testNode2/>)))
))