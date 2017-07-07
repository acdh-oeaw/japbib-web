<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:api="http://acdh.oeaw.ac.at/webapp/api" version="2.0" xmlns="http://www.w3.org/1999/xhtml" xmlns:mods="http://www.loc.gov/mods/v3">

    <xsl:param name="lang">en</xsl:param>
    
    <xsl:template match="mods:mods">
        <div>
            <h3><xsl:apply-templates select="mods:titleInfo"/>&#160;(<a href="?id={@xml:id}&amp;format=xml">XML</a>)</h3>
            <xsl:apply-templates select="* except (mods:titleInfo|mods:subject)"/>
            <xsl:if test="mods:subject">
                <h5><i>Keywords:</i></h5>
                <ul>
                    <xsl:apply-templates select="mods:subject"/>
                </ul>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template name="shortCitation">
        <xsl:apply-templates select="root()/mods:mods/mods:titleInfo"/>
    </xsl:template>
    
    <xsl:template match="mods:genre|mods:typeOfResource"/>
        
    
    
    <xsl:template match="mods:omit">
        <span style="color:red;">Verlorenes Feld: <xsl:value-of select="."/></span>
    </xsl:template>
    
    <xsl:template match="mods:name">
        <p xml:space="preserve"><xsl:apply-templates select="mods:role/mods:roleTerm"/>: <xsl:value-of select="mods:namePart"/></p>
    </xsl:template>
    
    <xsl:template match="mods:roleTerm">
        <xsl:choose>
            <xsl:when test=". = 'aut'">Author</xsl:when>
            <xsl:when test=". = 'trl'">Translator</xsl:when>
            <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mods:relatedItem">
        <div class="mods_relatedItem">
            <h4><xsl:value-of select="@type"/></h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="mods:titleInfo[parent::mods:relatedItem]">
        <p>Title: <xsl:apply-templates/></p>
    </xsl:template>
    
    <xsl:template match="mods:title">
        <xsl:value-of select="."/>
    </xsl:template>
    <xsl:template match="mods:nonSort">
        <xsl:text>_</xsl:text>
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="mods:originInfo">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mods:dateIssued">
        <p xml:space="preserve"><xsl:call-template name="label"/><xsl:value-of select="."/></p>
    </xsl:template>
    
    <xsl:template match="mods:publisher">
        <p xml:space="preserve">Publisher: <xsl:value-of select="."/></p>
    </xsl:template>
    
    <xsl:template match="mods:place">
        <p xml:space="preserve">Place: <xsl:value-of select="."/></p>
    </xsl:template>
    
    <xsl:template match="mods:subject">
        <li><a href="search.html?q={normalize-space(.)}&amp;field=subject"><xsl:value-of select="mods:*"/></a></li>
    </xsl:template>
    
    <xsl:template name="label">
        <xsl:variable name="string">
            <xsl:choose>
                <xsl:when test="self::mods:name"><xsl:value-of select="mods:role/mods:roleTerm"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="local-name(.)"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="label">
            <xsl:call-template name="label-for-string">
                <xsl:with-param name="string" select="$string"/>
                <xsl:with-param name="lang" select="$lang"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="concat($label, ': ')"/>
    </xsl:template>
    
    <xsl:template name="label-for-string">
        <xsl:param name="string"/>
        <xsl:param name="lang"/>
        <xsl:variable name="path-to-dict" select="concat('dict-',$lang,'.xml')"/>
        <xsl:variable name="dict" select="doc($path-to-dict)"/>
        <xsl:value-of select="key('label-for-string', $string, $dict)"/>
    </xsl:template>
    
</xsl:stylesheet>