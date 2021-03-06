/**
 * $Id: SearchServiceException.java 4679 2010-01-11 20:05:13Z mdiggory $
 * $URL: http://scm.dspace.org/svn/repo/modules/dspace-discovery/trunk/provider/src/main/java/org/dspace/discovery/SearchServiceException.java $
 * *************************************************************************
 * Copyright (c) 2002-2009, DuraSpace.  All rights reserved
 * Licensed under the DuraSpace License.
 *
 * A copy of the DuraSpace License has been included in this
 * distribution and is available at: http://scm.dspace.org/svn/repo/licenses/LICENSE.txt
 */
package org.dspace.discovery;

import org.apache.solr.client.solrj.SolrServerException;

/**
 * User: mdiggory
 * Date: Oct 19, 2009
 * Time: 1:30:47 PM
 */
public class SearchServiceException extends Exception {

    public SearchServiceException() {
    }

    public SearchServiceException(String s) {
        super(s);
    }

    public SearchServiceException(String s, Throwable throwable) {
        super(s, throwable);
    }

    public SearchServiceException(Throwable throwable) {
        super(throwable);
    }
    
}
