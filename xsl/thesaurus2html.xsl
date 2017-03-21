<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:template match="/taxonomy">
	<ul>
	    <xsl:apply-templates/>
	</ul>
    </xsl:template>
    <xsl:template match="category">
        <li class="li{count(ancestor::category)+1}">
            <xsl:apply-templates select="catDesc"/>
            <xsl:if test="category">
                <ul>
                    <xsl:apply-templates select="category"/>
                </ul>
            </xsl:if>
        </li>
    </xsl:template>
    <xsl:template match="catDesc">
        <span>
            <xsl:if test="../category">
                <xsl:attribute name="class">sup</xsl:attribute>
            </xsl:if>
            <xsl:value-of select="concat(../@n,' ', .)"/>
        </span>
    </xsl:template>

</xsl:stylesheet>