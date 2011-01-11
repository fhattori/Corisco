/**
 * $Id: Navigation.java 4845 2010-04-05 01:05:48Z mdiggory $
 * $URL: http://scm.dspace.org/svn/repo/modules/dspace-discovery/trunk/block/src/main/java/org/dspace/app/xmlui/aspect/discovery/Navigation.java $
 * *************************************************************************
 * Copyright (c) 2002-2009, DuraSpace.  All rights reserved
 * Licensed under the DuraSpace License.
 *
 * A copy of the DuraSpace License has been included in this
 * distribution and is available at: http://scm.dspace.org/svn/repo/licenses/LICENSE.txt
 */
package org.dspace.app.xmlui.aspect.discovery;

import java.io.IOException;
import java.io.Serializable;
import java.sql.SQLException;

import org.apache.cocoon.caching.CacheableProcessingComponent;
import org.apache.cocoon.environment.ObjectModelHelper;
import org.apache.cocoon.environment.Request;
import org.apache.cocoon.util.HashUtil;
import org.apache.excalibur.source.SourceValidity;
import org.apache.excalibur.source.impl.validity.NOPValidity;
import org.dspace.app.xmlui.cocoon.AbstractDSpaceTransformer;
import org.dspace.app.xmlui.utils.HandleUtil;
import org.dspace.app.xmlui.utils.UIException;
import org.dspace.app.xmlui.wing.Message;
import org.dspace.app.xmlui.wing.WingException;
import org.dspace.app.xmlui.wing.element.Composite;
import org.dspace.app.xmlui.wing.element.List;
import org.dspace.app.xmlui.wing.element.Options;
import org.dspace.app.xmlui.wing.element.PageMeta;
import org.dspace.app.xmlui.wing.element.Item;
import org.dspace.app.xmlui.wing.element.Select;
import org.dspace.authorize.AuthorizeException;
import org.dspace.content.Collection;
import org.dspace.content.Community;
import org.dspace.content.DSpaceObject;
import org.dspace.core.ConfigurationManager;
import org.dspace.discovery.SearchUtils;
import org.xml.sax.SAXException;

/**
 * This transform applies the basic navigational links that should be available
 * on all pages generated by DSpace.
 * 
 * @author Scott Phillips
 */
public class Navigation extends AbstractDSpaceTransformer implements CacheableProcessingComponent
{
    private static final Message T_FILTER_HELP = message("xmlui.Discovery.Navigation.top-search.help");
    private static final Message T_FILTER_HEAD = message("xmlui.Discovery.Navigation.top-search.head");

    
    public static final String FACET_FIELD = "field";

    /**
     * Generate the unique caching key.
     * This key must be unique inside the space of this component.
     */
    @Override
    public Serializable getKey() {
        try {
            Request request = ObjectModelHelper.getRequest(objectModel);
            String key = request.getScheme() + request.getServerName() + request.getServerPort() + request.getSitemapURI() + request.getQueryString();
            
            DSpaceObject dso = HandleUtil.obtainHandle(objectModel);
            if (dso != null)
                key += "-" + dso.getHandle();

            return HashUtil.hash(key);
        } 
        catch (SQLException sqle)
        {
            // Ignore all errors and just return that the component is not cachable.
            return "0";
        }
    }

    /**
     * Generate the cache validity object.
     * 
     * The cache is always valid.
     */
    @Override
    public SourceValidity getValidity() {
        return NOPValidity.SHARED_INSTANCE;
    }
    
