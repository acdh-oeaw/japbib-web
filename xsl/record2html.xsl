<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xcql="http://www.loc.gov/zing/cql/xcql/"
    xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/" xmlns="http://www.w3org/1999/xhtml"
    xmlns:mods="http://www.loc.gov/mods/v3" xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:_="urn:sur2html"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:include href="thesaurus2html.xsl"/>
    <xsl:strip-space elements="*"/>
    <xsl:param name="p_records-of-authors"/>
    <xsl:param name="p_records-of-series"/>
    <xsl:param name="p_records-of-publisher"/>
    <xsl:param name="p_records-of-topic"/>
    <xsl:param name="p_records-of-form"/>
    <xsl:variable name="records-of-authors" select="_:parse-stats($p_records-of-authors)"/>
    <xsl:variable name="records-of-series" select="_:parse-stats($p_records-of-series)"/>
    
   
    <xsl:function name="_:typeToLabel">
        <xsl:param name="string"/>
        <xsl:choose>
            <xsl:when test="$string = 'volume'">Bd.</xsl:when>
            <xsl:otherwise>UNKNOWN LABEL <xsl:value-of select="$string"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="_:resolveMARCcode">
        <xsl:param name="string"/>
        <xsl:choose>
            <xsl:when test="$string = 'aut'">Autor</xsl:when>
            <xsl:when test="$string = 'edt'">Hrsg.</xsl:when>
            <xsl:otherwise>UNKNOWN RELATOR CODE <xsl:value-of select="$string"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="_:parse-stats">
        <xsl:param name="string"/>
        <!-- "Heinz Huber"|20\t"Matthias Meier"|12-->
        <stats>
            <xsl:for-each select="tokenize($string,'\s*&#9;\s*')">
                <xsl:analyze-string select="." regex="&quot;(.+?)&quot;|\d+">
                    <xsl:matching-substring>
                        <item count="{regex-group(2)}"><xsl:value-of select="regex-group(1)"/></item>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:for-each>
        </stats>
    </xsl:function>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="sru:searchRetrieveResponse">
        <xsl:apply-templates select="sru:records"/>
    </xsl:template>

    <xsl:template match="sru:records">
        <xsl:apply-templates select="sru:record"/>
    </xsl:template>

    <xsl:template match="sru:record">
        <xsl:apply-templates select="sru:recordData"/>
    </xsl:template>

    <xsl:template match="sru:recordData">
        <div>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="mods:mods">
        <table>
            <tbody>
                <tr>
                    <td><i>Autor</i></td>
                    <td>
                        <xsl:for-each select="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')]">
                            <xsl:variable name="roleTerm" select="mods:role/normalize-space(mods:roleTerm)"/>
                            <xsl:variable name="roleLabel" select="_:resolveMARCcode($roleTerm)"/>
                            <span class="author"><xsl:value-of select="data(mods:namePart)"/> (<xsl:value-of select="$records-of-authors[. = current()]/@count"/>)<xsl:if test="$roleLabel != ''"><xsl:value-of select="concat(', ',$roleLabel)"/></xsl:if></span>
                        </xsl:for-each>
                    </td>
                </tr>
                <tr>
                    <td><i>Titel</i></td>
                    <td><xsl:value-of select="mods:titleInfo/data(.)"/></td>
                </tr>
                <xsl:if test="exists(descendant::mods:relatedItem[@type = 'series'])">
                    <tr>
                        <td><i>Reihe</i></td>
                        <td>
                            <xsl:apply-templates select="descendant::mods:relatedItem[@type= 'series']"/></td>
                    </tr>
                </xsl:if>
                <tr>
                    <td><i>Ort/Verlag/Jahr</i></td>
                    <td>
                        <xsl:value-of select="(mods:originInfo/mods:place/mods:placeTerm,mods:relatedItem[@type = 'host']/mods:originInfo/mods:place/mods:placeTerm)[1]"/>
                        <xsl:text>:&#160;</xsl:text>
                        <xsl:value-of select="(mods:originInfo/mods:publisher,mods:relatedItem[@type = 'host']/mods:originInfo/mods:publisher)[1]"/>
                        <xsl:text>,&#160;</xsl:text>
                        <xsl:value-of select="(mods:originInfo/mods:dateIssued,mods:relatedItem[@type = 'host']/mods:originInfo/mods:dateIssued)[1]"/>
                    </td>
                </tr>
                <xsl:if test="mods:physicalDescription">
                    <td><i>Kollationsvermerk</i></td>
                    <td><xsl:value-of select="mods:physicalDescription"/></td>
                </xsl:if>
            </tbody>
        </table>
        <h5>Verwandte Suchabfragen</h5>
        <table>
            <tr>
                <td>
                    <i>Thema</i>
                </td>
                <td>
                    <xsl:for-each select="mods:subject[not(@displayLabel)]/mods:topic">
                        <p><xsl:value-of select="."/></p>
                    </xsl:for-each>
                </td>
            </tr>
            <tr>
                <td>
                    <i>Form</i>
                </td>
                <td/>
            </tr>
            <tr>
                <td>
                    <i>Stichworte</i>
                </td>
                <td>
                    <xsl:for-each select="mods:subject[@displayLabel = 'Stichworte']/mods:topic">
                        <p><xsl:value-of select="."/> ()</p>
                    </xsl:for-each>
                </td>
            </tr>
        </table>
        <xsl:apply-templates select="mods:extension"/>
    </xsl:template>

    <xsl:template match="mods:name">
        <p>
            <xsl:value-of select="concat(mods:role/mods:roleTerm, ': ', mods:namePart)"/>
        </p>
    </xsl:template>

    <xsl:template match="mods:extension/LIDOS-Dokument">
        <div class="lidos-doc">
            <h5><xsl:value-of select="local-name()"/></h5>
            <pre>
                <xsl:for-each select="*">
                    <xsl:value-of select="concat(local-name(), ': ', ., '&#10;')"/>
                </xsl:for-each>
            </pre>
        </div>
    </xsl:template>
    
    <xsl:template match="mods:relatedItem[@type = 'series']">
        <xsl:value-of select="mods:titleInfo/data(.)"/>
        <xsl:text>&#160;</xsl:text>
        <xsl:apply-templates select="mods:part"/>
    </xsl:template>
    
    <xsl:template match="mods:part">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mods:detail">
        <xsl:value-of select="concat(_:typeToLabel(@type), '&#160;', .)"/>
    </xsl:template>
</xsl:stylesheet>
