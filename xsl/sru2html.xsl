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
    <xsl:variable name="dict" as="element()+">
        <dict xml:lang="de" xmlns="">
            <entry id="no-year-abbr">o.J.</entry>
        </dict>
    </xsl:variable>
    <xsl:function name="_:dict">
        <xsl:param name="id"/>
        <xsl:value-of select="$dict/entry[@id = $id]"/>
    </xsl:function>
    <xsl:template match="/">
        <xsl:apply-templates/>
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
            <form action="sru">
                <input name="query"/>
                <input name="version" type="hidden" value="{sru:version}"/>
                <input name="operation" type="hidden" value="searchRetrieve"/>
                <button type="submit">Search</button>
            </form>
            <div class="meta">
                <xsl:apply-templates select="sru:extraResponseData"/>
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
        <h4>Subjects</h4>
        <xsl:apply-templates select="taxonomy"/>
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
                    <tr><td>Next Record Position</td><td><xsl:value-of select="../sru:nextRecordPosition"/></td></tr>
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
        <a class="fullRecordLink" href="sru?operation=searchRetrieve&amp;version=1.2&amp;query=id={mods:mods/mods:recordInfo/mods:recordIdentifier}&amp;x-style=record2html.xsl">
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
        </a>
        <span class="title"><xsl:value-of select="$title"/>.</span>
    </xsl:template>
    
    <xsl:template name="format-record-heading">
        
    </xsl:template>
</xsl:stylesheet>
