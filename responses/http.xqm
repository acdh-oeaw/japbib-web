xquery version "3.1";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/http";
import module namespace request = "http://exquery.org/ns/request";
import module namespace l = "http://basex.org/modules/admin";

import module namespace rest = "http://exquery.org/ns/restxq";

declare function api:get-base-uri-public() as xs:string {
    let $forwarded-hostname := if (contains(request:header('X-Forwarded-Host'), ',')) 
                                 then substring-before(request:header('X-Forwarded-Host'), ',')
                                 else request:header('X-Forwarded-Host'),
        $urlScheme := if ((lower-case(request:header('X-Forwarded-Proto')) = 'https') or 
                          (lower-case(request:header('Front-End-Https')) = 'on')) then 'https' else 'http',
        $port := if ($urlScheme eq 'http' and request:port() ne 80) then ':'||request:port()
                 else if ($urlScheme eq 'https' and not(request:port() eq 80 or request:port() eq 443)) then ':'||request:port()
                 else '',
        (: FIXME: this is to naive. Works for ProxyPass / to /exist/apps/cr-xq-mets/project
           but probably not for /x/y/z/ to /exist/apps/cr-xq-mets/project. Especially check the get module. :)
        $xForwardBasedPath := (request:header('X-Forwarded-Request-Uri'), request:path())[1]
    return $urlScheme||'://'||($forwarded-hostname, request:hostname())[1]||$port||$xForwardBasedPath
};

(:~
 : Returns a html or related file.
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %rest:path("japbib-web/{$file=.+}")
function api:file($file as xs:string) as item()+ {
  let $path := api:base-dir()|| $file
  return if (file:exists($path)) then
    if (matches($file, '\.(htm|html|js|map|css|png|gif|jpg|jpeg)$', 'i')) then
    (
      web:response-header(map { 'media-type': web:content-type($path) }),
      file:read-binary($path)
    ) else
    api:forbidden-file($file)
  else if (matches($file, 'runTests/.+\.(xml)$')) then
	api:run-tests(replace($file, 'runTests/', ''))
  else
  (
  <rest:response>
    <http:response status="404" message="{$file} was not found.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>{$file||' was not found'}</title>
    <body>        
       <h1>{$file||' was not found'}</h1>
    </body>
  </html>
  )
};

declare %private function api:base-dir() as xs:string {
  replace(file:base-dir(), '^(.+)responses.*$', '$1')
};

(:~
 : Returns index.html on /.
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %rest:path("japbib-web")
function api:index-file() as item()+ {
  let $index-html := api:base-dir()||'index.html',
      $index-htm := api:base-dir()||'index.htm',
      $uri := rest:uri(),
(:      $log := l:write-log('api:index-file() $uri := '||$uri||' base-uri-public := '||api:get-base-uri-public(), 'DEBUG'),:)
      $absolute-prefix := if (matches(api:get-base-uri-public(), '/$')) then () else api:get-base-uri-public()||'/'
  return if (exists($absolute-prefix)) then
    <rest:redirect>{$absolute-prefix}</rest:redirect>
  else if (file:exists($index-html)) then
    <rest:forward>index.html</rest:forward>
  else if (file:exists($index-htm)) then
    <rest:forward>index.htm</rest:forward>
  else api:forbidden-file($index-html)    
};

(:~
 : Return 403 on all other (forbidden files).
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %private
function api:forbidden-file($file as xs:string) as item()+ {
  <rest:response>
    <http:response status="403" message="{$file} forbidden.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>{$file||' forbidden'}</title>
    <body>        
       <h1>{$file||' forbidden'}</h1>
    </body>
  </html>
};

declare
  %rest:error('*')
  %rest:error-param("code", "{$code}")
  %rest:error-param("description", "{$description}")
  %rest:error-param("value", "{$value}")
  %rest:error-param("module", "{$module}")
  %rest:error-param("line-number", "{$line-number}")
  %rest:error-param("column-number", "{$column-number}")
  %rest:error-param("additional", "{$additional}")
function api:error-handler($code as xs:string, $description, $value, $module, $line-number, $column-number, $additional) as item()+ {
  <rest:response>
    <http:response status="500" message="{$description}.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>{$description}</title>
    <body>        
       <h1>{$description}</h1>
	   <p>
       {$code}:{$description} {$value} in {$module} at {$line-number}:{$column-number}:<br/>
       {for $match in analyze-string($additional, '.*\n', 'm')/*
          return ($match/text(),<br/>)
       }
	   </p>
    </body>
  </html>
};

declare
  %rest:path("japbib-web/test-error.xqm")
function api:test-error() as item()+ {
  api:test-error('api:test-error')
};

declare
  %rest:path("japbib-web/test-error.xqm/{$error-qname}")
function api:test-error($error-qname as xs:string) as item()+ {
  error(xs:QName($error-qname))
};

declare
  %rest:path("japbib-web/runTests/{$file=[^/].+\.(xml)}")
function api:run-tests($file as xs:string) as item()+ {
  let $path := file:base-dir()|| $file
  return if (file:exists($path) and doc($path)/tests) then
  (
    web:response-header(map { 'media-type': 'text/xml'}),
    serialize(xquery:invoke('tests/runTests.xquery', map{'': doc($path)}))
  )
  else
  (
  <rest:response>
    <http:response status="404" message="Tests in {$file} were not found.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>{'Tests in '||$file||' were not found'}</title>
    <body>        
       <h1>{'Tests in '||$file||' were not found'}</h1>
    </body>
  </html>
  )
};

declare
  %rest:path("japbib-web/runtime")
function api:runtime-info() as item()+ {
  let $runtime-info := db:system()
  return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>Runtime info</title>
    <body>        
       <h1>Runtime info</h1>
       <table>
       {for $item in $runtime-info/*:generalinformation/*
       return
         <tr>
           <td>{$item/local-name()}</td>
           <td>{$item}</td>
         </tr>
       }
       </table>
    </body>
  </html>
};
