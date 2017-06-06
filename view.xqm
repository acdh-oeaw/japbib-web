xquery version "3.0" encoding "utf-8";

module namespace view = "http://acdh.oeaw.ac.at/webapp/view";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: This module renders any HTML content   :)
(: daniel.schopper@oeaw.ac.at 11/07/2016  :)

(: All of the following directory paths are relative to the "webapp" directory in basex-server installation :)
(: Path to the directory that contains static page templates:)
declare variable $view:tpl-path := "tpl";
(: Path to directory that contains all static web resources (JS, CSS files etc.) :)
declare variable $view:web-content-path := "web/";
(: Path to directory that contains all XSL stylesheets:)
declare variable $view:xsl-path := "xsl";

(: This is the main function which renders any .html "page". 
 Whenever starting a new web application do the following: 
    1) in %rest:path annotation: change the URL prefix ("japbib-web") to your prefix of choice
    2) add any request parameters that are needed in any view ("page") here. 
 :)
declare 
    %rest:path("japbib-web/{$page}.html")
    %rest:GET
    %rest:query-param("id", "{$id}")
    %rest:query-param("startAt", "{$startAt}")
    %rest:query-param("max", "{$max}")
    %output:method("xhtml")
    %output:omit-xml-declaration("no")
    %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")  
    %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
function view:view($page as xs:string, $id as xs:string?, $startAt as xs:integer?, $max as xs:integer?) {
     let $content := 
        try { doc($view:web-content-path||$page||".xml")}
        catch * {
            document {
                <view:surround with="page.html" at="content" xmlns="http://www.w3.org/1999/xhtml" xmlns:view="http://acdh.oeaw.ac.at/webapp/view">
                    <div class="panel panel-warning">
                        <div class="panel-heading">Warning</div>
                        <div class="panel-body">File <code>{$page}.xml</code> not found.</div>
                    </div>
                </view:surround>
            }
        },
         $params := (
            if (exists($page)) then map:entry("page", $page) else (),
            if (exists($id)) then map:entry("id", $id) else (),
            if (exists($startAt)) then map:entry("startAt", $startAt) else (),
            if (exists($max)) then map:entry("max", $max) else ()
         ),
         $params-map := if (exists($params)) then map:merge($params) else map{}
     return view:render($content, $params-map)
};


(:~
 : Returns a static file.
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %rest:path("japbib-web/static/{$file=.+}")
function view:file(  $file as xs:string ) as item()+ {
  let $path := file:base-dir() || $view:web-content-path || $file
  return (
    web:response-header(map { 'media-type': web:content-type($path) }),
    file:read-binary($path)
  )
};


declare function view:render($content as document-node(), $params as map(*)) {
    view:expand($content, $params)
};

(: Expands the given node, replacing any templating element placeholders with actual content  
 : $node the node to be rendered. 
 :)
declare function view:expand($nodes as node()+, $params as map(*)) {
    for $node in $nodes 
    return
        typeswitch($node)
            case document-node() return view:expand($node/*, $params)
            case element(view:surround) return view:surround-with($node, $params)
            case element(view:include) return view:include($node, $params)
            case element(view:transform) return view:transform($node, $params)
            case element(view:if) return view:if($node, $params)
            (:case element(view:limit) return view:limit($node, $params)
            case element(view:startAt) return view:startAt($node, $params):)
            case element(view:extract) return view:extract($node, $params)
            case element(view:if-param-set) return view:if-param-set($node, $params)
            case element(view:if-param-unset) return view:if-param-unset($node, $params)
            case element(view:exec) return view:exec($node, $params)
            case element() return
                element {QName(namespace-uri($node), local-name($node))} {(
                    $node/@*,
                    for $n in $node/node() return view:expand($n, $params)
                )}
            default return $node 
};

declare function view:extract($node as element(view:extract), $params as map(*)) {
    let $debug := false()
    let $content := view:expand($node/*, $params),
        $nss := map:merge(
                    for $p in distinct-values($node/ancestor-or-self::*/in-scope-prefixes(.))
                    where not($p = ("", "xml"))
                    return map:entry($p, namespace-uri-for-prefix($p, $node))
                )
    let $params := map:merge(($params, map:entry("content", $content)))
    let $query := concat(
                string-join(for $ns in map:keys($nss) return "declare namespace "||$ns||"='"||map:get($nss, $ns)||"';", "&#10;"),
                "&#10;",
                string-join(for $p in map:keys($params) return "declare variable $"||$p||" external;", "&#10;"),
                "&#10;&#10;",
                "$content"||$node/@xpath
            )
    return 
        if ($debug) 
        then <pre>{$query}</pre>
        else xquery:eval($query, $params)
};

