<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:api="http://acdh.oeaw.ac.at/webapp/api" version="2.0" xmlns="http://www.w3.org/1999/xhtml" xmlns:mods="http://www.loc.gov/mods/v3">    
    <xsl:output method="text" indent="no"/>
    <xsl:template match="/">
        <xsl:apply-templates select="*"/>
    </xsl:template>
    <xsl:template match="*">
<!--        <span class="element">-->
<!--            <span class="openingTag">-->
                <xsl:text>&lt;</xsl:text>
                <xsl:value-of select="local-name()"/>
                <xsl:if test="@*">
                    <xsl:text>&#160;</xsl:text>
                </xsl:if>
                <xsl:for-each select="@*">
                    <xsl:apply-templates select="."/>
                    <xsl:if test="position() lt count(parent::*/@*)">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:for-each>
                <xsl:if test="not(node())">/</xsl:if>
                <xsl:text>&gt;</xsl:text>
            <!--</span>-->
            <xsl:apply-templates select="node() except @*"/>
<!--            <span class="closingTag">-->
                <xsl:if test="node() except @*">
                    <xsl:text>&lt;/</xsl:text>
                    <xsl:value-of select="local-name()"/>
                    <xsl:text>&gt;</xsl:text>
                </xsl:if>
            <!--</span>-->
        <!--</span>-->
        <xsl:if test="node()[1][not(matches(.,'^\s+$'))] instance of element()">
            <xsl:text>&#10;</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="@*">
<!--        <span class="attribute">-->
<!--            <span class="attribute_name">-->
                <xsl:text>@</xsl:text><xsl:value-of select="name(.)"/>
<!--            </span>-->
<!--            <span class="attribute_value">-->
                <xsl:text>="</xsl:text><xsl:value-of select="."/><xsl:text>"</xsl:text>
            <!--</span>-->
        <!--</span>-->
    </xsl:template>
    <xsl:template match="text()">
        <xsl:value-of select="normalize-space()"/>
    </xsl:template>
</xsl:stylesheet>