    /**
     * Add the basic navigational options:
     * 
     * Search - advanced search
     * 
     * browse - browse by Titles - browse by Authors - browse by Dates
     * 
     * language FIXME: add languages
     * 
     * context no context options are added.
     * 
     * action no action options are added.
     */
    @Override
    public void addOptions(Options options) throws SAXException, WingException,
            UIException, SQLException, IOException, AuthorizeException
    {
//        DSpaceObject dso = HandleUtil.obtainHandle(objectModel);

        //List test = options.addList("browse");

        //        browseGlobal.addItem().addXref(contextPath + "/community-list", T_head_all_of_dspace );

        /*
        if (dso != null)
        {
            if (dso instanceof Item)
            {
                // If we are an item change the browse scope to the parent
                // collection.
                dso = ((Item) dso).getOwningCollection();
            }

            if (dso instanceof Collection)
            {
                browseContext.setHead(T_head_this_collection);
            }
            if (dso instanceof Community)
            {
                browseContext.setHead(T_head_this_community);
            }
        }*/
        
        List topSearchList = options.addList("top-search");

        int i = 1;
        String field = SearchUtils.getConfig().getString("solr.search.filter.type." + i, null);
        if (field != null) {
            //We have at least one filter so add our filter box
            Item item = topSearchList.addItem("search-filter-list", "search-filter-list");
            Composite filterComp = item.addComposite("search-filter-controls");
            filterComp.setLabel(T_FILTER_HEAD);
            filterComp.setHelp(T_FILTER_HELP);

//            filterComp.setLabel("");

            Select select = filterComp.addSelect("filtertype");
            //First of all add a default filter
            select.addOption("*", message("xmlui.ArtifactBrowser.SimpleSearch.filter.all"));
            //For each field found (at least one) add options

            while (field != null) {
                select.addOption(field, message("xmlui.ArtifactBrowser.SimpleSearch.filter." + field));

                field = SearchUtils.getConfig().getString("solr.search.filter.type." + ++i, null);
            }

            //Add a box so we can search for our value
//            Text fieldText = filterComp.addText("filter");
            filterComp.addText("filter");

            //And last add an add button
            filterComp.enableAddOperation();
        }

    }

    /**
     * Insure that the context path is added to the page meta.
     */
    @Override
    public void addPageMeta(PageMeta pageMeta) throws SAXException,
            WingException, UIException, SQLException, IOException,
            AuthorizeException
    {
        // FIXME: I don't think these should be set here, but there needed and I'm
        // not sure where else it could go. Perhaps the linkResolver?
    	Request request = ObjectModelHelper.getRequest(objectModel);
        pageMeta.addMetadata("contextPath").addContent(contextPath);
        pageMeta.addMetadata("request","queryString").addContent(request.getQueryString());
        pageMeta.addMetadata("request","scheme").addContent(request.getScheme());
        pageMeta.addMetadata("request","serverPort").addContent(request.getServerPort());
        pageMeta.addMetadata("request","serverName").addContent(request.getServerName());
        pageMeta.addMetadata("request","URI").addContent(request.getSitemapURI());
        
        
        String analyticsKey = ConfigurationManager.getProperty("xmlui.google.analytics.key");
        if (analyticsKey != null && analyticsKey.length() > 0)
        {
        	analyticsKey = analyticsKey.trim();
        	pageMeta.addMetadata("google","analytics").addContent(analyticsKey);
        }
        
        // Add metadata for quick searches:
        pageMeta.addMetadata("search", "simpleURL").addContent(
                contextPath + "/search");
        //pageMeta.addMetadata("search", "advancedURL").addContent(
        //        contextPath + "/advanced-search");
        pageMeta.addMetadata("search", "queryField").addContent("query");
        
        pageMeta.addMetadata("page","contactURL").addContent(contextPath + "/contact");
        pageMeta.addMetadata("page","feedbackURL").addContent(contextPath + "/feedback");
        
        DSpaceObject dso = HandleUtil.obtainHandle(objectModel);
        if (dso != null)
        {
            if (dso instanceof org.dspace.content.Item)
            {
                pageMeta.addMetadata("focus","object").addContent("hdl:"+dso.getHandle());
                this.getObjectManager().manageObject(dso);
                dso = ((org.dspace.content.Item) dso).getOwningCollection();
            }
            
            if (dso instanceof Collection || dso instanceof Community)
            {
                pageMeta.addMetadata("focus","container").addContent("hdl:"+dso.getHandle());
                this.getObjectManager().manageObject(dso);
            }
        }
    }

    /**
     * Add navigation for the configured browse tables to the supplied list.
     *
     * @param browseList
     * @param browseURL
     * @throws WingException
     */
/*    private void addBrowseOptions(List browseList, String browseURL) throws WingException
    {
        // FIXME Exception handling
        try
        {
            // Get a Map of all the browse tables
            String[] facets = SearchUtils.getFacetsForType("browse");
            for (String facet : facets)
            {
                // Create a Map of the query parameters for this link
                Map<String, String> parameters = new HashMap<String, String>();
                parameters.put(FACET_FIELD, facet);

                // Add a link to this browse
                browseList.addItemXref(generateURL(browseURL, parameters),
                        message("xmlui.ArtifactBrowser.Navigation.browse_" + facet));
            }
        }
        catch (Exception bex)
        {
            throw new UIException("Unable to get browse indicies", bex);
        }
    }*/

}
