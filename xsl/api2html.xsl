<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:api="http://acdh.oeaw.ac.at/webapp/api" version="2.0" xmlns="http://www.w3.org/1999/xhtml"
    xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:import href="entry2html.xsl"/>
    <xsl:variable name="field" select="root()//api:query-param[@name = 'field']"/>
    <xsl:template match="api:response">
        <xsl:variable name="operation" select="if (exists(api:browse)) then 'browse' else 'query'"/>
        <div>
            <h3>Results</h3>
            <div xml:space="preserve">Matches <xsl:value-of select="count(api:results/*)"/> of <xsl:value-of select="api:results/@total"/></div>
            <div class="panel-group pull-right" id="debug" role="tablist" aria-multiselectable="true">
                <div class="panel panel-default">
                    <div class="panel-heading" role="tab" id="headingOne">
                        <h4 class="panel-title">
                            <a role="button" data-toggle="collapse" data-parent="#accordion" href="#collapseOne" aria-expanded="true" aria-controls="collapseOne">
                                Debug
                            </a>
                        </h4>
                    </div>
                    <div id="collapseOne" class="panel-collapse collapse out" role="tabpanel" aria-labelledby="headingOne">
                        <div class="panel-body">
                            <xsl:apply-templates select="." mode="debug"/>
                        </div>
                    </div>
                </div>
            </div>
            <xsl:apply-templates select="api:results"/>
        </div>
        <!--<xsl:if test="count(api:results/*) lt xs:integer(api:results/@total)">
            <xsl:variable name="max" select="(api:browse | api:query)/xs:integer(@max)"/>
            <xsl:variable name="startAt" select="(api:browse | api:query)/xs:integer(@startAt) + $max"/>
            <a href="{$endpoint}?field={$field}&amp;startAt={$startAt}&amp;max={$max}">Next</a>
            <xsl:value-of select="$operation"/>
        </xsl:if>-->
    </xsl:template>

    <xsl:template match="api:results">
        <xsl:variable name="startAt" as="xs:integer" select="../(api:browse|api:query)/@startAt"/>
        <xsl:variable name="currentMode" select="../(api:query|api:browse)/local-name()"/>
        <ol start="{$startAt}">            
            <xsl:for-each select="*">
                <li>
                    <xsl:choose>
                        <!-- clicking on a "browse" result leads to a query -->
                        <xsl:when test="$currentMode eq 'browse'">
                            <a href="search.html?field={$field}&amp;q={.}"><xsl:apply-templates/></a>
                        </xsl:when>
                        <!-- query results are MODS records, clicking on one, returns the entry  -->
                        <xsl:when test="$currentMode eq 'query'">
                            <a href="entry.html?id={ancestor-or-self::mods:mods/@xml:id}"><xsl:call-template name="entryLinkText"></xsl:call-template></a>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </li>
            </xsl:for-each>
        </ol>
        <xsl:apply-templates select="." mode="pagination"/>
    </xsl:template>
    
    <xsl:template name="entryLinkText">
        <xsl:call-template name="shortCitation"/>
    </xsl:template>
    
    <xsl:template match="api:term">
        <li xml:space="preserve"><a href="?field={$field}&amp;q={.}"><xsl:value-of select="."/></a> (<xsl:value-of select="@occurences"/>)</li>
    </xsl:template>
    <xsl:template match="mods:titleInfo">
        <span xml:space="preserve"><xsl:apply-templates/></span>
    </xsl:template>
    <xsl:template match="mods:title">
        <xsl:value-of select="."/>
    </xsl:template>
    <xsl:template match="mods:nonSort">
        <xsl:text>_</xsl:text>
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="mods:mods">
        <xsl:apply-templates/>
    </xsl:template>
    
    
    
    
    
    <!--      DEBUG MODE          -->  
    
    <xsl:template match="api:response" mode="debug">
        <table class="table">
            <tbody><xsl:apply-templates select="api:*" mode="#current"/></tbody>
        </table>
    </xsl:template>
    
    <xsl:template match="api:results" mode="debug">
        <xsl:apply-templates select="*|@*" mode="debug"/>
    </xsl:template>
    
    <xsl:template match="api:results/*" mode="debug"/>
    
    <xsl:template match="api:query-param" mode="debug">
        <tr>
            <td xml:space="preserve">Query Param "<xsl:value-of select="@name"/>": </td>
            <td><xsl:value-of select="."/></td>
        </tr>
    </xsl:template>
    
    <xsl:template match="api:query|api:browse" mode="debug">
        <tr>
            <td>Method: </td>
            <td><xsl:value-of select="local-name()"/></td>
        </tr>
        <xsl:apply-templates select="*|@*" mode="debug"/>
    </xsl:template>
    
    
    <xsl:template match="@*|*" mode="debug">
        <tr>
            <td><xsl:value-of select="local-name()"/>: </td>
            <td><xsl:value-of select="."/></td>
        </tr>
        <xsl:apply-templates select="*|@*" mode="debug"/>
    </xsl:template>
    
    
    <!--  PAGINATION  -->    
    <xsl:template match="api:results" mode="pagination">
        <xsl:variable name="action" select="../(api:browse|api:query)/local-name()"/>
        <xsl:variable name="max" as="xs:integer" select="../(api:browse|api:query)/@max"/>
        <xsl:variable name="startAt" as="xs:integer" select="../(api:browse|api:query)/@startAt"/>
        <xsl:variable name="order" as="xs:string?" select="../(api:browse|api:query)/@order"/>
        <xsl:variable name="total" as="xs:integer" select="@total"/>
        <xsl:variable name="pages" as="xs:integer" select="if ($total mod $max eq 0) then xs:integer($total div $max) else xs:integer(ceiling($total div $max)*$max)"/>
        <xsl:variable name="startAtPage" as="xs:integer" select="xs:integer(ceiling($startAt div $max))"/>
        <xsl:variable name="navPagesWindow" as="xs:integer" select="5"/>
        <xsl:variable name="navPages" as="xs:integer*">
            <xsl:for-each select="1 to $navPagesWindow">
                <xsl:sequence select="($startAtPage + ., $startAtPage - .)"/>
            </xsl:for-each>
            <xsl:sequence select="$startAtPage"/>
        </xsl:variable>
        <xsl:if test="$total gt $max">
            <nav aria-label="Results navigation">
                <ol class="pagination">
                    <xsl:for-each-group select="1 to $total" group-by="ceiling(position() div $max)">   
                        <xsl:sort select="current-grouping-key()" order="ascending"/>
                        <xsl:choose>
                            <xsl:when test="current-grouping-key() = $navPages">
                                <li>
                                    <xsl:if test="$startAtPage eq current-grouping-key()">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <xsl:call-template name="navLink">
                                        <xsl:with-param name="page" select="current-grouping-key()"/>
                                        <xsl:with-param name="startAtPage" select="$startAtPage"/>
                                        <xsl:with-param name="max" select="$max"/>
                                        <xsl:with-param name="order" select="$order"/>
                                        <xsl:with-param name="action" select="$action"/>
                                    </xsl:call-template>
                                </li>
                            </xsl:when>
                            <xsl:when test="current-grouping-key() eq min($navPages)-1">
                                <li>
                                    <xsl:call-template name="navLink">
                                        <xsl:with-param name="page" select="current-grouping-key()"/>
                                        <xsl:with-param name="startAtPage" select="$startAtPage"/>
                                        <xsl:with-param name="max" select="$max"/>
                                        <xsl:with-param name="order" select="$order"/>
                                        <xsl:with-param name="action" select="$action"/>
                                        <xsl:with-param name="text">«</xsl:with-param>
                                    </xsl:call-template>
                                </li>
                            </xsl:when>
                            <xsl:when test="current-grouping-key() eq max($navPages)+1">
                                <li>
                                    <xsl:call-template name="navLink">
                                        <xsl:with-param name="page" select="current-grouping-key()"/>
                                        <xsl:with-param name="startAtPage" select="$startAtPage"/>
                                        <xsl:with-param name="max" select="$max"/>
                                        <xsl:with-param name="order" select="$order"/>
                                        <xsl:with-param name="action" select="$action"/>
                                        <xsl:with-param name="text">»</xsl:with-param>
                                    </xsl:call-template>
                                </li>
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:for-each-group>
                </ol>
            </nav>
        </xsl:if>
    </xsl:template>
    <xsl:template name="navLink">
        <xsl:param name="page"/>
        <xsl:param name="text" select="$page"/>
        <xsl:param name="startAtPage"/>
        <xsl:param name="action"/>
        <xsl:param name="order"/>
        <xsl:param name="max"/>
        <a class="ajaxref" aria-label="{$page}">
            <xsl:if test="not($startAtPage eq $page)">
                <xsl:attribute name="href">
                    <xsl:value-of select="$action"/>
                    <xsl:text>?field=</xsl:text>
                    <xsl:value-of select="$field"/>
                    <xsl:text>&amp;order=</xsl:text>
                    <xsl:value-of select="$order"/>
                    <xsl:text>&amp;startAt=</xsl:text>
                    <xsl:value-of select=".[1]"/>
                    <xsl:text>&amp;max=</xsl:text>
                    <xsl:value-of select="$max"/>
                </xsl:attribute> 
            </xsl:if>
            <span aria-hidden="true">
                <xsl:value-of select="$text"/>
            </span>
        </a>
    </xsl:template>
</xsl:stylesheet>
