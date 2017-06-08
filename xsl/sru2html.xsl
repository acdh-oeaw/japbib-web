<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xcql="http://www.loc.gov/zing/cql/xcql/"
    xmlns:d="http://www.loc.gov/zing/srw/diagnostic/"
    xmlns="http://www.w3org/1999/xhtml"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:_="urn:sur2html"
    xmlns:saxon="http://saxon.sf.net/"
    exclude-result-prefixes="#all"
    version="2.0">
    <xsl:param name="xcql" select="''" as="xs:string"/>
    <xsl:param name="startRecord" select="1" as="xs:integer"/>
    <xsl:param name="maximumRecords" select="10" as="xs:integer"/>
    <xsl:param name="query" select="''" as="xs:string"/>
    <xsl:param name="base-uri-public" select="''" as="xs:string"/>
    <xsl:param name="base-uri" select="''" as="xs:string"/>
    <xsl:param name="version" select="''" as="xs:string"/>
    
    <xsl:include href="thesaurus2html.xsl"/>
    <xsl:variable name="sru-url">http://localhost:8984/japbib-web/sru</xsl:variable>
    <xsl:variable name="dict" as="element()+">
        <dict xml:lang="de" xmlns="">
            <entry id="no-year-abbr">o.J.</entry>
            <entry id="aut">Autor</entry>
            <entry id="edt">Hrsg.</entry>
        </dict>
    </xsl:variable>
    <xsl:function name="_:dict">
        <xsl:param name="id"/>
        <xsl:choose>
            <xsl:when test="exists($dict/entry[@id = $id])">
                <xsl:value-of select="$dict/entry[@id = $id]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$id"/> <xsl:text> ABBREV NOT FOUND IN DICT !!!</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="/">
        <html>
            <head>
                <title>SRU Endpoint</title>
                <style type="text/css">
                    .css-switch ~ * {display: none;}
                    .css-switch:checked ~ *{display: initial;}
                </style>
            </head>
            <body>
                <xsl:apply-templates/>
            </body>
        </html>
    </xsl:template>
    <xsl:template match="sru:diagnostics">
       <div>
           <h1>ERROR</h1>
           <xsl:apply-templates/>
       </div>
    </xsl:template>
    
    <xsl:template match="d:diagnostic">
        <h5><xsl:value-of select="@key"/></h5>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="d:*" priority="-1">
        <p><xsl:value-of select="local-name()"/>: <xsl:value-of select="."/></p>
    </xsl:template>
    
    <xsl:template match="sru:searchRetrieveResponse">
        <div>
            <form action="{$base-uri-public}" method="get">
                <input name="query" value="{$query}"/>
                <input name="version" type="hidden" value="{$version}"/>
                <input name="startRecord" type="hidden" value="{$startRecord}"/>
                <input name="maximumRecords" type="hidden" value="{$maximumRecords}"/>
                <input name="operation" type="hidden" value="searchRetrieve"/>
                <button type="submit">Search</button>
            </form>
            <div class="meta">
                <xsl:if test="$xcql != ''">
                    <h4>XCQL</h4>
                    <pre><xsl:copy-of select="$xcql"/></pre>
                </xsl:if>
                <xsl:if test="$query != ''">
                    <h4>URI</h4>
                    <p>Public:
                    <pre><xsl:value-of select="concat($base-uri-public, '?version=', $version,
                                                                    '&amp;query=', $query,
                                                                    '&amp;maximumRecords=', $maximumRecords,
                                                                    '&amp;startRecord=', $startRecord)"/></pre>
                    Private:
                    <pre><xsl:value-of select="concat($base-uri, '?version=', $version,
                                                                    '&amp;query=', $query,
                                                                    '&amp;maximumRecords=', $maximumRecords,
                                                                    '&amp;startRecord=', $startRecord)"/></pre>
                    </p>
                </xsl:if>
                <xsl:apply-templates select="sru:extraResponseData"/>
            </div>
            <xsl:apply-templates select="sru:records"/>
        </div>
    </xsl:template>
    
    <xsl:template match="sru:extraResponseData/XPath">
        <h4>Transformed XQuery</h4>
        <pre><xsl:copy-of select="."/></pre>
    </xsl:template>
    
    <xsl:template match="sru:extraResponseData/XCQL">
        <h4>XCQL</h4>
        <pre><xsl:copy-of select="."/></pre>
    </xsl:template>
    
    <xsl:template match="sru:extraResponseData/subjects">
        <h4><label for="subjects-switch">Subjects</label></h4>
        <div>
            <input type="checkbox" class="css-switch" id="subjects-switch" name="ui-subjects-switch" style="display:none;" checked="checked"/>
            <xsl:apply-templates select="taxonomy"/>
        </div>
    </xsl:template>
    
    <xsl:template match="sru:extraResponseData">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="sru:records">
        <div class="records">
            <h4>Records</h4>
            <table>
                <tbody>
                    <tr><td>Number of Records</td><td><xsl:value-of select="../sru:numberOfRecords"/></td></tr>
                    <!--<xsl:if test="min(sru:recordNumber) gt 1">
                        <tr><td>Previous Record Position</td><td><a href="?{../sru}"><xsl:value-of select="../sru:nextRecordPosition"/></a></td></tr>
                    </xsl:if>-->
                    <xsl:if test="../sru:nextRecordPosition != ''">
                        <tr><td>Next Record Position</td><td><a href="?{../sru}"><xsl:value-of select="../sru:nextRecordPosition"/></a></td></tr>
                    </xsl:if>
                </tbody>
            </table>
            <ol data-numberOfRecords="{../sru:numberOfRecords}" data-nextRecordPosition="{../sru:nextRecordPosition}">
                <xsl:apply-templates select="sru:record"/>
            </ol>
        </div>
    </xsl:template>
    
    <xsl:template match="sru:record">
        <li value="{sru:recordNumber}">
            <xsl:apply-templates select="sru:recordData"/>
        </li>
    </xsl:template>
    
    <xsl:template match="sru:recordData">
        <xsl:variable name="title" select="mods:mods/mods:titleInfo/mods:title"></xsl:variable>
        <xsl:variable name="authors" select="mods:mods/mods:name[mods:role/mods:roleTerm = 'aut']/mods:namePart"/>
        <xsl:variable name="year" select="mods:mods/mods:originInfo/mods:dateIssued"/>
        <xsl:variable name="pubPlace" select="mods:mods//mods:originInfo/mods:place/mods:placeTerm"/>
        <xsl:variable name="publisher" select="mods:mods//mods:originInfo/mods:publisher"/>
        <xsl:variable name="host" select="mods:mods//mods:relatedItem[@type = 'host']"/>
        <xsl:variable name="series" select="mods:mods//mods:relatedItem[@type = 'series']"/>
        
        <span class="recordHead">
            <span class="authors">
                <xsl:for-each select="$authors">
                    <xsl:value-of select="."/>
                    <xsl:if test="count($authors) gt position()">
                        <xsl:text>,&#160;</xsl:text>
                    </xsl:if>
                </xsl:for-each>
                <xsl:text> </xsl:text>
            </span>
            <span class="year"><xsl:value-of select="($year,concat('[',_:dict('no-year-abbr'),']'))[1]"/></span>
            <xsl:text>,&#160;</xsl:text>
        
            <a href="sru?operation=searchRetrieve&amp;version=1.2&amp;query=id={mods:mods/mods:recordInfo/mods:recordIdentifier}&amp;x-style=record2html.xsl" class="sup"><xsl:value-of select="$title"/></a>
        </span>
        <div class="showEntry">
            <div class="showOptions">
                <form>
                    <label>Anzeige des Eintrags:
                        <select name="top5" size="1">
                            <option selected="">detailliert</option>
                            <option>Chicago Styles Manual</option>
                            <option>BibTeX</option>S
                            <option>Lidos</option>
                        </select>
                    </label>
                    <span class="erklärung"><span> „Detailliert“ enthält auch Stichworte, über die neue Suchabfragen möglich sind. Alle weiteren Optionen sind für das Kopieren in andere Formate gedacht. </span></span>
                </form>
            </div>
            <ul>
                <li class="eSegment"> Autor </li>
                <li> 
                    <xsl:choose>
                        <xsl:when test="not($authors)">o.N.</xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="$authors">
                                <xsl:value-of select="."/>
                                <xsl:call-template name="numberOfRecordsTemplate">
                                    <xsl:with-param name="index">author</xsl:with-param>
                                </xsl:call-template>
                                <xsl:if test="position() lt count($authors)"><xsl:text>, </xsl:text></xsl:if>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
                <li class="eSegment"> Titel </li>
                <li> <xsl:value-of select="string-join($title, ' ')"/></li>
                <xsl:if test="exists($host)">
                    <li class="eSegment"> In: </li>
                    <li>
                        <xsl:choose>
                            <xsl:when test="$host/mods:titleInfo != ''">
                                <xsl:value-of select="string-join($host/mods:titleInfo/*,'. ')"/>
                                <xsl:call-template name="numberOfRecordsTemplate">
                                    <xsl:with-param name="index">title</xsl:with-param>
                                    <xsl:with-param name="value"><xsl:value-of select="$host/mods:titleInfo/mods:title"/></xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>[o.T.]</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:choose>
                            <xsl:when test="$host/mods:name">
                                <xsl:call-template name="formatName">
                                    <xsl:with-param name="name" select="$host/mods:name"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                
                            </xsl:otherwise>
                        </xsl:choose>
                    </li>
                </xsl:if>
                <xsl:if test="exists($series)">
                    <xsl:variable name="volume" select="$series/mods:part/mods:detail[@type = 'volume']"/>
                    <li class="eSegment"> Reihe </li>
                    <li>
                        <xsl:value-of select="string-join($series//mods:titleInfo/*,' ')"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="if ($volume != '') then concat(', Bd. ', $volume) else ()"/>
                        <xsl:call-template name="numberOfRecordsTemplate">
                            <xsl:with-param name="index">series</xsl:with-param>
                            <xsl:with-param name="value" select="$series//mods:titleInfo"/>
                        </xsl:call-template>
                    </li>
                </xsl:if>
                <li class="eSegment"> Ort/Verlag/Jahr</li>
                <li xml:space="preserve"><xsl:value-of select="($pubPlace, 'o.O.')[1]"/>: <xsl:value-of select="($publisher, 'o.V.')[1]"/>, <xsl:value-of select="($year, 'o.J.')[1]"/></li>
                <!--<li class="eSegment"> Co-Autoren </li>
                <li> Paul, G. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Naumann, 
                    N. (<a href="#" class="zahl" title="Suchergebnisse">6</a>); Ōbayashi, T (<a href="#" class="zahl" title="Suchergebnisse">6</a>); Blümmel, 
                    V. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Vollmer, K. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Zöllner, 
                    R. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Lokowandt, H. (<a href="#" class="zahl" title="Suchergebnisse">6</a>); Fischer, 
                    P. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Knecht, P. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Pörtner, 
                    P. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Toelken, R. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Woirgardt, 
                    M. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Ikeda, H. (<a href="#" class="zahl" title="Suchergebnisse">6</a>)</li>
                <li class="eSegment"> Kollationsvermerk 
                </li>
                <li> 300 S. : Ill., graph. Darst., Notenbeisp.</li>-->
            </ul>
        </div>
    </xsl:template>
    
    <xsl:template name="format-record-heading">
        
    </xsl:template>
    
    <xsl:template name="numberOfRecordsTemplate">
        <xsl:param name="index" required="yes"/>
        <xsl:param name="value" required="no" select="."/>
        <xsl:variable name="query" select="concat($index,'=&quot;',$value,'&quot;')"/>
        <xsl:text>&#160;(</xsl:text>
        <a data-query="{$query}" href="{$sru-url}?operation=searchRetrieve&amp;version=1.2&amp;query={$query}" class="zahl" title="Suchergebnisse">numberOfRecords</a>
        <xsl:text>)</xsl:text>
    </xsl:template>
    
    <xsl:template name="formatName">
        <xsl:param name="name" as="element(mods:name)+"/>
        <xsl:for-each select="$name">
            <xsl:value-of select="mods:namePart"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="_:dict(mods:role/mods:roleTerm)"/>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