declare function view:if-param-set($node as element(view:if-param-set), $params as map(*)) {
    if (map:contains($params, $node/@name))
    then view:expand($node/*, $params)
    else ()
};

declare function view:if-param-unset($node as element(view:if-param-unset), $params as map(*)) {
    if (not(map:contains($params, $node/@name)))
    then view:expand($node/*, $params)
    else ()
};

declare function view:startAt($node as element(view:startAt), $params as map(*)) {
    let $content := view:expand($node/*, $params),
        $value := 
            if (exists($node/@value) and $node/@value castable as xs:integer) 
            then xs:integer($node/@value) 
            else 
                if (exists($node/@query-param) and map:contains($params, $node/@query-param) and map:get($params, $node/@query-param) castable as xs:integer)
                then xs:integer(map:get($params, $node/@query-param))
                else ()
    return 
        if (exists($value))
        then view:expand(subsequence(view:expand($content, $params), $value), $params)
        else () 
};

declare function view:limit($node as element(view:limit), $params as map(*)) {
    let $content := view:expand($node/*, $params),
        $value := 
            if (exists($node/@value) and $node/@value castable as xs:integer) 
            then xs:integer($node/@value) 
            else 
                if (exists($node/@query-param) and map:contains($params, $node/@query-param) and map:get($params, $node/@query-param) castable as xs:integer)
                then xs:integer(map:get($params, $node/@query-param))
                else ()
    return 
        if (exists($value))
        then view:expand(subsequence(view:expand($content, $params), 1, $value), $params)
        else () 
};


declare function view:if($node as element(view:if), $params as map(*)) {
    
        let $result := 
            xquery:eval(
                concat(
                    string-join(for $p in map:keys($params) return "declare variable $"||$p||" external;", ""),
                    $node/@test
                ), $params
            )
        return if ($result) then view:expand($node/*, $params) else ()
};

declare function view:transform($node as element(view:transform), $params as map(*)) {
    let $content := view:expand($node/*[not(self::view:param)], $params),
        $pp := $node/view:param,
        $params := map:merge(($params, for $p in $pp return map:entry($p/@name, data($p)))),
        $stylesheet := doc($view:xsl-path||"/"||$node/@stylesheet)
    return $content!xslt:transform(., $stylesheet, $params)
};

declare function view:exec($node as element(view:exec), $params as map(*)) {
    let $module := $node/@module/xs:string(.),
        $arity := count($node/view:argument),
        $f := fn:function-lookup(QName($module, $node/@function), $arity)
    return
        if ($arity eq 0) 
        then $f() 
        else  
            $f(
                for $p in $node/view:argument return
                    let $p-val := if ($p/@query-param) then map:get($params, $p/@query-param) else $p
                    return 
                        if ($p/@type eq "xs:integer") then xs:integer($p-val) else 
                        if ($p/@type eq "xs:string") then xs:string($p-val)  
                        else data($p-val)
            )
};

(: apply view:surround element
 : @param $node the original node to be surrounded
 :)
declare function view:surround-with($node as element(view:surround), $params as map(*)) {
    let $with-template := view:get($node/@with),
        $at := $node/@at/xs:string(.)
    return view:surround-with($node, $with-template, $at, $params) 
};

declare function view:surround-with($node as node(), $template as node(), $at as xs:string, $params as map(*)) {
    typeswitch ($template)
        case document-node() return view:surround-with($node, $template/*, $at, $params)
        case element() return 
            element {QName(namespace-uri($template), local-name($template))} {(
                $template/@*,
                if ($template/@id eq $at)
                then 
                    for $i in $node/node() 
                    return view:expand($i, $params)
                else 
                    for $n in $template/node()
                    return view:expand(view:surround-with($node, $n, $at, $params), $params) 
            )}
        default return $template

    
};

declare function view:include($node as element(view:include), $params as map(*)) {
    let $template := view:get($node/@what)
    return view:expand($template, $params)  
};


(: Reads the file indicated by $p in the templates directory :)
declare function view:get($p as xs:string) {
    (:if (doc-available(doc($view:tpl-path||$p)))
    then :)doc($view:tpl-path||"/"||$p)
(:    else <error>{"Template "||$view:tpl-path||$p||" not found."}</error>:)
};