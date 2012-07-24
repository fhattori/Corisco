<?xml version="1.0" encoding="UTF-8"?>

<!--
  new-structural.xsl

  Copyright (c) 2010-2011, Brasiliana Digital Library (http://brasiliana.usp.br).
  Copyright (c) 2002-2005, Hewlett-Packard Company and Massachusetts
  Institute of Technology.  All rights reserved.
 
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:
 
  - Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
 
  - Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
 
  - Neither the name of the Hewlett-Packard Company nor the name of the
  Massachusetts Institute of Technology nor the names of their
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.
 
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
  DAMAGE.
-->

<!--
    Author: Fernando Hattori
-->

<xsl:stylesheet xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
        xmlns:dri="http://di.tamu.edu/DRI/1.0/"
        xmlns:mets="http://www.loc.gov/METS/"
        xmlns:xlink="http://www.w3.org/TR/xlink/"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
        xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"
        xmlns:xhtml="http://www.w3.org/1999/xhtml"
        xmlns:mods="http://www.loc.gov/mods/v3"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:exsl="http://exslt.org/common"
        xmlns:fn="http://www.w3.org/2005/xpath-functions"
        xmlns="http://www.w3.org/1999/xhtml"
        extension-element-prefixes="exsl"
        exclude-result-prefixes="#default dri mets xlink xsl dim xhtml mods dc exsl fn">
    
    <xsl:output indent="yes"/>

    <xsl:variable name="string-max-length">80</xsl:variable>

    <!-- This stylesheet's purpose is to translate a DRI document to an HTML one, a task which it accomplishes
        through interative application of templates to select elements. While effort has been made to
        annotate all templates to make this stylesheet self-documenting, not all elements are used (and
        therefore described) here, and those that are may not be used to their full capacity. For this reason,
        you should consult the DRI Schema Reference manual if you intend to customize this file for your needs.
    -->

    <!--
        The starting point of any XSL processing is matching the root element. In DRI the root element is document,
        which contains a version attribute and three top level elements: body, options, meta (in that order).
        
        This template creates the html document, giving it a head and body. A title and the CSS style reference
        are placed in the html head, while the body is further split into several divs. The top-level div
        directly under html body is called "ds-main". It is further subdivided into:
            "ds-header"  - the header div containing title, subtitle, trail and other front matter
            "ds-body"    - the div containing all the content of the page; built from the contents of dri:body
            "ds-options" - the div with all the navigation and actions; built from the contents of dri:options
            "ds-footer"  - optional footer div, containing misc information
        
        The order in which the top level divisions appear may have some impact on the design of CSS and the
        final appearance of the DSpace page. While the layout of the DRI schema does favor the above div
        arrangement, nothing is preventing the designer from changing them around or adding new ones by
        overriding the dri:document template.
    -->

    <xsl:template name="buildHead">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <meta name="Generator">
          <xsl:attribute name="content">
            <xsl:text>DSpace</xsl:text>
            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='dspace'][@qualifier='version']">
              <xsl:text> </xsl:text>
              <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='dspace'][@qualifier='version']"/>
            </xsl:if>
          </xsl:attribute>
        </meta>
	<!-- Add stylsheets -->
        <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='stylesheet']">
          <link rel="stylesheet" type="text/css">
            <xsl:attribute name="media">
              <xsl:value-of select="@qualifier"/>
            </xsl:attribute>
            <xsl:attribute name="href">
              <xsl:value-of select="$theme-path"/>
              <xsl:text>/</xsl:text>
              <xsl:value-of select="."/>
            </xsl:attribute>
          </link>
        </xsl:for-each>
	
        <!-- Add syndication feeds -->
        <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='feed']">
          <link rel="alternate" type="application">
            <xsl:attribute name="type">
              <xsl:text>application/</xsl:text>
              <xsl:value-of select="@qualifier"/>
            </xsl:attribute>
            <xsl:attribute name="href">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </link>
        </xsl:for-each>
	
	<!--  Add OpenSearch auto-discovery link -->
	<xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='shortName']">
	  <link rel="search" type="application/opensearchdescription+xml">
            <xsl:attribute name="href">
              <xsl:value-of select="$absolute-base-url"/>
              <xsl:text>/</xsl:text>
              <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='context']"/>
              <xsl:text>description.xml</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="title" >
              <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='shortName']"/>
            </xsl:attribute>
	  </link>
	</xsl:if>
	
	<!-- The following javascript removes the default text of empty text areas when they are focused on or submitted -->
	<!-- There is also javascript to disable submitting a form when the 'enter' key is pressed. -->
	<script type="text/javascript">
	  //Clear default text of emty text areas on focus
	  function tFocus(element)
	  {
	  if (element.value == '<i18n:text>xmlui.dri2xhtml.default.textarea.value</i18n:text>'){element.value='';}
	  }
	  //Clear default text of emty text areas on submit
	  function tSubmit(form)
          {
	  var defaultedElements = document.getElementsByTagName("textarea");
	  for (var i=0; i != defaultedElements.length; i++){
	  if (defaultedElements[i].value == '<i18n:text>xmlui.dri2xhtml.default.textarea.value</i18n:text>'){
	  defaultedElements[i].value='';}}
	  }
	  //Disable pressing 'enter' key to submit a form (otherwise pressing 'enter' causes a submission to start over)
	  function disableEnterKey(e)
	  {
	  var key;
	  
	  if(window.event)
	  key = window.event.keyCode;     //Internet Explorer
	  else
	  key = e.which;     //Firefox and Netscape
	  
	  if(key == 13)  //if "Enter" pressed, then disable!
	  return false;
	  else
	  return true;
	  }
	</script>
	
	<!-- add "external" javascript from static, path is absolute-->
	<xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][@qualifier='external']">
	  <script type="text/javascript">
            <xsl:attribute name="src">
              <xsl:value-of select="."/>
            </xsl:attribute>&#160;
	  </script>
	</xsl:for-each>
	
	<xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][@qualifier='plugin']">
	  <script type="text/javascript">
            <xsl:attribute name="src">
              <xsl:value-of select="$theme-path"/>
              <xsl:text>/</xsl:text>
              <xsl:value-of select="."/>
            </xsl:attribute>&#160;
	  </script>
	</xsl:for-each>
	
	<!-- add "shared" javascript from static, path is relative to webapp root-->
	<xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][@qualifier='static']">
	  <script type="text/javascript">
            <xsl:attribute name="src">
              <xsl:value-of select="$context-path"/>
              <xsl:text>/</xsl:text>
              <xsl:value-of select="."/>
            </xsl:attribute>&#160;
	  </script>
	</xsl:for-each>
	
	<!-- Add theme javascipt  -->
	<xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][not(@qualifier)]">
	  <script type="text/javascript">
            <xsl:attribute name="src">
              <xsl:value-of select="$theme-path"/>
              <xsl:text>/</xsl:text>
              <xsl:value-of select="."/>
            </xsl:attribute>&#160;
	  </script>
	</xsl:for-each>
	
	<!-- Add the title in -->
	<xsl:variable name="page_title" select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='title']" />
	<title>
	  <xsl:choose>
            <xsl:when test="not($page_title)">
              <xsl:text>  </xsl:text>
            </xsl:when>
            <xsl:otherwise>
	      <xsl:choose>
		<xsl:when test="$page_title[not(i18n:text[@catalogue='default'])]">
		  <xsl:copy-of select="$page_title[not(i18n:text[@catalogue='default'])]/node()" />
		</xsl:when>
		<xsl:otherwise>
		  <xsl:copy-of select="$page_title/node()" />
		</xsl:otherwise>
	      </xsl:choose>
            </xsl:otherwise>
	  </xsl:choose>
	</title>
	
	<!-- Head metadata in item pages -->
	<xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='xhtml_head_item']">
	  <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='xhtml_head_item']"
			disable-output-escaping="yes"/>
	</xsl:if>
	
	<!-- Switching to new asynchronous code. -->
	<xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']">
	  <script type="text/javascript">
            <xsl:text>
              var _gaq = _gaq || [];
              _gaq.push(['_setAccount', '</xsl:text>
            <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']"/>
            <xsl:text>']);
              _gaq.push(['_trackPageview']);
	      
              (function() {
              var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
              ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
              var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
              })();
            </xsl:text>
	  </script>
	</xsl:if>
      </head>
    </xsl:template>

    <xsl:template name="conteudo-baixo">
      <div id="conteudo-baixo" class="borda">
        <form>
          <xsl:attribute name="id">formulario-busca</xsl:attribute>
          <xsl:attribute name="method">GET</xsl:attribute>
	  <xsl:call-template name="caixa-barra">
            <xsl:with-param name="position" select="'bottom'"/>
          </xsl:call-template>
        </form>
      </div>
    </xsl:template>

    <xsl:template name="caixa-barra">
        <xsl:param name="position" select="'top'"/>
        <xsl:choose>
            <xsl:when test="/dri:document/dri:body/dri:div[@n='search']">
                <!--<xsl:apply-templates select="//dri:body/dri:div[@n='search']//dri:table[@n='search-controls']"/>-->
                <xsl:apply-templates select="//dri:div[@n='search-controls']"/>
            </xsl:when>
            <xsl:when test="/dri:document/dri:body/dri:div[starts-with(@n, 'browse-by-')]">
                <xsl:apply-templates select="//dri:body/dri:div[starts-with(@n, 'browse-by-')]/dri:div[@n='browse-controls']"/>
            </xsl:when>
            <xsl:when test="/dri:document/dri:body/dri:div[@n='item-view']">
                <xsl:comment>item-view empty</xsl:comment>
                <xsl:if test="$position = 'bottom'">
                    <div class="visualizador-barra caixa"><xsl:comment>item-view</xsl:comment></div>
<!--                <xsl:apply-templates select="/dri:document/dri:body/dri:div[@n='item-view']" mode="viewControls"/>-->
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>caixa-barra: empty for everything else.</xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="//dri:div[@n='search-controls']" priority="4">
      <div class="caixa">
        <xsl:apply-templates select="//dri:div[@n='search-results']/@pagination"/>
	<xsl:if test="dri:list//dri:field[@n='rpp']">
	  <div class="resultados-pagina">
            <span class="barra-texto"><xsl:apply-templates select="dri:list/dri:item/child::*[1]"/></span>
	    <xsl:apply-templates select="//dri:div[@interactive='yes'][@n='search-controls']/dri:list//dri:field[@n='rpp']" mode="searchControls"/>
	  </div>
	</xsl:if>
	<xsl:if test="dri:list//dri:field[@n='sort_by'] and dri:list//dri:field[@n='order']">
	  <div class="resultados-ordenar">
            <span class="barra-texto"><xsl:apply-templates select="dri:list/dri:item/child::*[3]"/></span>
	    <span class="barra-texto">
              <xsl:apply-templates select="//dri:div[@interactive='yes'][@n='search-controls']/dri:list//dri:field[@n='sort_by']" mode="searchControls"/>
            </span>
	    <span class="ordenar-crescente">
              <xsl:apply-templates select="//dri:div[@interactive='yes'][@n='search-controls']/dri:list//dri:field[@n='order']/dri:option[@returnValue='ASC']" mode="searchControlsImage"/>
            </span>
            <span class="ordenar-decrescente">
	      <xsl:apply-templates select="//dri:div[@interactive='yes'][@n='search-controls']/dri:list//dri:field[@n='order']/dri:option[@returnValue='DESC']" mode="searchControlsImage"/>
            </span>
	  </div>
        </xsl:if>
      </div>
    </xsl:template>

    <xsl:template match="dri:referenceSet[@type = 'summaryList'][dri:reference[not(@type='DSpace Item')]]" priority="1">
        <!--NEVER SHOW RESULTS FOR COMMUNITIES AND COLLECTIONS NAMES.-->
    </xsl:template>

    <xsl:template match="dri:div[@id='aspect.discovery.SimpleSearch.div.search']" priority="10">
        <xsl:apply-templates select="*[not(@n='search-controls') and not(name()='head')]"/>
    </xsl:template>

    <xsl:template match="dri:options/dri:list[dri:list][@n='community-structure']"
		  priority="4">
      <xsl:apply-templates select="*[not(name()='head')]" mode="nested"/>
    </xsl:template>

    <xsl:template match="dri:options/dri:list[@n='community-structure']/dri:list[@n='community']"
		  priority="4" mode="nested">
      <div id="titulo-refinar" class="borda">
        <h3>
          <xsl:apply-templates select="dri:item"/>
        </h3>
      </div>
      <xsl:apply-templates select="dri:list" mode="nested"/>
    </xsl:template>

    <!-- Special case for nested options lists -->
    <xsl:template match="dri:options/dri:list/dri:list/dri:list[@n='oncommunity']"
		  priority="3" mode="nested">
      <xsl:apply-templates select="dri:item" mode="nested"/>
      <xsl:apply-templates select="dri:list" mode="nested"/>
    </xsl:template>

    <xsl:template match="dri:options/dri:list/dri:list/dri:list[@n='oncommunity']/dri:item"
                  priority="3" mode="nested">
      <div id="ano" class="borda">
	  <xsl:apply-templates />
      </div>
    </xsl:template>

    <xsl:template match="dri:options/dri:list/dri:list/dri:list[@n='oncommunity']/dri:list"
                  priority="3" mode="nested">
      <div id="ano" class="borda">
        <xsl:apply-templates select="dri:item"/>
	<span class="mais-filtro">
          <img>
            <xsl:attribute name="src">
              <xsl:value-of select="$images-path"/>
              <xsl:text>mais_filtro.png</xsl:text>
	    </xsl:attribute>
          </img>
	</span>
      <ul class="caixa">
	<xsl:apply-templates select="dri:list" mode="nested"/>
      </ul>
      </div>
    </xsl:template>
    
    <xsl:template match="dri:options/dri:list[dri:list][@n='discovery']" priority="4">
      <!--
      <xsl:apply-templates select="//dri:div[@n='search-filters']" />
      -->
      <!-- Once the search box is built, the other parts of the options are added -->
      <div id="titulo-refinar" class="borda">
        <h3><i18n:text>xmlui.dri2xhtml.structural.search-filter</i18n:text></h3>
      </div>

      <xsl:apply-templates select="*[not(name()='head')]" mode="nested"/>
    </xsl:template>

    <xsl:template match="dri:options/dri:list[@n='secondary-search']" priority="3">
      <xsl:if test="count(dri:item) > 0">
	<div id="titulo-buscas" class="borda">
          <h3><i18n:text>xmlui.Discovery.SimpleSearch.filter_head</i18n:text></h3>
	</div>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="dri:field[@type='composite']">
          <xsl:call-template name="pick-label"/>
          <xsl:apply-templates select="*[not(name()='head')]" mode="formComposite"/>
        </xsl:when>
        <xsl:when test="dri:list[@type='form']">
          <xsl:apply-templates />
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="pick-label"/>
            <xsl:apply-templates select="*[not(name()='head')]" mode="formComposite"/>
	    <!-- special name used in submission UI review page -->
	    <xsl:if test="@n = 'submit-review-field-with-authority'">
              <xsl:call-template name="authorityConfidenceIcon">
                <xsl:with-param name="confidence" select="substring-after(./@rend, 'cf-')"/>
              </xsl:call-template>
            </xsl:if>
	    <!--                        Botão BUSCAR-->
	    <!--                        <xsl:apply-templates select="//dri:div[@interactive='yes'][@n='general-query']/dri:p"/>-->
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>
    
    <xsl:template match="dri:options//dri:item" mode="Corisco" priority="1">
      <xsl:choose>
        <xsl:when test="contains(dri:xref/@target, 'community-list')">
          <!-- SKIP -->
        </xsl:when>
        <xsl:when test="contains(dri:xref/@target, 'title')">
	  <!-- if title, change the url to discover -->
	  <li class="lista-item">
            <span>
              <a>
		<xsl:attribute name="href">
		  <xsl:value-of select="$context-path"/>
		  <xsl:if test="//dri:meta/dri:pageMeta/dri:metadata[@element='focus'][@qualifier='container']">
                    <xsl:text>/handle/</xsl:text>
                    <xsl:value-of select="substring-after(//dri:meta/dri:pageMeta/dri:metadata[@element='focus'][@qualifier='container'], ':')"/>
		  </xsl:if>
		  <xsl:text>/discover?sort_by=dc.title_sort&amp;order=ASC</xsl:text>
		</xsl:attribute>
		<xsl:attribute name="class">
		  <xsl:value-of select="@rend"/>
		</xsl:attribute>
		<xsl:apply-templates select="dri:xref/*"/>
              </a>
            </span>
	  </li>
	</xsl:when>
	<xsl:when test="contains(dri:xref/@target, 'dateissued')">
	  <!-- if dataissued, change the url to discover -->
          <li class="lista-item">
            <span>
              <a>
                <xsl:attribute name="href">
                  <xsl:value-of select="$context-path"/>
                  <xsl:if test="//dri:meta/dri:pageMeta/dri:metadata[@element='focus'][@qualifier='container']">
                    <xsl:text>/handle/</xsl:text>
                    <xsl:value-of select="substring-after(//dri:meta/dri:pageMeta/dri:metadata[@element='focus'][@qualifier='container'], ':')"/>
                  </xsl:if>
                  <xsl:text>/discover?sort_by=dc.date.issued_dt&amp;order=ACS</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="class">
                  <xsl:value-of select="@rend"/>
                </xsl:attribute>
                <xsl:apply-templates select="dri:xref/*"/>
              </a>
            </span>
          </li>
        </xsl:when>
        <xsl:otherwise>
          <li class="lista-item">
            <span><xsl:apply-templates /></span>
          </li>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>
    
    <xsl:template match="dri:list[@n='account']" priority="100">
      <!-- hide -->
    </xsl:template>
    
</xsl:stylesheet>
