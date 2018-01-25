xquery version "3.1";

(: This script runs the actual data update scripts. It sets a maximum of
   $_:maxNumberOfChangesPerJob per script run and runs it as often as
   necessary (determined by the scripts response to a
   call with $_:onlyGetNumberOfEntries := true() )
:)

import module namespace session = "http://basex.org/modules/session";
import module namespace l = "http://basex.org/modules/admin";

declare namespace _ = "urn:_";

declare variable $_:maxNumberOfChangesPerJob := 1000;
declare variable $_:basePath := file:temp-dir() || 'dba/';
(: string-join(tokenize(static-base-uri(), '/')[last() > position()], '/'); :)
(: declare variable $script_to_run external := 'write-remove-non-letter.xq'; :)
declare variable $script_to_run external := '9203-write-remove-amp.xq';
declare variable $get-db-list-query := '"japbib_06"';
(: Note: assumes 9174-MagDiplArb-subject.xq does the very same for test purpose! :)
declare variable $keep_changed_xml_until_finished := true();
declare variable $stage_2 external := false();
declare variable $run_as_user external := '';

declare function _:start-jobs-or-get-results() {
  let $update-jobs := jobs:list-details()[ends-with(@id, '_updWrite')]
  return if (exists($update-jobs)) then
    let $wait := $update-jobs[@state="running"]!jobs:wait(@id),
        $countUnfinished := count($update-jobs[@state=("queued", "running")])
    return 
      if ($countUnfinished > 0) then <message>{$countUnfinished||' queued for execution.'}</message>
      else ('Done.', $update-jobs[@state="cached"]!jobs:result(@id))
  else if ($stage_2) then
  let $get-params := jobs:eval(_:bind-external-variables($_:basePath||'/'||$script_to_run, map {'__db__': '', '__helper_tables__': 'helper_tables' }), map {'{urn:_}getParams': true()}, map {'cache': true() }),  $_ := jobs:wait($get-params),
      $params := map:merge(parse-xml(jobs:result($get-params))/*/*!map {@key: *}),
      $get-db-list := jobs:eval($get-db-list-query, map {}, map {'cache': true() }),  $_ := jobs:wait($get-db-list),
      $db-list := jobs:result($get-db-list),
      $changed-entries-per-db := _:number_of_changed_entries($db-list),
      $job-description := map:merge(
        for $db in $changed-entries-per-db
        return map {data($db/@name): map {'xquery': _:bind-external-variables($_:basePath||'/'||$script_to_run, map {'__db__': xs:string(data($db/@name)), '__helper_tables__': '' }),
        'batchStart': for $i in (0 to xs:integer(ceiling(xs:integer($db/text()) div $_:maxNumberOfChangesPerJob) - 1))
          return $i * $_:maxNumberOfChangesPerJob + 1}}),
      $job-results := for $batch in (1 to max($job-description?*!count(?batchStart)))
        let $job-ids := _:run-update-job($batch, $job-description, $params), $_ := $job-ids!jobs:wait(.)
        return if ($keep_changed_xml_until_finished) then $job-ids!jobs:result(.) else ()
  return $job-results
  else if (jobs:finished('writeInJunks')) then
  let $mainId := jobs:eval(unparsed-text($_:basePath||'/writer-to-db-in-junks.xq'), map {
        'stage_2': true(),
        'run_as_user': try {session:get('dba')} catch bxerr:BXSE0003 {user:current()}
        }, map {
        'cache': $keep_changed_xml_until_finished,
        'id': 'writeInJunks',
        'base-uri': $_:basePath||'/'
        })
  return 'Run again to get results.'
  else 'Should not happen'
};

declare function _:bind-external-variables(
    $uri   as xs:string,
    $vars  as map(xs:string, xs:string)
  ) as xs:string {
    let $xqcode := unparsed-text($uri)
    return fold-left(
      map:keys($vars), $xqcode, function($string, $name) {
        $string
        => replace('declare variable \$' || $name || ' external.*;', '', '')
        => replace('$' || $name, '"' || $vars($name) || '"', 'q')
      }
    )
};

declare function _:run-update-job($batch as xs:integer, $jobDescr as map(*),
                                  $params as map(*)) as xs:string* {
for $db in map:keys($jobDescr)
  return if ($jobDescr($db)('batchStart')[$batch]) then
    jobs:eval($jobDescr($db)('xquery'), map:merge(($params, map {
          '{urn:_}firstChangeJob': $jobDescr($db)('batchStart')[$batch],
          '{urn:_}maxNumberOfChangesPerJob': $_:maxNumberOfChangesPerJob,
          '{https://acdh.oeaw.ac.at/vle/history}user': $run_as_user
          })), map {
          'cache': $keep_changed_xml_until_finished,
          'id': $db||'_'||$batch||'_updWrite',
          'base-uri': $_:basePath||'/'||$jobDescr($db)('batchStart')||'-'||$script_to_run
        })
    else ()
};

declare function _:number_of_changed_entries($db_names as xs:string+) as element(db)+ {
  (: Note: uses an XQuery script without the leading write- if it exists:)
  let $job-ids := 
    for $db_name in $db_names
      let $slaveScript := _:bind-external-variables(replace($_:basePath||'/'||$script_to_run, 'write-', ''), map {'__db__': $db_name, '__helper_tables__': '' })
      return jobs:eval($slaveScript, map {
          '{urn:_}onlyGetNumberOfEntries': true()
          }, map {
          'cache': true(),
          'id': $db_name||'_numberOfEntries',
          'base-uri': $_:basePath||'/'||$slaveScript
          }),
    $_ := $job-ids!jobs:wait(.) 
   return $job-ids!<db name="{replace(., '_numberOfEntries', '', 'q')}">{jobs:result(.)}</db>
};

_:start-jobs-or-get-results()