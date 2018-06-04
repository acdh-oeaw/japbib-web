<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs sru"
    version="3.0">
    
    <xsl:output indent="yes" method="xhtml"/>
    
    <xsl:import href="sru2ajax.xsl"/>
    
    <xsl:template match="/">
        <div class="ajax-result">
            <xsl:apply-templates select="taxonomy"/>
            <xsl:apply-templates select="sru:searchRetrieveResponse/sru:extraResponseData/subjects/taxonomy"/>
        </div>
    </xsl:template>
        
    <xsl:template match="taxonomy">
        <ol class="schlagworte"><xsl:apply-templates select="*"/></ol>
    </xsl:template>
    
    <xsl:template match="category[matches(@n, '^[123456789]$')]">
        <xsl:apply-imports/>
    </xsl:template>
    
    <xsl:template match="category"> 
        <li class="li{count(ancestor::category)+1}"> 
            <span class="wrapTerm">                
                <span class="term {if (category) then 'plusMinus' else ''}"
                    title="{if (category) then 'Unterschlagworte zeigen/ verbergen' else ''}"><xsl:value-of select="catDesc"/></span>
                <a href="#find?query=subject%3D&quot;{catDesc}&quot;" class="zahl" title="Direkte Suche auf der Sucheseite"><xsl:value-of select="numberOfRecords"/></a> 
            </span>
            <xsl:if test="category">
                <ol>
                    <xsl:apply-templates select="category"/>
                </ol>
            </xsl:if>
        </li>
    </xsl:template>
    
    <xsl:template match="catDesc"> 
        <xsl:value-of select="."/>
    </xsl:template> 

</xsl:stylesheet>